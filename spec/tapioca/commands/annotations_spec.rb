# typed: strict
# frozen_string_literal: true

require "spec_helper"
require "webmock"

module Tapioca
  module Commands
    class AnnotationsSpec < SpecWithProject
      include Tapioca::Helpers::Test::Isolation
      include WebMock::API

      DUMMY_REPO_URI_1 = "https://my-private-repo-1"
      DUMMY_REPO_URI_2 = "https://my-private-repo-2"

      before(:all) do
        WebMock.enable!
      end

      after(:all) do
        WebMock.disable!
      end

      describe "fetch annotations with auth" do
        before(:all) do
          T.bind(self, AnnotationsSpec)

          stub_request(:get, "#{DUMMY_REPO_URI_1}/#{Tapioca::CENTRAL_REPO_INDEX_PATH}")
            .with(headers: { "Authorization" => "TOKEN" })
            .to_return(status: 200, body: "{ \"foo\": {} }")

          stub_request(:get, "#{DUMMY_REPO_URI_2}/#{Tapioca::CENTRAL_REPO_INDEX_PATH}")
            .with(headers: { "Authorization" => "TOKEN" })
            .to_return(status: 200, body: "{ \"bar\": {} }")
        end

        it "adds the proper headers when fetching indexes" do
          command = Annotations.new(central_repo_root_uris: [DUMMY_REPO_URI_1, DUMMY_REPO_URI_2], auth: "TOKEN")

          indexes = T.unsafe(command).stub(:say, ->(*_args) {}) do
            command.send(:fetch_indexes)
          end

          assert_equal(["foo"], indexes[DUMMY_REPO_URI_1].gems.to_a)
          assert_equal(["bar"], indexes[DUMMY_REPO_URI_2].gems.to_a)
        end

        it "adds the proper headers when fetching annotations" do
          command = Annotations.new(central_repo_root_uris: [DUMMY_REPO_URI_1], auth: "TOKEN")

          T.unsafe(command).stub(:say, ->(*_args) {}) do
            command.instance_variable_set(:@indexes, command.send(:fetch_indexes))
          end

          stub_request(:get, "#{DUMMY_REPO_URI_1}/#{Tapioca::CENTRAL_REPO_ANNOTATIONS_DIR}/foo.rbi")
            .with(headers: { "Authorization" => "TOKEN" })
            .to_return(status: 200, body: "# typed: strict\n\nclass Foo;end")

          gems = T.unsafe(command).stub(:say, ->(*_args) {}) do
            T.unsafe(command).stub(:create_file, ->(*_args) {}) do
              annotations = [
                GemInfo.new(name: "foo", version: ::Gem::Version.new("1.0.0")),
                GemInfo.new(name: "bar", version: ::Gem::Version.new("2.0.0")),
              ]
              command.send(:fetch_annotations, annotations)
            end
          end

          assert_equal(["foo"], gems)
        end
      end

      describe "fetch annotations with netrc" do
        before(:all) do
          T.bind(self, AnnotationsSpec)

          project.write!(".netrc", <<~NETRC)
            machine my-private-repo-1 login user1 password TOKEN1
            machine my-private-repo-2 login user1 password TOKEN2
          NETRC
          project.bundle_exec("chmod 0600 .netrc")
        end

        after(:all) do
          project.destroy!
        end

        it "adds the proper headers when fetching indexes" do
          stub_request(:get, "#{DUMMY_REPO_URI_1}/#{Tapioca::CENTRAL_REPO_INDEX_PATH}")
            .with(headers: { "Authorization" => "token TOKEN1" })
            .to_return(status: 200, body: "{ \"foo\": {} }")

          stub_request(:get, "#{DUMMY_REPO_URI_2}/#{Tapioca::CENTRAL_REPO_INDEX_PATH}")
            .with(headers: { "Authorization" => "token TOKEN2" })
            .to_return(status: 200, body: "{ \"bar\": {} }")

          command = Annotations.new(
            central_repo_root_uris: [DUMMY_REPO_URI_1, DUMMY_REPO_URI_2],
            netrc_file: @project.absolute_path_to(".netrc"),
          )

          indexes = T.unsafe(command).stub(:say, ->(*_args) {}) do
            command.send(:fetch_indexes)
          end

          assert_equal(["foo"], indexes[DUMMY_REPO_URI_1].gems.to_a)
          assert_equal(["bar"], indexes[DUMMY_REPO_URI_2].gems.to_a)
        end

        it "doesn't complain if the netrc file is empty or non-existing" do
          stub_request(:get, "#{DUMMY_REPO_URI_1}/#{Tapioca::CENTRAL_REPO_INDEX_PATH}")
            .to_return(status: 200, body: "{ \"foo\": {} }")

          stub_request(:get, "#{DUMMY_REPO_URI_2}/#{Tapioca::CENTRAL_REPO_INDEX_PATH}")
            .to_return(status: 200, body: "{ \"bar\": {} }")

          command = Annotations.new(
            central_repo_root_uris: [DUMMY_REPO_URI_1, DUMMY_REPO_URI_2],
            netrc_file: @project.absolute_path_to(".netrc_not_found"),
          )

          indexes = T.unsafe(command).stub(:say, ->(*_args) {}) do
            command.send(:fetch_indexes)
          end

          assert_equal(["foo"], indexes[DUMMY_REPO_URI_1].gems.to_a)
          assert_equal(["bar"], indexes[DUMMY_REPO_URI_2].gems.to_a)
        end

        it "overrides netrc values with --auth value" do
          stub_request(:get, "#{DUMMY_REPO_URI_1}/#{Tapioca::CENTRAL_REPO_INDEX_PATH}")
            .with(headers: { "Authorization" => "AUTH" })
            .to_return(status: 200, body: "{ \"foo\": {} }")

          stub_request(:get, "#{DUMMY_REPO_URI_2}/#{Tapioca::CENTRAL_REPO_INDEX_PATH}")
            .with(headers: { "Authorization" => "AUTH" })
            .to_return(status: 200, body: "{ \"bar\": {} }")

          command = Annotations.new(
            central_repo_root_uris: [DUMMY_REPO_URI_1, DUMMY_REPO_URI_2],
            auth: "AUTH",
            netrc_file: @project.absolute_path_to(".netrc"),
          )

          indexes = T.unsafe(command).stub(:say, ->(*_args) {}) do
            command.send(:fetch_indexes)
          end

          assert_equal(["foo"], indexes[DUMMY_REPO_URI_1].gems.to_a)
          assert_equal(["bar"], indexes[DUMMY_REPO_URI_2].gems.to_a)
        end
      end
    end
  end
end
