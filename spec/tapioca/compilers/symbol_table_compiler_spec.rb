# typed: false
# frozen_string_literal: true

require "spec_helper"
require "pathname"
require "tmpdir"

RSpec.configure do |config|
  # Some tests are not compatible with different Ruby versions.
  # You can add `ruby: "X.Y.Z"` on a spec to specify which version should run it.
  #
  # For example:
  #   it("tests something with Ruby 2.5 or greater", ruby: ">= 2.5.0") do
  #     # ...
  #   end
  config.filter_run_excluding(ruby: ->(v) do
    !Gem::Requirement.new(v).satisfied_by?(Gem::Version.new(RUBY_VERSION))
  end)
end

RSpec.describe(Tapioca::Compilers::SymbolTableCompiler) do
  describe("compile") do
    def run_in_child
      read, write = IO.pipe

      pid = fork do
        Tapioca.silence_warnings do
          read.close
          result = yield
          write.puts(result)
        end
      end

      write.close
      Process.wait(pid)
      read.read.chomp
    ensure
      read&.close
    end

    def compile(contents)
      Dir.mktmpdir("gem") do |path|
        dir = Pathname.new(path)
        # Create a "lib" folder
        Dir.mkdir(dir.join("lib"))
        # Add our content into "file.rb" in lib folder
        File.write(dir.join("lib/file.rb"), contents)
        # Add an empty Ruby file "foo.rb" to use for requires
        File.write(dir.join("lib/foo.rb"), "")

        run_in_child do
          compiler = Tapioca::Compilers::SymbolTableCompiler.new

          spec = Bundler::StubSpecification.new("the-dep", "1.1.2", nil, nil)
          allow(spec).to(receive(:full_gem_path).and_return(dir))
          allow(spec).to(receive(:full_require_paths).and_return([dir.join("lib")]))
          gem = Tapioca::Gemfile::Gem.new(spec)

          # Require the file
          require(dir.join("lib/file.rb"))

          compiler.compile(gem)
        end
      end
    end

    def template(src)
      ERB.new(src, nil, ">").result(binding).chomp
    end

    it("compiles DelegateClass") do
      expect(
        compile(<<~RUBY)
          class Bar
          end

          class Foo < DelegateClass(Bar)
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Bar
          end

          class Foo
          end
        RUBY
      )
    end

    it("compiles extensions to BasicObject and Object") do
      expect(
        compile(<<~RUBY)
          class BasicObject
            def hello
            end
          end

          class Object
            def hello
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class BasicObject
            def hello; end
          end

          class Object < ::BasicObject
            include(::JSON::Ext::Generator::GeneratorMethods::Object)
            include(::Kernel)

            def hello; end
          end

          ::ARGF = T.let(T.unsafe(nil), T.untyped)

          ::ARGV = T.let(T.unsafe(nil), Array)

          ::ENV = T.let(T.unsafe(nil), Object)

          ::RUBY_COPYRIGHT = T.let(T.unsafe(nil), String)

          ::RUBY_DESCRIPTION = T.let(T.unsafe(nil), String)

          ::RUBY_ENGINE = T.let(T.unsafe(nil), String)

          ::RUBY_ENGINE_VERSION = T.let(T.unsafe(nil), String)

          ::RUBY_PATCHLEVEL = T.let(T.unsafe(nil), Integer)

          ::RUBY_PLATFORM = T.let(T.unsafe(nil), String)

          ::RUBY_RELEASE_DATE = T.let(T.unsafe(nil), String)

          ::RUBY_REVISION = T.let(T.unsafe(nil), Integer)

          ::RUBY_VERSION = T.let(T.unsafe(nil), String)

          ::STDERR = T.let(T.unsafe(nil), IO)

          ::STDIN = T.let(T.unsafe(nil), IO)

          ::STDOUT = T.let(T.unsafe(nil), IO)

          ::TOPLEVEL_BINDING = T.let(T.unsafe(nil), Binding)

          ::TRUE = T.let(T.unsafe(nil), TrueClass)
        RUBY
      )
    end

    it("compiles classes that have overridden == method that errors") do
      expect(
        compile(<<~RUBY)
          class Foo
            def self.==(other)
              raise RuntimeError
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Foo
            def self.==(other); end
          end
        RUBY
      )
    end

    it("compiles classes defined as static fields") do
      expect(
        compile(<<~RUBY)
          SymbolTableCompilerTest = Class.new
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class SymbolTableCompilerTest
          end
        RUBY
      )
    end

    it("compiles extensions to core types") do
      expect(
        compile(<<~RUBY)
          class Foo
            def to_s
              "Foo"
            end
            def bar
              "bar"
            end
          end

          class Integer
            def to_foo(base = 10)
              42 + base
            end
          end

          class Hash
            def to_bar
              {}
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Foo
            def bar; end
            def to_s; end
          end

          class Hash
            include(::JSON::Ext::Generator::GeneratorMethods::Hash)
            include(::Enumerable)

            def to_bar; end
          end

          class Integer < ::Numeric
            include(::JSON::Ext::Generator::GeneratorMethods::Integer)

            def to_foo(base = _); end
          end
        RUBY
      )
    end

    it("compiles without annotations") do
      expect(
        compile(<<~RUBY)
          class Bar
            def num(a)
              foo
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Bar
            def num(a); end
          end
        RUBY
      )
    end

    it("compiles methods and leaves spacing") do
      expect(
        compile(<<~RUBY)
          class Bar
            def num
            end

            def bar
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Bar
            def bar; end
            def num; end
          end
        RUBY
      )
    end

    it("compiles constants assignments") do
      expect(
        compile(<<~RUBY)
          module A
            ABC = 1
            DEF = ABC.to_s
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module A
          end

          A::ABC = T.let(T.unsafe(nil), Integer)

          A::DEF = T.let(T.unsafe(nil), String)
      RUBY
      )
    end

    it("compiles simple arguments") do
      expect(
        compile(<<~RUBY)
          class Foo
            def add(a, b:)
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Foo
            def add(a, b:); end
          end
        RUBY
      )
    end

    it("compiles default arguments") do
      expect(
        compile(<<~RUBY)
          class Foo
            def add(a = nil, b: 1)
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Foo
            def add(a = _, b: _); end
          end
        RUBY
      )
    end

    it("compiles modules") do
      expect(
        compile(<<~RUBY)
          module Foo
            # @return [Integer] a number
            def num(a)
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module Foo
            def num(a); end
          end
        RUBY
      )
    end

    it("compiles compact SymbolTableCompilerTests") do
      expect(
        compile(<<~RUBY)
          module Foo
          end

          module Foo::Bar
            def num(a)
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module Foo
          end

          module Foo::Bar
            def num(a); end
          end
        RUBY
      )
    end

    it("compiles nested namespaces") do
      expect(
        compile(<<~RUBY)
          module Foo
            class Bar
              def num(a)
              end
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module Foo
          end

          class Foo::Bar
            def num(a); end
          end
        RUBY
      )
    end

    it("compiles compact namespaces nested") do
      expect(
        compile(<<~RUBY)
          module Foo
            module Bar
            end
            class Bar::Baz
              def num(a)
              end
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module Foo
          end

          module Foo::Bar
          end

          class Foo::Bar::Baz
            def num(a); end
          end
        RUBY
      )
    end

    it("compiles deeply nested namespaces") do
      expect(
        compile(<<~RUBY)
          module Foo
            class Bar
              class Baz
                def num(a)
                end
              end
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module Foo
          end

          class Foo::Bar
          end

          class Foo::Bar::Baz
            def num(a); end
          end
        RUBY
      )
    end

    it("compiles a class with a superclass") do
      expect(
        compile(<<~RUBY)
          class Baz
            def toto
            end
          end

          class Bar < Baz
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Bar < ::Baz
          end

          class Baz
            def toto; end
          end
        RUBY
      )
    end

    it("compiles a class with a relative superclass") do
      expect(
        compile(<<~RUBY)
          module Foo
            class Baz
            end
            class Bar < Baz
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module Foo
          end

          class Foo::Bar < ::Foo::Baz
          end

          class Foo::Baz
          end
        RUBY
      )
    end

    it("compiles a class with an anchored superclass") do
      expect(
        compile(<<~RUBY)
          class Baz
          end

          module Foo
            class Bar < ::Baz
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Baz
          end

          module Foo
          end

          class Foo::Bar < ::Baz
          end
        RUBY
      )
    end

    it("compiles a class with an private superclass") do
      expect(
        compile(<<~RUBY)
          module Toto
            class Baz
            end

            module Foo
              class Bar < ::Toto::Baz
              end
            end

            private_constant(:Baz)
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module Toto
          end

          module Toto::Foo
          end

          class Toto::Foo::Bar
          end
        RUBY
      )
    end

    it("compiles a class which effectively has itself as a superclass") do
      expect(
        compile(<<~RUBY)
          module Foo
            class Baz < Numeric
            end

            class Bar < Baz
            end

            remove_const(:Baz)

            def self.const_missing(name)
              Bar if name == :Baz
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module Foo
            def self.const_missing(name); end
          end

          class Foo::Bar < ::Numeric
          end
        RUBY
      )
    end

    it("compiles a class with mixins") do
      expect(
        compile(<<~RUBY)
          class Baz
            def baz
            end
          end

          module Foo
            def foo
            end
          end

          module Toto
            def toto
            end
          end

          module Tutu
            def tutu
            end
          end

          class Bar < Baz
            include Foo
            extend Toto
            prepend Tutu
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Bar < ::Baz
            include(::Tutu)
            include(::Foo)
            extend(::Toto)
          end

          class Baz
            def baz; end
          end

          module Foo
            def foo; end
          end

          module Toto
            def toto; end
          end

          module Tutu
            def tutu; end
          end
        RUBY
      )
    end

    it("compiles Structs, Classes, and Modules") do
      expect(
        compile(<<~RUBY)
          class S1 < Struct.new(:foo)
          end
          S2 = Struct.new(:foo) do
            def foo
            end
          end
          S3 = Struct.new(:foo)
          class S4 < Struct.new("Foo", :foo)
          end
          class C1 < Class.new
          end
          C2 = Class.new do
            def foo
            end
          end
          C3 = Class.new
          module M1
          end
          M2 = Module.new do
            def foo
            end
          end
          M3 = Module.new
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class C1
          end

          class C2
            def foo; end
          end

          class C3
          end

          module M1
          end

          module M2
            def foo; end
          end

          module M3
          end

          class S1 < ::Struct
          end

          class S2 < ::Struct
            def foo; end
            def foo=(_); end

            def self.[](*_); end
            def self.inspect; end
            def self.members; end
            def self.new(*_); end
          end

          class S3 < ::Struct
            def foo; end
            def foo=(_); end

            def self.[](*_); end
            def self.inspect; end
            def self.members; end
            def self.new(*_); end
          end

          class S4 < ::Struct
          end
        RUBY
      )
    end

    it("handles dynamic mixins") do
      expect(
        compile(<<~RUBY)
          module Foo
          end

          module Baz
          end

          class Bar
            def self.abc
              Baz
            end

            include(Module.new, Foo)
            include(abc)
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Bar
            include(::Baz)
            include(::Foo)

            def self.abc; end
          end

          module Baz
          end

          module Foo
          end
        RUBY
      )
    end

    it("compiles methods on the class's singleton class") do
      expect(
        compile(<<~RUBY)
          class Bar
            def self.num(a)
              a
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Bar
            def self.num(a); end
          end
        RUBY
      )
    end

    it("doesn't compile non-static singleton class reopening") do
      expect(
        compile(<<~RUBY)
          class Bar
            obj = Object.new

            class << obj
              define_method(:foo) {}
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Bar
          end
        RUBY
      )
    end

    it("ignores methods on other objects") do
      expect(
        compile(<<~RUBY)
          class Bar
            a = Object.new

            def a.num(a)
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Bar
          end
        RUBY
      )
    end

    it("compiles a singleton class") do
      expect(
        compile(<<~RUBY)
          class Bar
            class << self
              def num(a)
              end
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Bar
            def self.num(a); end
          end
        RUBY
      )
    end

    it("compiles blocks") do
      expect(
        compile(<<~RUBY)
          class Bar
            def size(&block)
            end

            def unwrap(&block)
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Bar
            def size(&block); end
            def unwrap(&block); end
          end
        RUBY
      )
    end

    it("compiles attr_reader/attr_writer/attr_accessor") do
      expect(
        compile(<<~RUBY)
          class Bar
            attr_reader(:foo)

            attr_accessor(:bar)

            attr_writer(:baz)

            attr_reader(:a, :b)
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Bar
            def a; end
            def b; end
            def bar; end
            def bar=(_); end
            def baz=(_); end
            def foo; end
          end
        RUBY
      )
    end

    it("ignores methods with invalid names") do
      expect(
        compile(<<~RUBY)
          class Bar
            define_method("foo") do
              :foo
            end

            define_method("invalid_method_name?=") do
              1
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Bar
            def foo; end
          end
        RUBY
      )
    end

    it("ignores method calls") do
      expect(
        compile(<<~RUBY)
          require_relative("./foo")

          class Bar
            def self.a
              2
            end

            a + 1
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Bar
            def self.a; end
          end
        RUBY
      )
    end

    it("ignores loops") do
      expect(
        compile(<<~RUBY)
          class Toto
            for x in [1, 2, 3]
              puts x
            end

            loop do
              break
            end

            while false
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Toto
          end
        RUBY
      )
    end

    it("renames unnamed splats") do
      expect(
        compile(<<~RUBY)
          class Toto
            def toto(a, *, **)
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Toto
            def toto(a, *_, **_); end
          end
        RUBY
      )
    end

    it("ignores ivar and cvar assigns") do
      expect(
        compile(<<~RUBY)
          module Foo
            @@mod_var = 1
            @ivar = 2
            @ivar ||= 1
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module Foo
          end
        RUBY
      )
    end

    it("ignores things done in the file body") do
      expect(
        compile(<<~RUBY)
          begin

            require "foo"
          rescue LoadError, RuntimeError => e

            $stderr
            .puts "oopsie"
          end

          module Foo
          end

          obj = Object.new

          Dir.glob(File.join('yard', 'core_ext', '*.rb')).each do |file|
            begin
              require file
            rescue LoadError
            end
          end

          def tap; yield(self); self end unless defined?(tap)

          case obj
          when :constants
            class Job
            end
          when :method
            def hi
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module Foo
          end
        RUBY
      )
    end

    it("compiles methods of all visibility for classes") do
      expect(
        compile(<<~RUBY)
          class Bar
            def toto
            end
            private(:toto)

            def tutu
            end

            protected

            def num(a)
            end

            private

            def foo(b)
            end

            protected(def pc; end)
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Bar
            def tutu; end

            protected

            def num(a); end
            def pc; end

            private

            def foo(b); end
            def toto; end
          end
        RUBY
      )
    end

    it("compiles methods of all visibility for modules") do
      expect(
        compile(<<~RUBY)
          module Foo
            def toto
            end
            private(:toto)

            def tutu
            end

            protected

            def num(a)
            end

            private

            def foo(b)
            end

            protected(def pc; end)
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module Foo
            def tutu; end

            protected

            def num(a); end
            def pc; end

            private

            def foo(b); end
            def toto; end
          end
        RUBY
      )
    end

    it("removes useless spacing") do
      expect(
        compile(<<~RUBY)
          class Bar
            a = b = c = 1
            a
            b
            c
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Bar
          end
        RUBY
      )
    end

    it("compiles initialize") do
      expect(
        compile(<<~RUBY)
          class Bar
            def initialize
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Bar
            def initialize; end
          end
        RUBY
      )
    end

    it("understands redefined attr_accessor") do
      expect(
        compile(<<~RUBY)
          class Toto
            # @return [String]
            attr_accessor(:foo)

            undef :foo

            def foo
            end

            undef :foo=

            def foo=(the_foo)
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Toto
            def foo; end
            def foo=(the_foo); end
          end
        RUBY
      )
    end

    it("handles inheritance properly when the parent is a method call") do
      expect(
        compile(<<~RUBY)
          module Baz
            class Bar; end

            def self.foo(x)
              x
            end

            class Toto < foo(Bar)
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module Baz
            def self.foo(x); end
          end

          class Baz::Bar
          end

          class Baz::Toto < ::Baz::Bar
          end
        RUBY
      )
    end

    it("handles multiple assign of constants") do
      expect(
        compile(<<~RUBY)
          module Toto
            A, B, C, *D, e = "1.2.3.4".split(".")
            NUMS = [A, B, C, *D]
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module Toto
          end

          Toto::A = T.let(T.unsafe(nil), String)

          Toto::B = T.let(T.unsafe(nil), String)

          Toto::C = T.let(T.unsafe(nil), String)

          Toto::D = T.let(T.unsafe(nil), Array)

          Toto::NUMS = T.let(T.unsafe(nil), Array)
        RUBY
      )
    end

    it("handles constants that override #!") do
      expect(
        compile(<<~RUBY)
          class Hostile
            class << self
              def !
                self
              end
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Hostile
            def self.!; end
          end
        RUBY
      )
    end

    it("handles ranges properly") do
      expect(
        compile(<<~RUBY)
          module Toto
            A = ('a'...'z')
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module Toto
          end

          Toto::A = T.let(T.unsafe(nil), Range)
        RUBY
      )
    end

    it("doesn't output prepend for modules unrechable via constants") do
      expect(
        compile(<<~RUBY)
          module Foo
          end

          class << Foo
            module Bar
              def hi  # unfortunately we miss out on this
              end
            end

            prepend(Bar)
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module Foo
          end
        RUBY
      )
    end

    it("doesn't output include for modules unrechable via constants") do
      expect(
        compile(<<~RUBY)
          module Foo
          end

          class << Foo
            module Bar
              def hi  # unfortunately we miss out on this
              end
            end

            include(Bar)
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module Foo
          end
        RUBY
      )
    end

    it("can handle BasicObjects") do
      expect(
        compile(<<~RUBY)
          module BasicObjectTest
            class B < ::BasicObject
            end

            Basic = B.new
            VeryBasic = ::BasicObject.new
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module BasicObjectTest
          end

          class BasicObjectTest::B < ::BasicObject
          end

          BasicObjectTest::Basic = T.let(T.unsafe(nil), BasicObjectTest::B)

          BasicObjectTest::VeryBasic = T.let(T.unsafe(nil), BasicObject)
        RUBY
      )
    end

    it("adds mixes_in_class_methods to modules extending ActiveSupport::Concern") do
      expect(
        compile(<<~RUBY)
          module ActiveSupport
            module Concern
            end
          end

          module FooConcern
            extend(ActiveSupport::Concern)

            module ClassMethods
              def wow_a_class_method
                "something"
              end
            end

            def a_normal_method
              123
            end
          end

          module BarConcern
            extend(ActiveSupport::Concern)

            ClassMethods = 1
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module ActiveSupport
          end

          module ActiveSupport::Concern
          end

          module BarConcern
            extend(::ActiveSupport::Concern)
          end

          BarConcern::ClassMethods = T.let(T.unsafe(nil), Integer)

          module FooConcern
            extend(::ActiveSupport::Concern)

            mixes_in_class_methods(ClassMethods)

            def a_normal_method; end
          end

          module FooConcern::ClassMethods
            def wow_a_class_method; end
          end
        RUBY
      )
    end

    it("properly treats pre-Rails 6.1 ActiveSupport::Deprecation::DeprecatedConstantProxy instances") do
      expect(
        compile(<<~RUBY)
          module ActiveSupport
            class Deprecation
              class DeprecationProxy #:nodoc:
                def self.new(*args, &block)
                  object = args.first

                  return object unless object
                  super
                end

                instance_methods.each { |m| undef_method m unless /^__|^object_id$/.match?(m) }

                def inspect
                  target.inspect
                end

                private
                  def method_missing(called, *args, &block)
                    target.__send__(called, *args, &block)
                  end
              end

              class DeprecatedConstantProxy < DeprecationProxy
                def initialize(old_const, new_const)
                  @old_const = old_const
                  @new_const = new_const
                end

                def class
                  target.class
                end

                private
                  def target
                    Object.const_get(@new_const.to_s)
                  end

                  def warn(callstack, called, args)
                    @deprecator.warn(@message, callstack)
                  end
              end
            end
          end

          class Foo
            def self.name
              "SomethingElse"
            end
          end

          Bar = ActiveSupport::Deprecation::DeprecatedConstantProxy.new("Bar", "Foo")
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module ActiveSupport
          end

          class ActiveSupport::Deprecation
          end

          class ActiveSupport::Deprecation::DeprecatedConstantProxy < ::ActiveSupport::Deprecation::DeprecationProxy
            def initialize(old_const, new_const); end

            def class; end

            private

            def target; end
            def warn(callstack, called, args); end
          end

          class ActiveSupport::Deprecation::DeprecationProxy
            def inspect; end

            private

            def method_missing(called, *args, &block); end

            def self.new(*args, &block); end
          end

          Bar = T.let(T.unsafe(nil), ActiveSupport::Deprecation::DeprecatedConstantProxy)

          class Foo
            def self.name; end
          end
        RUBY
      )
    end

    it("properly treats Rails 6.1 ActiveSupport::Deprecation::DeprecatedConstantProxy instances") do
      expect(
        compile(<<~RUBY)
          module ActiveSupport
            class Deprecation
              class DeprecatedConstantProxy < Module
                def self.new(*args, &block)
                  object = args.first

                  return object unless object
                  super
                end

                def initialize(old_const, new_const)
                  @old_const = old_const
                  @new_const = new_const
                end

                instance_methods.each { |m| undef_method m unless /^__|^object_id$/.match?(m) }

                def inspect
                  target.inspect
                end

                def class
                  target.class
                end

                private
                  def target
                    Object.const_get(@new_const.to_s)
                  end

                  def const_missing(name)
                    target.const_get(name)
                  end

                  def method_missing(called, *args, &block)
                    target.__send__(called, *args, &block)
                  end
              end
            end
          end

          class Foo
            def self.name
              "SomethingElse"
            end
          end

          Bar = ActiveSupport::Deprecation::DeprecatedConstantProxy.new("Bar", "Foo")
        RUBY
      ).to(
        eq(template(<<~RUBY))
          module ActiveSupport
          end

          class ActiveSupport::Deprecation
          end

          class ActiveSupport::Deprecation::DeprecatedConstantProxy < ::Module
            def initialize(old_const, new_const); end

            def class; end
            def inspect; end

            private

            def const_missing(name); end
            def method_missing(called, *args, &block); end
            def target; end

            def self.new(*args, &block); end
          end

          Bar = Foo

          class Foo
            def self.name; end
          end
        RUBY
      )
    end

    it("properly filters out T::Private modules") do
      expect(
        compile(<<~RUBY)
          class Foo
            extend(T::Private::Methods::SingletonMethodHooks)
            extend(T::Private::Abstract::Hooks)
            extend(T::Private::Methods)
            extend(T::Private::Methods::MethodHooks)

            def self.name
              "SomethingElse"
            end
          end
        RUBY
      ).to(
        eq(template(<<~RUBY))
          class Foo
            def self.name; end
          end
        RUBY
      )
    end
  end
end
