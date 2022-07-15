# typed: true
# frozen_string_literal: true

module T
  module Types
    module ProcBindPatch
      def initialize(arg_types, returns, bind)
        super(arg_types, returns)

        unless bind == T::Private::Methods::ARG_NOT_PROVIDED
          @bind = T.let(T::Utils.coerce(bind), T::Types::Base)
        end
      end

      def name
        args = []
        @arg_types.each do |k, v|
          args << "#{k}: #{v.name}"
        end

        base_name = +"T.proc"
        base_name << ".bind(#{@bind})" if @bind
        "#{base_name}.params(#{args.join(", ")}).returns(#{@returns})"
      end
    end

    Proc.prepend(ProcBindPatch)
  end
end

module T
  module Private
    module Methods
      module ProcBindPatch
        def finalize_proc(decl)
          decl.finalized = true
          decl.params = {} if decl.params == ARG_NOT_PROVIDED

          T.unsafe(T::Types::Proc).new(decl.params, decl.returns, decl.bind)
        end
      end

      singleton_class.prepend(ProcBindPatch)
    end
  end
end
