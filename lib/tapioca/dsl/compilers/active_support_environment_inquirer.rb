# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveSupport::EnvironmentInquirer)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveSupportEnvironmentInquirer` decorates an RBI file for non-default environment
      # files in the `config/environments` directory.
      #
      # For example, in a Rails application with the following files:
      #
      # - config/environments/development.rb
      # - config/environments/demo.rb
      # - config/environments/production.rb
      # - config/environments/staging.rb
      # - config/environments/test.rb
      #
      # this compiler will produce an RBI file with the following content:
      # ~~~rbi
      # # typed: true
      #
      # class ActiveSupport::EnvironmentInquirer
      #   sig { returns(T::Boolean) }
      #   def demo?; end
      #
      #   sig { returns(T::Boolean) }
      #   def staging?; end
      # end
      # ~~~
      #: [ConstantType = singleton(::ActiveSupport::EnvironmentInquirer)]
      class ActiveSupportEnvironmentInquirer < Compiler
        extend T::Sig

        # @override
        #: -> void
        def decorate
          envs = Rails.root.glob("config/environments/*.rb").map { |f| f.basename(".rb").to_s }.sort
          envs -= ::ActiveSupport::EnvironmentInquirer::DEFAULT_ENVIRONMENTS
          return if envs.none?

          root.create_path(::ActiveSupport::EnvironmentInquirer) do |mod|
            envs.each do |env|
              mod.create_method("#{env}?", return_type: "T::Boolean")
            end
          end
        end

        class << self
          extend T::Sig

          # @override
          #: -> T::Enumerable[T::Module[top]]
          def gather_constants
            return [] unless defined?(Rails.application) && Rails.application

            [::ActiveSupport::EnvironmentInquirer]
          end
        end
      end
    end
  end
end
