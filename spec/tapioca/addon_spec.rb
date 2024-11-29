# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  class AddonSpec < SpecWithProject
    describe "Tapioca::Cli" do
      before do
        @command_stub = mock(run: nil)
      end

      it "passes through the `lsp_addon` flag to the DslGenerate command" do
        Commands::DslGenerate.expects(:new).with do |options|
          options[:lsp_addon] == true
        end.returns(@command_stub)

        Cli.start(["dsl", "--lsp_addon"])
      end

      it "does not pass through the `lsp_addon` flag to the DslGenerate command if not present" do
        Commands::DslGenerate.expects(:new).with do |options|
          options[:lsp_addon].nil?
        end.returns(@command_stub)

        # Suppress the 'Unknown switches' warning
        capture_io { Cli.start(["dsl", "--another-flag"]) }
      end
    end
  end
end
