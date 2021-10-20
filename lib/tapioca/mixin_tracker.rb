# typed: true
# frozen_string_literal: true

module Tapioca
  module MixinTracker
    extend T::Helpers
    requires_ancestor { Kernel }

    @mixin_map = {}.compare_by_identity

    def prepend(*mods)
      MixinTracker.register(self, mods, :prepend, caller_locations)
      super
    end

    def include(*mods)
      MixinTracker.register(self, mods, :include, caller_locations)
      super
    end

    def extend(*mods)
      MixinTracker.register(self, mods, :extend, caller_locations)
      super
    end

    def self.register(constant, mods, mixin_type, locations)
      locs = mixin_locations_for(constant)
      locations.map!(&:absolute_path)

      mods.each do |mod|
        locs[mixin_type][mod] = locations
      end
    end

    def self.mixin_locations_for(constant)
      @mixin_map[constant] ||= {
        prepend: {}.compare_by_identity,
        include: {}.compare_by_identity,
        extend: {}.compare_by_identity,
      }
    end

    Module.prepend(self)
    register(Module, [self], :prepend, caller_locations)
  end

  private_constant :MixinTracker
end
