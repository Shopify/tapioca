# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    class Event
      extend T::Helpers

      abstract!
    end

    class SymbolFound < Event

      #: String
      attr_reader :symbol

      #: (String symbol) -> void
      def initialize(symbol)
        super()
        @symbol = symbol
      end
    end

    class ConstantFound < Event

      #: String
      attr_reader :symbol

      #: BasicObject
      attr_reader :constant

      #: (String symbol, BasicObject constant) -> void
      def initialize(symbol, constant)
        super()
        @symbol = symbol
        @constant = constant
      end
    end

    class ForeignConstantFound < ConstantFound

      # @override
      #: -> Module
      def constant
        T.cast(@constant, Module)
      end

      #: (String symbol, Module constant) -> void
      def initialize(symbol, constant)
        super
      end
    end

    class NodeAdded < Event
      extend T::Helpers

      abstract!

      #: String
      attr_reader :symbol

      #: Module
      attr_reader :constant

      #: (String symbol, Module constant) -> void
      def initialize(symbol, constant)
        super()
        @symbol = symbol
        @constant = constant
      end
    end

    class ConstNodeAdded < NodeAdded

      #: RBI::Const
      attr_reader :node

      #: (String symbol, Module constant, RBI::Const node) -> void
      def initialize(symbol, constant, node)
        super(symbol, constant)
        @node = node
      end
    end

    class ScopeNodeAdded < NodeAdded

      #: RBI::Scope
      attr_reader :node

      #: (String symbol, Module constant, RBI::Scope node) -> void
      def initialize(symbol, constant, node)
        super(symbol, constant)
        @node = node
      end
    end

    class ForeignScopeNodeAdded < ScopeNodeAdded; end

    class MethodNodeAdded < NodeAdded

      #: UnboundMethod
      attr_reader :method

      #: RBI::Method
      attr_reader :node

      #: untyped
      attr_reader :signature

      #: Array[[Symbol, String]]
      attr_reader :parameters

      #: (String symbol, Module constant, UnboundMethod method, RBI::Method node, untyped signature, Array[[Symbol, String]] parameters) -> void
      def initialize(symbol, constant, method, node, signature, parameters) # rubocop:disable Metrics/ParameterLists
        super(symbol, constant)
        @node = node
        @method = method
        @signature = signature
        @parameters = parameters
      end
    end
  end
end
