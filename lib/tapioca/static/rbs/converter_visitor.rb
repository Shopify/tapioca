# typed: strict
# frozen_string_literal: true

require_relative "./visitor.rb"

module Tapioca
  module Static
    module Rbs
      class ConverterVisitor < RBS::AST::Visitor
        extend T::Sig
        include Tapioca::RBIHelper

        sig { returns(Converter) }
        attr_reader :converter

        sig { returns(RBI::Tree) }
        attr_reader :root

        sig { params(include_foreign: T::Boolean).returns(T::Boolean) }
        attr_writer :include_foreign

        sig { params(converter: Converter).void }
        def initialize(converter)
          super()
          @converter = converter
          @root = T.let(RBI::Tree.new, RBI::Tree)
          @scope_stack = T.let([], T::Array[RBI::Scope])
          @include_foreign = T.let(false, T::Boolean)
          @current_visibility = T.let(:public, Symbol)
        end

        sig { returns(RBI::Tree) }
        def process
          visit_all(@converter.declarations)
          @include_foreign = true
          visit_all(@converter.foreign_decls)
          @root
        end

        sig { params(node: T.any(RBS::AST::Members::Base, RBS::AST::Declarations::Base)).void }
        def visit(node)
          return if skip_declaration?(node)

          super
        end

        sig { params(member: RBS::AST::Members::MethodDefinition).void }
        def visit_member_method_definition(member)
          method_type = T.must(member.overloads.first).method_type
          type_converter = TypeConverter.new(@converter, method_type.type_params)
          param_converter = ParameterConverter.new(type_converter, method_type.type, method_type.block)
          return_type = type_converter.to_string(method_type.type.return_type)
          visibility = type_converter.visibility(member.visibility || @current_visibility)

          current_scope << RBI::Method.new(
            member.name.to_s,
            is_singleton: member.singleton?,
            visibility: visibility,
            comments: rbi_comments(member.comment),
          ) do |method|
            param_converter.convert.each do |param|
              name = param.name

              rbi_param = case param.kind
              when :req
                RBI::Param.new(name)
              when :opt
                RBI::OptParam.new(name, "T.unsafe(nil)")
              when :rest
                RBI::RestParam.new(name)
              when :keyreq
                RBI::KwParam.new(name)
              when :key
                RBI::KwOptParam.new(name, "T.unsafe(nil)")
              when :keyrest
                RBI::KwRestParam.new(name)
              when :block
                RBI::BlockParam.new(name)
              end

              method << T.must(rbi_param)
            end

            method.sigs << RBI::Sig.new do |sig|
              # Type parameters
              type_converter.type_params.each do |type_param|
                sig.type_params << type_param.to_s
              end

              # Parameters
              param_converter.convert.each do |param|
                sig << RBI::SigParam.new(param.name, type_converter.to_string(param.type))
              end

              # Return type
              sig.return_type = if method.name == "initialize"
                "void"
              elsif return_type == "T.attached_class" && !method.is_singleton
                "T.untyped"
              else
                return_type
              end
            end
          end
        end

        sig { params(member: RBS::AST::Members::Alias).void }
        def visit_member_alias(member)
          current_scope.create_method_alias(member.new_name.to_s, member.old_name.to_s)
        end

        sig { params(member: RBS::AST::Members::AttrReader).void }
        def visit_member_attr_reader(member)
          current_scope.create_method(
            member.name.to_s,
            return_type: type_converter.to_string(member.type),
            visibility: type_converter.visibility(member.visibility || @current_visibility),
          )
        end

        sig { params(member: RBS::AST::Members::AttrWriter).void }
        def visit_member_attr_writer(member)
          current_scope.create_method(
            "#{member.name}=",
            parameters: [
              create_param(member.name.to_s, type: type_converter.to_string(member.type)),
            ],
            return_type: type_converter.to_string(member.type),
            visibility: type_converter.visibility(member.visibility || @current_visibility),
          )
        end

        sig { params(member: RBS::AST::Members::AttrAccessor).void }
        def visit_member_attr_accessor(member)
          current_scope.create_method(
            member.name.to_s,
            return_type: type_converter.to_string(member.type),
            visibility: type_converter.visibility(member.visibility || @current_visibility),
          )

          current_scope.create_method(
            "#{member.name}=",
            parameters: [
              create_param(member.name.to_s, type: type_converter.to_string(member.type)),
            ],
            return_type: type_converter.to_string(member.type),
            visibility: type_converter.visibility(member.visibility || @current_visibility),
          )
        end

        sig { params(member: RBS::AST::Members::Private).void }
        def visit_member_private(member)
          @current_visibility = :private
        end

        sig { params(member: RBS::AST::Members::Public).void }
        def visit_member_public(member)
          @current_visibility = :public
        end

        sig { params(member: RBS::AST::Members::Include).void }
        def visit_member_include(member)
          current_scope.create_include(member.name.to_s)
          @converter.push_foreign_name(member.name)
        end

        alias_method :visit_member_prepend, :visit_member_include

        sig { params(member: RBS::AST::Members::Extend).void }
        def visit_member_extend(member)
          current_scope.create_extend(member.name.to_s)
          @converter.push_foreign_name(member.name)
        end

        sig { params(decl: RBS::AST::Declarations::Class).void }
        def visit_declaration_class(decl)
          scope = @root.create_class(
            decl.name.to_s,
            superclass_name: decl.super_class&.name&.to_s,
            comments: rbi_comments(decl.comment),
          )
          add_type_variables(scope, decl)

          visit_scope(scope) { super }
        end

        sig { params(decl: RBS::AST::Declarations::Module).void }
        def visit_declaration_module(decl)
          # We don't want to generate a definition for ::Enumerable ever,
          # since it crashes Sorbet, if we do so.
          return if decl.name.to_s == "::Enumerable"

          scope = @root.create_module(decl.name.to_s, comments: rbi_comments(decl.comment))
          add_type_variables(scope, decl)

          visit_scope(scope) { super }
        end

        alias_method :visit_declaration_interface, :visit_declaration_module

        sig { params(decl: RBS::AST::Declarations::Constant).void }
        def visit_declaration_constant(decl)
          @root.create_constant(
            decl.name.to_s,
            value: "T.let(T.unsafe(nil), #{type_converter.convert(decl.type)})",
            comments: rbi_comments(decl.comment),
          )
        end

        sig { params(decl: RBS::AST::Declarations::TypeAlias).void }
        def visit_declaration_type_alias(decl)
          name = decl.name.to_s
          value = type_converter.convert(decl.type).to_s
          value = "T.untyped" if value.include?(name)

          @root.create_constant(name, value: "T.type_alias { #{value} }")
        end

        private

        sig { params(scope: RBI::Scope, block: T.proc.void).void }
        def visit_scope(scope, &block)
          @current_visibility = :public
          @scope_stack << scope

          block.call

          @scope_stack.pop
        end

        sig { returns(RBI::Scope) }
        def current_scope
          T.must(@scope_stack.last)
        end

        sig { params(node: T.any(RBS::AST::Declarations::Base, RBS::AST::Members::Base)).returns(T::Boolean) }
        def skip_declaration?(node)
          RBS::AST::Declarations::Base === node &&
            !@include_foreign &&
            @converter.skipped?(node)
        end

        sig do
          params(
            scope: RBI::Scope,
            decl: T.any(
              ::RBS::AST::Declarations::Class,
              ::RBS::AST::Declarations::Interface,
              ::RBS::AST::Declarations::Module,
            ),
          ).void
        end
        def add_type_variables(scope, decl)
          scope.create_extend("T::Generic") unless decl.type_params.empty?

          decl.type_params.each do |type_param|
            scope.create_constant(type_param.name.to_s, value: "type_member")
          end

          if RBS::AST::Declarations::Class === decl && superclass = decl.super_class
            superclass_decl = @converter.decl_for_class_name(superclass.name)
            return unless superclass_decl

            superclass_decl.type_params.zip(superclass.args).each do |type_param, arg|
              value = "type_member { { fixed: #{type_converter.to_string(arg)} } }"
              scope.create_constant(type_param.name.to_s, value: value)
            end
          end
        end

        sig { params(rbs_comment: T.nilable(RBS::AST::Comment)).returns(T::Array[RBI::Comment]) }
        def rbi_comments(rbs_comment)
          return [] unless rbs_comment

          rbs_comment.string.lines.map do |line|
            RBI::Comment.new(line)
          end
        end

        sig { returns(TypeConverter) }
        def type_converter
          @type_converter ||= T.let(TypeConverter.new(@converter), T.nilable(TypeConverter))
        end
      end
    end
  end
end
