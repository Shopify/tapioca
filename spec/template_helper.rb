# frozen_string_literal: true

module TemplateHelper
  class ErbBinding
    ERB_SUPPORTS_KVARGS = ::ERB.instance_method(:initialize).parameters.assoc(:key)

    def ruby_version(selector)
      Gem::Requirement.new(selector).satisfied_by?(Gem::Version.new(RUBY_VERSION))
    end

    def erb_bindings
      binding
    end
  end

  def template(src)
    erb = if ErbBinding::ERB_SUPPORTS_KVARGS
      ::ERB.new(src, trim_mode: ">")
    else
      ::ERB.new(src, nil, ">")
    end

    erb.result(ErbBinding.new.erb_bindings)
  end
end
