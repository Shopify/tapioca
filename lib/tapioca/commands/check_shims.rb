# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class CheckShims < Command
      extend T::Sig
      include SorbetHelper
      include RBIFilesHelper

      sig do
        params(
          gem_rbi_dir: String,
          dsl_rbi_dir: String,
          shim_rbi_dir: String,
          payload: T::Boolean
        ).void
      end
      def initialize(gem_rbi_dir:, dsl_rbi_dir:, shim_rbi_dir:, payload:)
        super()
        @gem_rbi_dir = gem_rbi_dir
        @dsl_rbi_dir = dsl_rbi_dir
        @shim_rbi_dir = shim_rbi_dir
        @payload = payload
      end

      sig { override.void }
      def execute
        index = RBI::Index.new

        if !Dir.exist?(@shim_rbi_dir) || Dir.empty?(@shim_rbi_dir)
          say("No shim RBIs to check", :green)
          exit(0)
        end

        payload_path = T.let(nil, T.nilable(String))

        if @payload
          if sorbet_supports?(:print_payload_sources)
            Dir.mktmpdir do |dir|
              payload_path = dir
              result = sorbet("--no-config --print=payload-sources:#{payload_path}")

              unless result.status
                say_error("Sorbet failed to dump payload")
                say_error(result.err)
                exit(1)
              end

              index_payload(index, payload_path)
            end
          else
            say_error("The version of Sorbet used in your Gemfile.lock does not support `--print=payload-sources`")
            say_error("Current: v#{SORBET_GEM_SPEC.version}")
            say_error("Required: #{FEATURE_REQUIREMENTS[:print_payload_sources]}")
            exit(1)
          end
        end

        index_rbis(index, "shim", @shim_rbi_dir)
        index_rbis(index, "gem", @gem_rbi_dir)
        index_rbis(index, "dsl", @dsl_rbi_dir)

        duplicates = duplicated_nodes_from_index(index, @shim_rbi_dir)
        unless duplicates.empty?
          duplicates.each do |key, nodes|
            say_error("\nDuplicated RBI for #{key}:", :red)
            nodes.each do |node|
              node_loc = node.loc
              next unless node_loc

              loc_string = location_to_payload_url(node_loc, path_prefix: payload_path)
              say_error(" * #{loc_string}", :red)
            end
          end
          say_error("\nPlease remove the duplicated definitions from the #{@shim_rbi_dir} directory.", :red)
          exit(1)
        end

        say("\nNo duplicates found in shim RBIs", :green)
        exit(0)
      end
    end
  end
end
