# typed: strict
# frozen_string_literal: true

module Tapioca
  module Trackers
    class MixinType < T::Enum
      enums do
        Prepend = new
        Include = new
        Extend = new
      end
    end
  end
end
