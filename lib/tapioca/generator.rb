# typed: strict
# frozen_string_literal: true

require "pathname"
require "thor"

module Tapioca
  class Generator < ::Thor::Shell::Color
    extend(T::Sig)

    sig { returns(Config) }
    attr_reader :config

    sig do
      params(
        config: Config
      ).void
    end
    def initialize(config)
      @config = config
      @bundle = T.let(nil, T.nilable(Gemfile))
      @loader = T.let(nil, T.nilable(Loader))
      @compiler = T.let(nil, T.nilable(Compilers::SymbolTableCompiler))
      @existing_rbis = T.let(nil, T.nilable(T::Hash[String, String]))
      @expected_rbis = T.let(nil, T.nilable(T::Hash[String, String]))
      super()
    end

    private

    sig { returns(Compilers::SymbolTableCompiler) }
    def compiler
      @compiler ||= Compilers::SymbolTableCompiler.new
    end

    sig { params(class_name: String).returns(String) }
    def underscore(class_name)
      return class_name unless /[A-Z-]|::/.match?(class_name)

      word = class_name.to_s.gsub("::", "/")
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end
  end
end
