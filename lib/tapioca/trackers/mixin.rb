# typed: true
# frozen_string_literal: true

require "tapioca/trackers/mixin_type"

module Tapioca
  module Trackers
    module Mixin
      extend T::Helpers
      requires_ancestor { Kernel }

      @mixin_map = {}.compare_by_identity

      def prepend_features(constant)
        Mixin.register(constant, self, MixinType::Prepend, caller_locations)
        super
      end

      def append_features(constant)
        Mixin.register(constant, self, MixinType::Include, caller_locations)
        super
      end

      def extend_object(obj)
        Mixin.register(obj, self, MixinType::Extend, caller_locations) if Module === obj
        super
      end

      def self.register(constant, mod, mixin_type, locations)
        locations.map!(&:absolute_path).uniq!
        locs = mixin_locations_for(constant)
        locs[mixin_type][mod] = locations
      end

      def self.mixin_locations_for(constant)
        @mixin_map[constant] ||= {
          MixinType::Prepend => {}.compare_by_identity,
          MixinType::Include => {}.compare_by_identity,
          MixinType::Extend => {}.compare_by_identity,
        }
      end

      Module.prepend(self)
      # We want to register ourselves explicitly, since when we
      # get prepended, the hook has not been setup yet. Thus, we
      # need to do the registration manually.
      register(Module, self, MixinType::Prepend, caller_locations)
    end
  end
end
