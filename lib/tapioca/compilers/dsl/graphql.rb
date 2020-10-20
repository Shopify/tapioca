# typed: strict
# frozen_string_literal: true

require "parlour"

begin
  require "graphql"
rescue LoadError
  # means Graphql is not installed,
  # so let's not even define the generator.
  return
end


module Tapioca
  module Compilers
    module Dsl
      class Graphql < Base
        extend T::Sig


        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          classes = T.cast(ObjectSpace.each_object(Class), T::Enumerable[Class])
          classes.select do |c|
            c < ::GraphQL::Schema::Object
          end.reject do |c|
            c.name.nil? || c == ::SmartProperties::Validations::Ancestor
          end
        end
      end
    end
  end
end
