# typed: false
# frozen_string_literal: true

require "tapioca/internal"

module RubyLsp
  module Tapioca
    class ServerAddon < ::RubyLsp::Rails::ServerAddon
      def name
        "Tapioca"
      end

      def execute(request, params)
        case request
        when "dsl"
          dsl(params)
        when "gem"
          gem(params)
        end
      end

      private

      def dsl(params)
        load("tapioca/cli.rb") # Reload the CLI to reset thor defaults between requests
        ::Tapioca::Cli.start(["dsl", "--lsp_addon", "--workers=1"] + params[:constants])
      end

      def gem(params)
        snapshot_specs = parse_lockfile(params[:snapshot_lockfile])
        current_specs = parse_lockfile(params[:current_lockfile])

        removed_gems = snapshot_specs.keys - current_specs.keys
        changed_gems = current_specs.select { |name, version| snapshot_specs[name] != version }.keys

        return $stdout.puts("No gem changes detected") if removed_gems.empty? && changed_gems.empty?

        if removed_gems.any?
          $stdout.puts("Removing RBIs for deleted gems: #{removed_gems.join(", ")}")
          FileUtils.rm_f(Dir.glob("sorbet/rbi/gems/{#{removed_gems.join(",")}}@*.rbi"))
        end

        if changed_gems.any?
          $stdout.puts("Generating RBIs for changed gems: #{changed_gems.join(", ")}")

          load("tapioca/cli.rb") # Reload the CLI to reset thor defaults between requests
          ::Tapioca::Cli.start(["gem"] + changed_gems)
        end
      end

      def parse_lockfile(content)
        return {} if content.to_s.empty?

        Bundler::LockfileParser.new(content).specs.to_h { |spec| [spec.name, spec.version.to_s] }
      end
    end
  end
end
