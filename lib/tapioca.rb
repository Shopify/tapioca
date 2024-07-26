# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "rubygems/user_interaction"

module TypeCastHelpers
  extend T::Sig
  extend T::Helpers

  requires_ancestor { Kernel }

  sig do
    type_parameters(:Type)
      .params(type: T::Class[T.type_parameter(:Type)])
      .returns(T.nilable(T.type_parameter(:Type)))
  end
  def as?(type) = is_a?(type) ? self : nil

  sig do
    type_parameters(:Type)
      .params(type: T::Class[T.type_parameter(:Type)])
      .returns(T.type_parameter(:Type))
  end
  def as!(type) = T.cast(self, T.type_parameter(:Type)) # rubocop:disable Sorbet/NewCastSyntax

  sig do
    type_parameters(:Type)
      .params(type: T::Class[T.type_parameter(:Type)])
      .returns(T.type_parameter(:Type))
  end
  def as?(type)
    # Inlined from `T.cast` from sorbet-runtime-0.5.11422/lib/types/_types.rb
    # To avoid:
    #
    #   lib/tapioca/commands/dsl_generate.rb:71: Unsupported type syntax https://srb.help/5004
    #        71 |  def as!(type) = T.cast(self, type)
    #                                           ^^^^
    #
    # const_get to avoid:
    #   Did you mean T::Class? Use -a to autocorrect
    #     lib/tapioca/commands/dsl_generate.rb:87: Replace with T::Class
    #     87 |    T::Private::Casts.cast(self, type, "T.cast")
    #             ^^^^^^^^^^^^^^^^^
    T.const_get(:Private).const_get(:Casts).cast(self, type, "T.cast")
  end

  # Check method name availability with:
  #     ObjectSpace.each_object(Module).any? { |m| method_defined.bind_call(m, :some!) } ? "taken" : "available"
  #
  # Other possible names: `non_nil`, `some!`
  # Not available: `unwrap`, `unwrap!`, `some`
  sig { returns(T.self_type) }
  def non_nil! = self
end

module NilTypeCastHelpers
  extend T::Sig
  extend T::Helpers

  requires_ancestor { NilClass }

  sig { returns(T.noreturn) }
  def non_nil!
    # Inlined from `T.must` from sorbet-runtime-0.5.11422/lib/types/_types.rb
    raise TypeError.new("Passed `nil` into T.must")
  rescue TypeError => e # raise into rescue to ensure e.backtrace is populated
    T::Configuration.inline_type_error_handler(e, {kind: 'T.must', value: self, type: nil})
  end
end

Kernel.include(TypeCastHelpers)
NilClass.include(NilTypeCastHelpers)

module Tapioca
  extend T::Sig

  @traces = T.let([], T::Array[TracePoint])

  class << self
    extend T::Sig

    sig do
      type_parameters(:Result)
        .params(blk: T.proc.returns(T.type_parameter(:Result)))
        .returns(T.type_parameter(:Result))
    end
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

  LIB_ROOT_DIR = T.let(__dir__.non_nil!, String)
  SORBET_DIR = T.let("sorbet", String)
  SORBET_CONFIG_FILE = T.let("#{SORBET_DIR}/config", String)
  TAPIOCA_DIR = T.let("#{SORBET_DIR}/tapioca", String)
  TAPIOCA_CONFIG_FILE = T.let("#{TAPIOCA_DIR}/config.yml", String)

  BINARY_FILE = T.let("bin/tapioca", String)
  DEFAULT_POSTREQUIRE_FILE = T.let("#{TAPIOCA_DIR}/require.rb", String)
  DEFAULT_RBI_DIR = T.let("#{SORBET_DIR}/rbi", String)
  DEFAULT_DSL_DIR = T.let("#{DEFAULT_RBI_DIR}/dsl", String)
  DEFAULT_GEM_DIR = T.let("#{DEFAULT_RBI_DIR}/gems", String)
  DEFAULT_SHIM_DIR = T.let("#{DEFAULT_RBI_DIR}/shims", String)
  DEFAULT_TODO_FILE = T.let("#{DEFAULT_RBI_DIR}/todo.rbi", String)
  DEFAULT_ANNOTATIONS_DIR = T.let("#{DEFAULT_RBI_DIR}/annotations", String)

  DEFAULT_OVERRIDES = T.let(
    {
      # ActiveSupport overrides some core methods with different signatures
      # so we generate a typed: false RBI for it to suppress errors
      "activesupport" => "false",
    }.freeze,
    T::Hash[String, String],
  )

  DEFAULT_RBI_MAX_LINE_LENGTH = 120
  DEFAULT_ENVIRONMENT = "development"

  CENTRAL_REPO_ROOT_URI = "https://raw.githubusercontent.com/Shopify/rbi-central/main"
  CENTRAL_REPO_INDEX_PATH = "index.json"
  CENTRAL_REPO_ANNOTATIONS_DIR = "rbi/annotations"
end

require "tapioca/version"
