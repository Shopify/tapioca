# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Helpers
      module ActiveRecordConstantsHelper
        extend T::Sig

        ReflectionType = T.type_alias do
          T.any(::ActiveRecord::Reflection::ThroughReflection, ::ActiveRecord::Reflection::AssociationReflection)
        end

        # rubocop:disable Naming/ConstantName

        AttributeMethodsModuleName = "GeneratedAttributeMethods" #: String
        AssociationMethodsModuleName = "GeneratedAssociationMethods" #: String
        DelegatedTypesModuleName = "GeneratedDelegatedTypeMethods" #: String
        SecureTokensModuleName = "GeneratedSecureTokenMethods" #: String
        StoredAttributesModuleName = "GeneratedStoredAttributesMethods" #: String

        RelationMethodsModuleName = "GeneratedRelationMethods" #: String
        AssociationRelationMethodsModuleName = "GeneratedAssociationRelationMethods" #: String
        CommonRelationMethodsModuleName = "CommonRelationMethods" #: String

        RelationClassName = "PrivateRelation" #: String
        RelationGroupChainClassName = "PrivateRelationGroupChain" #: String
        RelationWhereChainClassName = "PrivateRelationWhereChain" #: String
        AssociationRelationClassName = "PrivateAssociationRelation" #: String
        AssociationRelationGroupChainClassName = "PrivateAssociationRelationGroupChain" #: String
        AssociationRelationWhereChainClassName = "PrivateAssociationRelationWhereChain" #: String
        AssociationsCollectionProxyClassName = "PrivateCollectionProxy" #: String

        # rubocop:enable Naming/ConstantName
      end
    end
  end
end
