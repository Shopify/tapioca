# typed: true
# frozen_string_literal: true

unless ENV["LSP_TESTS"]
  puts "Skipping LSP tests"
  return
end

require "addon_spec_helper"
require "ruby_lsp/ruby_lsp_rails/runner_client"

require "spoom/context"

require "spec_with_project"

module RubyLsp
  module Tapioca
    # class RunnerClientTest < ActiveSupport::TestCase
    class AddonSpec < ::Tapioca::SpecWithProject
      # The approach here is based on tests within the Ruby LSP Rails gem

      before do
        @outgoing_queue = Thread::Queue.new
        @client = T.let(RubyLsp::Rails::RunnerClient.new(@outgoing_queue), RubyLsp::Rails::RunnerClient)
      end

      after do
        @client.shutdown

        # On Windows, the server process sometimes takes a lot longer to shutdown and may end up getting force killed,
        # which makes this assertion flaky
        assert_predicate(@client, :stopped?) unless Gem.win_platform?
        @outgoing_queue.close
      end

      EXPECTED_RBI_PATH = "sorbet/rbi/dsl/notify_user_job.rbi"
      it "generates DSL RBIs for a gem" do
        raise "RBI already exists" if File.exist?(EXPECTED_RBI_PATH)

        addon_path = File.expand_path("lib/ruby_lsp/tapioca/server_addon.rb")
        @client.register_server_addon(File.expand_path(addon_path))
        @client.delegate_notification(
          server_addon_name: "Tapioca",
          request_name: "dsl",
          constants: ["NotifyUserJob"],
        )

        begin
          Timeout.timeout(10) do
            found = File.exist?(EXPECTED_RBI_PATH) until found
          end
        rescue Timeout::Error
          flunk("RBI file was not generated")
        end
      ensure
        FileUtils.rm_f(EXPECTED_RBI_PATH)
      end
    end
  end
end
