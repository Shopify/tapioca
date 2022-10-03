# typed: true
# frozen_string_literal: true

require "forwardable"

module Tapioca
  module Dsl
    module Helpers
      class DrySchemaAstHelper
        extend ::T::Sig

        class Undefined
          def to_s
            "Undefined"
          end
        end

        class Sum
          attr_reader :types

          def initialize(types = [])
            @types = types
          end

          def size
            @types.size
          end

          def <<(arg)
            if arg.is_a?(Sum)
              arg.types.each { |t| @types << t }
            else
              @types << arg
            end
          end

          def include_undefined?
            @types.any? { |t| t.is_a?(Undefined) }
          end

          def include_nilclass?
            @types.include?(::NilClass)
          end

          def delete_nilclass!
            @types.reject! { |t| t == ::NilClass }
          end

          def to_s
            "Sum(#{@types.map(&:to_s).join(",")})"
          end

          def inspect
            to_s
          end
        end

        class Schema
          extend ::Forwardable

          delegate [:map, :empty?] => :@attribute_infos

          def initialize(attribute_infos)
            @attribute_infos = attribute_infos
          end
        end

        def visit(node)
          method, rest = node
          public_send(:"visit_#{method}", rest)
        end

        def visit_key(node)
          name, required, rest = node
          {
            name: name,
            required: required,
            type: visit(rest),
          }
        end

        def visit_constructor(node)
          a, _ = node
          visit(a)
        end

        def visit_struct(node)
          type, _ = node
          type
        end

        def visit_sum(node)
          type = Sum.new
          node.each do |n|
            next if n.is_a?(::Hash)

            type << visit(n)
          end
          type
        end

        def visit_array(node)
          type = visit(node[0])
          [type]
        end

        def visit_constrained(node)
          types = node.map { |r| visit(r) }.reject(&:nil?)
          types.size == 1 ? types[0] : types
        end

        def visit_nominal(node)
          type, _option = node
          type
        end

        def visit_predicate(node)
          # NOP
        end

        def visit_schema(node)
          if ::ENV["DRY_USE_EXPERIMENTAL_SHAPE"]
            Schema.new(node[0].map { |n| visit(n) })
          else
            ::Hash
          end
        end

        def visit_hash(node)
          ::Hash
        end

        def visit_any(node)
          Undefined.new
        end
      end
    end
  end
end
