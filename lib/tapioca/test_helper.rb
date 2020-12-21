# typed: strict
# frozen_string_literal: true

require "parlour"

require "tapioca/testing/isolation"
require "tapioca/testing/content_helpers"
require "tapioca/testing/output_helpers"

module Tapioca
  module TestHelper
    include Tapioca::Testing::Isolation
    include Tapioca::Testing::ContentHelpers
    include Tapioca::Testing::OutputHelpers

    module Dsl
      extend T::Sig

      include TestHelper

      sig { returns(T.nilable(T.class_of(Tapioca::Compilers::Dsl::Base))) }
      attr_accessor :generator_class

      sig { returns(T::Array[String]) }
      def gathered_constants
        class_under_test = generator_class
        Kernel.raise("`generator_class` should be set before using `gathered_constants`") unless class_under_test

        class_under_test.new.processable_constants.map(&:to_s).sort
      end

      sig do
        params(
          constant_name: T.any(Symbol, String)
        ).returns(String)
      end
      def rbi_for(constant_name)
        class_under_test = generator_class
        Kernel.raise "`generator_class` should be set before using `rbi_for`" unless class_under_test

        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        class_under_test.new.decorate(parlour.root, Object.const_get(constant_name))
        parlour.rbi
      end
    end
  end
end
