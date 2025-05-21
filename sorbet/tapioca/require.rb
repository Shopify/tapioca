# typed: strict
# frozen_string_literal: true

# Add your extra requires here
require "rails/all"
require "rails/generators"
require "rails/generators/app_base"
require "ansi/code"
require "google/protobuf"
require "rake/testtask"
require "rubocop/rake_task"
require "zeitwerk"

# Add-on related requires. These are not required by default, so we must list them in order to generate proper RBIs
require "ruby_lsp/internal"
require "ruby_lsp/test_helper"
require "ruby_lsp/ruby_lsp_rails/addon"
require "ruby_lsp/ruby_lsp_rails/server"
