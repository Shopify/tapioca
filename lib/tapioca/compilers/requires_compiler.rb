# frozen_string_literal: true
# typed: strict

require_relative '../sorbet_config_parser'

module Tapioca
  module Compilers
    class RequiresCompiler
      extend T::Sig

      sig { params(sorbet_path: String).void }
      def initialize(sorbet_path)
        @sorbet_path = sorbet_path
      end

      sig { returns(String) }
      def compile
        config = SorbetConfig.parse_file(@sorbet_path)
        files = collect_files(config)
        files.flat_map do |file|
          collect_requires(file).reject do |req|
            name_in_project?(files, req)
          end
        end.sort.uniq.map do |name|
          "require '#{name}'\n"
        end.join
      end

      private

      sig { params(config: SorbetConfig).returns(T::Array[String]) }
      def collect_files(config)
        config.paths.flat_map do |path|
          path = (Pathname.new(@sorbet_path) / "../.." / path).cleanpath
          if path.directory?
            Dir.glob("#{path}/**/*.rb", File::FNM_EXTGLOB).reject do |file|
              file_ignored_by_sorbet?(config, file)
            end
          else
            [path.to_s]
          end
        end.sort.uniq
      end

      sig { params(file_path: String).returns(T::Enumerable[String]) }
      def collect_requires(file_path)
        File.read(file_path).lines.map do |line|
          /^\s*require\s*(\(\s*)?['"](?<name>[^'"]+)['"](\s*\))?/.match(line) { |m| m["name"] }
        end.compact
      end

      sig { params(config: SorbetConfig, file: String).returns(T::Boolean) }
      def file_ignored_by_sorbet?(config, file)
        config.ignore.any? do |path|
          Regexp.new(Regexp.escape(path)) =~ file
        end
      end

      sig { params(files: T::Enumerable[String], name: String).returns(T::Boolean) }
      def name_in_project?(files, name)
        files.any? do |file|
          File.basename(file, '.rb') == name
        end
      end
    end
  end
end
