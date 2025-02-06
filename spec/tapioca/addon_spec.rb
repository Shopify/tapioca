# typed: true
# frozen_string_literal: true

require "spec_helper"
require "language_server-protocol"
require "ruby_lsp/internal"
require "ruby_lsp/ruby_lsp_rails/addon"
require "ruby_lsp/tapioca/addon"
require "minitest/hooks"

module RubyLsp
  module Tapioca
    class AddonSpec < Minitest::HooksSpec
      # The approach here is based on tests within the Ruby LSP Rails gem

      it "generates DSL RBIs for a given constant" do
        create_client
        @client.delegate_notification(
          server_addon_name: "Tapioca",
          request_name: "dsl",
          constants: ["NotifyUserJob"],
        )
        wait_until_exists("spec/dummy/sorbet/rbi/dsl/notify_user_job.rbi")

        shutdown_client

        assert_path_exists("spec/dummy/sorbet/rbi/dsl/notify_user_job.rbi")
      ensure
        FileUtils.rm_rf("spec/dummy/sorbet/rbi")
      end

      it "triggers route DSL generation if routes.rb is modified" do
        create_client

        global_state = RubyLsp::GlobalState.new
        global_state.apply_options({
          initializationOptions: {
            enabledFeatureFlags: {
              tapiocaAddon: true,
            },
          },
        })

        addon = Addon.new
        addon.instance_variable_set(:@rails_runner_client, @client)
        addon.instance_variable_set(:@global_state, global_state)
        addon.instance_variable_set(:@index, global_state.index)
        addon.instance_variable_set(:@outgoing_queue, @outgoing_queue)

        File.write("spec/dummy/config/routes.rb", <<~RUBY)
          Rails.application.routes.draw do
          end
        RUBY

        addon.workspace_did_change_watched_files([{
          uri: "file://#{Dir.pwd}/spec/dummy/config/routes.rb",
          type: Constant::FileChangeType::CREATED,
        }])

        wait_until_exists("spec/dummy/sorbet/rbi/dsl/generated_path_helpers_module.rbi")
        shutdown_client

        assert_match("rails_info_routes_path", File.read("spec/dummy/sorbet/rbi/dsl/generated_path_helpers_module.rbi"))
        assert_match("rails_info_routes_url", File.read("spec/dummy/sorbet/rbi/dsl/generated_url_helpers_module.rbi"))
      ensure
        FileUtils.rm_rf("spec/dummy/sorbet/rbi")
        FileUtils.rm("spec/dummy/config/routes.rb") if File.exist?("spec/dummy/config/routes.rb")
      end

      it "triggers ActiveRecordFixtures DSL compiler if a fixture is modified" do
        create_client

        global_state = RubyLsp::GlobalState.new
        global_state.apply_options({
          initializationOptions: {
            enabledFeatureFlags: {
              tapiocaAddon: true,
            },
          },
        })

        addon = Addon.new
        addon.instance_variable_set(:@rails_runner_client, @client)
        addon.instance_variable_set(:@global_state, global_state)
        addon.instance_variable_set(:@index, global_state.index)
        addon.instance_variable_set(:@outgoing_queue, @outgoing_queue)

        FileUtils.mkdir_p("spec/dummy/test/fixtures")
        FileUtils.touch("spec/dummy/test/fixtures/users.yml")

        addon.workspace_did_change_watched_files([{
          uri: "file://#{Dir.pwd}/spec/dummy/test/fixtures/users.yml",
          type: Constant::FileChangeType::CREATED,
        }])

        wait_until_exists("spec/dummy/sorbet/rbi/dsl/active_support/test_case.rbi")
        shutdown_client

        assert_match(
          "def users",
          File.read("#{Dir.pwd}/spec/dummy/sorbet/rbi/dsl/active_support/test_case.rbi"),
        )
      ensure
        FileUtils.rm_rf("spec/dummy/sorbet/rbi")
        FileUtils.rm("spec/dummy/test/fixtures/users.yml") if File.exist?("spec/dummy/test/fixtures/users.yml")
      end

      it "reloads compilers automatically" do
        create_client

        FileUtils.mkdir_p("spec/dummy/sorbet/tapioca/compilers")
        File.write("spec/dummy/sorbet/tapioca/compilers/test_compiler.rb", <<~RUBY)
          class TestCompiler < ::Tapioca::Dsl::Compiler
            def self.gather_constants
              descendants_of(::ActiveJob::Base)
            end

            def decorate
              root.create_path(constant) do |job|
                job.create_method(
                  "hello_from_spec",
                  parameters: [],
                  return_type: "T.untyped",
                  class_method: true,
                )
              end
            end
          end
        RUBY

        @client.delegate_notification(
          server_addon_name: "Tapioca",
          request_name: "reload_workspace_compilers",
          workspace_path: File.expand_path("spec/dummy"),
        )

        @client.delegate_notification(
          server_addon_name: "Tapioca",
          request_name: "dsl",
          constants: ["NotifyUserJob"],
        )
        wait_until_exists("spec/dummy/sorbet/rbi/dsl/notify_user_job.rbi")
        shutdown_client

        assert_match("hello_from_spec", File.read("spec/dummy/sorbet/rbi/dsl/notify_user_job.rbi"))
      ensure
        FileUtils.rm_rf("spec/dummy/sorbet/rbi")
        FileUtils.rm_rf("spec/dummy/sorbet/tapioca")
      end

      it "triggers gem RBI generation upon activation" do
        global_state = RubyLsp::GlobalState.new
        global_state.apply_options({
          initializationOptions: {
            enabledFeatureFlags: {
              tapiocaAddon: true,
            },
          },
        })

        outgoing_queue = Thread::Queue.new
        FileUtils.chdir("spec/dummy") do
          # Activate the Rails add-on manually
          rails_addon = Rails::Addon.new
          RubyLsp::Addon.addons << rails_addon
          rails_addon.activate(global_state, outgoing_queue)

          Thread.new do
            # Wait until the Rails runner client is ready and then patch its methods so that we can avoid doing work we
            # are not interested in while at the same time asserting that we invoked the right notification
            client = rails_addon.rails_runner_client
            client.instance_eval do
              def server_addon_name
                @server_addon_name
              end

              def request_name
                @request_name
              end

              def register_server_addon(path); end

              def delegate_notification(**kwargs)
                @server_addon_name = kwargs[:server_addon_name]
                @request_name = kwargs[:request_name]
              end
            end
          end.join

          begin
            addon = Addon.new
            assert_includes(RubyLsp::Addon.addons, rails_addon)
            assert_equal(rails_addon, ::RubyLsp::Addon.get("Ruby LSP Rails", ">= 0.4.0", "< 0.5"))

            # Activate the Tapioca add-on and wait until all notifications have been popped from both add-ons
            addon.activate(global_state, outgoing_queue)
            4.times do
              outgoing_queue.pop
            end

            # Verify that we triggered gem RBI generation
            assert_equal("Tapioca", T.unsafe(rails_addon.rails_runner_client).server_addon_name)
            assert_equal("gem", T.unsafe(rails_addon.rails_runner_client).request_name)
          ensure
            outgoing_queue.close
            RubyLsp::Addon.unload_addons
          end
        end
      end

      private

      # Starts a new client
      def create_client
        @outgoing_queue = Thread::Queue.new
        global_state = GlobalState.new
        @client = FileUtils.chdir("spec/dummy") do
          RubyLsp::Rails::RunnerClient.new(@outgoing_queue, global_state)
        end

        addon_path = File.expand_path("lib/ruby_lsp/tapioca/server_addon.rb")
        @client.register_server_addon(File.expand_path(addon_path))
        @client.delegate_notification(
          server_addon_name: "Tapioca",
          request_name: "load_compilers_and_extensions",
          workspace_path: Dir.pwd,
        )
      end

      # Triggers shutdown and waits for it to complete
      def shutdown_client
        @client.shutdown
        @client.instance_variable_get(:@wait_thread).join

        assert_predicate(@client, :stopped?)
        @outgoing_queue.close
      end

      def wait_until_exists(path)
        Timeout.timeout(4) do
          sleep(0.2) until File.exist?(path)
        end
      rescue Timeout::Error
        flunk("#{path} was not created in time")
      end
    end
  end
end
