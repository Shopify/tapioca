# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class KaminariSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::Kaminari" do
          sig { void }
          def before_setup
            require "active_record"
            require "kaminari/activerecord"
          end

          describe "initialize" do
            it "gathers no constants if there are no ActiveRecord classes" do
              assert_empty(gathered_constants)
            end

            it "gathers only ActiveRecord constants with no abstract classes" do
              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                end

                class Product < ActiveRecord::Base
                  self.abstract_class = true
                end

                class User
                end
              RUBY

              assert_equal(["Post"], gathered_constants)
            end
          end

          describe "decorate" do
            describe "with relations enabled" do
              before do
                require "tapioca/dsl/compilers/active_record_relations"
                activate_other_dsl_compilers(ActiveRecordRelations)
              end

              it "generates an RBI file" do
                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                  end
                RUBY

                expected = <<~RBI
                  # typed: strong

                  class Post
                    extend GeneratedRelationMethods

                    module GeneratedAssociationRelationMethods
                      sig { params(num: T.any(Integer, String)).returns(T.all(PrivateAssociationRelation, Kaminari::PageScopeMethods, Kaminari::ActiveRecordRelationMethods)) }
                      def page(num = nil); end
                    end

                    module GeneratedRelationMethods
                      sig { params(num: T.any(Integer, String)).returns(T.all(PrivateRelation, Kaminari::PageScopeMethods, Kaminari::ActiveRecordRelationMethods)) }
                      def page(num = nil); end
                    end
                  end
                RBI

                assert_equal(expected, rbi_for(:Post))
              end
            end

            describe "without relations enabled" do
              it "generates an RBI file" do
                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                  end
                RUBY

                expected = <<~RBI
                  # typed: strong

                  class Post
                    extend GeneratedRelationMethods

                    module GeneratedRelationMethods
                      sig { params(num: T.any(Integer, String)).returns(T.all(T.untyped, Kaminari::PageScopeMethods, Kaminari::ActiveRecordRelationMethods)) }
                      def page(num = nil); end
                    end
                  end
                RBI

                assert_equal(expected, rbi_for(:Post))
              end
            end
          end
        end
      end
    end
  end
end
