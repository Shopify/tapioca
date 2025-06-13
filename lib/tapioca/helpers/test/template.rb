# typed: strict
# frozen_string_literal: true

module Tapioca
  module Helpers
    module Test
      # @requires_ancestor: Kernel
      module Template
        extend T::Sig
        ERB_SUPPORTS_KVARGS = ::ERB.instance_method(:initialize).parameters.assoc(:key) #: [Symbol, Symbol]?

        #: (String selector) -> bool
        def ruby_version(selector)
          ::Gem::Requirement.new(selector).satisfied_by?(::Gem::Version.new(RUBY_VERSION))
        end

        #: (String selector) -> bool
        def rails_version(selector)
          ::Gem::Requirement.new(selector).satisfied_by?(ActiveSupport.gem_version)
        end

        #: (String src, ?trim_mode: String) -> String
        def template(src, trim_mode: ">")
          erb = if ERB_SUPPORTS_KVARGS
            ::ERB.new(src, trim_mode: trim_mode)
          else
            ::ERB.new(src, nil, trim_mode)
          end

          erb.result(binding)
        end

        #: (String str, Integer indent) -> String
        def indented(str, indent)
          str.lines.map! do |line|
            next line if line.chomp.empty?

            (" " * indent) + line
          end.join
        end
      end
    end
  end
end
