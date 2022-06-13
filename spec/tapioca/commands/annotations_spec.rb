# typed: strict
# frozen_string_literal: true

require "spec_helper"
require "webmock"

module Tapioca
  module Commands
    class AnnotationsSpec < Minitest::HooksSpec
      include WebMock::API

      before(:all) do
        T.bind(self, AnnotationsSpec)

        WebMock.enable!

        stub_request(:get, "#{DUMMY_REPO_URI_1}/#{Tapioca::CENTRAL_REPO_INDEX_PATH}")
          .with(headers: { "Authorization" => "TOKEN" })
          .to_return(status: 200, body: "{ \"foo\": {} }")

        stub_request(:get, "#{DUMMY_REPO_URI_2}/#{Tapioca::CENTRAL_REPO_INDEX_PATH}")
          .with(headers: { "Authorization" => "TOKEN" })
          .to_return(status: 200, body: "{ \"bar\": {} }")
      end

      after(:all) do
        WebMock.disable!
      end

      DUMMY_REPO_URI_1 = "https://my-private-repo-1"
      DUMMY_REPO_URI_2 = "https://my-private-repo-2"

      describe "Tapioca::Commands::Annotations" do
        it "adds the proper headers when fetching indexes with authorization" do
          command = Annotations.new(central_repo_root_uris: [DUMMY_REPO_URI_1, DUMMY_REPO_URI_2], auth: "TOKEN")

          indexes = T.unsafe(command).stub(:say, ->(*_args) {}) do
            command.send(:fetch_indexes)
          end

          assert_equal(["foo"], indexes[DUMMY_REPO_URI_1].gems.to_a)
          assert_equal(["bar"], indexes[DUMMY_REPO_URI_2].gems.to_a)
        end

        it "adds the proper headers when fetching annotations with authorization" do
          command = Annotations.new(central_repo_root_uris: [DUMMY_REPO_URI_1], auth: "TOKEN")

          T.unsafe(command).stub(:say, ->(*_args) {}) do
            command.instance_variable_set(:@indexes, command.send(:fetch_indexes))
          end

          stub_request(:get, "#{DUMMY_REPO_URI_1}/#{Tapioca::CENTRAL_REPO_ANNOTATIONS_DIR}/foo.rbi")
            .with(headers: { "Authorization" => "TOKEN" })
            .to_return(status: 200, body: "# typed: strict\n\nclass Foo;end")

          gems = T.unsafe(command).stub(:say, ->(*_args) {}) do
            T.unsafe(command).stub(:create_file, ->(*_args) {}) do
              command.send(:fetch_annotations, ["foo", "bar"])
            end
          end

          assert_equal(["foo"], gems)
        end
      end
    end
  end
end
