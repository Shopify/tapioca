# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "rubygems/user_interaction"

module Tapioca
  extend T::Sig

  @traces = [] #: Array[TracePoint]

  class << self
    extend T::Sig

    #: [Result] { -> Result } -> Result
    def silence_warnings(&blk)
      original_verbosity = $VERBOSE
      $VERBOSE = nil
      ::Gem::DefaultUserInteraction.use_ui(::Gem::SilentUI.new) do
        blk.call
      end
    ensure
      $VERBOSE = original_verbosity
    end
  end

  class Error < StandardError; end

  LIB_ROOT_DIR = T.must(__dir__) #: String
  SORBET_DIR = "sorbet" #: String
  SORBET_CONFIG_FILE = "#{SORBET_DIR}/config" #: String
  TAPIOCA_DIR = "#{SORBET_DIR}/tapioca" #: String
  TAPIOCA_CONFIG_FILE = "#{TAPIOCA_DIR}/config.yml" #: String

  BINARY_FILE = "bin/tapioca" #: String
  DEFAULT_POSTREQUIRE_FILE = "#{TAPIOCA_DIR}/require.rb" #: String
  DEFAULT_RBI_DIR = "#{SORBET_DIR}/rbi" #: String
  DEFAULT_DSL_DIR = "#{DEFAULT_RBI_DIR}/dsl" #: String
  DEFAULT_GEM_DIR = "#{DEFAULT_RBI_DIR}/gems" #: String
  DEFAULT_SHIM_DIR = "#{DEFAULT_RBI_DIR}/shims" #: String
  DEFAULT_TODO_FILE = "#{DEFAULT_RBI_DIR}/todo.rbi" #: String
  DEFAULT_ANNOTATIONS_DIR = "#{DEFAULT_RBI_DIR}/annotations" #: String

  DEFAULT_OVERRIDES = {
    # ActiveSupport overrides some core methods with different signatures
    # so we generate a typed: false RBI for it to suppress errors
    "activesupport" => "false",
  }.freeze #: Hash[String, String]

  DEFAULT_RBI_MAX_LINE_LENGTH = 120
  DEFAULT_ENVIRONMENT = "development"

  CENTRAL_REPO_ROOT_URI = "https://raw.githubusercontent.com/Shopify/rbi-central/main"
  CENTRAL_REPO_INDEX_PATH = "index.json"
  CENTRAL_REPO_ANNOTATIONS_DIR = "rbi/annotations"
end

require "tapioca/version"
