# typed: true
# frozen_string_literal: true

module Tapioca
  module Static
    module Rbs
      class ParameterConverter
        extend T::Sig
        include Tapioca::RBIHelper

        class ParameterResult < T::Struct
          const :kind, Symbol
          const :name, String
          const :type, T::Types::Base
        end

        sig do
          params(
            type_converter: TypeConverter,
            type: RBS::Types::Function,
            block: T.nilable(RBS::Types::Block)
          ).void
        end
        def initialize(type_converter, type, block)
          @type = type
          @type_converter = type_converter
          @block = block
        end

        sig { returns(T::Array[ParameterResult]) }
        def convert
          parameters = [
            @type.required_positionals.map { |param| [:req, nil, param] },
            @type.optional_positionals.map { |param| [:opt, nil, param] },
            Array(@type.rest_positionals).map { |param| [:rest, nil, param] },
            @type.trailing_positionals.map { |param| [:opt, nil, param] },
            @type.required_keywords.map { |name, param| [:keyreq, name, param] },
            @type.optional_keywords.map { |name, param| [:key, name, param] },
            Array(@type.rest_keywords).map { |param| [:keyrest, nil, param] },
          ].flatten(1)

          result = parameters.map.with_index do |(kind, name, param), index|
            name = param.name unless name
            name = nil if [:module, :class, :end, :if, :unless].include?(name)
            name = (name || "_arg#{index}").to_s
            param_type = @type_converter.convert(param.type)

            ParameterResult.new(kind: kind, name: name, type: param_type)
          end

          if @block
            result << ParameterResult.new(kind: :block, name: "blk", type: @type_converter.convert(@block))
          end

          result
        end
      end
    end
  end
end
