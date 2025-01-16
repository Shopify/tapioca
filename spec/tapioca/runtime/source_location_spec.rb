# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Runtime
    class ReflectionSpec < Minitest::Spec
      describe Tapioca::Runtime::SourceLocation do
        it "cannot be created with .new" do
          assert_raises(NoMethodError) do
            SourceLocation.new(file: "foo.rb", line: 1)
          end
        end

        it "can be created with .from_loc" do
          loc = SourceLocation.from_loc(["foo.rb", 1])
          loc = T.must(loc)

          assert_equal("foo.rb", loc.file)
          assert_equal(1, loc.line)
        end

        it "can be created with .from_loc with eval source location" do
          loc = SourceLocation.from_loc(["(eval at some/path/to/foo.rb:145)", 1])
          loc = T.must(loc)

          assert_equal("some/path/to/foo.rb", loc.file)
          assert_equal(145, loc.line)
        end

        it "returns nil when .from_loc is called with nil" do
          assert_nil(SourceLocation.from_loc(nil))
        end

        it "returns nil when .from_loc is called with nil file" do
          assert_nil(SourceLocation.from_loc([nil, 1]))
        end

        it "returns nil when .from_loc is called with nil line" do
          assert_nil(SourceLocation.from_loc(["foo.rb", nil]))
        end

        it "returns nil when .from_loc is called with nil file and line" do
          assert_nil(SourceLocation.from_loc([nil, nil]))
        end
      end
    end
  end
end
