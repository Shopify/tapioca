# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class RipperSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::Ripper" do
          sig { void }
          def before_setup
            require "ripper"
          end

          describe "decorate" do
            it "generates RBI definitions for ripper events" do
              rbi = rbi_for(:Ripper).gsub(/^\s+/, "")

              assert_includes(rbi, <<~RUBY)
                sig { params(value: ::String).returns(T.untyped) }
                def on_int(value); end
              RUBY

              assert_includes(rbi, <<~RUBY)
                sig { params(param0: T.untyped, param1: T.untyped, param2: T.untyped).returns(T.untyped) }
                def on_binary(param0, param1, param2); end
              RUBY
            end

            it "generates RBI definitions for ripper state constants" do
              rbi = rbi_for(:Ripper)

              assert_match(/^Ripper::EXPR_BEG =.+::Integer.+$/, rbi)
            end
          end
        end
      end
    end
  end
end
