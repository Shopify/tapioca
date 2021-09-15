# typed: true
# frozen_string_literal: true

module Bar
  PI = 3.1415

  def self.bar(a = 1, b: 2, **opts)
    number = opts[:number] || 0
    39 + a + b + number
  end
end

# Used to check we load the Rails application before the gems
#
# We try to access the `Rails::Application` constant defined in the `config/application.rb` of the support repo.
# If the application is not loaded before the gems, this call will fail.
puts Rails::Application
