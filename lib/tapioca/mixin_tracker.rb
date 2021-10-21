# typed: true
# frozen_string_literal: true

module Tapioca
  module MixinTracker
    extend T::Helpers
    requires_ancestor { Kernel }

    @mixin_map = {}.compare_by_identity

    def prepend_features(constant)
      MixinTracker.register(constant, self, :prepend, caller_locations)
      super
    end

    def append_features(constant)
      MixinTracker.register(constant, self, :include, caller_locations)
      super
    end

    def extend_object(obj)
      MixinTracker.register(obj, self, :extend, caller_locations) if Module === obj
      super
    end

    def self.register(constant, mod, mixin_type, locations)
      locations.map!(&:absolute_path).uniq!
      locs = mixin_locations_for(constant)
      locs[mixin_type][mod] = locations
    end

    def self.mixin_locations_for(constant)
      @mixin_map[constant] ||= {
        prepend: {}.compare_by_identity,
        include: {}.compare_by_identity,
        extend: {}.compare_by_identity,
      }
    end

    Module.prepend(self)
    register(Module, self, :prepend, caller_locations)
  end

  private_constant :MixinTracker
end
