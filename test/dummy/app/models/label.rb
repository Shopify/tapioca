# frozen_string_literal: true

class Label < ApplicationRecord
  has_and_belongs_to_many :profiles
end
