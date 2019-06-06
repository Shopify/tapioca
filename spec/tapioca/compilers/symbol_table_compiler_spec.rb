# typed: false
# frozen_string_literal: true

require "spec_helper"
require "pathname"
require "tmpdir"

# Since we load all examples into memory,
# we need to wrap all examples in a Namespace module
# so that we can clean up.
#
# This is the name of the Namespace module
#
NAMESPACE = :SymbolTableCompilerTest

RSpec.describe(Tapioca::Compilers::SymbolTableCompiler) do
  describe("compile") do
    def remove_namespace
      Object.send(:remove_const, NAMESPACE) if Object.const_defined?(NAMESPACE)
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

        Tapioca.silence_warnings do
          compiler = Tapioca::Compilers::SymbolTableCompiler.new

          spec = Bundler::StubSpecification.new("the-dep", "1.1.2", nil, nil)
          allow(spec).to(receive(:full_gem_path).and_return(dir))
          allow(spec).to(receive(:full_require_paths).and_return([dir.join("lib")]))
          gem = Tapioca::Gemfile::Gem.new(spec)

          # Require the file
          require(dir.join("lib/file.rb"))

          compiler.compile(gem).chomp
        end
      ensure
        # Remove the wrapper namespace module
        # (and, thus, everything else defined within)
        remove_namespace
      end
    end

    it("compiles DelegateClass") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Bar
            end

            class Foo < DelegateClass(Bar)
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Bar
          end

          class SymbolTableCompilerTest::Foo
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
        eq(<<~RUBY.chomp)
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

          ::NAMESPACE = T.let(T.unsafe(nil), Symbol)

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
          module SymbolTableCompilerTest
            class Foo
              def self.==(other)
                raise RuntimeError
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Foo
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
        eq(<<~RUBY.chomp)
          class SymbolTableCompilerTest
          end
        RUBY
      )
    end

    it("compiles extensions to core types") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Foo
              def to_s
                "Foo"
              end
              def bar
                "bar"
              end
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
        eq(<<~RUBY.chomp)
          class Hash
            include(::JSON::Ext::Generator::GeneratorMethods::Hash)
            include(::Enumerable)

            def to_bar; end
          end

          class Integer < ::Numeric
            include(::JSON::Ext::Generator::GeneratorMethods::Integer)

            def to_foo(base = _); end
          end

          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Foo
            def bar; end
            def to_s; end
          end
        RUBY
      )
    end

    it("compiles without annotations") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Bar
              def num(a)
                foo
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Bar
            def num(a); end
          end
        RUBY
      )
    end

    it("compiles methods and leaves spacing") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Bar
              def num
              end

              def bar
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Bar
            def bar; end
            def num; end
          end
        RUBY
      )
    end

    it("compiles constants assignments") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            module A
              ABC = 1
              DEF = ABC.to_s
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          module SymbolTableCompilerTest::A
          end

          SymbolTableCompilerTest::A::ABC = T.let(T.unsafe(nil), Integer)

          SymbolTableCompilerTest::A::DEF = T.let(T.unsafe(nil), String)
      RUBY
      )
    end

    it("compiles simple arguments") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Foo
              def add(a, b:)
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Foo
            def add(a, b:); end
          end
        RUBY
      )
    end

    it("compiles default arguments") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Foo
              def add(a = nil, b: 1)
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Foo
            def add(a = _, b: _); end
          end
        RUBY
      )
    end

    it("compiles modules") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            module Foo
              # @return [Integer] a number
              def num(a)
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          module SymbolTableCompilerTest::Foo
            def num(a); end
          end
        RUBY
      )
    end

    it("compiles compact SymbolTableCompilerTests") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            module Foo
            end

            module Foo::Bar
              def num(a)
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          module SymbolTableCompilerTest::Foo
          end

          module SymbolTableCompilerTest::Foo::Bar
            def num(a); end
          end
        RUBY
      )
    end

    it("compiles nested namespaces") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            module Foo
              class Bar
                def num(a)
                end
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          module SymbolTableCompilerTest::Foo
          end

          class SymbolTableCompilerTest::Foo::Bar
            def num(a); end
          end
        RUBY
      )
    end

    it("compiles compact namespaces nested") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            module Foo
              module Bar
              end
              class Bar::Baz
                def num(a)
                end
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          module SymbolTableCompilerTest::Foo
          end

          module SymbolTableCompilerTest::Foo::Bar
          end

          class SymbolTableCompilerTest::Foo::Bar::Baz
            def num(a); end
          end
        RUBY
      )
    end

    it("compiles deeply nested namespaces") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            module Foo
              class Bar
                class Baz
                  def num(a)
                  end
                end
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          module SymbolTableCompilerTest::Foo
          end

          class SymbolTableCompilerTest::Foo::Bar
          end

          class SymbolTableCompilerTest::Foo::Bar::Baz
            def num(a); end
          end
        RUBY
      )
    end

    it("compiles a class with a superclass") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Baz
              def toto
              end
            end

            class Bar < Baz
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Bar < ::SymbolTableCompilerTest::Baz
          end

          class SymbolTableCompilerTest::Baz
            def toto; end
          end
        RUBY
      )
    end

    it("compiles a class with a relative superclass") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            module Foo
              class Baz
              end
              class Bar < Baz
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          module SymbolTableCompilerTest::Foo
          end

          class SymbolTableCompilerTest::Foo::Bar < ::SymbolTableCompilerTest::Foo::Baz
          end

          class SymbolTableCompilerTest::Foo::Baz
          end
        RUBY
      )
    end

    it("compiles a class with an anchored superclass") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Baz
            end

            module Foo
              class Bar < ::SymbolTableCompilerTest::Baz
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Baz
          end

          module SymbolTableCompilerTest::Foo
          end

          class SymbolTableCompilerTest::Foo::Bar < ::SymbolTableCompilerTest::Baz
          end
        RUBY
      )
    end

    it("compiles a class with an private superclass") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Baz
            end

            module Foo
              class Bar < ::SymbolTableCompilerTest::Baz
              end
            end

            private_constant(:Baz)
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          module SymbolTableCompilerTest::Foo
          end

          class SymbolTableCompilerTest::Foo::Bar
          end
        RUBY
      )
    end

    it("compiles a class which effectively has itself as a superclass") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
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
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
            def self.const_missing(name); end
          end

          class SymbolTableCompilerTest::Bar < ::Numeric
          end
        RUBY
      )
    end

    it("compiles a class with mixins") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
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
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Bar < ::SymbolTableCompilerTest::Baz
            include(::SymbolTableCompilerTest::Tutu)
            include(::SymbolTableCompilerTest::Foo)
            extend(::SymbolTableCompilerTest::Toto)
          end

          class SymbolTableCompilerTest::Baz
            def baz; end
          end

          module SymbolTableCompilerTest::Foo
            def foo; end
          end

          module SymbolTableCompilerTest::Toto
            def toto; end
          end

          module SymbolTableCompilerTest::Tutu
            def tutu; end
          end
        RUBY
      )
    end

    it("compiles Structs, Classes, and Modules") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
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
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::C1
          end

          class SymbolTableCompilerTest::C2
            def foo; end
          end

          class SymbolTableCompilerTest::C3
          end

          module SymbolTableCompilerTest::M1
          end

          module SymbolTableCompilerTest::M2
            def foo; end
          end

          module SymbolTableCompilerTest::M3
          end

          class SymbolTableCompilerTest::S1 < ::Struct
          end

          class SymbolTableCompilerTest::S2 < ::Struct
            def foo; end
            def foo=(_); end

            def self.[](*_); end
            def self.inspect; end
            def self.members; end
            def self.new(*_); end
          end

          class SymbolTableCompilerTest::S3 < ::Struct
            def foo; end
            def foo=(_); end

            def self.[](*_); end
            def self.inspect; end
            def self.members; end
            def self.new(*_); end
          end

          class SymbolTableCompilerTest::S4 < ::Struct
          end
        RUBY
      )
    end

    it("handles dynamic mixins") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
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
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Bar
            include(::SymbolTableCompilerTest::Baz)
            include(::SymbolTableCompilerTest::Foo)

            def self.abc; end
          end

          module SymbolTableCompilerTest::Baz
          end

          module SymbolTableCompilerTest::Foo
          end
        RUBY
      )
    end

    it("compiles methods on the class's singleton class") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Bar
              def self.num(a)
                a
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Bar
            def self.num(a); end
          end
        RUBY
      )
    end

    it("doesn't compile non-static singleton class reopening") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Bar
              obj = Object.new

              class << obj
                define_method(:foo) {}
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Bar
          end
        RUBY
      )
    end

    it("ignores methods on other objects") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Bar
              a = Object.new

              def a.num(a)
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Bar
          end
        RUBY
      )
    end

    it("compiles a singleton class") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Bar
              class << self
                def num(a)
                end
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Bar
            def self.num(a); end
          end
        RUBY
      )
    end

    it("compiles blocks") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Bar
              def size(&block)
              end

              def unwrap(&block)
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Bar
            def size(&block); end
            def unwrap(&block); end
          end
        RUBY
      )
    end

    it("compiles attr_reader/attr_writer/attr_accessor") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Bar
              attr_reader(:foo)

              attr_accessor(:bar)

              attr_writer(:baz)

              attr_reader(:a, :b)
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Bar
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
          module SymbolTableCompilerTest
            class Bar
              define_method("foo") do
                :foo
              end

              define_method("invalid_method_name?=") do
                1
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Bar
            def foo; end
          end
        RUBY
      )
    end

    it("ignores method calls") do
      expect(
        compile(<<~RUBY)
          require_relative("./foo")

          module SymbolTableCompilerTest
            class Bar
              def self.a
                2
              end

              a + 1
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Bar
            def self.a; end
          end
        RUBY
      )
    end

    it("ignores loops") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
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
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Toto
          end
        RUBY
      )
    end

    it("renames unnamed splats") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Toto
              def toto(a, *, **)
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Toto
            def toto(a, *_, **_); end
          end
        RUBY
      )
    end

    it("ignores ivar and cvar assigns") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            module Foo
              @@mod_var = 1
              @ivar = 2
              @ivar ||= 1
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          module SymbolTableCompilerTest::Foo
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

          module SymbolTableCompilerTest
            module Foo
            end

            obj = Object.new

            Dir.glob(File.join('yard', 'core_ext', '*.rb')).each do |file|
              require file
            rescue LoadError
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
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          module SymbolTableCompilerTest::Foo
          end
        RUBY
      )
    end

    it("compiles methods of all visibility for classes") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
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
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Bar
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
          module SymbolTableCompilerTest
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
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
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
          module SymbolTableCompilerTest
            class Bar
              a = b = c = 1
              a
              b
              c
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Bar
          end
        RUBY
      )
    end

    it("compiles initialize") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Bar
              def initialize
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Bar
            def initialize; end
          end
        RUBY
      )
    end

    it("understands redefined attr_accessor") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
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
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Toto
            def foo; end
            def foo=(the_foo); end
          end
        RUBY
      )
    end

    it("handles inheritance properly when the parent is a method call") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Bar; end

            def self.foo(x)
              x
            end

            class Toto < foo(Bar)
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
            def self.foo(x); end
          end

          class SymbolTableCompilerTest::Bar
          end

          class SymbolTableCompilerTest::Toto < ::SymbolTableCompilerTest::Bar
          end
        RUBY
      )
    end

    it("handles multiple assign of constants") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            module Toto
              A, B, C, *D, e = "1.2.3.4".split(".")
              NUMS = [A, B, C, *D]
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          module SymbolTableCompilerTest::Toto
          end

          SymbolTableCompilerTest::Toto::A = T.let(T.unsafe(nil), String)

          SymbolTableCompilerTest::Toto::B = T.let(T.unsafe(nil), String)

          SymbolTableCompilerTest::Toto::C = T.let(T.unsafe(nil), String)

          SymbolTableCompilerTest::Toto::D = T.let(T.unsafe(nil), Array)

          SymbolTableCompilerTest::Toto::NUMS = T.let(T.unsafe(nil), Array)
        RUBY
      )
    end

    it("handles constants that override #!") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            class Hostile
              class << self
                def !
                  self
                end
              end
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          class SymbolTableCompilerTest::Hostile
            def self.!; end
          end
        RUBY
      )
    end

    it("handles ranges properly") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            module Toto
              A = ('a'...'z')
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          module SymbolTableCompilerTest::Toto
          end

          SymbolTableCompilerTest::Toto::A = T.let(T.unsafe(nil), T::Range[String])
        RUBY
      )
    end

    it("doesn't output prepend for modules unrechable via constants") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            module Foo
            end

            class << Foo
              module Bar
                def hi  # unfortunately we miss out on this
                end
              end

              prepend(Bar)
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          module SymbolTableCompilerTest::Foo
          end
        RUBY
      )
    end

    it("doesn't output include for modules unrechable via constants") do
      expect(
        compile(<<~RUBY)
          module SymbolTableCompilerTest
            module Foo
            end

            class << Foo
              module Bar
                def hi  # unfortunately we miss out on this
                end
              end

              include(Bar)
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module SymbolTableCompilerTest
          end

          module SymbolTableCompilerTest::Foo
          end
        RUBY
      )
    end

    it("can handle BasicObjects") do
      expect(
        compile(<<~RUBY)
          class SymbolTableCompilerTest
            module BasicObjectTest
              class B < ::BasicObject
              end

              Basic = B.new
              VeryBasic = ::BasicObject.new
            end
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          class SymbolTableCompilerTest
          end

          module SymbolTableCompilerTest::BasicObjectTest
          end

          class SymbolTableCompilerTest::BasicObjectTest::B < ::BasicObject
          end

          SymbolTableCompilerTest::BasicObjectTest::Basic = T.let(T.unsafe(nil), SymbolTableCompilerTest::BasicObjectTest::B)

          SymbolTableCompilerTest::BasicObjectTest::VeryBasic = T.let(T.unsafe(nil), BasicObject)
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

          module SymbolTableCompilerTest
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
          end
        RUBY
      ).to(
        eq(<<~RUBY.chomp)
          module ActiveSupport
          end

          module ActiveSupport::Concern
          end

          module SymbolTableCompilerTest
          end

          module SymbolTableCompilerTest::BarConcern
            extend(::ActiveSupport::Concern)
          end

          SymbolTableCompilerTest::BarConcern::ClassMethods = T.let(T.unsafe(nil), Integer)

          module SymbolTableCompilerTest::FooConcern
            extend(::ActiveSupport::Concern)

            mixes_in_class_methods(ClassMethods)

            def a_normal_method; end
          end

          module SymbolTableCompilerTest::FooConcern::ClassMethods
            def wow_a_class_method; end
          end
        RUBY
      )
    end
  end
end
