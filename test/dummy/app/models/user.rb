# frozen_string_literal: true

class User < ApplicationRecord
  before_create :foo, -> () {}
  validates :first_name, presence: true
  has_one :profile
  scope :adult, -> { where(age: 18..) }
  has_one :location, class_name: "Country"

  attr_readonly :last_name

  include Verifiable # an ActiveSupport::Concern

  private

  def foo
    puts "test"
  end
end
