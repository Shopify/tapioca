# frozen_string_literal: true

class Profile < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :labels
end
