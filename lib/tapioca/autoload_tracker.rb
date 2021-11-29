# typed: true
# frozen_string_literal: true

module Tapioca
  module AutoloadTracker
    extend T::Sig

    @constant_names_registered_for_autoload = T.let([], T::Array[String])

    def autoload(module_name, filename)
      AutoloadTracker.register("#{self}::#{module_name}")
      super
    end

    sig { void }
    def self.eager_load_all!
      until @constant_names_registered_for_autoload.empty?
        # Grab the next constant name
        constant_name = T.must(@constant_names_registered_for_autoload.shift)
        # Trigger autoload by constantizing the registered name
        Reflection.constantize(constant_name, inherit: true)
      end
    end

    sig { params(constant_name: String).void }
    def self.register(constant_name)
      @constant_names_registered_for_autoload << constant_name
    end

    Module.prepend(self)
  end
end
