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

      it "triggers route DSL generation if routes.rb is modified" do
        create_rails_project
        @project.bundle_install!

        create_client(@project.absolute_path)

        global_state = RubyLsp::GlobalState.new
        global_state.apply_options({
          initializationOptions: {
            enabledFeatureFlags: {
              tapiocaAddon: true,
            },
          },
        })

        # File.write("spec/dummy/config/routes.rb", <<~RUBY)
        @project.write!("config/routes.rb", <<~RUBY)
          Rails.application.routes.draw do
          end
        RUBY

        @client.delegate_notification(
          server_addon_name: "Tapioca",
          request_name: "route_dsl",
        )

        wait_until_exists("#{@project.absolute_path}/sorbet/rbi/dsl/generated_path_helpers_module.rbi")
        shutdown_client

        assert_match(
          "rails_info_routes_path",
          File.read("#{@project.absolute_path}/sorbet/rbi/dsl/generated_path_helpers_module.rbi"),
        )
        assert_match(
          "rails_info_routes_url",
          File.read("#{@project.absolute_path}/sorbet/rbi/dsl/generated_url_helpers_module.rbi"),
        )
        # ensure
        # FileUtils.rm_rf("spec/dummy/sorbet/rbi")
        # FileUtils.rm("spec/dummy/config/routes.rb") if File.exist?("spec/dummy/config/routes.rb")
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
