# typed: strict
# frozen_string_literal: true

# Optimize RBI to cache expensive case/Module#=== checks.
module RBI
  # Replace the giant 40-branch case statement in Visitor#visit with a hash dispatch table.
  # This reduces O(n) type checks per visit to O(1) hash lookup.
  class Visitor
    VISIT_DISPATCH = {
      BlankLine => :visit_blank_line,
      RBSComment => :visit_rbs_comment,
      Comment => :visit_comment,
      TEnum => :visit_tenum,
      TStruct => :visit_tstruct,
      Module => :visit_module,
      Class => :visit_class,
      SingletonClass => :visit_singleton_class,
      Struct => :visit_struct,
      Group => :visit_group,
      VisibilityGroup => :visit_visibility_group,
      ConflictTree => :visit_conflict_tree,
      ScopeConflict => :visit_scope_conflict,
      TEnumBlock => :visit_tenum_block,
      Tree => :visit_tree,
      Const => :visit_const,
      AttrAccessor => :visit_attr_accessor,
      AttrReader => :visit_attr_reader,
      AttrWriter => :visit_attr_writer,
      Method => :visit_method,
      ReqParam => :visit_req_param,
      OptParam => :visit_opt_param,
      RestParam => :visit_rest_param,
      KwParam => :visit_kw_param,
      KwOptParam => :visit_kw_opt_param,
      KwRestParam => :visit_kw_rest_param,
      BlockParam => :visit_block_param,
      Include => :visit_include,
      Extend => :visit_extend,
      Public => :visit_public,
      Protected => :visit_protected,
      Private => :visit_private,
      Send => :visit_send,
      KwArg => :visit_kw_arg,
      Arg => :visit_arg,
      Sig => :visit_sig,
      SigParam => :visit_sig_param,
      TEnumValue => :visit_tenum_value,
      TStructConst => :visit_tstruct_const,
      TStructProp => :visit_tstruct_prop,
      Helper => :visit_helper,
      TypeMember => :visit_type_member,
      MixesInClassMethods => :visit_mixes_in_class_methods,
      RequiresAncestor => :visit_requires_ancestor,
    }.freeze #: Hash[Class, Symbol]

    # Memoized class-to-method dispatch. Once a class is resolved, subsequent lookups are O(1).
    VISIT_RESOLVED = {} #: Hash[Class, Symbol]

    #: (Node? node) -> void
    def visit(node)
      return unless node

      klass = node.class
      method_name = VISIT_RESOLVED[klass]
      unless method_name
        # Walk the class hierarchy to find the matching dispatch entry
        klass.ancestors.each do |ancestor|
          method_name = VISIT_DISPATCH[ancestor]
          if method_name
            VISIT_RESOLVED[klass] = method_name
            break
          end
        end
        raise VisitorError, "Unhandled node: #{node.class}" unless method_name
      end
      send(method_name, node)
    end
  end

  module Rewriters
    # Optimize GroupNodes to pre-compute group_kind once per node instead of twice
    # (once in the `kinds.map` and once in the `groups[group_kind(child)]` call).
    class GroupNodes < Visitor
      # @override
      #: (Node? node) -> void
      def visit(node)
        return unless node

        case node
        when Tree
          # Pre-compute group_kind for each child to avoid calling it twice per node
          kind_cache = {}.compare_by_identity #: Hash[Node, Group::Kind]
          node.nodes.each { |child| kind_cache[child] = group_kind(child) }

          kinds = kind_cache.values
          kinds.uniq!

          groups = {}
          kinds.each { |kind| groups[kind] = Group.new(kind) }

          node.nodes.dup.each do |child|
            visit(child)
            child.detach
            groups[kind_cache[child]] << child
          end

          groups.each { |_, group| node << group }
        end
      end
    end

    class SortNodes < Visitor
      # @override
      #: (Node? node) -> void
      def visit(node)
        sort_node_names!(node) if node

        return unless node.is_a?(Tree)

        visit_all(node.nodes)
        original_order = node.nodes.map.with_index.to_h

        # Pre-compute ranks and names for all nodes to avoid repeated case/Module#===
        # checks during O(n log n) comparisons. Uses compare_by_identity for fast lookups.
        rank_cache = {}.compare_by_identity #: Hash[Node, Integer]
        name_cache = {}.compare_by_identity #: Hash[Node, String?]
        node.nodes.each do |n|
          rank_cache[n] = node_rank(n)
          name_cache[n] = node_name(n)
        end

        sorted_nodes = node.nodes.chunk do |n|
          n.is_a?(Visibility)
        end.flat_map do |_, nodes|
          nodes.sort! do |a, b|
            res = rank_cache[a] <=> rank_cache[b]
            next res if res != 0

            res = name_cache[a] <=> name_cache[b]
            next res if res && res != 0

            original_order_a = original_order[a] #: as !nil
            original_order_b = original_order[b] #: as !nil
            original_order_a <=> original_order_b
          end
        end

        node.nodes.replace(sorted_nodes)
      end
    end
  end
end

module Tapioca
  class RBIFormatter < RBI::Formatter
    #: (RBI::File file, String command, ?reason: String?) -> void
    def write_header!(file, command, reason: nil)
      file.comments << RBI::Comment.new("DO NOT EDIT MANUALLY")
      file.comments << RBI::Comment.new("This is an autogenerated file for #{reason}.") unless reason.nil?
      file.comments << RBI::Comment.new("Please instead update this file by running `#{command}`.")
      # Prevent the header from being attached to the top-level node when generating YARD docs
      file.comments << RBI::BlankLine.new
    end

    #: (RBI::File file) -> void
    def write_empty_body_comment!(file)
      file.comments << RBI::BlankLine.new unless file.comments.empty?
      file.comments << RBI::Comment.new("THIS IS AN EMPTY RBI FILE.")
      file.comments << RBI::Comment.new("see https://github.com/Shopify/tapioca#manually-requiring-parts-of-a-gem")
    end
  end

  DEFAULT_RBI_FORMATTER = RBIFormatter.new(
    add_sig_templates: false,
    group_nodes: true,
    max_line_length: nil,
    nest_singleton_methods: true,
    nest_non_public_members: true,
    sort_nodes: true,
  ) #: RBIFormatter
end
