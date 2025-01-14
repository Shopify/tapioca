# typed: true
# frozen_string_literal: true

require "spec_helper"
require "language_server-protocol"
require "ruby_lsp/utils"
require "ruby_lsp/ruby_lsp_rails/runner_client"
require "minitest/hooks"

module RubyLsp
  module Tapioca
    class AddonSpec < Minitest::HooksSpec
      # The approach here is based on tests within the Ruby LSP Rails gem

      # TODO: Replace with `before(:all)` once Sorbet understands it
      def initialize(*args)
        super(*T.unsafe(args))
        @outgoing_queue = Thread::Queue.new
        @client = T.let(
          FileUtils.chdir("spec/dummy") do
            RubyLsp::Rails::RunnerClient.new(@outgoing_queue)
          end,
          RubyLsp::Rails::RunnerClient,
        )

        addon_path = File.expand_path("lib/ruby_lsp/tapioca/server_addon.rb")
        @client.register_server_addon(File.expand_path(addon_path))
        @client.delegate_notification(
          server_addon_name: "Tapioca",
          request_name: "load_compilers_and_extensions",
          workspace_path: Dir.pwd,
        )
      end

      after(:all) do
        @client.shutdown

        assert_predicate(@client, :stopped?)
        @outgoing_queue.close
      end

      it "generates DSL RBIs for a given constant" do
        @client.delegate_notification(
          server_addon_name: "Tapioca",
          request_name: "dsl",
          constants: ["NotifyUserJob"],
        )

        begin
          Timeout.timeout(10) do
            sleep(1) until File.exist?("spec/dummy/sorbet/rbi/dsl/notify_user_job.rbi")
          end
        rescue Timeout::Error
          flunk("RBI file was not generated")
        end
      ensure
        FileUtils.rm_rf("spec/dummy/sorbet/rbi")
      end
    end
  end
end
