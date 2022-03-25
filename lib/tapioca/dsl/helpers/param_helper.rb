# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Helpers
      module ParamHelper
        extend T::Sig
        include SignaturesHelper

        sig { params(name: String, type: String).returns(RBI::TypedParam) }
        def create_param(name, type:)
          create_typed_param(RBI::Param.new(name), type)
        end

        sig { params(name: String, type: String, default: String).returns(RBI::TypedParam) }
        def create_opt_param(name, type:, default:)
          create_typed_param(RBI::OptParam.new(name, default), type)
        end

        sig { params(name: String, type: String).returns(RBI::TypedParam) }
        def create_rest_param(name, type:)
          create_typed_param(RBI::RestParam.new(name), type)
        end

        sig { params(name: String, type: String).returns(RBI::TypedParam) }
        def create_kw_param(name, type:)
          create_typed_param(RBI::KwParam.new(name), type)
        end

        sig { params(name: String, type: String, default: String).returns(RBI::TypedParam) }
        def create_kw_opt_param(name, type:, default:)
          create_typed_param(RBI::KwOptParam.new(name, default), type)
        end

        sig { params(name: String, type: String).returns(RBI::TypedParam) }
        def create_kw_rest_param(name, type:)
          create_typed_param(RBI::KwRestParam.new(name), type)
        end

        sig { params(name: String, type: String).returns(RBI::TypedParam) }
        def create_block_param(name, type:)
          create_typed_param(RBI::BlockParam.new(name), sanitize_signature_types(type))
        end

        sig { params(param: RBI::Param, type: String).returns(RBI::TypedParam) }
        def create_typed_param(param, type)
          RBI::TypedParam.new(param: param, type: type)
        end
      end
    end
  end
end
