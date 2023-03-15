# typed: strict
# frozen_string_literal: true

require_relative "./converter_visitor.rb"

module Tapioca
  module Static
    module Rbs
      class Converter
        extend T::Sig

        sig { returns(T::Array[T.untyped]) }
        attr_reader :declarations

        sig { returns(T::Set[T.untyped]) }
        attr_reader :foreign_decls

        sig { params(gem_name: String, gem_version: String).void }
        def initialize(gem_name, gem_version)
          @gem_name = gem_name
          @gem_version = gem_version
          @env = T.let(load_environment, ::RBS::Environment)
          @declarations = T.let(@env.declarations, T::Array[T.untyped])
          @foreign_decls = T.let(Set.new.compare_by_identity, T::Set[T.untyped])
          @visitor = T.let(ConverterVisitor.new(self), ConverterVisitor)
        end

        sig { returns(RBI::Tree) }
        def convert
          @visitor.process

          @visitor.root
        end

        sig { params(name: RBS::TypeName).void }
        def push_foreign_name(name)
          # binding.b if type.respond_to?(:name) && type.name.to_s == "::Interfaces::Interface_ToJson"
          # if type.respond_to?(:location) && skipped?(type.location)
          decl = lookup_declaration_for_name(name)
          return unless decl
          return unless skipped?(decl)
          return if @foreign_decls.include?(decl)

          puts "Pushing decl of #{decl.name}"
          @foreign_decls << decl
        end

        sig { params(decl: T.untyped).returns(T::Boolean) }
        def skipped?(decl)
          decl.location.buffer.name.start_with?(
            RBS::Repository::DEFAULT_STDLIB_ROOT.to_s,
            RBS::EnvironmentLoader::DEFAULT_CORE_ROOT.to_s
          )
        end

        sig do
          params(name: RBS::TypeName)
            .returns(T.nilable(T.any(RBS::Environment::ClassEntry, RBS::Environment::ModuleEntry)))
        end
        def decl_for_class_name(name)
          @env.class_decls[name]
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
          end
        end
      end
    end
  end
end
