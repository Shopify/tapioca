# typed: strict
# frozen_string_literal: true

require "unparser"

module Tapioca
  module RBI
    class Parser
      extend T::Sig

      class Error < StandardError; end

      # opt-in to most recent AST format
      ::Parser::Builders::Default.emit_lambda               = true
      ::Parser::Builders::Default.emit_procarg0             = true
      ::Parser::Builders::Default.emit_encoding             = true
      ::Parser::Builders::Default.emit_index                = true
      ::Parser::Builders::Default.emit_arg_inside_procarg0  = true

      sig { params(string: String).returns(Tree) }
      def self.parse_string(string)
        Parser.new.parse_string(string)
      end

      sig { params(path: String).returns(Tree) }
      def self.parse_file(path)
        Parser.new.parse_file(path)
      end

      sig { params(string: String).returns(Tree) }
      def parse_string(string)
        parse(string, file: "-")
      rescue ::Parser::SyntaxError => e
        raise Error, e.message
      end

      sig { params(path: String).returns(Tree) }
      def parse_file(path)
        parse(File.read(path), file: path)
      rescue ::Parser::SyntaxError => e
        raise Error, e.message
      end

      private

      sig { params(content: String, file: String).returns(Tree) }
      def parse(content, file:)
        node, comments = Unparser.parse_with_comments(content)
        assoc = ::Parser::Source::Comment.associate_locations(node, comments)
        builder = TreeBuilder.new(file: file, comments: assoc)
        builder.visit(node)
        builder.assoc_dangling_comments(comments)
        builder.tree
      end
    end

    class ASTVisitor
      extend T::Helpers
      extend T::Sig

      abstract!

      sig { params(nodes: T::Array[AST::Node]).void }
      def visit_all(nodes)
        nodes.each { |node| visit(node) }
      end

      sig { abstract.params(node: T.nilable(AST::Node)).void }
      def visit(node); end

      private

      sig { params(node: AST::Node).returns(String) }
      def visit_name(node)
        T.must(ConstBuilder.visit(node))
      end

      sig { params(node: AST::Node).returns(String) }
      def visit_expr(node)
        Unparser.unparse(node)
      end
    end

    class TreeBuilder < ASTVisitor
      extend T::Sig

      sig { returns(Tree) }
      attr_reader :tree

      sig do
        params(
          file: String,
          comments: T.nilable(T::Hash[::Parser::Source::Map, T::Array[::Parser::Source::Comment]])
        ).void
      end
      def initialize(file:, comments: nil)
        super()
        @file = file
        @comments = comments
        @tree = T.let(Tree.new, Tree)
        @scopes_stack = T.let([@tree], T::Array[Tree])
        @last_sigs = T.let([], T::Array[RBI::Sig])
      end

      sig { override.params(node: T.nilable(Object)).void }
      def visit(node)
        return unless node.is_a?(AST::Node)
        case node.type
        when :module, :class, :sclass
          visit_scope(node)
        when :casgn
          visit_const_assign(node)
        when :def, :defs
          visit_def(node)
        when :send
          visit_send(node)
        when :block
          visit_block(node)
        else
          visit_all(node.children)
        end
      end

      sig { params(comments: T::Array[::Parser::Source::Comment]).void }
      def assoc_dangling_comments(comments)
        return unless tree.empty?
        comments.each do |comment|
          text = comment.text[1..-1].strip
          loc = ast_to_rbi_loc(comment.location)
          tree.comments << Comment.new(text, loc: loc)
        end
      end

      private

      sig { params(node: AST::Node).void }
      def visit_scope(node)
        loc = node_loc(node)
        comments = node_comments(node)

        scope = case node.type
        when :module
          name = visit_name(node.children[0])
          Module.new(name, loc: loc, comments: comments)
        when :class
          name = visit_name(node.children[0])
          superclass_name = ConstBuilder.visit(node.children[1])
          Class.new(name, superclass_name: superclass_name, loc: loc, comments: comments)
        when :sclass
          SingletonClass.new(loc: loc, comments: comments)
        else
          raise "Unsupported node #{node.type}"
        end
        current_scope << scope

        @scopes_stack << scope
        visit_all(node.children)
        @scopes_stack.pop
      end

      sig { params(node: AST::Node).void }
      def visit_const_assign(node)
        name = visit_name(node)
        value = visit_expr(node.children[2])
        loc = node_loc(node)
        comments = node_comments(node)

        current_scope << Const.new(name, value, loc: loc, comments: comments)
      end

      sig { params(node: AST::Node).void }
      def visit_def(node)
        current_scope << case node.type
        when :def
          Method.new(
            node.children[0].to_s,
            params: node.children[1].children.map { |child| visit_param(child) },
            sigs: current_sigs,
            loc: node_loc(node),
            comments: node_comments(node)
          )
        when :defs
          Method.new(
            node.children[1].to_s,
            params: node.children[2].children.map { |child| visit_param(child) },
            is_singleton: true,
            sigs: current_sigs,
            loc: node_loc(node),
            comments: node_comments(node)
          )
        else
          raise "Unsupported node #{node.type}"
        end
      end

      sig { params(node: AST::Node).returns(Param) }
      def visit_param(node)
        name = node.children[0].to_s
        loc = node_loc(node)
        comments = node_comments(node)

        case node.type
        when :arg
          Param.new(name, loc: loc, comments: comments)
        when :optarg
          value = visit_expr(node.children[1])
          OptParam.new(name, value, loc: loc, comments: comments)
        when :restarg
          RestParam.new(name, loc: loc, comments: comments)
        when :kwarg
          KwParam.new(name, loc: loc, comments: comments)
        when :kwoptarg
          value = visit_expr(node.children[1])
          KwOptParam.new(name, value, loc: loc, comments: comments)
        when :kwrestarg
          KwRestParam.new(name, loc: loc, comments: comments)
        when :blockarg
          BlockParam.new(name, loc: loc, comments: comments)
        else
          raise "Unsupported node #{node.type}"
        end
      end

      sig { params(node: AST::Node).void }
      def visit_send(node)
        recv = node.children[0]
        return if recv && recv != :self

        method_name = node.children[1]
        loc = node_loc(node)
        comments = node_comments(node)

        current_scope << case method_name
        when :attr_reader
          symbols = node.children[2..-1].map { |child| child.children[0] }
          AttrReader.new(*symbols, sigs: current_sigs, loc: loc, comments: comments)
        when :attr_writer
          symbols = node.children[2..-1].map { |child| child.children[0] }
          AttrWriter.new(*symbols, sigs: current_sigs, loc: loc, comments: comments)
        when :attr_accessor
          symbols = node.children[2..-1].map { |child| child.children[0] }
          AttrAccessor.new(*symbols, sigs: current_sigs, loc: loc, comments: comments)
        when :include
          names = node.children[2..-1].map { |child| visit_name(child) }
          Include.new(*names, loc: loc, comments: comments)
        when :extend
          names = node.children[2..-1].map { |child| visit_name(child) }
          Extend.new(*names, loc: loc, comments: comments)
        when :abstract!, :sealed!, :interface!
          Helper.new(method_name.to_s.delete_suffix("!"), loc: loc, comments: comments)
        when :mixes_in_class_methods
          names = node.children[2..-1].map { |child| visit_name(child) }
          MixesInClassMethods.new(*names, loc: loc, comments: comments)
        when :public, :protected, :private
          Visibility.new(method_name, loc: loc)
        when :prop
          name, type, default_value = visit_struct_prop(node)
          TStructProp.new(name, type, default: default_value, loc: loc, comments: comments)
        when :const
          name, type, default_value = visit_struct_prop(node)
          TStructConst.new(name, type, default: default_value, loc: loc, comments: comments)
        else
          raise "Unsupported node #{node.type} with name #{method_name}"
        end
      end

      sig { params(node: AST::Node).void }
      def visit_block(node)
        name = node.children[0].children[1]

        case name
        when :sig
          @last_sigs << visit_sig(node)
        when :enums
          current_scope << visit_enum(node)
        else
          raise "Unsupported node #{node.type} with name #{name}"
        end
      end

      sig { params(node: AST::Node).returns([String, String, T.nilable(String)]) }
      def visit_struct_prop(node)
        name = node.children[2].children[0].to_s
        type = visit_expr(node.children[3])
        has_default = node.children[4]
          &.children&.fetch(0, nil)
          &.children&.fetch(0, nil)
          &.children&.fetch(0, nil) == :default
        default_value = if has_default
          visit_expr(node.children.fetch(4, nil)
            &.children&.fetch(0, nil)
            &.children&.fetch(1, nil))
        end
        [name, type, default_value]
      end

      sig { params(node: AST::Node).returns(Sig) }
      def visit_sig(node)
        sig = SigBuilder.build(node)
        sig.loc = node_loc(node)
        sig
      end

      sig { params(node: AST::Node).returns(TEnumBlock) }
      def visit_enum(node)
        enum = TEnumBlock.new
        node.children[2].children.each do |child|
          enum << visit_name(child)
        end
        enum.loc = node_loc(node)
        enum
      end

      sig { params(node: AST::Node).returns(Loc) }
      def node_loc(node)
        ast_to_rbi_loc(node.location)
      end

      sig { params(ast_loc: ::Parser::Source::Map).returns(Loc) }
      def ast_to_rbi_loc(ast_loc)
        Loc.new(
          file: @file,
          begin_line: ast_loc.line,
          begin_column: ast_loc.column,
          end_line: ast_loc.last_line,
          end_column: ast_loc.last_column
        )
      end

      sig { params(node: AST::Node).returns(T::Array[Comment]) }
      def node_comments(node)
        return [] unless @comments
        comments = @comments[node.location]
        return [] unless comments
        comments.map do |comment|
          text = comment.text[1..-1].strip
          loc = ast_to_rbi_loc(comment.location)
          Comment.new(text, loc: loc)
        end
      end

      sig { returns(Tree) }
      def current_scope
        T.must(@scopes_stack.last) # Should never be nil since we create a Tree as the root
      end

      sig { returns(T::Array[Sig]) }
      def current_sigs
        sigs = @last_sigs.dup
        @last_sigs.clear
        sigs
      end
    end

    class ConstBuilder < ASTVisitor
      extend T::Sig

      sig { params(node: T.nilable(AST::Node)).returns(T.nilable(String)) }
      def self.visit(node)
        v = ConstBuilder.new
        v.visit(node)
        return nil if v.names.empty?
        v.names.join("::")
      end

      sig { returns(T::Array[String]) }
      attr_accessor :names

      sig { void }
      def initialize
        super
        @names = T.let([], T::Array[String])
      end

      sig { override.params(node: T.nilable(AST::Node)).void }
      def visit(node)
        return unless node
        case node.type
        when :const, :casgn
          visit(node.children[0])
          @names << node.children[1].to_s
        when :cbase
          @names << ""
        when :sym
          @names << ":#{node.children[0]}"
        end
      end
    end

    class SigBuilder < ASTVisitor
      extend T::Sig

      sig { params(node: AST::Node).returns(Sig) }
      def self.build(node)
        v = SigBuilder.new
        v.visit_all(node.children[2..-1])
        v.current
      end

      sig { returns(Sig) }
      attr_accessor :current

      sig { void }
      def initialize
        super
        @current = T.let(Sig.new, Sig)
      end

      sig { override.params(node: T.nilable(AST::Node)).void }
      def visit(node)
        return unless node
        case node.type
        when :send
          visit_send(node)
        end
      end

      sig { params(node: AST::Node).void }
      def visit_send(node)
        visit(node.children[0]) if node.children[0]
        name = node.children[1]
        case name
        when :abstract
          @current.is_abstract = true
        when :override
          @current.is_override = true
        when :overridable
          @current.is_overridable = true
        when :checked
          @current.checked = node.children[2].children[0]
        when :type_parameters
          node.children[2..-1].each do |child|
            @current.type_params << child.children[0].to_s
          end
        when :params
          node.children[2].children.each do |child|
            name = child.children[0].children[0].to_s
            type = visit_expr(child.children[1])
            @current << SigParam.new(name, type)
          end
        when :returns
          @current.return_type = visit_expr(node.children[2])
        when :void
          @current.return_type = nil
        else
          raise "#{node.location.line}: Unhandled #{name}"
        end
      end
    end
  end
end
