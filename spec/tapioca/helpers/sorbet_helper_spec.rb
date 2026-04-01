# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::SorbetHelperSpec < Minitest::Spec
  include Tapioca::SorbetHelper

  describe Tapioca::SorbetHelper do
    it "returns the value of TAPIOCA_SORBET_EXE if set" do
      with_custom_sorbet_exe_path("bin/custom-sorbet-static") do |custom_path|
        assert_equal(sorbet_path, custom_path)
      end
    end

    it "returns the default sorbet path if TAPIOCA_SORBET_EXE is empty" do
      default_path = SORBET_BIN.to_s.shellescape
      with_custom_sorbet_exe_path("") do
        assert_equal(sorbet_path, default_path)
      end
    end

    it "returns the default sorbet path if TAPIOCA_SORBET_EXE is not set" do
      default_path = SORBET_BIN.to_s.shellescape
      with_custom_sorbet_exe_path(nil) do
        assert_equal(sorbet_path, default_path)
      end
    end

    it "raises for an unknown feature check" do
      assert_raises do
        sorbet_supports?(:unknown_feature_name)
      end
    end
  end

  describe Tapioca::SorbetHelper::SorbetConfig do
    it "ignores comment lines" do
      config = parse(<<~CONFIG)
        # --parser=prism
      CONFIG
      assert_equal(:original, config.parser)
    end

    it "ignores blank lines" do
      config = parse(<<~CONFIG)

        --parser=prism

      CONFIG
      assert_equal(:prism, config.parser)
    end

    it "ignores lines without -- prefix" do
      config = parse(<<~CONFIG)
        .
        src/
        --parser=prism
      CONFIG
      assert_equal(:prism, config.parser)
    end

    describe "--parser" do
      it "detects --parser=prism" do
        config = parse(<<~CONFIG)
          .
          --parser=prism
        CONFIG
        assert_equal(:prism, config.parser)
        assert_predicate(config, :parse_with_prism?)
      end

      it "defaults to :original for empty config" do
        config = parse("")
        assert_equal(:original, config.parser)
        refute_predicate(config, :parse_with_prism?)
      end

      it "defaults to :original when no --parser option" do
        config = parse(<<~CONFIG)
          .
          --dir=foo
        CONFIG
        assert_equal(:original, config.parser)
      end

      it "treats non-prism values as :original" do
        config = parse(<<~CONFIG)
          .
          --parser=original
        CONFIG
        assert_equal(:original, config.parser)
        refute_predicate(config, :parse_with_prism?)
      end
    end

    describe "--cache-dir" do
      it "detects --cache-dir" do
        config = parse(<<~CONFIG)
          .
          --cache-dir=/tmp/sorbet-cache
        CONFIG
        assert_equal("/tmp/sorbet-cache", config.cache_dir)
      end

      it "returns nil when not set" do
        config = parse(<<~CONFIG)
          .
          --parser=prism
        CONFIG
        assert_nil(config.cache_dir)
      end

      it "returns nil for empty value" do
        config = parse(<<~CONFIG)
          .
          --cache-dir=
        CONFIG
        assert_nil(config.cache_dir)
      end
    end

    private

    #: (String content) -> Tapioca::SorbetHelper::SorbetConfig
    def parse(content) = Tapioca::SorbetHelper::SorbetConfig.parse(content)
  end

  # Rubocop thinks the `private` call above (in the `describe` block) still applies here. It doesn't.
  private # rubocop:disable Lint/UselessAccessModifier

  #: (String? path) { (String? custom_path) -> void } -> void
  def with_custom_sorbet_exe_path(path, &block)
    sorbet_exe_env_value = ENV[SORBET_EXE_PATH_ENV_VAR]
    begin
      ENV[SORBET_EXE_PATH_ENV_VAR] = path
      block.call(path)
    ensure
      ENV[SORBET_EXE_PATH_ENV_VAR] = sorbet_exe_env_value
    end
  end
end
