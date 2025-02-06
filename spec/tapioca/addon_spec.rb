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
    class AddonSpec < ::Tapioca::SpecWithProject
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

      it "generates gem RBIs for added gems" do
        create_rails_project
        create_client(@project.absolute_path)
        FOO_RB = <<~RB
          module Foo
          end
        RB
        foo = mock_gem("foo", "0.0.1") do
          write!("lib/foo.rb", FOO_RB)
        end
        @project.require_mock_gem(foo)
        @project.bundle_install!

        @client.delegate_notification(
          server_addon_name: "Tapioca",
          request_name: "gem",
          added_or_modified_gems: ["foo"],
          removed_gems: ["bar"],
        )
        expected_rbi_path = @project.absolute_path_to("sorbet/rbi/gems/foo@0.0.1.rbi")
        wait_until_exists(expected_rbi_path)

        shutdown_client

        assert_path_exists(expected_rbi_path)
      end

      it "deletes gem RBIs for removed gems" do
        create_rails_project
        create_client(@project.absolute_path)
        FOO_RB = <<~RB
          module Foo
          end
        RB
        foo = mock_gem("foo", "0.0.1") do
          write!("lib/foo.rb", FOO_RB)
        end
        @project.require_mock_gem(foo)
        @project.bundle_install!
        wait_until_exists(@project.absolute_path_to("Gemfile.lock"))

        @client.delegate_notification(
          server_addon_name: "Tapioca",
          request_name: "gem",
          added_or_modified_gems: ["foo"],
          removed_gems: [],
        )

        expected_rbi_path = @project.absolute_path_to("sorbet/rbi/gems/foo@0.0.1.rbi")
        wait_until_exists(expected_rbi_path)

        # We 'remove' the gem overwriting with the default lockfile
        @project.write_gemfile!(@project.tapioca_gemfile)

        @client.delegate_notification(
          server_addon_name: "Tapioca",
          request_name: "gem",
          added_or_modified_gems: [],
          removed_gems: ["foo"],
        )
        wait_until_removed(expected_rbi_path)
        refute(File.exist?(expected_rbi_path))

        shutdown_client
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

      private

      # Starts a new client
      def create_client(path = "spec/dummy")
        @outgoing_queue = Thread::Queue.new
        global_state = GlobalState.new
        @client = FileUtils.chdir(path) do
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
      # TODO: move all shutdown_client calls into `ensure`? See https://github.com/Shopify/tapioca/pull/2179
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

      def wait_until_removed(path)
        Timeout.timeout(4) do
          sleep(0.2) while File.exist?(path)
        end
      rescue Timeout::Error
        flunk("#{path} was not removed in time")
      end

      def create_rails_project
        @project.write!("config/environment.rb", <<~RB)
          require_relative "application.rb"
        RB

        @project.write!("config/application.rb", <<~RB)
          require "rails"

          module Test
            class Application < Rails::Application
            end
          end
        RB

        @project.require_real_gem("rails")

        content = File.read("spec/dummy/bin/rails")
        @project.write!("bin/rails", content)
      end
    end
  end
end
