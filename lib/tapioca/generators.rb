# typed: true
# frozen_string_literal: true

Dir["#{__dir__}/generators/*.rb"].each do |generator|
  require generator
end
