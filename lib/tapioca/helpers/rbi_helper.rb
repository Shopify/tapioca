# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBIHelper
    extend T::Sig
    include SorbetHelper

    sig { params(sig_string: String).returns(String) }
    def sanitize_signature_types(sig_string)
      sig_string
        .gsub(".returns(<VOID>)", ".void")
        .gsub("<VOID>", "void")
        .gsub("<NOT-TYPED>", "T.untyped")
        .gsub(".params()", "")
    end

    sig do
      params(
        type: String,
        variance: Symbol,
        fixed: T.nilable(String),
        upper: T.nilable(String),
        lower: T.nilable(String)
      ).returns(String)
    end
    def serialize_type_variable(type, variance, fixed, upper, lower)
      variance = nil if variance == :invariant

      bounds = []
      bounds << "fixed: #{fixed}" if fixed
      bounds << "lower: #{lower}" if lower
      bounds << "upper: #{upper}" if upper

      parameters = []
      block = []

      parameters << ":#{variance}" if variance

      if sorbet_supports?(:type_variable_block_syntax)
        block = bounds
      else
        parameters.concat(bounds)
      end

      serialized = type.dup
      serialized << "(#{parameters.join(", ")})" unless parameters.empty?
      serialized << " { { #{block.join(", ")} } }" unless block.empty?
      serialized
    end
  end
end
