# typed: strict
# frozen_string_literal: true

module Tapioca
  module Static
    module Rbs
      class Converter
        extend T::Sig
        include Tapioca::RBIHelper

        sig { params(gem_name: String, gem_version: String).void }
        def initialize(gem_name, gem_version)
          @gem_name = gem_name
          @gem_version = gem_version
          @env = T.let(load_environment, ::RBS::Environment)
          @declarations = T.let(@env.declarations, T::Array[T.untyped])
          @foreign_decls = T.let(Set.new.compare_by_identity, T::Set[T.untyped])
          @root = T.let(RBI::Tree.new, RBI::Tree)
        end

        sig { returns(RBI::Tree) }
        def convert
          @declarations.each { |decl| process_declaration(decl) }
          index = 0
          while (index < @foreign_decls.size)
            process_declaration(@foreign_decls.to_a[index], include_foreign: true)
            index += 1
          end
          @root
        end

        sig { params(name: RBS::TypeName).void }
        def push_foreign_name(name)
          # binding.b if type.respond_to?(:name) && type.name.to_s == "::Interfaces::Interface_ToJson"
          # if type.respond_to?(:location) && skipped?(type.location)
          decl = lookup_declaration_for_name(name)
          return unless decl
          return unless skipped?(decl.location)
          return if @foreign_decls.include?(decl)

          puts "Pushind decl of #{decl.name}"
          @foreign_decls << decl
        end

        private

        sig { returns(RBS::Environment) }
        def load_environment
          loader = RBS::EnvironmentLoader.new
          loader.dirs.concat(loader.repository.dirs)
          T.unsafe(loader).add(library: @gem_name, version: @gem_version)
          RBS::Environment.from_loader(loader).resolve_type_names
        end

        sig { params(name: RBS::TypeName).returns(T.untyped) }
        def lookup_declaration_for_name(name)
          if @env.interface_decls.key?(name)
            @env.interface_decls[name].decl
          elsif @env.alias_decls.key?(name)
            @env.alias_decls[name].decl
          # elsif @env.constant_decls.key?(name)
          #   Array(@env.constant_decls[name].decl)
          else
            nil
          end
        end

        sig do
          params(
            scope: RBI::Scope,
            member:
              T.any(
                RBS::AST::Members::AttrReader,
                RBS::AST::Members::AttrAccessor
              ),
            current_visibility: Symbol
          ).void
        end
        def create_attr_reader_method(scope, member, current_visibility)
          return_type = type_converter.to_string(member.type)
          visibility = type_converter.visibility(member.visibility || current_visibility)

          scope.create_method(
            member.name.to_s,
            return_type: return_type,
            visibility: visibility
          )
        end

        sig do
          params(
            scope: RBI::Scope,
            member:
              T.any(
                RBS::AST::Members::AttrWriter,
                RBS::AST::Members::AttrAccessor
              ),
            current_visibility: Symbol
          ).void
        end
        def create_attr_writer_method(scope, member, current_visibility)
          parameters = [
            create_param(member.name.to_s, type: type_converter.to_string(member.type)),
          ]
          visibility = type_converter.visibility(member.visibility || current_visibility)

          scope.create_method(
            member.name.to_s,
            parameters: parameters,
            return_type: "void",
            visibility: visibility
          )
        end

        sig do
          params(scope: RBI::Scope, decl:               T.any(
            ::RBS::AST::Declarations::Class,
            ::RBS::AST::Declarations::Interface,
            ::RBS::AST::Declarations::Module
          )).void
        end
        def add_type_variables(scope, decl)
          if decl.type_params.any?
            decl.type_params.each do |type_param|
              scope.create_constant(type_param.name.to_s, value: "type_member")
            end
          end

          if RBS::AST::Declarations::Class === decl && superclass = decl.super_class
            superclass_decl = @env.class_decls[superclass.name]
            return unless superclass_decl

            superclass_decl.type_params.zip(superclass.args).each do |type_param, arg|
              value = "type_member { { fixed: #{type_converter.to_string(arg)} } }"
              scope.create_constant(type_param.name.to_s, value: value)
            end
          end
        end

        sig do
          params(
            scope: RBI::Scope,
            decl:
              T.any(
                ::RBS::AST::Declarations::Class,
                ::RBS::AST::Declarations::Interface,
                ::RBS::AST::Declarations::Module
              )
          ).void
        end
        def process_scope(scope, decl)
          add_comments(scope, decl.comment)
          add_type_variables(scope, decl)

          current_visibility = T.let(:public, Symbol)

          decl.members.each do |member|
            case member
            when RBS::AST::Members::Alias
              scope << RBI::Send.new("alias") do |node|
                node << RBI::Arg.new("#{member.new_name} #{member.old_name}")
              end
            when RBS::AST::Members::ClassInstanceVariable
            when RBS::AST::Members::ClassVariable
            when RBS::AST::Members::InstanceVariable
            when RBS::AST::Members::Private
              current_visibility = :private
            when RBS::AST::Members::Public
              current_visibility = :public
            when RBS::AST::Members::MethodDefinition
              converter = MethodConverter.new(
                self,
                T.must(member.types.first),
                member.name.to_s,
                member.singleton?,
                member.visibility || current_visibility
              )
              scope << converter.to_rbi_method do |method|
                add_comments(method, member.comment)
              end
            when RBS::AST::Members::AttrReader
              create_attr_reader_method(scope, member, current_visibility)
            when RBS::AST::Members::AttrWriter
              create_attr_writer_method(scope, member, current_visibility)
            when RBS::AST::Members::AttrAccessor
              create_attr_reader_method(scope, member, current_visibility)
              create_attr_writer_method(scope, member, current_visibility)
            when RBS::AST::Members::Include, RBS::AST::Members::Prepend
              scope.create_include(member.name.to_s)
              push_foreign_name(member.name)
            when RBS::AST::Members::Extend
              name = member.name.to_s
              scope.create_extend(member.name.to_s)
            else
              # This is a nested declaration, hoist it to top level.
              process_declaration(T.unsafe(member))
            end
          end
        end

        sig { returns(TypeConverter) }
        def type_converter
          @type_converter ||= T.let(TypeConverter.new(self), T.nilable(TypeConverter))
        end

        sig { params(location: T.untyped).returns(T::Boolean) }
        def skipped?(location)
          location.buffer.name.start_with?(
            RBS::Repository::DEFAULT_STDLIB_ROOT.to_s,
            RBS::EnvironmentLoader::DEFAULT_CORE_ROOT.to_s
          )
        end

        sig { params(decl: T.untyped, include_foreign: T::Boolean).void }
        def process_declaration(decl, include_foreign: false)
          return if !include_foreign && skipped?(decl.location)

          case decl
          when RBS::AST::Declarations::Global
          when RBS::AST::Declarations::Class
            @root.create_class(decl.name.to_s, superclass_name: decl.super_class&.name&.to_s) do |scope|
              process_scope(scope, decl)
            end
          when RBS::AST::Declarations::Module
            # We don't want to generate a definition for ::Enumerable ever,
            # since it crashes Sorbet, if we do so.
            return if decl.name.to_s == "::Enumerable"

            @root.create_module(decl.name.to_s) do |scope|
              process_scope(scope, decl)
            end
          when RBS::AST::Declarations::Constant
            node = RBI::Const.new(
              decl.name.to_s,
              "T.let(T.unsafe(nil), #{type_converter.convert(decl.type)})"
            )
            @root << node
          when RBS::AST::Declarations::Alias
            name = decl.name.to_s
            value = type_converter.convert(decl.type).to_s
            value = "T.untyped" if value.include?(name)

            node = RBI::Const.new(
              name,
              "T.type_alias { #{value} }"
            )
            @root << node
          when RBS::AST::Declarations::Interface
            name = decl.name.to_s
            @root.create_module(name) { |scope| process_scope(scope, decl) }
          end
        end

        sig { params(scope: RBI::NodeWithComments, comment: T.nilable(RBS::AST::Comment)).void }
        def add_comments(scope, comment)
          return unless comment

          comment.string.lines.each do |line|
            scope.comments << RBI::Comment.new(line)
          end
        end
      end
    end
  end
end
