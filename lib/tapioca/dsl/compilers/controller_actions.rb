# typed: strict
# frozen_string_literal: true

begin
  require "action_controller"
rescue LoadError
  return
end

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ControllerActions` generates RBI files for classes that include
      # [`ActionController::Base`](https://api.rubyonrails.org/classes/ActionController/Base.html).
      #
      # For example, with the following class that includes `ActionController::Base`:
      #
      # ~~~rb
      # class PostsController < ApplicationController
      #  def index
      #   # ...
      #  end
      #
      #  def create
      #    # ...
      #  end
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `posts_controller.rbi` with the following content:
      #
      # ~~~rbi
      # # posts_controller.rbi
      # # typed: strong
      # class PostsController
      #   sig { void }
      #   def index; end
      #
      #   sig { void }
      #   def create; end
      # end
      # ~~~
      class ControllerActions < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::ActionController::Base) } }

        sig { override.void }
        def decorate
          public_methods = constant.instance_methods(false)
          return if public_methods.empty?

          root.create_path(constant) do |klass|
            public_methods.each do |method_name|
              method = constant.instance_method(method_name)
              signature = signature_of(method)
              next if signature

              klass.create_method(method_name.to_s, return_type: "void")
            end
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes.select { |c| c < ActionController::Base }
          end
        end
      end
    end
  end
end
