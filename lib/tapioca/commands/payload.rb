# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class Payload < Command
      class PayloadPipeline < Tapioca::Gem::Pipeline
        sig { params(gem_name: T.nilable(String), core_constants: T::Set[String], include_doc: T::Boolean).void }
        def initialize(gem_name, core_constants:, include_doc: false)
          gem = if gem_name
            Kernel.gem(gem_name)
            require gem_name
            puts ::Gem.loaded_specs
            ::Gem.loaded_specs[gem_name]
          else
            ::Gem::Specification.new
          end
          @core_constants = core_constants
          super(Tapioca::Gemfile::GemSpec.new(gem), include_doc: include_doc)
          @bootstrap_symbols.clear
          @events.clear
        end

        sig { params(constant: Module, strict: T::Boolean).returns(T::Boolean) }
        def defined_in_gem?(constant, strict: true)
          true
        end

        sig { override.params(symbol_name: String).returns(T::Boolean) }
        def symbol_in_payload?(symbol_name)
          @core_constants.include?(symbol_name)
        end

        sig { override.params(method: UnboundMethod).returns(T::Boolean) }
        def method_in_gem?(method)
          true
        end
      end

      sig { params(outpath: Pathname, rbi_formatter: RBIFormatter).void }
      def initialize(outpath:, rbi_formatter: DEFAULT_RBI_FORMATTER)
        super()
        @outpath = outpath
        @rbi_formatter = rbi_formatter
      end

      sig { override.void }
      def execute
        core_constants = list_top_level_constants
        compile_rbi("core", [], core_constants, core_constants: Set.new)

        # TODO: should we also generate docs?
        # TODO: import existing sigs from existing payload?

        stdlib_libraries.each do |lib_name, library_requires|
          lib_constants = list_top_level_constants(library_requires)
          compile_rbi(lib_name, library_requires, lib_constants, core_constants: core_constants)
        end
      end

      private

      sig do
        params(
          name: String,
          requires: T::Array[String],
          constants: T::Set[String],
          core_constants: T::Set[String],
        ).void
      end
      def compile_rbi(name, requires, constants, core_constants:)
        # Kernel.gem(name)
        requires.each { |require_name| require require_name }
        pipeline = PayloadPipeline.new(nil, core_constants: core_constants, include_doc: true)
        constants.each do |constant|
          pipeline.push_symbol(constant.to_s)
        end

        rbi = RBI::File.new(strictness: "__STDLIB_INTERNAL")

        # @rbi_formatter.write_header!(
        #   rbi,
        #   default_command(:gem, name),
        #   reason: "types exported from the `#{name}` gem",
        # ) # if @file_header

        rbi.root = pipeline.compile

        if rbi.empty?
          @rbi_formatter.write_empty_body_comment!(rbi)
          say("Compiled #{name} (empty output)", :yellow)
        else
          say("Compiled #{name}", :green)
        end

        rbi_string = @rbi_formatter.print_file(rbi)
        create_file(@outpath / "#{name}.rbi", rbi_string)
      rescue RuntimeError, LoadError, NameError => e
        say_error("Can't require #{name}: (#{e.message})", :bold, :red)
      end

      sig { params(libraries: T.nilable(T::Array[String])).returns(T::Set[String]) }
      def list_top_level_constants(libraries = nil)
        code = String.new
        libraries&.each do |library|
          code << "require '#{library}'; "
        end
        code << "p Object.constants.map(&:to_s)"

        out, err, status = run_in_ruby_process(code)

        if status.success?
          Set.new(eval(out)) # rubocop:disable Security/Eval
        else
          say_error("Can't list top level constants:", :bold, :red)
          say_error(err)
          Set.new
        end
      rescue SyntaxError => e
        say_error("Can't list top level constants (#{e.message})", :bold, :red)
        Set.new
      end

      sig { params(command: String).returns([String, String, Process::Status]) }
      def run_in_ruby_process(command)
        Bundler.with_unbundled_env do
          Open3.capture3(RbConfig.ruby, "-e", command)
        end
      end

      sig { returns(T::Hash[String, T::Array[String]]) }
      def stdlib_libraries
        rubyarchdir_libraries = libraries_at(RbConfig::CONFIG["rubyarchdir"])
        rubylibdir_libraries = libraries_at(RbConfig::CONFIG["rubylibdir"])

        res = rubyarchdir_libraries.merge(rubylibdir_libraries)
        res.delete_if { |lib_name, _| ["debug", "profile"].include?(lib_name) }
        res
      end

      sig { params(path: String).returns(T::Hash[String, T::Array[String]]) }
      def libraries_at(path)
        hash = {}
        path = Pathname(path)
        path.glob("*").map do |f|
          library_name = f.basename(".*")
          libraries =
            if f.directory?
              f.glob("*").map do |sub_file|
                (library_name / sub_file.basename(".*")).to_s
              end
            else
              [library_name.to_s]
            end

          hash[library_name.to_s] ||= []
          hash[library_name.to_s].concat(libraries)
        end
        hash
      end
    end
  end
end
