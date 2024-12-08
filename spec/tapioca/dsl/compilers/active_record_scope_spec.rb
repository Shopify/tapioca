# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveRecordScopeSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActiveRecordScope" do
          sig { void }
          def before_setup
            require "active_record"
          end

          describe "initialize" do
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
            describe "with relations enabled" do
              before do
                require "tapioca/dsl/compilers/active_record_relations"
                activate_other_dsl_compilers(ActiveRecordRelations)
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

              it "generates RBI for class methods" do
                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                    extend T::Sig

                    def self.published
                      where(published: true)
                    end

                    sig { returns(T.nilable(Post)) }
                    def self.most_popular
                      order(:likes).first
                    end
                  end
                RUBY

                expected = <<~RBI
                  # typed: strong

                  class Post
                    extend GeneratedRelationMethods

                    module GeneratedAssociationRelationMethods
                      sig { returns(T.nilable(::Post)) }
                      def most_popular; end

                      sig { returns(T.untyped) }
                      def published; end
                    end

                    module GeneratedRelationMethods
                      sig { returns(T.nilable(::Post)) }
                      def most_popular; end

                      sig { returns(T.untyped) }
                      def published; end
                    end
                  end
                RBI

                assert_equal(expected, rbi_for(:Post))
              end

              it "generates relation includes from non-abstract parent models" do
                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                    extend T::Sig

                    scope :post_scope, -> { where.not(kind: 'private') }

                    sig { returns(T.nilable(Post)) }
                    def self.most_popular
                      order(:likes).first
                    end
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

                      sig { returns(T.nilable(::Post)) }
                      def most_popular; end

                      sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                      def post_scope(*args, &blk); end

                      sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                      def super_custom_post_scope(*args, &blk); end
                    end

                    module GeneratedRelationMethods
                      sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                      def custom_post_scope(*args, &blk); end

                      sig { returns(T.nilable(::Post)) }
                      def most_popular; end

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

              it "does not duplicate relation includes from abstract parent models" do
                add_ruby_file("post.rb", <<~RUBY)
                  class ApplicationRecord < ActiveRecord::Base
                    self.abstract_class = true

                    default_scope { max_execution_time(100) }
                  end

                  class ConfigurationRecord < ApplicationRecord
                    self.abstract_class = true

                    scope :post_scope, -> { where.not(kind: 'private') }

                    default_scope { max_execution_time(200) }
                  end

                  class Post < ConfigurationRecord
                    scope :post_scope, -> { where.not(kind: 'private') }
                  end
                RUBY

                expected = <<~RBI
                  # typed: strong

                  class Post
                    extend GeneratedRelationMethods

                    module GeneratedAssociationRelationMethods
                      sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                      def post_scope(*args, &blk); end
                    end

                    module GeneratedRelationMethods
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

              it "generates scopes defined by enum attributes" do
                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                    enum status: [ :active, :archived ]
                  end
                RUBY

                expected = <<~RBI
                  # typed: strong

                  class Post
                    extend GeneratedRelationMethods

                    module GeneratedRelationMethods
                      sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
                      def active(*args, &blk); end

                      sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
                      def archived(*args, &blk); end

                      sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
                      def not_active(*args, &blk); end

                      sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
                      def not_archived(*args, &blk); end
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
            before do
              require "tapioca/dsl/compilers/active_record_relations"
              activate_other_dsl_compilers(ActiveRecordRelations)

              Tapioca::RailsSpecHelper.load_active_storage
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
    end
  end
end
