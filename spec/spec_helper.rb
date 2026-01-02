# typed: strict
# frozen_string_literal: true

require "tapioca/internal"
require "minitest/autorun"
require "minitest/spec"
require "minitest/hooks/default"
require "minitest/reporters"
require "rails/test_unit/line_filtering"

require "tapioca/helpers/test/content"
require "tapioca/helpers/test/template"
require "tapioca/helpers/test/isolation"
require "spec_reporter"
require "dsl_spec_helper"
require "spec_with_project"
require "rails_spec_helper"

backtrace_filter = Minitest::ExtensibleBacktraceFilter.default_filter
backtrace_filter.add_filter(%r{gems/sorbet-runtime})
backtrace_filter.add_filter(%r{gems/railties})
backtrace_filter.add_filter(%r{tapioca/helpers/test/})

Minitest::Reporters.use!(SpecReporter.new(color: true), ENV, backtrace_filter)

module Minitest
  class Test
    extend T::Sig
    extend Rails::LineFiltering
  end
end

module WarnMonkeyPatch
  # extend T::Sig

  # Detects the file, line number and "warning: " prefix at the
  # start of every warning message, for us to chop off.
  # Users can get the file/line from the backtrace.
  WARNING_PREFIX_PATTERN = /^.+?:\d+: warning: /

  #: (String message, ?category: Symbol?, **top) -> void
  def warn(message, category: nil, **kwargs)
    if Thread.current[:__raise_warnings_as_exceptions]
      message.sub!(WARNING_PREFIX_PATTERN, "")
      message.chomp!
      Kernel.raise Warning::Exception, message
    else
      super
    end
  end

  # sig do
  #   type_parameters(:R)
  #     .params(block: T.proc.returns(T.type_parameter(:R)))
  #     .returns(T.type_parameter(:R))
  # end
  #: [R] { -> R } -> R
  def raise_warnings_as_exceptions(&block)
    previous_state = Thread.current[:__raise_warnings_as_exceptions]
    Thread.current[:__raise_warnings_as_exceptions] = true
    block.call
  ensure
    Thread.current[:__raise_warnings_as_exceptions] = previous_state
  end
end

module ::Warning
  extend T::Helpers

  Exception = Class.new(StandardError)
  
  singleton_class.prepend(WarnMonkeyPatch)
  mixes_in_class_methods(WarnMonkeyPatch)
end