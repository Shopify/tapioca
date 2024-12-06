# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    class PipelineSpec < Minitest::Spec
      include Tapioca::Helpers::Test::Content
      include Tapioca::Helpers::Test::Isolation

      describe Tapioca::Dsl::Pipeline do
        describe "#active_compilers" do
          it "sorts the list of active compilers using `.run_after_compilers`" do
            add_ruby_file("sorbet/tapioca/compilers/cherry.rb", <<~RUBY)
              class Tapioca::Dsl::Cherry < Tapioca::Dsl::Compiler; end
            RUBY

            add_ruby_file("sorbet/tapioca/compilers/banana.rb", <<~RUBY)
              class Tapioca::Dsl::Banana < Tapioca::Dsl::Compiler; end
            RUBY

            add_ruby_file("sorbet/tapioca/compilers/apple.rb", <<~RUBY)
              require_relative 'banana'

              class Tapioca::Dsl::Apple < Tapioca::Dsl::Compiler
                def self.run_after_compilers = [Tapioca::Dsl::Banana]
              end
            RUBY

            expected_compilers = ["Tapioca::Dsl::Banana", "Tapioca::Dsl::Apple", "Tapioca::Dsl::Cherry"]
            actual_compilers = Pipeline.new(requested_constants: []).active_compilers.map(&:name)
            assert_equal(expected_compilers, actual_compilers)
          end
        end
      end
    end
  end
end
