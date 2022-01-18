# typed: strict
# frozen_string_literal: true

module Tapioca
  module CompilerHelper
    class << self
      extend T::Sig

      sig { params(mixin: String).returns(T::Boolean) }
      def filtered_mixin?(mixin:)
        # filter T:: namespace mixins that aren't T::Props
        # T::Props and subconstants have semantic value
        mixin.start_with?("T::") && !mixin.start_with?("T::Props")
      end
    end
  end
end