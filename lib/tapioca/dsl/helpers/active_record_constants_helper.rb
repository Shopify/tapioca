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

        AttributeMethodsModuleName = T.let("GeneratedAttributeMethods", String)
        AssociationMethodsModuleName = T.let("GeneratedAssociationMethods", String)

        RelationMethodsModuleName = T.let("GeneratedRelationMethods", String)
        AssociationRelationMethodsModuleName = T.let("GeneratedAssociationRelationMethods", String)
        CommonRelationMethodsModuleName = T.let("CommonRelationMethods", String)

        RelationClassName = T.let("ActiveRecord_Relation", String)
        RelationWhereChainClassName = T.let("PrivateRelationWhereChain", String)
        AssociationRelationClassName = T.let("ActiveRecord_AssociationRelation", String)
        AssociationRelationWhereChainClassName = T.let("PrivateAssociationRelationWhereChain", String)
        AssociationsCollectionProxyClassName = T.let("ActiveRecord_Associations_CollectionProxy", String)
      end
    end
  end
end
