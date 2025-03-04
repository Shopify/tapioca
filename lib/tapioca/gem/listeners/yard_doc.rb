# typed: strict
# frozen_string_literal: true

require "rbs"

module Tapioca
  module Gem
    module Listeners
      class YardDoc < Base
        extend T::Sig

        IGNORED_COMMENTS = T.let(
          [
            ":doc:",
            ":nodoc:",
            "typed:",
            "frozen_string_literal:",
            "encoding:",
            "warn_indent:",
            "shareable_constant_value:",
            "rubocop:",
          ],
          T::Array[String],
        )

        IGNORED_SIG_TAGS = T.let(["param", "return"], T::Array[String])

        RBS_SIGNATURE_PREFIX = T.let(":", String)

        #: (Pipeline pipeline) -> void
        def initialize(pipeline)
          YARD::Registry.clear
          super(pipeline)
          pipeline.gem.parse_yard_docs
        end

        private

        # @override
        #: (ConstNodeAdded event) -> void
        def on_const(event)
          event.node.comments, _ = documentation_comments(event.symbol)
        end

        # @override
        #: (ScopeNodeAdded event) -> void
        def on_scope(event)
          event.node.comments, _ = documentation_comments(event.symbol)
        end

        # @override
        #: (MethodNodeAdded event) -> void
        def on_method(event)
          separator = event.constant.singleton_class? ? "." : "#"
          name = "#{event.symbol}#{separator}#{event.node.name}"
          event.node.comments, event.node.rbs_sigs = documentation_comments(
            name,
            sigs: event.node.sigs,
            node: event.node,
          )
        end

        #: (String name, ?sigs: Array[RBI::Sig], ?node: RBI::Method?) -> [Array[RBI::Comment], Array[RBI::RBSSig]]
        def documentation_comments(name, sigs: [], node: nil)
          yard_docs = YARD::Registry.at(name)
          return [], [] unless yard_docs

          docstring = yard_docs.docstring
          return [], [] if /(copyright|license)/i.match?(docstring)

          comments = []
          rbs_sigs = []

          docstring.lines
            .reject { |line| IGNORED_COMMENTS.any? { |comment| line.include?(comment) } }
            .map! do |line|
              if line.strip.start_with?(RBS_SIGNATURE_PREFIX)
                rbs_sigs << create_rbs_sig(line, node) if node
              else
                comments << RBI::Comment.new(line)
              end
            end

          tags = yard_docs.tags
          tags.reject! { |tag| IGNORED_SIG_TAGS.include?(tag.tag_name) } unless sigs.empty?

          comments << RBI::Comment.new("") if comments.any? && tags.any?

          tags.sort_by(&:tag_name).each do |tag|
            line = +"@#{tag.tag_name}"

            tag_name = tag.name
            line << " #{tag_name}" if tag_name

            tag_types = tag.types
            line << " [#{tag_types.join(", ")}]" if tag_types&.any?

            tag_text = tag.text
            if tag_text && !tag_text.empty?
              text_lines = tag_text.lines

              # Example are a special case because we want the text to start on the next line
              line << " #{text_lines.shift&.strip}" unless tag.tag_name == "example"

              text_lines.each do |text_line|
                line << "\n  #{text_line.strip}"
              end
            end

            comments << RBI::Comment.new(line)
          end

          [comments, rbs_sigs]
        end

        #: (String line, RBI::Method node) -> RBI::RBSSig
        def create_rbs_sig(line, node)
          sig = T.must(line[1..]).strip

          # attr_* methods don't have to specify "->" in their signatures but since we convert it
          # to a regular method definitions we need to have "->" to represent the return type.
          # Also we need be careful of proc types since they contain a "->" already.
          if !sig.include?("->")
            sig = "-> #{sig}"
          elsif sig.include?("^") # Proc type
            sig = add_return_type_for_proc(sig)
          end

          sig = fully_qualify_types(sig, node)

          # Signatures for writer methods lack the `_arg0` parameter required for type checking
          # sig = add_implicit_arg0(sig, node) if writer_method?(node)

          RBI::RBSSig.new(sig)
        end

        # Signature types don't have to be fully qualified, this causes errors when we generate flat class definitions.
        #: (String sig, RBI::Method node) -> String
        def fully_qualify_types(sig, node)
          method_type = RBS::Parser.parse_method_type(sig)
          return sig unless method_type.type.return_type.is_a?(RBS::Types::ClassInstance)

          return_type_name = method_type.type.return_type.name.name.to_s
          if return_type_name == "Array"
            array = true
            return_type_name = method_type.type.return_type.args[0].name.name
          end

          possible_parent_namespaces(node.parent_tree.name).each do |namespace|
            fully_qualified_name = "#{namespace}::#{return_type_name}"
            if Object.const_defined?(fully_qualified_name)
              if array
                method_type.type.return_type.args[0].name.instance_variable_set(:@name, fully_qualified_name)
              else
                method_type.type.return_type.name.instance_variable_set(:@name, fully_qualified_name)
              end
            end
          end

          method_type.to_s
        end

        # Adds implicit `_arg0` parameter. Useful for `attr_writer` and `attr_accessor` signatures
        #: (String sig, RBI::Method node) -> String
        def add_implicit_arg0(sig, node)
          type = sig.sub(/^->\s*/, "")
          "(#{type} _arg0) #{sig}"
        end

        #: (String sig) -> String
        def add_return_type_for_proc(sig)
          # Check if there's a "->" that's not inside a proc type
          # A proc type will have the form (^(Arg1, Arg2) -> ReturnType)
          outer_arrow_present = !/\([^()]*->[^()]*\)/.match?(sig)
          return "-> #{sig}" unless outer_arrow_present

          sig
        end

        #: (RBI::Method node) -> bool
        def writer_method?(node)
          node.name.end_with?("=") &&
            node.params.size == 1 &&
            node.params.first.is_a?(RBI::ReqParam) &&
            node.params.first.name == "_arg0"
        end

        # @override
        #: (NodeAdded event) -> bool
        def ignore?(event)
          event.is_a?(Tapioca::Gem::ForeignScopeNodeAdded)
        end

        #: (String name) -> T::Array[String]
        def possible_parent_namespaces(name)
          parts = name.split("::")
          result = []

          # Build up parent namespaces from the parts, starting with the full namespace
          # and progressively removing the rightmost part
          parts.size.downto(1) do |i|
            result << parts[0...i].join("::")
          end

          result
        end
      end
    end
  end
end
