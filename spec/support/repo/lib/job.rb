# typed: true
# frozen_string_literal: true

class Job
  include Sidekiq::Worker
  def perform(foo, bar)
  end
end
