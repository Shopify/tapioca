# typed: strict
# frozen_string_literal: true

module Tapioca
  module Compilers
    module Dsl
      module Helper
        module ActiveRecordConstants
          extend T::Sig

          AttributeMethodsModuleName = T.let("GeneratedAttributeMethods", String)
          AssociationMethodsModuleName = T.let("GeneratedAssociationMethods", String)

          RelationMethodsModuleName = T.let("GeneratedRelationMethods", String)
          AssociationRelationMethodsModuleName = T.let("GeneratedAssociationRelationMethods", String)
          CommonRelationMethodsModuleName = T.let("CommonRelationMethods", String)

          RelationClassName = T.let("PrivateRelation", String)
          RelationWhereChainClassName = T.let("PrivateWhereChainRelation", String)
          AssociationRelationClassName = T.let("PrivateAssociationRelation", String)
          AssociationRelationWhereChainClassName = T.let("PrivateAssociationWhereChainRelation", String)
          AssociationsCollectionProxyClassName = T.let("PrivateCollectionProxy", String)
        end
      end
    end
  end
end
