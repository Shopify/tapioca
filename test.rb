# typed: ignore
# frozen_string_literal: true

# require "sorbet-runtime"

# module Hooks
#   def with_hooks(method_name, hooks)
#     hooks_module.define_method(method_name) do |*args, &block|
#       hooks[:before].call
#       super(*args, &block)
#     end
#   end

#   private

#   def hooks_module
#     @hooks_module ||= Module.new.tap { |mod| prepend(mod) }
#   end
# end

# module Service
#   extend T::Sig
#   extend Hooks

#   #: (String a) -> void
#   def some_method(a)
#     puts "Here in some_method. a: #{a}"
#   end

#   with_hooks :some_method, before: -> { puts "before" }
# end

# class Main
#   extend Service
# end

# Main.some_method("hello")
# Main.some_method("world")
# Main.some_method(42)

TracePoint.new(:c_return) { puts "#{it.self}.#{it.method_id} returned #{it.return_value.inspect}" }.enable do
  Foo = Class.new
  Bar = Module.new
end
