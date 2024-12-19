# typed: true
# frozen_string_literal: true

require "addon_spec_helper"
require "ruby_lsp/ruby_lsp_rails/runner_client"
require "minitest/hooks"

module RubyLsp
  module Tapioca
    class AddonSpec < Minitest::HooksSpec
      # The approach here is based on tests within the Ruby LSP Rails gem

      # TODO: Replace by `before(:all)` once Sorbet understands it
      def initialize(*args)
        super(*T.unsafe(args))
        FileUtils.cp("spec/dummy/bin/rails", "bin/rails")
        @outgoing_queue = Thread::Queue.new
        @client = T.let(nil, T.nilable(RubyLsp::Rails::RunnerClient))
        FileUtils.chdir("spec/dummy") do
          @client = RubyLsp::Rails::RunnerClient.new(@outgoing_queue)
        end
      end

      after(:all) do
        # TODO: Remove `bind` once Sorbet understands `after(:all)`
        T.bind(self, AddonSpec)

        T.must(@client).shutdown

        assert_predicate(@client, :stopped?)
        @outgoing_queue.close
        FileUtils.rm("bin/rails")
      end

      EXPECTED_RBI_PATH = "spec/dummy/sorbet/rbi/dsl/notify_user_job.rbi"
      it "generates DSL RBIs for a given constant" do
        addon_path = File.expand_path("lib/ruby_lsp/tapioca/server_addon.rb")
        T.must(@client).register_server_addon(File.expand_path(addon_path))
        T.must(@client).delegate_notification(
          server_addon_name: "Tapioca",
          request_name: "dsl",
          constants: ["NotifyUserJob"],
        )

        begin
          Timeout.timeout(10) do
            sleep(1)
            until File.exist?(EXPECTED_RBI_PATH)
            end
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
