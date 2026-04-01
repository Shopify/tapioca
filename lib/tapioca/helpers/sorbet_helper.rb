# typed: strict
# frozen_string_literal: true

module Tapioca
  module SorbetHelper
    SORBET_GEM_SPEC = ::Gem::Specification.find_by_name("sorbet-static") #: ::Gem::Specification

    SORBET_BIN = Pathname.new(SORBET_GEM_SPEC.full_gem_path) / "libexec" / "sorbet" #: Pathname

    SORBET_EXE_PATH_ENV_VAR = "TAPIOCA_SORBET_EXE"

    SORBET_PAYLOAD_URL = "https://github.com/sorbet/sorbet/tree/master/rbi"

    SPOOM_CONTEXT = Spoom::Context.new(".") #: Spoom::Context

    # Represents the `sorbet/config` file, and provides access to its options. https://sorbet.org/docs/cli-ref
    # If the file doesn't exist, this object will still exist, but will return default values for all options.
    class SorbetConfig
      class << self
        #: (Spoom::Context spoom_context) -> SorbetConfig
        def parse_from(spoom_context)
          config_path = File.join(spoom_context.absolute_path, "sorbet", "config")
          content = File.exist?(config_path) ? File.read(config_path) : ""
          parse(content)
        end

        #: (String content) -> SorbetConfig
        def parse(content)
          lines = content.lines.map(&:strip).reject(&:empty?)

          options = lines.filter_map do |line|
            next if line.start_with?("#") # Skip comments
            next unless line.start_with?("--")

            key, value = line.split("=", 2)
            key = key #: as !nil

            [key, value]
          end.to_h #: Hash[String, String | bool | nil]

          new(
            # `--cache-dir=` disables the cache, modeled here with a `nil` value
            cache_dir: if (value = options["--cache-dir"]).is_a?(String)
                         value.empty? ? nil : value
                       end,

            parser: options["--parser"] == "prism" ? :prism : :original,
          )
        end
      end

      #: (cache_dir: String?, parser: Symbol) -> void
      def initialize(cache_dir:, parser:)
        @cache_dir = cache_dir #: String?
        @parser = parser #: Symbol
      end

      #: String?
      attr_reader :cache_dir

      #: Symbol
      attr_reader :parser

      #: -> bool
      def parse_with_prism? = @parser == :prism
    end

    FEATURE_REQUIREMENTS = {
      # feature_name: ::Gem::Requirement.new(">= ___"), # https://github.com/sorbet/sorbet/pull/___

      prism_syntax_check_with_stop_after_parser: ::Gem::Requirement.new("> 0.6.13073"), # https://github.com/sorbet/sorbet/pull/10076
    }.freeze #: Hash[Symbol, ::Gem::Requirement]

    #: (*String sorbet_args) -> Spoom::ExecResult
    def sorbet(*sorbet_args)
      if sorbet_config.cache_dir
        sorbet_args << "--cache-dir=#{sorbet_config.cache_dir}"
      end

      if sorbet_config.parse_with_prism?
        sorbet_args << "--parser=prism"
      end

      SPOOM_CONTEXT.srb(sorbet_args.join(" "), sorbet_bin: sorbet_path)
    end

    #: (String, rbi_mode: bool) { (String stderr) -> void } -> void
    def sorbet_syntax_check!(source, rbi_mode:, &on_failure)
      quoted_source = "\"#{source}\""

      stop_after = "--stop-after=parser"

      # This version of Sorbet doesn't report parse errors until the desugarer, so we need to modify the
      # stop-after argument to get far enough to get those errors (and a non-zero exit code).
      if sorbet_config.parse_with_prism? && !sorbet_supports?(:prism_syntax_check_with_stop_after_parser)
        stop_after = "--stop-after=desugarer"
      end

      result = if rbi_mode
        # --e-rbi cannot be used on its own, so we pass a dummy value like `-e ""`
        sorbet("--no-config", stop_after, "-e", '""', "--e-rbi", quoted_source)
      else
        sorbet("--no-config", stop_after, "-e", quoted_source)
      end

      unless result.status
        stderr = result.err #: as !nil
        on_failure.call(stderr)
      end

      nil
    end

    #: -> SorbetConfig
    def sorbet_config
      @sorbet_config ||= SorbetConfig.parse_from(SPOOM_CONTEXT) #: SorbetConfig?
    end

    #: -> String
    def sorbet_path
      sorbet_path = ENV.fetch(SORBET_EXE_PATH_ENV_VAR, SORBET_BIN)
      sorbet_path = SORBET_BIN if sorbet_path.empty?
      sorbet_path.to_s.shellescape
    end

    #: (Symbol feature, ?version: ::Gem::Version?) -> bool
    def sorbet_supports?(feature, version: nil)
      version = SORBET_GEM_SPEC.version unless version
      requirement = FEATURE_REQUIREMENTS[feature]

      Kernel.raise "Invalid Sorbet feature #{feature}" unless requirement

      requirement.satisfied_by?(version)
    end
  end
end
