# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveRecordRelationsSpec < ::DslSpec
        include Tapioca::SorbetHelper

        describe "Tapioca::Dsl::Compilers::ActiveRecordRelations" do
          sig { void }
          def before_setup
            require "active_record"
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
            before do
              require "active_record"

              ::ActiveRecord::Base.establish_connection(
                adapter: "sqlite3",
                database: ":memory:",
              )
            end

            it "generates proper relation classes and modules" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                    end
                  end
                end
              RUBY

              add_ruby_file("custom_id.rb", <<~RUBY)
                class CustomId < ActiveRecord::Type::Value
                  extend T::Sig

                  sig { params(value: T.untyped).returns(T.nilable(CustomId)) }
                  def deserialize(value)
                    CustomId.new(value) unless value.nil?
                  end

                  def serialize(value)
                    value
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  attribute :id, CustomId.new
                end
              RUBY

              expected = template(<<~RUBY)
                # typed: strong

                class Post
                  extend CommonRelationMethods
                  extend GeneratedRelationMethods

                  sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                  def new(attributes = nil, &block); end

                  private

                  sig { returns(NilClass) }
                  def to_ary; end

                  module CommonRelationMethods
                    sig { params(block: T.nilable(T.proc.params(record: ::Post).returns(T.untyped))).returns(T::Boolean) }
                    def any?(&block); end

                    sig { params(column_name: T.any(String, Symbol)).returns(T.any(Integer, Float, BigDecimal)) }
                    def average(column_name); end

                    sig { params(block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def build(attributes = nil, &block); end

                    sig { params(operation: Symbol, column_name: T.any(String, Symbol)).returns(T.any(Integer, Float, BigDecimal)) }
                    def calculate(operation, column_name); end

                    sig { params(column_name: T.nilable(T.any(String, Symbol))).returns(Integer) }
                    sig { params(column_name: NilClass, block: T.proc.params(object: ::Post).void).returns(Integer) }
                    def count(column_name = nil, &block); end

                    sig { params(block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def create(attributes = nil, &block); end

                    sig { params(block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def create!(attributes = nil, &block); end

                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def create_or_find_by(attributes, &block); end

                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def create_or_find_by!(attributes, &block); end

                    sig { returns(T::Array[::Post]) }
                    def destroy_all; end

                    sig { params(conditions: T.untyped).returns(T::Boolean) }
                    def exists?(conditions = :none); end

                    sig { returns(T.nilable(::Post)) }
                    def fifth; end

                    sig { returns(::Post) }
                    def fifth!; end

                    sig { params(args: T.any(String, Symbol, ::ActiveSupport::Multibyte::Chars, T::Boolean, BigDecimal, Numeric, ::ActiveRecord::Type::Binary::Data, ::ActiveRecord::Type::Time::Value, Date, Time, ::ActiveSupport::Duration, T::Class[T.anything], ::CustomId)).returns(::Post) }
                    sig { params(args: T::Array[T.any(String, Symbol, ::ActiveSupport::Multibyte::Chars, T::Boolean, BigDecimal, Numeric, ::ActiveRecord::Type::Binary::Data, ::ActiveRecord::Type::Time::Value, Date, Time, ::ActiveSupport::Duration, T::Class[T.anything], ::CustomId)]).returns(T::Enumerable[::Post]) }
                    sig { params(args: NilClass, block: T.proc.params(object: ::Post).void).returns(T.nilable(::Post)) }
                    def find(args = nil, &block); end

                    sig { params(args: T.untyped).returns(T.nilable(::Post)) }
                    def find_by(*args); end

                    sig { params(args: T.untyped).returns(::Post) }
                    def find_by!(*args); end

                    sig { params(start: T.untyped, finish: T.untyped, batch_size: Integer, error_on_ignore: T.untyped, order: Symbol, block: T.proc.params(object: ::Post).void).void }
                    sig { params(start: T.untyped, finish: T.untyped, batch_size: Integer, error_on_ignore: T.untyped, order: Symbol).returns(T::Enumerator[::Post]) }
                    def find_each(start: nil, finish: nil, batch_size: 1000, error_on_ignore: nil, order: :asc, &block); end

                    sig { params(start: T.untyped, finish: T.untyped, batch_size: Integer, error_on_ignore: T.untyped, order: Symbol, block: T.proc.params(object: T::Array[::Post]).void).void }
                    sig { params(start: T.untyped, finish: T.untyped, batch_size: Integer, error_on_ignore: T.untyped, order: Symbol).returns(T::Enumerator[T::Enumerator[::Post]]) }
                    def find_in_batches(start: nil, finish: nil, batch_size: 1000, error_on_ignore: nil, order: :asc, &block); end

                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def find_or_create_by(attributes, &block); end

                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def find_or_create_by!(attributes, &block); end

                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def find_or_initialize_by(attributes, &block); end

                    sig { params(signed_id: T.untyped, purpose: T.untyped).returns(T.nilable(::Post)) }
                    def find_signed(signed_id, purpose: nil); end

                    sig { params(signed_id: T.untyped, purpose: T.untyped).returns(::Post) }
                    def find_signed!(signed_id, purpose: nil); end

                <% if rails_version(">= 7.0") %>
                    sig { params(arg: T.untyped, args: T.untyped).returns(::Post) }
                    def find_sole_by(arg, *args); end

                <% end %>
                    sig { returns(T.nilable(::Post)) }
                    sig { params(limit: Integer).returns(T::Array[::Post]) }
                    def first(limit = nil); end

                    sig { returns(::Post) }
                    def first!; end

                    sig { returns(T.nilable(::Post)) }
                    def forty_two; end

                    sig { returns(::Post) }
                    def forty_two!; end

                    sig { returns(T.nilable(::Post)) }
                    def fourth; end

                    sig { returns(::Post) }
                    def fourth!; end

                    sig { returns(Array) }
                    def ids; end

                <% if rails_version(">= 7.1") %>
                    sig { params(of: Integer, start: T.untyped, finish: T.untyped, load: T.untyped, error_on_ignore: T.untyped, order: Symbol, use_ranges: T.untyped, block: T.proc.params(object: PrivateRelation).void).void }
                    sig { params(of: Integer, start: T.untyped, finish: T.untyped, load: T.untyped, error_on_ignore: T.untyped, order: Symbol, use_ranges: T.untyped).returns(::ActiveRecord::Batches::BatchEnumerator) }
                    def in_batches(of: 1000, start: nil, finish: nil, load: false, error_on_ignore: nil, order: :asc, use_ranges: nil, &block); end
                <% else %>
                    sig { params(of: Integer, start: T.untyped, finish: T.untyped, load: T.untyped, error_on_ignore: T.untyped, order: Symbol, block: T.proc.params(object: PrivateRelation).void).void }
                    sig { params(of: Integer, start: T.untyped, finish: T.untyped, load: T.untyped, error_on_ignore: T.untyped, order: Symbol).returns(::ActiveRecord::Batches::BatchEnumerator) }
                    def in_batches(of: 1000, start: nil, finish: nil, load: false, error_on_ignore: nil, order: :asc, &block); end
                <% end %>

                    sig { params(record: T.untyped).returns(T::Boolean) }
                    def include?(record); end

                    sig { returns(T.nilable(::Post)) }
                    sig { params(limit: Integer).returns(T::Array[::Post]) }
                    def last(limit = nil); end

                    sig { returns(::Post) }
                    def last!; end

                    sig { params(block: T.nilable(T.proc.params(record: ::Post).returns(T.untyped))).returns(T::Boolean) }
                    def many?(&block); end

                    sig { params(column_name: T.any(String, Symbol)).returns(T.untyped) }
                    def maximum(column_name); end

                    sig { params(record: T.untyped).returns(T::Boolean) }
                    def member?(record); end

                    sig { params(column_name: T.any(String, Symbol)).returns(T.untyped) }
                    def minimum(column_name); end

                    sig { params(block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def new(attributes = nil, &block); end

                    sig { params(block: T.nilable(T.proc.params(record: ::Post).returns(T.untyped))).returns(T::Boolean) }
                    def none?(&block); end

                    sig { params(block: T.nilable(T.proc.params(record: ::Post).returns(T.untyped))).returns(T::Boolean) }
                    def one?(&block); end

                    sig { params(column_names: T.untyped).returns(T.untyped) }
                    def pick(*column_names); end

                    sig { params(column_names: T.untyped).returns(T.untyped) }
                    def pluck(*column_names); end

                    sig { returns(T.nilable(::Post)) }
                    def second; end

                    sig { returns(::Post) }
                    def second!; end

                    sig { returns(T.nilable(::Post)) }
                    def second_to_last; end

                    sig { returns(::Post) }
                    def second_to_last!; end

                <% if rails_version(">= 7.0") %>
                    sig { returns(::Post) }
                    def sole; end

                <% end %>
                    sig { params(initial_value_or_column: T.untyped).returns(T.any(Integer, Float, BigDecimal)) }
                    sig { type_parameters(:U).params(initial_value_or_column: T.nilable(T.type_parameter(:U)), block: T.proc.params(object: ::Post).returns(T.type_parameter(:U))).returns(T.type_parameter(:U)) }
                    def sum(initial_value_or_column = nil, &block); end

                    sig { returns(T.nilable(::Post)) }
                    sig { params(limit: Integer).returns(T::Array[::Post]) }
                    def take(limit = nil); end

                    sig { returns(::Post) }
                    def take!; end

                    sig { returns(T.nilable(::Post)) }
                    def third; end

                    sig { returns(::Post) }
                    def third!; end

                    sig { returns(T.nilable(::Post)) }
                    def third_to_last; end

                    sig { returns(::Post) }
                    def third_to_last!; end
                  end

                  module GeneratedAssociationRelationMethods
                    sig { returns(PrivateAssociationRelation) }
                    def all; end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def and(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def annotate(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def create_with(*args, &blk); end

                    sig { params(value: T::Boolean).returns(PrivateAssociationRelation) }
                    def distinct(value = true); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def eager_load(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def except(*args, &blk); end

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def excluding(*args, &blk); end

                <% end %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def extending(*args, &blk); end

                    sig { params(association: Symbol).returns(T::Array[T.untyped]) }
                    def extract_associated(association); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def from(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelationGroupChain) }
                    def group(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def having(*args, &blk); end

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def in_order_of(*args, &blk); end

                <% end %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def includes(*args, &blk); end

                    sig { params(attributes: Hash, returning: T.nilable(T.any(T::Array[Symbol], FalseClass)), unique_by: T.nilable(T.any(T::Array[Symbol], Symbol))).returns(ActiveRecord::Result) }
                    def insert(attributes, returning: nil, unique_by: nil); end

                    sig { params(attributes: Hash, returning: T.nilable(T.any(T::Array[Symbol], FalseClass))).returns(ActiveRecord::Result) }
                    def insert!(attributes, returning: nil); end

                    sig { params(attributes: T::Array[Hash], returning: T.nilable(T.any(T::Array[Symbol], FalseClass)), unique_by: T.nilable(T.any(T::Array[Symbol], Symbol))).returns(ActiveRecord::Result) }
                    def insert_all(attributes, returning: nil, unique_by: nil); end

                    sig { params(attributes: T::Array[Hash], returning: T.nilable(T.any(T::Array[Symbol], FalseClass))).returns(ActiveRecord::Result) }
                    def insert_all!(attributes, returning: nil); end

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def invert_where(*args, &blk); end

                <% end %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def joins(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def left_joins(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def left_outer_joins(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def limit(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def lock(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def merge(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def none(*args, &blk); end
                <% if rails_version(">= 7.1") %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def null_relation?(*args, &blk); end
                <% end %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def offset(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def only(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def optimizer_hints(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def or(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def order(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def preload(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def readonly(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def references(*args, &blk); end
                <% if rails_version(">= 7.1") %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def regroup(*args, &blk); end
                <% end %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def reorder(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def reselect(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def reverse_order(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def rewhere(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def select(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def strict_loading(*args, &blk); end

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def structurally_compatible?(*args, &blk); end

                <% end %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def uniq!(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def unscope(*args, &blk); end

                    sig { params(attributes: Hash, returning: T.nilable(T.any(T::Array[Symbol], FalseClass)), unique_by: T.nilable(T.any(T::Array[Symbol], Symbol))).returns(ActiveRecord::Result) }
                    def upsert(attributes, returning: nil, unique_by: nil); end

                    sig { params(attributes: T::Array[Hash], returning: T.nilable(T.any(T::Array[Symbol], FalseClass)), unique_by: T.nilable(T.any(T::Array[Symbol], Symbol))).returns(ActiveRecord::Result) }
                    def upsert_all(attributes, returning: nil, unique_by: nil); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelationWhereChain) }
                    def where(*args, &blk); end
                <% if rails_version(">= 7.1") %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def with(*args, &blk); end
                <% end %>
                <% if rails_version(">= 7.0") %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def without(*args, &blk); end
                <% end %>
                  end

                  module GeneratedRelationMethods
                    sig { returns(PrivateRelation) }
                    def all; end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def and(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def annotate(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def create_with(*args, &blk); end

                    sig { params(value: T::Boolean).returns(PrivateRelation) }
                    def distinct(value = true); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def eager_load(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def except(*args, &blk); end

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def excluding(*args, &blk); end

                <% end %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def extending(*args, &blk); end

                    sig { params(association: Symbol).returns(T::Array[T.untyped]) }
                    def extract_associated(association); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def from(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelationGroupChain) }
                    def group(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def having(*args, &blk); end

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def in_order_of(*args, &blk); end

                <% end %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def includes(*args, &blk); end

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def invert_where(*args, &blk); end

                <% end %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def joins(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def left_joins(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def left_outer_joins(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def limit(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def lock(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def merge(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def none(*args, &blk); end
                <% if rails_version(">= 7.1") %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def null_relation?(*args, &blk); end
                <% end %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def offset(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def only(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def optimizer_hints(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def or(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def order(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def preload(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def readonly(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def references(*args, &blk); end
                <% if rails_version(">= 7.1") %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def regroup(*args, &blk); end
                <% end %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def reorder(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def reselect(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def reverse_order(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def rewhere(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def select(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def strict_loading(*args, &blk); end

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def structurally_compatible?(*args, &blk); end

                <% end %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def uniq!(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def unscope(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelationWhereChain) }
                    def where(*args, &blk); end
                <% if rails_version(">= 7.1") %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def with(*args, &blk); end
                <% end %>
                <% if rails_version(">= 7.0") %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def without(*args, &blk); end
                <% end %>
                  end

                  class PrivateAssociationRelation < ::ActiveRecord::AssociationRelation
                    include CommonRelationMethods
                    include GeneratedAssociationRelationMethods

                    Elem = type_member { { fixed: ::Post } }

                    sig { returns(T::Array[::Post]) }
                    def to_a; end

                    sig { returns(T::Array[::Post]) }
                    def to_ary; end
                  end

                  class PrivateAssociationRelationGroupChain < PrivateAssociationRelation
                    Elem = type_member { { fixed: ::Post } }

                    sig { params(column_name: T.any(String, Symbol)).returns(T::Hash[T.untyped, T.any(Integer, Float, BigDecimal)]) }
                    def average(column_name); end

                    sig { params(operation: Symbol, column_name: T.any(String, Symbol)).returns(T::Hash[T.untyped, T.any(Integer, Float, BigDecimal)]) }
                    def calculate(operation, column_name); end

                    sig { params(column_name: T.untyped).returns(T::Hash[T.untyped, Integer]) }
                    def count(column_name = nil); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(T.self_type) }
                    def having(*args, &blk); end

                    sig { params(column_name: T.any(String, Symbol)).returns(T::Hash[T.untyped, T.untyped]) }
                    def maximum(column_name); end

                    sig { params(column_name: T.any(String, Symbol)).returns(T::Hash[T.untyped, T.untyped]) }
                    def minimum(column_name); end

                    sig { params(column_name: T.nilable(T.any(String, Symbol)), block: T.nilable(T.proc.params(record: T.untyped).returns(T.untyped))).returns(T::Hash[T.untyped, T.any(Integer, Float, BigDecimal)]) }
                    def sum(column_name = nil, &block); end
                  end

                  class PrivateAssociationRelationWhereChain < PrivateAssociationRelation
                    Elem = type_member { { fixed: ::Post } }

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped).returns(PrivateAssociationRelation) }
                    def associated(*args); end

                <% end %>
                    sig { params(args: T.untyped).returns(PrivateAssociationRelation) }
                    def missing(*args); end

                    sig { params(opts: T.untyped, rest: T.untyped).returns(PrivateAssociationRelation) }
                    def not(opts, *rest); end
                  end

                  class PrivateCollectionProxy < ::ActiveRecord::Associations::CollectionProxy
                    include CommonRelationMethods
                    include GeneratedAssociationRelationMethods

                    Elem = type_member { { fixed: ::Post } }

                    sig { params(records: T.any(::Post, T::Enumerable[T.any(::Post, T::Enumerable[::Post])])).returns(PrivateCollectionProxy) }
                    def <<(*records); end

                    sig { params(records: T.any(::Post, T::Enumerable[T.any(::Post, T::Enumerable[::Post])])).returns(PrivateCollectionProxy) }
                    def append(*records); end

                    sig { returns(PrivateCollectionProxy) }
                    def clear; end

                    sig { params(records: T.any(::Post, T::Enumerable[T.any(::Post, T::Enumerable[::Post])])).returns(PrivateCollectionProxy) }
                    def concat(*records); end

                    sig { params(records: T.any(::Post, Integer, String, T::Enumerable[T.any(::Post, Integer, String, T::Enumerable[::Post])])).returns(T::Array[::Post]) }
                    def delete(*records); end

                    sig { params(records: T.any(::Post, Integer, String, T::Enumerable[T.any(::Post, Integer, String, T::Enumerable[::Post])])).returns(T::Array[::Post]) }
                    def destroy(*records); end

                    sig { returns(T::Array[::Post]) }
                    def load_target; end

                    sig { params(records: T.any(::Post, T::Enumerable[T.any(::Post, T::Enumerable[::Post])])).returns(PrivateCollectionProxy) }
                    def prepend(*records); end

                    sig { params(records: T.any(::Post, T::Enumerable[T.any(::Post, T::Enumerable[::Post])])).returns(PrivateCollectionProxy) }
                    def push(*records); end

                    sig { params(other_array: T.any(::Post, T::Enumerable[T.any(::Post, T::Enumerable[::Post])])).returns(T::Array[::Post]) }
                    def replace(other_array); end

                    sig { returns(PrivateAssociationRelation) }
                    def scope; end

                    sig { returns(T::Array[::Post]) }
                    def target; end

                    sig { returns(T::Array[::Post]) }
                    def to_a; end

                    sig { returns(T::Array[::Post]) }
                    def to_ary; end
                  end

                  class PrivateRelation < ::ActiveRecord::Relation
                    include CommonRelationMethods
                    include GeneratedRelationMethods

                    Elem = type_member { { fixed: ::Post } }

                    sig { returns(T::Array[::Post]) }
                    def to_a; end

                    sig { returns(T::Array[::Post]) }
                    def to_ary; end
                  end

                  class PrivateRelationGroupChain < PrivateRelation
                    Elem = type_member { { fixed: ::Post } }

                    sig { params(column_name: T.any(String, Symbol)).returns(T::Hash[T.untyped, T.any(Integer, Float, BigDecimal)]) }
                    def average(column_name); end

                    sig { params(operation: Symbol, column_name: T.any(String, Symbol)).returns(T::Hash[T.untyped, T.any(Integer, Float, BigDecimal)]) }
                    def calculate(operation, column_name); end

                    sig { params(column_name: T.untyped).returns(T::Hash[T.untyped, Integer]) }
                    def count(column_name = nil); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(T.self_type) }
                    def having(*args, &blk); end

                    sig { params(column_name: T.any(String, Symbol)).returns(T::Hash[T.untyped, T.untyped]) }
                    def maximum(column_name); end

                    sig { params(column_name: T.any(String, Symbol)).returns(T::Hash[T.untyped, T.untyped]) }
                    def minimum(column_name); end

                    sig { params(column_name: T.nilable(T.any(String, Symbol)), block: T.nilable(T.proc.params(record: T.untyped).returns(T.untyped))).returns(T::Hash[T.untyped, T.any(Integer, Float, BigDecimal)]) }
                    def sum(column_name = nil, &block); end
                  end

                  class PrivateRelationWhereChain < PrivateRelation
                    Elem = type_member { { fixed: ::Post } }

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped).returns(PrivateRelation) }
                    def associated(*args); end

                <% end %>
                    sig { params(args: T.untyped).returns(PrivateRelation) }
                    def missing(*args); end

                    sig { params(opts: T.untyped, rest: T.untyped).returns(PrivateRelation) }
                    def not(opts, *rest); end
                  end
                end
              RUBY

              assert_equal(expected, rbi_for(:Post))
            end

            it "generates handles composite primary keys" do
              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  self.primary_key = [:shop_id, :id]
                end
              RUBY

              expected = template(<<~RUBY)
                # typed: strong

                class Post
                  extend CommonRelationMethods
                  extend GeneratedRelationMethods

                  sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                  def new(attributes = nil, &block); end

                  private

                  sig { returns(NilClass) }
                  def to_ary; end

                  module CommonRelationMethods
                    sig { params(block: T.nilable(T.proc.params(record: ::Post).returns(T.untyped))).returns(T::Boolean) }
                    def any?(&block); end

                    sig { params(column_name: T.any(String, Symbol)).returns(T.any(Integer, Float, BigDecimal)) }
                    def average(column_name); end

                    sig { params(block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def build(attributes = nil, &block); end

                    sig { params(operation: Symbol, column_name: T.any(String, Symbol)).returns(T.any(Integer, Float, BigDecimal)) }
                    def calculate(operation, column_name); end

                    sig { params(column_name: T.nilable(T.any(String, Symbol))).returns(Integer) }
                    sig { params(column_name: NilClass, block: T.proc.params(object: ::Post).void).returns(Integer) }
                    def count(column_name = nil, &block); end

                    sig { params(block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def create(attributes = nil, &block); end

                    sig { params(block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def create!(attributes = nil, &block); end

                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def create_or_find_by(attributes, &block); end

                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def create_or_find_by!(attributes, &block); end

                    sig { returns(T::Array[::Post]) }
                    def destroy_all; end

                    sig { params(conditions: T.untyped).returns(T::Boolean) }
                    def exists?(conditions = :none); end

                    sig { returns(T.nilable(::Post)) }
                    def fifth; end

                    sig { returns(::Post) }
                    def fifth!; end

                <% if rails_version(">= 7.1") %>
                    sig { params(args: T::Array[T.any(String, Symbol, ::ActiveSupport::Multibyte::Chars, T::Boolean, BigDecimal, Numeric, ::ActiveRecord::Type::Binary::Data, ::ActiveRecord::Type::Time::Value, Date, Time, ::ActiveSupport::Duration, T::Class[T.anything])]).returns(::Post) }
                    sig { params(args: T::Array[T::Array[T.any(String, Symbol, ::ActiveSupport::Multibyte::Chars, T::Boolean, BigDecimal, Numeric, ::ActiveRecord::Type::Binary::Data, ::ActiveRecord::Type::Time::Value, Date, Time, ::ActiveSupport::Duration, T::Class[T.anything])]]).returns(T::Enumerable[::Post]) }
                <% else %>
                    sig { params(args: T.any(String, Symbol, ::ActiveSupport::Multibyte::Chars, T::Boolean, BigDecimal, Numeric, ::ActiveRecord::Type::Binary::Data, ::ActiveRecord::Type::Time::Value, Date, Time, ::ActiveSupport::Duration, T::Class[T.anything])).returns(::Post) }
                    sig { params(args: T::Array[T.any(String, Symbol, ::ActiveSupport::Multibyte::Chars, T::Boolean, BigDecimal, Numeric, ::ActiveRecord::Type::Binary::Data, ::ActiveRecord::Type::Time::Value, Date, Time, ::ActiveSupport::Duration, T::Class[T.anything])]).returns(T::Enumerable[::Post]) }
                <% end %>
                    sig { params(args: NilClass, block: T.proc.params(object: ::Post).void).returns(T.nilable(::Post)) }
                    def find(args = nil, &block); end

                    sig { params(args: T.untyped).returns(T.nilable(::Post)) }
                    def find_by(*args); end

                    sig { params(args: T.untyped).returns(::Post) }
                    def find_by!(*args); end

                    sig { params(start: T.untyped, finish: T.untyped, batch_size: Integer, error_on_ignore: T.untyped, order: Symbol, block: T.proc.params(object: ::Post).void).void }
                    sig { params(start: T.untyped, finish: T.untyped, batch_size: Integer, error_on_ignore: T.untyped, order: Symbol).returns(T::Enumerator[::Post]) }
                    def find_each(start: nil, finish: nil, batch_size: 1000, error_on_ignore: nil, order: :asc, &block); end

                    sig { params(start: T.untyped, finish: T.untyped, batch_size: Integer, error_on_ignore: T.untyped, order: Symbol, block: T.proc.params(object: T::Array[::Post]).void).void }
                    sig { params(start: T.untyped, finish: T.untyped, batch_size: Integer, error_on_ignore: T.untyped, order: Symbol).returns(T::Enumerator[T::Enumerator[::Post]]) }
                    def find_in_batches(start: nil, finish: nil, batch_size: 1000, error_on_ignore: nil, order: :asc, &block); end

                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def find_or_create_by(attributes, &block); end

                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def find_or_create_by!(attributes, &block); end

                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def find_or_initialize_by(attributes, &block); end

                    sig { params(signed_id: T.untyped, purpose: T.untyped).returns(T.nilable(::Post)) }
                    def find_signed(signed_id, purpose: nil); end

                    sig { params(signed_id: T.untyped, purpose: T.untyped).returns(::Post) }
                    def find_signed!(signed_id, purpose: nil); end

                <% if rails_version(">= 7.0") %>
                    sig { params(arg: T.untyped, args: T.untyped).returns(::Post) }
                    def find_sole_by(arg, *args); end

                <% end %>
                    sig { returns(T.nilable(::Post)) }
                    sig { params(limit: Integer).returns(T::Array[::Post]) }
                    def first(limit = nil); end

                    sig { returns(::Post) }
                    def first!; end

                    sig { returns(T.nilable(::Post)) }
                    def forty_two; end

                    sig { returns(::Post) }
                    def forty_two!; end

                    sig { returns(T.nilable(::Post)) }
                    def fourth; end

                    sig { returns(::Post) }
                    def fourth!; end

                    sig { returns(Array) }
                    def ids; end

                <% if rails_version(">= 7.1") %>
                    sig { params(of: Integer, start: T.untyped, finish: T.untyped, load: T.untyped, error_on_ignore: T.untyped, order: Symbol, use_ranges: T.untyped, block: T.proc.params(object: PrivateRelation).void).void }
                    sig { params(of: Integer, start: T.untyped, finish: T.untyped, load: T.untyped, error_on_ignore: T.untyped, order: Symbol, use_ranges: T.untyped).returns(::ActiveRecord::Batches::BatchEnumerator) }
                    def in_batches(of: 1000, start: nil, finish: nil, load: false, error_on_ignore: nil, order: :asc, use_ranges: nil, &block); end
                <% else %>
                    sig { params(of: Integer, start: T.untyped, finish: T.untyped, load: T.untyped, error_on_ignore: T.untyped, order: Symbol, block: T.proc.params(object: PrivateRelation).void).void }
                    sig { params(of: Integer, start: T.untyped, finish: T.untyped, load: T.untyped, error_on_ignore: T.untyped, order: Symbol).returns(::ActiveRecord::Batches::BatchEnumerator) }
                    def in_batches(of: 1000, start: nil, finish: nil, load: false, error_on_ignore: nil, order: :asc, &block); end
                <% end %>

                    sig { params(record: T.untyped).returns(T::Boolean) }
                    def include?(record); end

                    sig { returns(T.nilable(::Post)) }
                    sig { params(limit: Integer).returns(T::Array[::Post]) }
                    def last(limit = nil); end

                    sig { returns(::Post) }
                    def last!; end

                    sig { params(block: T.nilable(T.proc.params(record: ::Post).returns(T.untyped))).returns(T::Boolean) }
                    def many?(&block); end

                    sig { params(column_name: T.any(String, Symbol)).returns(T.untyped) }
                    def maximum(column_name); end

                    sig { params(record: T.untyped).returns(T::Boolean) }
                    def member?(record); end

                    sig { params(column_name: T.any(String, Symbol)).returns(T.untyped) }
                    def minimum(column_name); end

                    sig { params(block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    sig { params(attributes: T::Array[T.untyped], block: T.nilable(T.proc.params(object: ::Post).void)).returns(T::Array[::Post]) }
                    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::Post).void)).returns(::Post) }
                    def new(attributes = nil, &block); end

                    sig { params(block: T.nilable(T.proc.params(record: ::Post).returns(T.untyped))).returns(T::Boolean) }
                    def none?(&block); end

                    sig { params(block: T.nilable(T.proc.params(record: ::Post).returns(T.untyped))).returns(T::Boolean) }
                    def one?(&block); end

                    sig { params(column_names: T.untyped).returns(T.untyped) }
                    def pick(*column_names); end

                    sig { params(column_names: T.untyped).returns(T.untyped) }
                    def pluck(*column_names); end

                    sig { returns(T.nilable(::Post)) }
                    def second; end

                    sig { returns(::Post) }
                    def second!; end

                    sig { returns(T.nilable(::Post)) }
                    def second_to_last; end

                    sig { returns(::Post) }
                    def second_to_last!; end

                <% if rails_version(">= 7.0") %>
                    sig { returns(::Post) }
                    def sole; end

                <% end %>
                    sig { params(initial_value_or_column: T.untyped).returns(T.any(Integer, Float, BigDecimal)) }
                    sig { type_parameters(:U).params(initial_value_or_column: T.nilable(T.type_parameter(:U)), block: T.proc.params(object: ::Post).returns(T.type_parameter(:U))).returns(T.type_parameter(:U)) }
                    def sum(initial_value_or_column = nil, &block); end

                    sig { returns(T.nilable(::Post)) }
                    sig { params(limit: Integer).returns(T::Array[::Post]) }
                    def take(limit = nil); end

                    sig { returns(::Post) }
                    def take!; end

                    sig { returns(T.nilable(::Post)) }
                    def third; end

                    sig { returns(::Post) }
                    def third!; end

                    sig { returns(T.nilable(::Post)) }
                    def third_to_last; end

                    sig { returns(::Post) }
                    def third_to_last!; end
                  end

                  module GeneratedAssociationRelationMethods
                    sig { returns(PrivateAssociationRelation) }
                    def all; end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def and(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def annotate(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def create_with(*args, &blk); end

                    sig { params(value: T::Boolean).returns(PrivateAssociationRelation) }
                    def distinct(value = true); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def eager_load(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def except(*args, &blk); end

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def excluding(*args, &blk); end

                <% end %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def extending(*args, &blk); end

                    sig { params(association: Symbol).returns(T::Array[T.untyped]) }
                    def extract_associated(association); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def from(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelationGroupChain) }
                    def group(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def having(*args, &blk); end

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def in_order_of(*args, &blk); end

                <% end %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def includes(*args, &blk); end

                    sig { params(attributes: Hash, returning: T.nilable(T.any(T::Array[Symbol], FalseClass)), unique_by: T.nilable(T.any(T::Array[Symbol], Symbol))).returns(ActiveRecord::Result) }
                    def insert(attributes, returning: nil, unique_by: nil); end

                    sig { params(attributes: Hash, returning: T.nilable(T.any(T::Array[Symbol], FalseClass))).returns(ActiveRecord::Result) }
                    def insert!(attributes, returning: nil); end

                    sig { params(attributes: T::Array[Hash], returning: T.nilable(T.any(T::Array[Symbol], FalseClass)), unique_by: T.nilable(T.any(T::Array[Symbol], Symbol))).returns(ActiveRecord::Result) }
                    def insert_all(attributes, returning: nil, unique_by: nil); end

                    sig { params(attributes: T::Array[Hash], returning: T.nilable(T.any(T::Array[Symbol], FalseClass))).returns(ActiveRecord::Result) }
                    def insert_all!(attributes, returning: nil); end

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def invert_where(*args, &blk); end

                <% end %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def joins(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def left_joins(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def left_outer_joins(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def limit(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def lock(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def merge(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def none(*args, &blk); end
                <% if rails_version(">= 7.1") %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def null_relation?(*args, &blk); end
                <% end %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def offset(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def only(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def optimizer_hints(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def or(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def order(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def preload(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def readonly(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def references(*args, &blk); end
                <% if rails_version(">= 7.1") %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def regroup(*args, &blk); end
                <% end %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def reorder(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def reselect(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def reverse_order(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def rewhere(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def select(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def strict_loading(*args, &blk); end

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def structurally_compatible?(*args, &blk); end

                <% end %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def uniq!(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def unscope(*args, &blk); end

                    sig { params(attributes: Hash, returning: T.nilable(T.any(T::Array[Symbol], FalseClass)), unique_by: T.nilable(T.any(T::Array[Symbol], Symbol))).returns(ActiveRecord::Result) }
                    def upsert(attributes, returning: nil, unique_by: nil); end

                    sig { params(attributes: T::Array[Hash], returning: T.nilable(T.any(T::Array[Symbol], FalseClass)), unique_by: T.nilable(T.any(T::Array[Symbol], Symbol))).returns(ActiveRecord::Result) }
                    def upsert_all(attributes, returning: nil, unique_by: nil); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelationWhereChain) }
                    def where(*args, &blk); end
                <% if rails_version(">= 7.1") %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def with(*args, &blk); end
                <% end %>
                <% if rails_version(">= 7.0") %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
                    def without(*args, &blk); end
                <% end %>
                  end

                  module GeneratedRelationMethods
                    sig { returns(PrivateRelation) }
                    def all; end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def and(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def annotate(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def create_with(*args, &blk); end

                    sig { params(value: T::Boolean).returns(PrivateRelation) }
                    def distinct(value = true); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def eager_load(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def except(*args, &blk); end

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def excluding(*args, &blk); end

                <% end %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def extending(*args, &blk); end

                    sig { params(association: Symbol).returns(T::Array[T.untyped]) }
                    def extract_associated(association); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def from(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelationGroupChain) }
                    def group(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def having(*args, &blk); end

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def in_order_of(*args, &blk); end

                <% end %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def includes(*args, &blk); end

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def invert_where(*args, &blk); end

                <% end %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def joins(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def left_joins(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def left_outer_joins(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def limit(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def lock(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def merge(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def none(*args, &blk); end
                <% if rails_version(">= 7.1") %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def null_relation?(*args, &blk); end
                <% end %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def offset(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def only(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def optimizer_hints(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def or(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def order(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def preload(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def readonly(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def references(*args, &blk); end
                <% if rails_version(">= 7.1") %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def regroup(*args, &blk); end
                <% end %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def reorder(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def reselect(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def reverse_order(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def rewhere(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def select(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def strict_loading(*args, &blk); end

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def structurally_compatible?(*args, &blk); end

                <% end %>
                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def uniq!(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def unscope(*args, &blk); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelationWhereChain) }
                    def where(*args, &blk); end
                <% if rails_version(">= 7.1") %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def with(*args, &blk); end
                <% end %>
                <% if rails_version(">= 7.0") %>

                    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
                    def without(*args, &blk); end
                <% end %>
                  end

                  class PrivateAssociationRelation < ::ActiveRecord::AssociationRelation
                    include CommonRelationMethods
                    include GeneratedAssociationRelationMethods

                    Elem = type_member { { fixed: ::Post } }

                    sig { returns(T::Array[::Post]) }
                    def to_a; end

                    sig { returns(T::Array[::Post]) }
                    def to_ary; end
                  end

                  class PrivateAssociationRelationGroupChain < PrivateAssociationRelation
                    Elem = type_member { { fixed: ::Post } }

                    sig { params(column_name: T.any(String, Symbol)).returns(T::Hash[T.untyped, T.any(Integer, Float, BigDecimal)]) }
                    def average(column_name); end

                    sig { params(operation: Symbol, column_name: T.any(String, Symbol)).returns(T::Hash[T.untyped, T.any(Integer, Float, BigDecimal)]) }
                    def calculate(operation, column_name); end

                    sig { params(column_name: T.untyped).returns(T::Hash[T.untyped, Integer]) }
                    def count(column_name = nil); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(T.self_type) }
                    def having(*args, &blk); end

                    sig { params(column_name: T.any(String, Symbol)).returns(T::Hash[T.untyped, T.untyped]) }
                    def maximum(column_name); end

                    sig { params(column_name: T.any(String, Symbol)).returns(T::Hash[T.untyped, T.untyped]) }
                    def minimum(column_name); end

                    sig { params(column_name: T.nilable(T.any(String, Symbol)), block: T.nilable(T.proc.params(record: T.untyped).returns(T.untyped))).returns(T::Hash[T.untyped, T.any(Integer, Float, BigDecimal)]) }
                    def sum(column_name = nil, &block); end
                  end

                  class PrivateAssociationRelationWhereChain < PrivateAssociationRelation
                    Elem = type_member { { fixed: ::Post } }

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped).returns(PrivateAssociationRelation) }
                    def associated(*args); end

                <% end %>
                    sig { params(args: T.untyped).returns(PrivateAssociationRelation) }
                    def missing(*args); end

                    sig { params(opts: T.untyped, rest: T.untyped).returns(PrivateAssociationRelation) }
                    def not(opts, *rest); end
                  end

                  class PrivateCollectionProxy < ::ActiveRecord::Associations::CollectionProxy
                    include CommonRelationMethods
                    include GeneratedAssociationRelationMethods

                    Elem = type_member { { fixed: ::Post } }

                    sig { params(records: T.any(::Post, T::Enumerable[T.any(::Post, T::Enumerable[::Post])])).returns(PrivateCollectionProxy) }
                    def <<(*records); end

                    sig { params(records: T.any(::Post, T::Enumerable[T.any(::Post, T::Enumerable[::Post])])).returns(PrivateCollectionProxy) }
                    def append(*records); end

                    sig { returns(PrivateCollectionProxy) }
                    def clear; end

                    sig { params(records: T.any(::Post, T::Enumerable[T.any(::Post, T::Enumerable[::Post])])).returns(PrivateCollectionProxy) }
                    def concat(*records); end

                    sig { params(records: T.any(::Post, Integer, String, T::Enumerable[T.any(::Post, Integer, String, T::Enumerable[::Post])])).returns(T::Array[::Post]) }
                    def delete(*records); end

                    sig { params(records: T.any(::Post, Integer, String, T::Enumerable[T.any(::Post, Integer, String, T::Enumerable[::Post])])).returns(T::Array[::Post]) }
                    def destroy(*records); end

                    sig { returns(T::Array[::Post]) }
                    def load_target; end

                    sig { params(records: T.any(::Post, T::Enumerable[T.any(::Post, T::Enumerable[::Post])])).returns(PrivateCollectionProxy) }
                    def prepend(*records); end

                    sig { params(records: T.any(::Post, T::Enumerable[T.any(::Post, T::Enumerable[::Post])])).returns(PrivateCollectionProxy) }
                    def push(*records); end

                    sig { params(other_array: T.any(::Post, T::Enumerable[T.any(::Post, T::Enumerable[::Post])])).returns(T::Array[::Post]) }
                    def replace(other_array); end

                    sig { returns(PrivateAssociationRelation) }
                    def scope; end

                    sig { returns(T::Array[::Post]) }
                    def target; end

                    sig { returns(T::Array[::Post]) }
                    def to_a; end

                    sig { returns(T::Array[::Post]) }
                    def to_ary; end
                  end

                  class PrivateRelation < ::ActiveRecord::Relation
                    include CommonRelationMethods
                    include GeneratedRelationMethods

                    Elem = type_member { { fixed: ::Post } }

                    sig { returns(T::Array[::Post]) }
                    def to_a; end

                    sig { returns(T::Array[::Post]) }
                    def to_ary; end
                  end

                  class PrivateRelationGroupChain < PrivateRelation
                    Elem = type_member { { fixed: ::Post } }

                    sig { params(column_name: T.any(String, Symbol)).returns(T::Hash[T.untyped, T.any(Integer, Float, BigDecimal)]) }
                    def average(column_name); end

                    sig { params(operation: Symbol, column_name: T.any(String, Symbol)).returns(T::Hash[T.untyped, T.any(Integer, Float, BigDecimal)]) }
                    def calculate(operation, column_name); end

                    sig { params(column_name: T.untyped).returns(T::Hash[T.untyped, Integer]) }
                    def count(column_name = nil); end

                    sig { params(args: T.untyped, blk: T.untyped).returns(T.self_type) }
                    def having(*args, &blk); end

                    sig { params(column_name: T.any(String, Symbol)).returns(T::Hash[T.untyped, T.untyped]) }
                    def maximum(column_name); end

                    sig { params(column_name: T.any(String, Symbol)).returns(T::Hash[T.untyped, T.untyped]) }
                    def minimum(column_name); end

                    sig { params(column_name: T.nilable(T.any(String, Symbol)), block: T.nilable(T.proc.params(record: T.untyped).returns(T.untyped))).returns(T::Hash[T.untyped, T.any(Integer, Float, BigDecimal)]) }
                    def sum(column_name = nil, &block); end
                  end

                  class PrivateRelationWhereChain < PrivateRelation
                    Elem = type_member { { fixed: ::Post } }

                <% if rails_version(">= 7.0") %>
                    sig { params(args: T.untyped).returns(PrivateRelation) }
                    def associated(*args); end

                <% end %>
                    sig { params(args: T.untyped).returns(PrivateRelation) }
                    def missing(*args); end

                    sig { params(opts: T.untyped, rest: T.untyped).returns(PrivateRelation) }
                    def not(opts, *rest); end
                  end
                end
              RUBY

              assert_equal(expected, rbi_for(:Post))
            end
          end
        end
      end
    end
  end
end
