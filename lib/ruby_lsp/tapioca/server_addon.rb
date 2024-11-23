# typed: false
# frozen_string_literal: true

require "tapioca/internal"
require_relative "lockfile_diff_parser"

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
        gem_changes = LockfileDiffParser.new(params[:diff])

        removed_gems = gem_changes.removed_gems
        added_or_modified_gems = gem_changes.added_or_modified_gems

        if removed_gems.any?
          $stdout.puts("Removing RBIs for deleted gems: #{removed_gems.join(", ")}")
          FileUtils.rm_f(Dir.glob("sorbet/rbi/gems/{#{removed_gems.join(",")}}@*.rbi"))
        end

        if added_or_modified_gems.any?
          $stdout.puts("Generating RBIs for added or modified gems: #{added_or_modified_gems.join(", ")}")

          load("tapioca/cli.rb") # Reload the CLI to reset thor defaults between requests
          ::Tapioca::Cli.start(["gem"] + added_or_modified_gems)
        end
      end
    end
  end
end
