# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBIHelper
    extend T::Sig
    include SorbetHelper
    extend SorbetHelper
    include Runtime::Reflection
    extend self

    class << self
      extend T::Sig

      sig do
        params(
          type: String,
          variance: Symbol,
          fixed: T.nilable(String),
          upper: T.nilable(String),
          lower: T.nilable(String),
        ).returns(String)
      end
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

    sig { params(name: String, type: String).returns(RBI::TypedParam) }
    def create_param(name, type:)
      create_typed_param(RBI::ReqParam.new(name), type)
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
      create_typed_param(RBI::BlockParam.new(name), type)
    end

    sig { params(param: RBI::Param, type: String).returns(RBI::TypedParam) }
    def create_typed_param(param, type)
      RBI::TypedParam.new(param: param, type: sanitize_signature_types(type))
    end

    sig { params(sig_string: String).returns(String) }
    def sanitize_signature_types(sig_string)
      sig_string
        .gsub(".returns(<VOID>)", ".void")
        .gsub("<VOID>", "void")
        .gsub("<NOT-TYPED>", "T.untyped")
        .gsub(".params()", "")
    end

    sig { params(type: String).returns(String) }
    def as_nilable_type(type)
      if type.start_with?("T.nilable(", "::T.nilable(") || type == "T.untyped" || type == "::T.untyped"
        type
      else
        "T.nilable(#{type})"
      end
    end

    sig { params(type: String).returns(String) }
    def as_non_nilable_type(type)
      if type.match(/\A(?:::)?T.nilable\((.+)\)\z/)
        T.must(::Regexp.last_match(1))
      else
        type
      end
    end

    sig { params(name: String).returns(T::Boolean) }
    def valid_method_name?(name)
      # try to parse a method definition with this name
      iseq = RubyVM::InstructionSequence.compile("def #{name}; end", nil, nil, 0, false)
      # pull out the first operation in the instruction sequence and its first argument
      op, arg, _data = iseq.to_a.dig(-1, 0)
      # make sure that the operation is a method definition and the method that was
      # defined has the expected name, for example, for `def !foo; end` we don't get
      # a syntax error but instead get a method defined as `"foo"`
      op == :definemethod && arg == name.to_sym
    rescue SyntaxError
      false
    end

    sig { params(name: String).returns(T::Boolean) }
    def valid_parameter_name?(name)
      sentinel_method_name = :sentinel_method_name
      # try to parse a method definition with this name as the name of a
      # keyword parameter. If we use a positional parameter, then parameter names
      # like `&` (and maybe others) will be treated like `def foo(&); end` and will
      # thus be considered valid. Using a required keyword parameter prevents that
      # confusion between Ruby syntax and parameter name.
      iseq = RubyVM::InstructionSequence.compile("def #{sentinel_method_name}(#{name}:); end", nil, nil, 0, false)
      # pull out the first operation in the instruction sequence and its first argument and data
      op, arg, data = iseq.to_a.dig(-1, 0)
      # make sure that:
      # 1. a method was defined, and
      # 2. the method has the expected method name, and
      # 3. the method has a keyword parameter with the expected name
      op == :definemethod && arg == sentinel_method_name && data.dig(11, :keyword, 0) == name.to_sym
    rescue SyntaxError
      false
    end

    sig { params(constant: T.all(Module, T::Generic)).returns(String) }
    def generic_name_of(constant)
      type_name = T.must(qualified_name_of(constant))
      return type_name if type_name =~ /\[.*\]$/

      type_variables = Runtime::GenericTypeRegistry.lookup_type_variables(constant)
      return type_name unless type_variables

      type_variables = type_variables.reject(&:fixed?)
      return type_name if type_variables.empty?

      type_variable_names = type_variables.map { "T.untyped" }.join(", ")

      "#{type_name}[#{type_variable_names}]"
    end

    sig { params(constant: Module).returns(T.nilable(String)) }
    def qualified_name_of(constant)
      name = name_of(constant)
      return if name.nil?

      if name.start_with?("::")
        name
      else
        "::#{name}"
      end
    end

    sig { params(constant: Module).returns(T.nilable(String)) }
    def name_of(constant)
      name = name_of_proxy_target(constant, super(class_of(constant)))
      return name if name

      name = super(constant)
      return if name.nil?
      return unless are_equal?(constant, constantize(name, inherit: true))

      name = "Struct" if name =~ /^(::)?Struct::[^:]+$/
      name
    end

    sig { params(constant: Module, class_name: T.nilable(String)).returns(T.nilable(String)) }
    def name_of_proxy_target(constant, class_name)
      return unless class_name == "ActiveSupport::Deprecation::DeprecatedConstantProxy"

      # We are dealing with a ActiveSupport::Deprecation::DeprecatedConstantProxy
      # so try to get the name of the target class
      begin
        target = constant.__send__(:target)
      rescue NoMethodError
        return
      end

      name_of(target)
    end
  end
end
