# typed: strict
# frozen_string_literal: true

require "tapioca/dsl"
require "tapioca/helpers/test/content"
require "tapioca/helpers/test/isolation"
require "tapioca/helpers/test/template"
require "tapioca/helpers/sorbet_helper"

module Tapioca
  module Helpers
    module Test
      # @requires_ancestor: Kernel
      module DslCompiler
        extend T::Sig
        include Isolation
        include Content
        include Template

        #: (singleton(Tapioca::Dsl::Compiler) compiler_class) -> void
        def use_dsl_compiler(compiler_class)
          @context = CompilerContext.new(compiler_class) #: CompilerContext?
        end

        #: (*singleton(Tapioca::Dsl::Compiler) compiler_classes) -> void
        def activate_other_dsl_compilers(*compiler_classes)
          context.activate_other_dsl_compilers(compiler_classes)
        end

        #: ((Symbol | String) constant_name, ?compiler_options: Hash[Symbol, untyped]) -> String
        def rbi_for(constant_name, compiler_options: {})
          context.rbi_for(constant_name, compiler_options: compiler_options)
        end

        #: -> Array[String]
        def gathered_constants
          context.gathered_constants
        end

        #: -> Array[String]
        def generated_errors
          context.errors
        end

        #: -> CompilerContext
        def context
          raise "Please call `use_dsl_compiler` before" unless @context

          @context
        end

        class CompilerContext
          extend T::Sig

          include SorbetHelper

          #: singleton(Tapioca::Dsl::Compiler)
          attr_reader :compiler_class

          #: Array[singleton(Tapioca::Dsl::Compiler)]
          attr_reader :other_compiler_classes

          #: (singleton(Tapioca::Dsl::Compiler) compiler_class) -> void
          def initialize(compiler_class)
            @compiler_class = compiler_class
            @other_compiler_classes = [] #: Array[singleton(Tapioca::Dsl::Compiler)]
            @pipeline = nil #: Tapioca::Dsl::Pipeline?
            @errors = [] #: Array[String]
          end

          #: (Array[singleton(Tapioca::Dsl::Compiler)] compiler_classes) -> void
          def activate_other_dsl_compilers(compiler_classes)
            @other_compiler_classes = compiler_classes
          end

          #: -> Array[singleton(Tapioca::Dsl::Compiler)]
          def activated_compiler_classes
            [compiler_class, *other_compiler_classes]
          end

          #: -> Array[String]
          def gathered_constants
            compiler_class.processable_constants.filter_map(&:name).sort
          end

          #: ((Symbol | String) constant_name, ?compiler_options: Hash[Symbol, untyped]) -> String
          def rbi_for(constant_name, compiler_options: {})
            # Make sure this is a constant that we can handle.
            unless gathered_constants.include?(constant_name.to_s)
              raise "`#{constant_name}` is not processable by the `#{compiler_class}` compiler."
            end

            file = RBI::File.new(strictness: "strong")
            constant = Object.const_get(constant_name)

            compiler = compiler_class.new(pipeline, file.root, constant, compiler_options.transform_keys(&:to_s))
            compiler.decorate

            rbi = Tapioca::DEFAULT_RBI_FORMATTER.print_file(file)
            result = sorbet(
              "--no-config",
              "--stop-after",
              "parser",
              "-e",
              "\"#{rbi}\"",
            )

            unless result.status
              raise(SyntaxError, <<~MSG)
                Expected generated RBI file for `#{constant_name}` to not have any parsing errors.

                Got these parsing errors:

                #{result.err}
              MSG
            end

            rbi
          end

          #: -> Array[String]
          def errors
            pipeline.errors
          end

          private

          #: -> Tapioca::Dsl::Pipeline
          def pipeline
            @pipeline ||= Tapioca::Dsl::Pipeline.new(
              requested_constants: [],
              requested_compilers: activated_compiler_classes,
            )
          end
        end
      end
    end
  end
end
