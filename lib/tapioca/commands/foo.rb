# typed: true
# frozen_string_literal: true

require "smart_properties"

module Tapioca
  module Commands
    class Foo
      include SmartProperties

      property :bar
      property :baz
    end
  end
end

puts "IN SMARTPROPERTIES"
