# typed: strict
# frozen_string_literal: true

module Tapioca
  class SorbetConfig
    extend T::Sig

    sig { returns(T::Array[String]) }
    attr_reader :paths, :ignore

    sig { void }
    def initialize
      @paths = T.let([], T::Array[String])
      @ignore = T.let([], T::Array[String])
    end

    class << self
      extend T::Sig

      sig { params(sorbet_config_path: String).returns(SorbetConfig) }
      def parse_file(sorbet_config_path)
        parse_string(File.read(sorbet_config_path))
      end

      sig { params(sorbet_config: String).returns(SorbetConfig) }
      def parse_string(sorbet_config)
        config = SorbetConfig.new
        ignore = T.let(false, T::Boolean)
        skip = T.let(false, T::Boolean)
        sorbet_config.each_line do |line|
          line = line.strip
          case line
          when /^--ignore$/
            ignore = true
            next
          when /^--ignore=/
            config.ignore << parse_option(line)
            next
          when /^--file$/
            next
          when /^--file=/
            config.paths << parse_option(line)
            next
          when /^--dir$/
            next
          when /^--dir=/
            config.paths << parse_option(line)
            next
          when /^--.*=/
            next
          when /^--/
            skip = true
          when /^-.*=?/
            next
          else
            if ignore
              config.ignore << line
              ignore = false
            elsif skip
              skip = false
            else
              config.paths << line
            end
          end
        end
        config
      end

      private

      sig { params(line: String).returns(String) }
      def parse_option(line)
        T.must(line.split("=").last).strip
      end
    end
  end
end
