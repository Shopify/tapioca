# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBIHelper
    extend T::Sig
    include SorbetHelper
    extend SorbetHelper
    extend self

    class << self
      extend T::Sig

      #: (String type, Symbol variance, String? fixed, String? upper, String? lower) -> String
      def serialize_type_variable(type, variance, fixed, upper, lower)
        variance = nil if variance == :invariant

        block = []
        block << "fixed: #{fixed}" if fixed
        block << "lower: #{lower}" if lower
        block << "upper: #{upper}" if upper

        parameters = []
        parameters << ":#{variance}" if variance

        serialized = type.dup
        serialized << "(#{parameters.join(", ")})" unless parameters.empty?
        serialized << " { { #{block.join(", ")} } }" unless block.empty?
        serialized
      end
    end

    #: (String name, type: String) -> RBI::TypedParam
    def create_param(name, type:)
      create_typed_param(RBI::ReqParam.new(name), type)
    end

    #: (String name, type: String, default: String) -> RBI::TypedParam
    def create_opt_param(name, type:, default:)
      create_typed_param(RBI::OptParam.new(name, default), type)
    end

    #: (String name, type: String) -> RBI::TypedParam
    def create_rest_param(name, type:)
      create_typed_param(RBI::RestParam.new(name), type)
    end

    #: (String name, type: String) -> RBI::TypedParam
    def create_kw_param(name, type:)
      create_typed_param(RBI::KwParam.new(name), type)
    end

    #: (String name, type: String, default: String) -> RBI::TypedParam
    def create_kw_opt_param(name, type:, default:)
      create_typed_param(RBI::KwOptParam.new(name, default), type)
    end

    #: (String name, type: String) -> RBI::TypedParam
    def create_kw_rest_param(name, type:)
      create_typed_param(RBI::KwRestParam.new(name), type)
    end

    #: (String name, type: String) -> RBI::TypedParam
    def create_block_param(name, type:)
      create_typed_param(RBI::BlockParam.new(name), type)
    end

    #: (RBI::Param param, String type) -> RBI::TypedParam
    def create_typed_param(param, type)
      RBI::TypedParam.new(param: param, type: sanitize_signature_types(type))
    end

    #: (String sig_string) -> String
    def sanitize_signature_types(sig_string)
      sig_string
        .gsub(".returns(<VOID>)", ".void")
        .gsub("<VOID>", "void")
        .gsub("<NOT-TYPED>", "T.untyped")
        .gsub(".params()", "")
    end

    #: (String type) -> String
    def as_nilable_type(type)
      if type.start_with?("T.nilable(", "::T.nilable(") || type == "T.untyped" || type == "::T.untyped"
        type
      else
        "T.nilable(#{type})"
      end
    end

    #: (String type) -> String
    def as_non_nilable_type(type)
      if type.match(/\A(?:::)?T.nilable\((.+)\)\z/)
        T.must(::Regexp.last_match(1))
      else
        type
      end
    end

    #: (String name) -> bool
    def valid_method_name?(name)
      Prism.parse_success?("def self.#{name}(a); end")
    end

    #: (String name) -> bool
    def valid_parameter_name?(name)
      Prism.parse_success?("def sentinel_method_name(#{name}:); end")
    end
  end
end
