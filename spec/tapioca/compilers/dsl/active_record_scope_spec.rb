# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ActiveRecordScopeSpec < DslSpec
  describe "Tapioca::Compilers::Dsl::ActiveRecordScope" do
    describe "initialize" do
      after do
        T.unsafe(self).assert_no_generated_errors
      end

      it "gathers no constants if there are no ActiveRecord classes" do
        assert_empty(gathered_constants)
      end

      it "gathers only ActiveRecord constants with no abstract classes" do
        add_ruby_file("conversation.rb", <<~RUBY)
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
      after do
        T.unsafe(self).assert_no_generated_errors
      end

      describe "with relations enabled" do
        before do
          require "tapioca/compilers/dsl/active_record_relations"
          activate_other_dsl_compilers(Tapioca::Compilers::Dsl::ActiveRecordRelations)
        end

        it "generates an empty RBI file for ActiveRecord classes with no scope field" do
          add_ruby_file("post.rb", <<~RUBY)
            class Post < ActiveRecord::Base
            end
          RUBY

          expected = <<~RBI
            # typed: strong
          RBI

          assert_equal(expected, rbi_for(:Post))
        end

        it "generates RBI file for ActiveRecord classes with a scope field" do
          add_ruby_file("post.rb", <<~RUBY)
            class Post < ActiveRecord::Base
              scope :public_kind, -> { where.not(kind: 'private') }
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Post
              extend GeneratedRelationMethods

              module GeneratedAssociationRelationMethods
                sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                def public_kind(*args, &blk); end
              end

              module GeneratedRelationMethods
                sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                def public_kind(*args, &blk); end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:Post))
        end

        it "generates RBI file for ActiveRecord classes with multiple scope fields" do
          add_ruby_file("post.rb", <<~RUBY)
            class Post < ActiveRecord::Base
              scope :public_kind, -> { where.not(kind: 'private') }
              scope :private_kind, -> { where(kind: 'private') }
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Post
              extend GeneratedRelationMethods

              module GeneratedAssociationRelationMethods
                sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                def private_kind(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                def public_kind(*args, &blk); end
              end

              module GeneratedRelationMethods
                sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                def private_kind(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                def public_kind(*args, &blk); end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:Post))
        end

        it "generates relation includes from non-abstract parent models" do
          add_ruby_file("post.rb", <<~RUBY)
            class Post < ActiveRecord::Base
              scope :post_scope, -> { where.not(kind: 'private') }
            end

            class CustomPost < Post
              scope :custom_post_scope, -> { where.not(kind: 'private') }
            end

            class SuperCustomPost < CustomPost
              scope :super_custom_post_scope, -> { where.not(kind: 'private') }
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class SuperCustomPost
              extend GeneratedRelationMethods

              module GeneratedAssociationRelationMethods
                sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                def custom_post_scope(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                def post_scope(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                def super_custom_post_scope(*args, &blk); end
              end

              module GeneratedRelationMethods
                sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                def custom_post_scope(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                def post_scope(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                def super_custom_post_scope(*args, &blk); end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:SuperCustomPost))
        end

        it "generates relation includes from abstract parent models" do
          add_ruby_file("post.rb", <<~RUBY)
            class ApplicationRecord < ActiveRecord::Base
              self.abstract_class = true

              scope :app_scope, -> { where.not(kind: 'private') }
            end

            class Post < ApplicationRecord
              scope :post_scope, -> { where.not(kind: 'private') }
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Post
              extend GeneratedRelationMethods

              module GeneratedAssociationRelationMethods
                sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                def app_scope(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                def post_scope(*args, &blk); end
              end

              module GeneratedRelationMethods
                sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                def app_scope(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                def post_scope(*args, &blk); end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:Post))
        end
      end

      describe "without relations enabled" do
        it "generates an empty RBI file for ActiveRecord classes with no scope field" do
          add_ruby_file("post.rb", <<~RUBY)
            class Post < ActiveRecord::Base
            end
          RUBY

          expected = <<~RBI
            # typed: strong
          RBI

          assert_equal(expected, rbi_for(:Post))
        end

        it "generates RBI file for ActiveRecord classes with a scope field" do
          add_ruby_file("post.rb", <<~RUBY)
            class Post < ActiveRecord::Base
              scope :public_kind, -> { where.not(kind: 'private') }
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Post
              extend GeneratedRelationMethods

              module GeneratedRelationMethods
                sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
                def public_kind(*args, &blk); end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:Post))
        end

        it "generates RBI file for ActiveRecord classes with multiple scope fields" do
          add_ruby_file("post.rb", <<~RUBY)
            class Post < ActiveRecord::Base
              scope :public_kind, -> { where.not(kind: 'private') }
              scope :private_kind, -> { where(kind: 'private') }
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Post
              extend GeneratedRelationMethods

              module GeneratedRelationMethods
                sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
                def private_kind(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
                def public_kind(*args, &blk); end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:Post))
        end

        it "generates relation includes from non-abstract parent models" do
          add_ruby_file("post.rb", <<~RUBY)
            class Post < ActiveRecord::Base
              scope :post_scope, -> { where.not(kind: 'private') }
            end

            class CustomPost < Post
              scope :custom_post_scope, -> { where.not(kind: 'private') }
            end

            class SuperCustomPost < CustomPost
              scope :super_custom_post_scope, -> { where.not(kind: 'private') }
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class SuperCustomPost
              extend GeneratedRelationMethods

              module GeneratedRelationMethods
                sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
                def custom_post_scope(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
                def post_scope(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
                def super_custom_post_scope(*args, &blk); end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:SuperCustomPost))
        end

        it "generates relation includes from abstract parent models" do
          add_ruby_file("post.rb", <<~RUBY)
            class ApplicationRecord < ActiveRecord::Base
              self.abstract_class = true

              scope :app_scope, -> { where.not(kind: 'private') }
            end

            class Post < ApplicationRecord
              scope :post_scope, -> { where.not(kind: 'private') }
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Post
              extend GeneratedRelationMethods

              module GeneratedRelationMethods
                sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
                def app_scope(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
                def post_scope(*args, &blk); end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:Post))
        end
      end
    end

    describe "decorate_active_storage" do
      after do
        assert_no_generated_errors
      end

      before do
        require "tapioca/compilers/dsl/active_record_relations"
        activate_other_dsl_compilers(Tapioca::Compilers::Dsl::ActiveRecordRelations)

        require "active_record"
        require "active_storage/attached"
        require "active_storage/reflection"
        ActiveRecord::Base.include(ActiveStorage::Attached::Model)
        ActiveRecord::Base.include(ActiveStorage::Reflection::ActiveRecordExtensions)
        ActiveRecord::Reflection.singleton_class.prepend(ActiveStorage::Reflection::ReflectionExtension)
      end

      it "generates RBI file for ActiveRecord classes with has_one_attached scope fields" do
        add_ruby_file("post.rb", <<~RUBY)
          class Post < ActiveRecord::Base
            has_one_attached :photo
          end
        RUBY

        expected = <<~RBI
          # typed: strong

          class Post
            extend GeneratedRelationMethods

            module GeneratedAssociationRelationMethods
              sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
              def with_attached_photo(*args, &blk); end
            end

            module GeneratedRelationMethods
              sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
              def with_attached_photo(*args, &blk); end
            end
          end
        RBI

        assert_equal(expected, rbi_for(:Post))
      end

      it "generates RBI file for ActiveRecord classes with has_many_attached scope fields" do
        add_ruby_file("post.rb", <<~RUBY)
          class Post < ActiveRecord::Base
            has_many_attached :photos
          end
        RUBY

        expected = <<~RBI
          # typed: strong

          class Post
            extend GeneratedRelationMethods

            module GeneratedAssociationRelationMethods
              sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
              def with_attached_photos(*args, &blk); end
            end

            module GeneratedRelationMethods
              sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
              def with_attached_photos(*args, &blk); end
            end
          end
        RBI

        assert_equal(expected, rbi_for(:Post))
      end
    end
  end
end
