# typed: strict
# frozen_string_literal: true

return unless defined?(JsonApiClient::Resource)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::JsonApiClientResource` generates RBI files for classes that inherit
      # [`JsonApiClient::Resource`](https://github.com/JsonApiClient/json_api_client).
      #
      # For example, with the following classes that inherits `JsonApiClient::Resource`:
      #
      # ~~~rb
      # # user.rb
      # class User < JsonApiClient::Resource
      #   has_many :posts
      #
      #   property :name, type: :string
      #   property :is_admin, type: :boolean, default: false
      # end
      #
      # # post.rb
      # class Post < JsonApiClient::Resource
      #   belongs_to :user
      #
      #   property :title, type: :string
      # end
      # ~~~
      #
      # this compiler will produce RBI files with the following content:
      #
      # ~~~rbi
      # # user.rbi
      # # typed: strong
      #
      # class User
      #   include JsonApiClientResourceGeneratedMethods
      #
      #   module JsonApiClientResourceGeneratedMethods
      #     sig { returns(T::Boolean) }
      #     def is_admin; end
      #
      #     sig { params(is_admin: T::Boolean).returns(T::Boolean) }
      #     def is_admin=(is_admin); end
      #
      #     sig { returns(T.nilable(::String)) }
      #     def name; end
      #
      #     sig { params(name: T.nilable(::String)).returns(T.nilable(::String)) }
      #     def name=(name); end
      #
      #     sig { returns(T.nilable(T::Array[Post])) }
      #     def posts; end
      #
      #     sig { params(posts: T.nilable(T::Array[Post])).returns(T.nilable(T::Array[Post])) }
      #     def posts=(posts); end
      #   end
      # end
      #
      # # post.rbi
      # # typed: strong
      #
      # class Post
      #   include JsonApiClientResourceGeneratedMethods
      #
      #   module JsonApiClientResourceGeneratedMethods
      #     sig { returns(T.nilable(::String)) }
      #     def title; end
      #
      #     sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
      #     def title=(title); end
      #
      #     sig { returns(T.nilable(::String)) }
      #     def user_id; end
      #
      #     sig { params(user_id: T.nilable(::String)).returns(T.nilable(::String)) }
      #     def user_id=(user_id); end
      #   end
      # end
      # ~~~
      #: [ConstantType = singleton(::JsonApiClient::Resource)]
      class JsonApiClientResource < Compiler
        # @override
        #: -> void
        def decorate
          schema = resource_schema
          return if schema.nil? && constant.associations.empty?

          root.create_path(constant) do |k|
            module_name = "JsonApiClientResourceGeneratedMethods"
            k.create_module(module_name) do |mod|
              schema&.each_property do |property|
                generate_methods_for_property(mod, property)
              end

              constant.associations.each do |association|
                generate_methods_for_association(mod, association)
              end
            end

            k.create_include(module_name)
          end
        end

        class << self
          # @override
          #: -> Enumerable[T::Module[top]]
          def gather_constants
            all_modules.select do |c|
              name_of(c) && ::JsonApiClient::Resource > c
            end
          end
        end

        private

        #: -> ::JsonApiClient::Schema?
        def resource_schema
          schema = constant.schema

          # empty? does not exist on JsonApiClient::Schema
          schema if schema.size > 0 # rubocop:disable Style/ZeroLengthPredicate
        end

        #: (RBI::Scope mod, ::JsonApiClient::Schema::Property property) -> void
        def generate_methods_for_property(mod, property)
          type = type_for(property)

          name = property.name.to_s

          mod.create_method(name, return_type: type)
          mod.create_method("#{name}=", parameters: [create_param(name, type: type)], return_type: type)
        end

        #: (::JsonApiClient::Schema::Property property) -> RBI::Type
        def type_for(property)
          type = ::JsonApiClient::Schema::TypeFactory.type_for(property.type)
          return RBI::Type.untyped if type.nil?

          sorbet_type = if type.respond_to?(:sorbet_type)
            line, file = type.method(:sorbet_type).source_location

            $stderr.puts <<~MESSAGE
              WARNING: `#sorbet_type` is deprecated. Please rename your method to `#__tapioca_type`."

              Defined on line #{line} of #{file}
            MESSAGE

            RBI::Type.parse_string(type.sorbet_type)
          elsif type.respond_to?(:__tapioca_type)
            RBI::Type.parse_string(type.__tapioca_type)
          elsif type == ::JsonApiClient::Schema::Types::Integer
            RBI::Type.simple("::Integer")
          elsif type == ::JsonApiClient::Schema::Types::String
            RBI::Type.simple("::String")
          elsif type == ::JsonApiClient::Schema::Types::Float
            RBI::Type.simple("::Float")
          elsif type == ::JsonApiClient::Schema::Types::Time
            RBI::Type.simple("::Time")
          elsif type == ::JsonApiClient::Schema::Types::Decimal
            RBI::Type.simple("::BigDecimal")
          elsif type == ::JsonApiClient::Schema::Types::Boolean
            RBI::Type.boolean
          else
            RBI::Type.untyped
          end

          if property.default.nil?
            as_nilable_type(sorbet_type)
          else
            sorbet_type
          end
        end

        #: (RBI::Scope mod, JsonApiClient::Associations::BaseAssociation association) -> void
        def generate_methods_for_association(mod, association)
          # If the association is broken, it will raise a NameError when trying to access the association_class
          klass = association.association_class

          name, type = case association
          when ::JsonApiClient::Associations::BelongsTo::Association
            # id must be a string: # https://jsonapi.org/format/#document-resource-object-identification
            [association.param.to_s, RBI::Type.simple("::String").nilable]
          when ::JsonApiClient::Associations::HasOne::Association
            [association.attr_name.to_s, RBI::Type.simple(T.must(qualified_name_of(klass))).nilable]
          when ::JsonApiClient::Associations::HasMany::Association
            [association.attr_name.to_s, RBI::Type.generic("T::Array", RBI::Type.simple(T.must(qualified_name_of(klass)))).nilable]
          else
            return # Unsupported association type
          end

          mod.create_method(name, return_type: type)
          mod.create_method("#{name}=", parameters: [create_param(name, type: type)], return_type: type)
        end
      end
    end
  end
end
