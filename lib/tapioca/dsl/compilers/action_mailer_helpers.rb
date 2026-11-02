# typed: strict
# frozen_string_literal: true

return unless defined?(ActionMailer::Base)

require "tapioca/dsl/helpers/helper_methods_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActionMailerHelpers` decorates RBI files for all
      # subclasses of [`ActionMailer::Base`](https://api.rubyonrails.org/classes/ActionMailer/Base.html)
      # that define helpers.
      #
      # Like a controller, a mailer that calls `helper` or `helper_method` gets its own `HelperMethods` module, which
      # its views include. For example, with the following `FormatHelper` module:
      #
      # ~~~rb
      # module FormatHelper
      #   def format_amount(cents)
      #     # ...
      #   end
      # end
      # ~~~
      #
      # and the following mailer:
      #
      # ~~~rb
      # class NotifierMailer < ActionMailer::Base
      #   helper FormatHelper
      #   helper_method :unsubscribe_url
      #
      #   def unsubscribe_url
      #     # ...
      #   end
      # end
      # ~~~
      #
      # this compiler will produce an RBI file `notifier_mailer.rbi` with the following content:
      #
      # ~~~rbi
      # # notifier_mailer.rbi
      # # typed: strong
      # class NotifierMailer
      #   module HelperMethods
      #     include ::ActionMailer::MailHelper
      #     include ::ActionMailer::Base::HelperMethods
      #     include ::FormatHelper
      #
      #     sig { returns(T.untyped) }
      #     def unsubscribe_url; end
      #   end
      # end
      # ~~~
      #
      # A mailer whose parent mailer has helpers includes the parent's `HelperMethods` and only the helper modules it
      # adds, as `Tapioca::Dsl::Compilers::ActionControllerHelpers` does for controllers. Mailers have no `helpers`
      # proxy, so there is no `HelperProxy` class.
      #: [ConstantType = singleton(::ActionMailer::Base)]
      class ActionMailerHelpers < Compiler
        include Helpers::HelperMethodsHelper

        # @override
        #: -> void
        def decorate
          root.create_path(constant) do |mailer|
            create_helper_methods_module(mailer, constant, base: ::ActionMailer::Base)
          end
        end

        class << self
          # @override
          #: -> Enumerable[Module[top]]
          def gather_constants
            descendants_of(::ActionMailer::Base).select(&:name).select do |klass|
              klass.const_defined?(:HelperMethods, false)
            end
          end
        end
      end
    end
  end
end
