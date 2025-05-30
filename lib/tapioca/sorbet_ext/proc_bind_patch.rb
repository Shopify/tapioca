# typed: true
# frozen_string_literal: true

module T
  module Types
    module ProcBindPatch
      def initialize(arg_types, returns, bind = T::Private::Methods::ARG_NOT_PROVIDED)
        super(arg_types, returns)

        unless bind == T::Private::Methods::ARG_NOT_PROVIDED
          @bind = T::Utils.coerce(bind) #: T::Types::Base
        end
      end

      def name
        name = super
        name = name.sub("T.proc", "T.proc.bind(#{@bind})") unless @bind.nil?
        name
      end
    end

    Proc.prepend(ProcBindPatch)
  end
end

module T
  module Private
    module Methods
      module ProcBindPatch
      end

      singleton_class.prepend(ProcBindPatch)
    end
  end
end
