# typed: true
# frozen_string_literal: true

require "test_helper"
require "ruby_lsp/ruby_lsp_rails/runner_client"

module RubyLsp
  module Rails
    class RunnerClientTest < ActiveSupport::TestCase
      setup do
        @outgoing_queue = Thread::Queue.new
        @client = T.let(RunnerClient.new(@outgoing_queue), RunnerClient)
      end

      teardown do
        @client.shutdown

        # On Windows, the server process sometimes takes a lot longer to shutdown and may end up getting force killed,
        # which makes this assertion flaky
        assert_predicate(@client, :stopped?) unless Gem.win_platform?
        @outgoing_queue.close
      end

      # These are integration tests which start the server. For the more fine-grained tests, see `server_test.rb`.

      test "#model returns information for the requested model" do
        # These columns are from the schema in the dummy app: test/dummy/db/schema.rb
        columns = [
          ["id", "integer", nil, false],
          ["first_name", "string", "", true],
          ["last_name", "string", nil, true],
          ["age", "integer", "0", true],
          ["created_at", "datetime", nil, false],
          ["updated_at", "datetime", nil, false],
          ["country_id", "integer", nil, false],
          ["active", "boolean", "1", false],
        ]
        response = T.must(@client.model("User"))
        assert_equal(columns, response.fetch(:columns))
        assert_match(%r{db/schema\.rb$}, response.fetch(:schema_file))
      end

      test "returns nil if the request returns a nil response" do
        assert_nil @client.model("ApplicationRecord") # ApplicationRecord is abstract
      end

      test "falls back to null client when bin/rails is not found" do
        FileUtils.mv("bin/rails", "bin/rails_backup")

        outgoing_queue = Thread::Queue.new
        client = RunnerClient.create_client(outgoing_queue)

        assert_instance_of(NullClient, client)
        assert_nil(client.model("User"))
        assert_predicate(client, :stopped?)
        log = pop_log_notification(outgoing_queue, RubyLsp::Constant::MessageType::WARNING)

        assert_instance_of(RubyLsp::Notification, log)
        assert_match("Ruby LSP Rails failed to locate bin/rails in the current directory", log.params.message)
      ensure
        T.must(outgoing_queue).close
        FileUtils.mv("bin/rails_backup", "bin/rails")
      end

      test "failing to spawn server creates a null client" do
        FileUtils.mv("test/dummy/config/application.rb", "test/dummy/config/application.rb.bak")

        outgoing_queue = Thread::Queue.new
        client = RunnerClient.create_client(outgoing_queue)

        assert_instance_of(NullClient, client)
        assert_nil(client.model("User"))
        assert_predicate(client, :stopped?)

        log = pop_log_notification(outgoing_queue, RubyLsp::Constant::MessageType::ERROR)

        assert_instance_of(RubyLsp::Notification, log)
        assert_match("Ruby LSP Rails failed to initialize server", log.params.message)
      ensure
        T.must(outgoing_queue).close
        FileUtils.mv("test/dummy/config/application.rb.bak", "test/dummy/config/application.rb")
      end

      test "is resilient to extra output being printed during boot" do
        content = File.read("test/dummy/config/application.rb")
        FileUtils.mv("test/dummy/config/application.rb", "test/dummy/config/application.rb.bak")
        junk = %{\nputs "1\r\n\r\nhello"}
        File.write("test/dummy/config/application.rb", content + junk)

        outgoing_queue = Thread::Queue.new
        client = RunnerClient.create_client(outgoing_queue)
        response = client.model("User")

        begin
          assert(T.must(response).key?(:columns))
        ensure
          T.must(outgoing_queue).close
          FileUtils.mv("test/dummy/config/application.rb.bak", "test/dummy/config/application.rb")
        end
      end

      test "delegate notification" do
        @client.expects(:send_notification).with(
          "server_addon/delegate",
          server_addon_name: "My Add-on",
          request_name: "do_something",
          id: 5,
        )
        @client.delegate_notification(server_addon_name: "My Add-on", request_name: "do_something", id: 5)
      end

      test "delegate request" do
        @client.expects(:make_request).with(
          "server_addon/delegate",
          server_addon_name: "My Add-on",
          request_name: "do_something",
          id: 5,
        )
        @client.delegate_request(server_addon_name: "My Add-on", request_name: "do_something", id: 5)
      end

      test "server add-ons can log messages with the editor" do
        File.write("server_addon.rb", <<~RUBY)
          class TapiocaServerAddon < RubyLsp::Rails::ServerAddon
            def name
              "Tapioca"
            end

            def execute(request, params)
              log_message("Hello!")
              send_message({ request:, params: })
            end
          end
        RUBY

        @client.register_server_addon(File.expand_path("server_addon.rb"))
        @client.delegate_notification(server_addon_name: "Tapioca", request_name: "dsl")

        # Started booting server
        pop_log_notification(@outgoing_queue, RubyLsp::Constant::MessageType::LOG)
        # Finished booting server
        pop_log_notification(@outgoing_queue, RubyLsp::Constant::MessageType::LOG)

        log = pop_log_notification(@outgoing_queue, RubyLsp::Constant::MessageType::LOG)

        # Sometimes we get warnings concerning deprecations and they mess up this expectation
        3.times do
          unless log.params.message.match?(/Hello!/)
            log = pop_log_notification(@outgoing_queue, RubyLsp::Constant::MessageType::LOG)
          end
        end

        assert_match("Hello!", log.params.message)
      ensure
        FileUtils.rm("server_addon.rb")
      end
    end

    class NullClientTest < ActiveSupport::TestCase
      setup { @client = NullClient.new }

      test "#shutdown is a no-op" do
        assert_nothing_raised { @client.shutdown }
      end

      test "#stopped? is always true" do
        assert_predicate @client, :stopped?
      end

      test "#rails_root is just the current working directory" do
        assert_equal Dir.pwd, @client.rails_root
      end

      test "#send_message is a no-op" do
        assert_nothing_raised { @client.send(:send_message, "request") }
      end

      test "#send_notification is a no-op" do
        assert_nothing_raised { @client.send(:send_notification, "request") }
      end

      test "#read_response is a no-op" do
        assert_nothing_raised { @client.send(:read_response) }
      end
    end
  end
end
