# typed: strict
# frozen_string_literal: true

module TemplateHelper
  extend T::Sig

  class ErbBinding
    extend T::Sig

    ERB_SUPPORTS_KVARGS = T.let(::ERB.instance_method(:initialize).parameters.assoc(:key), T.nilable([Symbol, Symbol]))

    sig { params(selector: String).returns(T::Boolean) }
    def ruby_version(selector)
      Gem::Requirement.new(selector).satisfied_by?(Gem::Version.new(RUBY_VERSION))
    end

    sig { returns(Binding) }
    def erb_bindings
      binding
    end
  end

  sig { params(src: String).returns(String) }
  def template(src)
    erb = if ErbBinding::ERB_SUPPORTS_KVARGS
      ::ERB.new(src, trim_mode: ">")
    else
      ::ERB.new(src, nil, ">")
    end

    erb.result(ErbBinding.new.erb_bindings)
  end
end
