# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    # This module should only be included when running Ruby version 3.2
    # or newer. It relies on the Class#attached_object method, which was
    # added in Ruby 3.2 and fetches the attached object of a singleton
    # class without having to iterate through all of ObjectSpace.
    module AttachedClassOf
      extend T::Sig

      #: (Class singleton_class) -> Module?
      def attached_class_of(singleton_class)
        result = singleton_class.attached_object
        Module === result ? result : nil
      end
    end
  end
end
