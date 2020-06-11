# typed: false
# frozen_string_literal: true

require "spec_helper"

describe("Tapioca::Compilers::Dsl::ActiveRecordAssociations") do
  before(:each) do
    require "tapioca/compilers/dsl/active_record_associations"
  end

  subject do
    Tapioca::Compilers::Dsl::ActiveRecordAssociations.new
  end

  describe("#initialize") do
    def constants_from(content)
      with_content(content) do
        subject.processable_constants.map(&:to_s).sort
      end
    end

    it("gathers no constants if there are no ActiveRecord subclasses") do
      assert_empty(subject.processable_constants)
    end

    it("gathers only ActiveRecord subclasses") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
        end

        class Current
        end
      RUBY

      assert_equal(constants_from(content), ["Post"])
    end

    it("rejects abstract ActiveRecord subclasses") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
        end

        class Current < ActiveRecord::Base
          self.abstract_class = true
        end
      RUBY

      assert_equal(constants_from(content), ["Post"])
    end
  end

  describe("#decorate") do
    before(:each) do
      ActiveRecord::Base.establish_connection(
        adapter: 'sqlite3',
        database: ':memory:'
      )
    end

    def rbi_for(contents)
      with_contents(contents, requires: contents.keys) do
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        subject.decorate(parlour.root, Post)
        parlour.rbi
      end
    end
  end
end
