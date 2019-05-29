# frozen_string_literal: true

source("https://rubygems.org")

PACKAGE_CLOUD = "https://packages.shopify.io/shopify/gems"
source(PACKAGE_CLOUD)

gemspec

group(:deployment) do
  gem("package_cloud", "~> 0.2.33")
end

group(:deployment, :development) do
  gem("rake", "~> 12.3")
end

source("https://stripe.dev/sorbet-repo/super-secret-private-beta/") do
  gem("sorbet", :group => :development)
  gem("sorbet-runtime")
end
