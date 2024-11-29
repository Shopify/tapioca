# frozen_string_literal: true

class ExampleJob < ApplicationJob
  queue_as :default

  def perform(*values)
    # Do something later
  end
end
