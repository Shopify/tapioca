# typed: true
# frozen_string_literal: true

class Job
  include Sidekiq::Worker
  def perform(foo, bar)
  end
end

# This is to make sure we don't fail on anonymous constants
Class.new do
  include Sidekiq::Worker
end
