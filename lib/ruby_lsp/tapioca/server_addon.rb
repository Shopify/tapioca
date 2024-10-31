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
          fork do
            dsl(params)
          end
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

        if added_or_modified_gems.any?
          load("tapioca/cli.rb") # Reload the CLI to reset thor defaults between requests
          ::Tapioca::Cli.start(["gem"] + added_or_modified_gems)
        elsif removed_gems.any?
          FileUtils.rm_f(Dir.glob("sorbet/rbi/gems/{#{removed_gems.join(",")}}@*.rbi"))
        end
      end
    end
  end
end
