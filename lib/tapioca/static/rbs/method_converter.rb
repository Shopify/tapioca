# typed: true
# frozen_string_literal: true

module Tapioca
  module Static
    module Rbs
      class MethodConverter
        extend T::Sig

        sig { params(converter: Converter, method_type: RBS::MethodType, name: String, is_singleton: T::Boolean, visibility: Symbol).void }
        def initialize(converter, method_type, name = "", is_singleton = false, visibility = :public)
          @converter = converter
          @name = name
          @is_singleton = is_singleton
          @type_converter = T.let(TypeConverter.new(converter, method_type.type_params), TypeConverter)
          @param_converter = T.let(
            ParameterConverter.new(@type_converter, method_type.type, method_type.block),
            ParameterConverter
          )
          @return_type = T.let(@type_converter.to_string(method_type.type.return_type), String)
          @visibility = T.let(@type_converter.visibility(visibility), RBI::Visibility)
        end

        sig { params(block: T.nilable(T.proc.params(method: RBI::Method).void)).returns(RBI::Method) }
        def to_rbi_method(&block)
          RBI::Method.new(@name, is_singleton: @is_singleton, visibility: @visibility) do |method|
            each_param { |param| method << param }
            method.sigs << signature
            block&.call(method)
          end
        end

        sig { params(block: T.proc.params(param: RBI::Param).void).void }
        def each_param(&block)
          @param_converter.convert.each do |param|
            name = param.name

            rbi_param = case param.kind
            when :req
              RBI::Param.new(name)
            when :opt
              RBI::OptParam.new(name, "T.unsafe(nil)")
            when :rest
              RBI::RestParam.new(name)
            when :keyreq
              RBI::KwParam.new(name)
            when :key
              RBI::KwOptParam.new(name, "T.unsafe(nil)")
            when :keyrest
              RBI::KwRestParam.new(name)
            when :block
              RBI::BlockParam.new(name)
            end

            block.call(T.must(rbi_param))
          end
        end

        sig { returns(RBI::Sig) }
        def signature
          sig = RBI::Sig.new

          # Type parameters
          @type_converter.type_params.each do |type_param|
            sig.type_params << type_param.to_s
          end

          # Parameters
          @param_converter.convert.each do |param|
            param_type = @type_converter.to_string(param.type)

            sig << RBI::SigParam.new(param.name, param_type)
          end

          # Return type
          sig.return_type = if @name == "initialize"
            "void"
          elsif !@is_singleton && @return_type == "T.attached_class"
            "T.untyped"
          else
            @return_type
          end

          sig
        end
      end
    end
  end
end
