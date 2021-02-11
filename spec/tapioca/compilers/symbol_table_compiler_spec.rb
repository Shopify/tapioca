# typed: strict
# frozen_string_literal: true

require "spec_helper"
require "pathname"
require "tmpdir"
require "bundler"

class Tapioca::Compilers::SymbolTableCompilerSpec < Minitest::HooksSpec
  include ContentHelper
  include TemplateHelper
  include IsolationHelper

  describe("compile") do
    sig { returns(String) }
    def compile
      stub = Struct.new(:name, :version, :platform, :full_gem_path, :full_require_paths)
        .new("the-dep", "1.1.2", nil, tmp_path, [tmp_path("lib")])

      spec = Bundler::StubSpecification.from_stub(stub)
      gem = Tapioca::Gemfile::Gem.new(spec)

      Tapioca::Compilers::SymbolTableCompiler.new.compile(gem)
    end

    it("compiles DelegateClass") do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
        end
      RUBY

      add_ruby_file("foo.rb", <<~RUBY)
        class Foo < DelegateClass(Bar)
        end
      RUBY

      output = template(<<~RBI)
        class Bar
        end

        class Foo
        end
      RBI

      assert_equal(output, compile)
    end

    it("does not compile Sorbet related constants") do
      add_ruby_file("bar.rb", <<~RUBY)
        module Bar
          extend(::T::Sig)
          extend(::T::Helpers)
          extend(T::Generic)

          Elem = type_member(fixed: Integer)

          interface!

          Arr = T.let([1,2,3], T::Array[Integer])
          Foo = ::T.type_alias { T.any(String, Symbol) }
        end
      RUBY

      output = template(<<~RBI)
        module Bar
          interface!
        end

        Bar::Arr = T.let(T.unsafe(nil), Array)
      RBI

      assert_equal(output, compile)
    end

    it("compiles extensions to BasicObject and Object") do
      add_ruby_file("ext.rb", <<~RUBY)
        class BasicObject
          def hello
          end
        end

        class Object
          def hello
          end
        end
      RUBY

      output = template(<<~RBI)
        class BasicObject
          def hello; end
        end

        class Object < ::BasicObject
          include(::Kernel)

          def hello; end
        end
      RBI

      compiled = compile
        .gsub(/^\s+include\(::Minitest::Expectations\)\s/, "")
        .gsub(/^\s+include\(::JSON::Ext::Generator::GeneratorMethods::Object\)\s/, "")
        .gsub(/^\s+include\(::PP::ObjectMixin\)\s/, "")

      assert_equal(output, compiled)
    end

    it("compiles mixins in the correct order") do
      add_ruby_file("bar.rb", <<~RUBY)
        module ModuleA
        end

        module ModuleB
        end

        module ModuleC
        end

        class Bar
          include ModuleA
          include ModuleB
          include ModuleC

          extend ModuleC
          extend ModuleB
          extend ModuleA
        end
      RUBY

      output = template(<<~RBI)
        class Bar
          include(::ModuleA)
          include(::ModuleB)
          include(::ModuleC)
          extend(::ModuleC)
          extend(::ModuleB)
          extend(::ModuleA)
        end

        module ModuleA
        end

        module ModuleB
        end

        module ModuleC
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles classes that have overridden == method that errors") do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          def self.==(other)
            raise RuntimeError
          end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          class << self
            def ==(other); end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles classes defined as static fields") do
      add_ruby_file("symbol_table_compiler_test.rb", <<~RUBY)
        SymbolTableCompilerTest = Class.new
      RUBY

      output = template(<<~RBI)
        class SymbolTableCompilerTest
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles extensions to core types") do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          def to_s
            "Foo"
          end
          def bar
            "bar"
          end
        end
      RUBY

      add_ruby_file("ext.rb", <<~RUBY)
        class String
          def to_foo(base = "def")
            "abc" + base
          end
        end

        class Hash
          def to_bar
            {}
          end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          def bar; end
          def to_s; end
        end

        class Hash
          include(::Enumerable)
          include(::JSON::Ext::Generator::GeneratorMethods::Hash)

          def to_bar; end
        end

        class String
          include(::Comparable)
          include(::JSON::Ext::Generator::GeneratorMethods::String)
          include(::Colorize::InstanceMethods)
          extend(::JSON::Ext::Generator::GeneratorMethods::String::Extend)
          extend(::Colorize::ClassMethods)

          def to_foo(base = T.unsafe(nil)); end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles without annotations") do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          def num(a)
            foo
          end
        end
      RUBY

      output = template(<<~RBI)
        class Bar
          def num(a); end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles methods and leaves spacing") do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          def num
          end

          def bar
          end
        end
      RUBY

      output = template(<<~RBI)
        class Bar
          def bar; end
          def num; end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles constants assignments") do
      add_ruby_file("a.rb", <<~RUBY)
        module A
          ABC = 1
          DEF = ABC.to_s
        end
      RUBY

      output = template(<<~RBI)
        module A
        end

        <% if ruby_version(">= 2.4.0") %>
        A::ABC = T.let(T.unsafe(nil), Integer)
        <% else %>
        A::ABC = T.let(T.unsafe(nil), Fixnum)
        <% end %>

        A::DEF = T.let(T.unsafe(nil), String)
      RBI

      assert_equal(output, compile)
    end

    it("compiles simple arguments") do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          def add(a, b:)
          end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          def add(a, b:); end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles default arguments") do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          def add(a = nil, b: 1)
          end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          def add(a = T.unsafe(nil), b: T.unsafe(nil)); end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles modules") do
      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
          # @return [Integer] a number
          def num(a)
          end
        end
      RUBY

      output = template(<<~RBI)
        module Foo
          def num(a); end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles compact SymbolTableCompilerTests") do
      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
        end

        module Foo::Bar
          def num(a)
          end
        end
      RUBY

      output = template(<<~RBI)
        module Foo
        end

        module Foo::Bar
          def num(a); end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles nested namespaces") do
      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
          class Bar
            def num(a)
            end
          end
        end
      RUBY

      output = template(<<~RBI)
        module Foo
        end

        class Foo::Bar
          def num(a); end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles compact namespaces nested") do
      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
          module Bar
          end
          class Bar::Baz
            def num(a)
            end
          end
        end
      RUBY

      output = template(<<~RBI)
        module Foo
        end

        module Foo::Bar
        end

        class Foo::Bar::Baz
          def num(a); end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles deeply nested namespaces") do
      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
          class Bar
            class Baz
              def num(a)
              end
            end
          end
        end
      RUBY

      output = template(<<~RBI)
        module Foo
        end

        class Foo::Bar
        end

        class Foo::Bar::Baz
          def num(a); end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles a class with a superclass") do
      add_ruby_file("baz.rb", <<~RUBY)
        class Baz
          def toto
          end
        end
      RUBY

      add_ruby_file("bar.rb", <<~RUBY)
        class Bar < Baz
        end
      RUBY

      output = template(<<~RBI)
        class Bar < ::Baz
        end

        class Baz
          def toto; end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles a class with a relative superclass") do
      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
          class Baz
          end
          class Bar < Baz
          end
        end
      RUBY

      output = template(<<~RBI)
        module Foo
        end

        class Foo::Bar < ::Foo::Baz
        end

        class Foo::Baz
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles a class alias that is pointing to a constant which has been overwritten") do
      add_ruby_file("baz.rb", <<~RUBY)
        class HTTPClient
          module CookieManager
          end
        end

        class WebMockHTTPClient < HTTPClient
        end

        HTTPClient = WebMockHTTPClient

        class WebAgent
          CookieManager = ::HTTPClient::CookieManager
        end
      RUBY

      output = template(<<~RBI)
        HTTPClient = WebMockHTTPClient

        class WebAgent
        end

        WebAgent::CookieManager = HTTPClient::CookieManager

        class WebMockHTTPClient
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles a constant which is aliased to a constant that has been overwritten as a placeholder") do
      add_ruby_file("overwritten_class_module_references.rb", <<~RUBY)
        class MyClient
        end

        module MyModule
        end

        module SomeModule
          # The test above doesn't catch this because the names are different
          OriginalClient = ::MyClient
          OriginalModule = ::MyModule
        end

        class MockClient < MyClient
        end

        module MockModule
        end

        MyClient = MockClient
        MyModule = MockModule
      RUBY

      output = template(<<~RBI)
        class MockClient
        end

        module MockModule
        end

        MyClient = MockClient

        MyModule = MockModule

        module SomeModule
        end

        SomeModule::OriginalClient = Class.new

        SomeModule::OriginalModule = Module.new
      RBI

      assert_equal(output, compile)
    end

    it("compiles a class with an anchored superclass") do
      add_ruby_file("baz.rb", <<~RUBY)
        class Baz
        end
      RUBY

      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
          class Bar < ::Baz
          end
        end
      RUBY

      output = template(<<~RBI)
        class Baz
        end

        module Foo
        end

        class Foo::Bar < ::Baz
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles a class with an private superclass") do
      add_ruby_file("toto.rb", <<~RUBY)
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

      output = template(<<~RBI)
        module Toto
        end

        module Toto::Foo
        end

        class Toto::Foo::Bar
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles constants that have a hash method on the constant which does not return an Integer") do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          class << self
            def hash
              {}
            end
          end

          module Bar
            def self.hash
              {}
            end
          end

          class Baz
            def self.hash
              {}
            end
          end
        end
      RUBY

      output = <<~RBI
        class Foo
          class << self
            def hash; end
          end
        end

        module Foo::Bar
          class << self
            def hash; end
          end
        end

        class Foo::Baz
          class << self
            def hash; end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles constants that have horrible eql? or equal? overrides") do
      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
          module Bar
            def self.equal?
              raise RuntimeError
            end
          end

          class Baz
            def self.eql?
              raise RuntimeError
            end
          end
        end
      RUBY

      output = <<~RBI
        module Foo
        end

        module Foo::Bar
          class << self
            def equal?; end
          end
        end

        class Foo::Baz
          class << self
            def eql?; end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles a class which effectively has itself as a superclass") do
      add_ruby_file("foo.rb", <<~RUBY)
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

      output = template(<<~RBI)
        module Foo
          class << self
            def const_missing(name); end
          end
        end

        class Foo::Bar < ::Numeric
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles a class with mixins") do
      add_ruby_file("baz.rb", <<~RUBY)
        class Baz
          def baz
          end
        end
      RUBY

      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
          def foo
          end
        end
        RUBY

      add_ruby_file("toto.rb", <<~RUBY)
        module Toto
          def toto
          end
        end
      RUBY

      add_ruby_file("tutu.rb", <<~RUBY)
        module Tutu
          def tutu
          end
        end
      RUBY

      add_ruby_file("bar.rb", <<~RUBY)
        class Bar < Baz
          include Foo
          extend Toto
          prepend Tutu
        end
      RUBY

      output = template(<<~RBI)
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
      RBI

      assert_equal(output, compile)
    end

    it("compiles Structs, Classes, and Modules") do
      add_ruby_file("structs.rb", <<~RUBY)
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

      output = template(<<~RBI)
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

          class << self
            def [](*_arg0); end
        <% if ruby_version(">= 2.5.0") %>
            def inspect; end
        <% end %>
            def members; end
            def new(*_arg0); end
          end
        end

        class S3 < ::Struct
          def foo; end
          def foo=(_); end

          class << self
            def [](*_arg0); end
        <% if ruby_version(">= 2.5.0") %>
            def inspect; end
        <% end %>
            def members; end
            def new(*_arg0); end
          end
        end

        class S4 < ::Struct
        end
      RBI

      assert_equal(output, compile)
    end

    it("handles dynamic mixins") do
      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
        end
      RUBY

      add_ruby_file("baz.rb", <<~RUBY)
        module Baz
        end
      RUBY

      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          def self.abc
            Baz
          end

          include(Module.new, Foo)
          include(abc)
        end
      RUBY

      output = template(<<~RBI)
        class Bar
          include(::Foo)
          include(::Baz)

          class << self
            def abc; end
          end
        end

        module Baz
        end

        module Foo
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles methods on the class's singleton class") do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          def self.num(a)
            a
          end
        end
      RUBY

      output = template(<<~RBI)
        class Bar
          class << self
            def num(a); end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it("doesn't compile non-static singleton class reopening") do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          obj = Object.new

          class << obj
            define_method(:foo) {}
          end
        end
      RUBY

      output = template(<<~RBI)
        class Bar
        end
      RBI

      assert_equal(output, compile)
    end

    it("ignores methods on other objects") do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          a = Object.new

          def a.num(a)
          end
        end
      RUBY

      output = template(<<~RBI)
        class Bar
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles a singleton class") do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          class << self
            def num(a)
            end
          end
        end
      RUBY

      output = template(<<~RBI)
        class Bar
          class << self
            def num(a); end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles blocks") do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          def size(&block)
          end

          def unwrap(&block)
          end
        end
      RUBY

      output = template(<<~RBI)
        class Bar
          def size(&block); end
          def unwrap(&block); end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles attr_reader/attr_writer/attr_accessor") do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          attr_reader(:foo)

          attr_accessor(:bar)

          attr_writer(:baz)

          attr_reader(:a, :b)
        end
      RUBY

      output = template(<<~RBI)
        class Bar
          def a; end
          def b; end
          def bar; end
          def bar=(_arg0); end
          def baz=(_arg0); end
          def foo; end
        end
      RBI

      assert_equal(output, compile)
    end

    it("ignores methods with invalid names") do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          define_method("foo") do
            :foo
          end

          define_method("invalid_method_name?=") do
            1
          end
        end
      RUBY

      output = template(<<~RBI)
        class Bar
          def foo; end
        end
      RBI

      assert_equal(output, compile)
    end

    it("ignores method calls") do
      add_ruby_file("foo.rb", "", require_file: false)

      add_ruby_file("bar.rb", <<~RUBY)
        require_relative("./foo")

        class Bar
          def self.a
            2
          end

          a + 1
        end
      RUBY

      output = template(<<~RBI)
        class Bar
          class << self
            def a; end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it("ignores loops") do
      add_ruby_file("toto.rb", <<~RUBY)
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

      output = template(<<~RBI)
        class Toto
        end
      RBI

      assert_equal(output, compile)
    end

    it("renames unnamed splats") do
      add_ruby_file("toto.rb", <<~RUBY)
        class Toto
          def toto(a, *, **)
          end
        end
      RUBY

      output = template(<<~RBI)
        class Toto
          def toto(a, *_arg1, **_arg2); end
        end
      RBI

      assert_equal(output, compile)
    end

    it("ignores ivar and cvar assigns") do
      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
          @@mod_var = 1
          @ivar = 2
          @ivar ||= 1
        end
      RUBY

      output = template(<<~RBI)
        module Foo
        end
      RBI

      assert_equal(output, compile)
    end

    it("ignores things done in the file body") do
      add_ruby_file("foo.rb", <<~RUBY)
        begin
          require "no_existent"
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

      output = template(<<~RBI)
        module Foo
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles methods of all visibility for classes") do
      add_ruby_file("bar.rb", <<~RUBY)
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

          class << self
            def fim
            end

            protected

            def fom
            end

            private

            def fum
            end
          end

          protected(def pc; end)
        end
      RUBY

      output = template(<<~RBI)
        class Bar
          def tutu; end

          protected

          def num(a); end
          def pc; end

          private

          def foo(b); end
          def toto; end

          class << self
            def fim; end

            protected

            def fom; end

            private

            def fum; end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles methods of all visibility for modules") do
      add_ruby_file("foo.rb", <<~RUBY)
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

      output = template(<<~RBI)
        module Foo
          def tutu; end

          protected

          def num(a); end
          def pc; end

          private

          def foo(b); end
          def toto; end
        end
      RBI

      assert_equal(output, compile)
    end

    it("removes useless spacing") do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          a = b = c = 1
          a
          b
          c
        end
      RUBY

      output = template(<<~RBI)
        class Bar
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles initialize") do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          def initialize
          end
        end
      RUBY

      output = template(<<~RBI)
        class Bar
          def initialize; end
        end
      RBI

      assert_equal(output, compile)
    end

    it("understands redefined attr_accessor") do
      add_ruby_file("toto.rb", <<~RUBY)
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

      output = template(<<~RBI)
        class Toto
          def foo; end
          def foo=(the_foo); end
        end
      RBI

      assert_equal(output, compile)
    end

    it("handles inheritance properly when the parent is a method call") do
      add_ruby_file("baz.rb", <<~RUBY)
        module Baz
          class Bar; end

          def self.foo(x)
            x
          end

          class Toto < foo(Bar)
          end
        end
      RUBY

      output = template(<<~RBI)
        module Baz
          class << self
            def foo(x); end
          end
        end

        class Baz::Bar
        end

        class Baz::Toto < ::Baz::Bar
        end
      RBI

      assert_equal(output, compile)
    end

    it("handles multiple assign of constants") do
      add_ruby_file("toto.rb", <<~RUBY)
        module Toto
          A, B, C, *D, e = "1.2.3.4".split(".")
          NUMS = [A, B, C, *D]
        end
      RUBY

      output = template(<<~RBI)
        module Toto
        end

        Toto::A = T.let(T.unsafe(nil), String)

        Toto::B = T.let(T.unsafe(nil), String)

        Toto::C = T.let(T.unsafe(nil), String)

        Toto::D = T.let(T.unsafe(nil), Array)

        Toto::NUMS = T.let(T.unsafe(nil), Array)
      RBI

      assert_equal(output, compile)
    end

    it("handles constants that override #!") do
      add_ruby_file("hostile.rb", <<~RUBY)
        class Hostile
          class << self
            def !
              self
            end
          end
        end
      RUBY

      output = template(<<~RBI)
        class Hostile
          class << self
            def !; end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it("handles ranges properly") do
      add_ruby_file("toto.rb", <<~RUBY)
        module Toto
          A = ('a'...'z')
        end
      RUBY

      output = template(<<~RBI)
        module Toto
        end

        Toto::A = T.let(T.unsafe(nil), Range)
      RBI

      assert_equal(output, compile)
    end

    it("doesn't output prepend for modules unrechable via constants") do
      add_ruby_file("foo.rb", <<~RUBY)
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

      output = template(<<~RBI)
        module Foo
        end
      RBI

      assert_equal(output, compile)
    end

    it("doesn't output include for modules unrechable via constants") do
      add_ruby_file("foo.rb", <<~RUBY)
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

      output = template(<<~RBI)
        module Foo
        end
      RBI

      assert_equal(output, compile)
    end

    it("can handle BasicObjects") do
      add_ruby_file("basic_object_test.rb", <<~RUBY)
        module BasicObjectTest
          class B < ::BasicObject
          end

          Basic = B.new
          VeryBasic = ::BasicObject.new
        end
      RUBY

      output = template(<<~RBI)
        module BasicObjectTest
        end

        class BasicObjectTest::B < ::BasicObject
        end

        BasicObjectTest::Basic = T.let(T.unsafe(nil), BasicObjectTest::B)

        BasicObjectTest::VeryBasic = T.let(T.unsafe(nil), BasicObject)
      RBI

      assert_equal(output, compile)
    end

    it("adds mixes_in_class_methods to modules that extend base classes") do
      add_ruby_file("concern.rb", <<~RUBY)
        module Concern
          def included(base)
            base.extend(const_get(:CustomClassMethods)) if const_defined?(:CustomClassMethods)
          end
        end
      RUBY

      add_ruby_file("foo_concern.rb", <<~RUBY)
        module FooConcern
          extend(Concern)

          module CustomClassMethods
            def wow_a_class_method
              "something"
            end
          end

          def a_normal_method
            123
          end
        end
      RUBY

      add_ruby_file("bar_concern.rb", <<~RUBY)
        module BarConcern
          module Something
            def another_class_method
              "super awesome"
            end
          end

          class << self
            private

            def included(base)
              base.extend(Something)
            end
          end
        end
      RUBY

      add_ruby_file("some_other_concern.rb", <<~RUBY)
        module SomeOtherConcern
          def included(base)
            base.include(FooConcern)
            base.include(BarConcern)
          end
        end
      RUBY

      add_ruby_file("baz.rb", <<~RUBY)
        module Baz
          extend SomeOtherConcern
        end
      RUBY

      output = template(<<~RBI)
        module BarConcern
          mixes_in_class_methods(::BarConcern::Something)

          class << self

            private

            def included(base); end
          end
        end

        module BarConcern::Something
          def another_class_method; end
        end

        module Baz
          extend(::SomeOtherConcern)

          include(::FooConcern)
          include(::BarConcern)
        end

        module Concern
          def included(base); end
        end

        module FooConcern
          extend(::Concern)

          mixes_in_class_methods(::FooConcern::CustomClassMethods)

          def a_normal_method; end
        end

        module FooConcern::CustomClassMethods
          def wow_a_class_method; end
        end

        module SomeOtherConcern
          def included(base); end
        end
      RBI

      assert_equal(output, compile)
    end

    it("adds mixes_in_class_methods(ClassMethods) to modules that extend from ActiveSuport::Concern") do
      add_ruby_file("active_support/concern.rb", <<~RUBY)
        module ActiveSupport
          module Concern
            def included(base = nil, &block)
              if base.nil?
                @_included_block = block
              else
                base.extend(const_get(:ClassMethods)) if const_defined?(:ClassMethods)
                base.class_eval(&@_included_block) if instance_variable_defined?(:@_included_block)
                super
              end
            end
          end
        end
      RUBY

      add_ruby_file("active_model/validations.rb", <<~RUBY)
        module ActiveModel
          module Validations
            module HelperMethods
            end

            module ClassMethods
            end

            extend ActiveSupport::Concern

            included do
              extend  HelperMethods
              include HelperMethods
            end
          end
        end
      RUBY

      output = template(<<~RBI)
        module ActiveModel
        end

        module ActiveModel::Validations
          extend(::ActiveSupport::Concern)

          include(::ActiveModel::Validations::HelperMethods)

          mixes_in_class_methods(::ActiveModel::Validations::ClassMethods)
        end

        module ActiveModel::Validations::ClassMethods
        end

        module ActiveModel::Validations::HelperMethods
        end

        module ActiveSupport
        end

        module ActiveSupport::Concern
          def included(base = T.unsafe(nil), &block); end
        end
      RBI

      assert_equal(output, compile)
    end

    it("properly treats pre-Rails 6.1 ActiveSupport::Deprecation::DeprecatedConstantProxy instances") do
      add_ruby_file("active_support/deprecation/deprecation_proxy.rb", <<~RUBY)
        module ActiveSupport
          class Deprecation
            class DeprecationProxy #:nodoc:
              def self.new(*args, &block)
                object = args.first

                return object unless object
                super
              end

              instance_methods.each { |m| undef_method m unless /^__|^object_id$/.match(m) }

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
      RUBY

      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          def self.name
            "SomethingElse"
          end
        end

        Bar = ActiveSupport::Deprecation::DeprecatedConstantProxy.new("Bar", "Foo")
      RUBY

      output = template(<<~RBI)
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

          class << self
            def new(*args, &block); end
          end
        end

        Bar = T.let(T.unsafe(nil), ActiveSupport::Deprecation::DeprecatedConstantProxy)

        class Foo
          class << self
            def name; end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it("properly treats Rails 6.1 ActiveSupport::Deprecation::DeprecatedConstantProxy instances") do
      add_ruby_file("active_support/deprecation/deprecation_proxy.rb", <<~RUBY)
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

              instance_methods.each { |m| undef_method m unless /^__|^object_id$/.match(m) }

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
      RUBY

      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          def self.name
            "SomethingElse"
          end
        end

        Bar = ActiveSupport::Deprecation::DeprecatedConstantProxy.new("Bar", "Foo")
      RUBY

      output = template(<<~RBI)
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

          class << self
            def new(*args, &block); end
          end
        end

        Bar = Foo

        class Foo
          class << self
            def name; end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it("properly filters out T::Private modules") do
      add_ruby_file("foo.rb", <<~RUBY)
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

      output = template(<<~RBI)
        class Foo
          class << self
            def name; end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it("doesn't crash when `singleton_class` is overloaded") do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          module Bar

            private

            def singleton_class(klass)
              class << klass; self; end
            end
          end

          class << self
            include Bar
          end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          extend(::Foo::Bar)
        end

        module Foo::Bar

          private

          def singleton_class(klass); end
        end
      RBI

      assert_equal(output, compile)
    end

    it("sanitize parameter names created through meta-programming") do
      add_ruby_file("foo.rb", template(<<~RUBY))
        class Foo
        <% if ruby_version(">= 2.7.0") %>
          module_eval("def foo(...); end")
        <% end %>
        end
      RUBY

      output = template(<<~RBI)
        class Foo
        <% if ruby_version(">= 2.7.0") %>
          def foo(*_arg0, &_arg1); end
        <% end %>
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles signatures and structs in source files") do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          extend(T::Sig)

          sig { params(a: Integer, b: String).void }
          def foo(a, b:)
          end

          sig { params(a: Integer, b: String).returns(Integer) }
          def bar(a, b:)
          end

          sig { type_parameters(:U).params(a: T.type_parameter(:U)).returns(T.type_parameter(:U)) }
          def baz(a)
            a
          end

          sig { params(a: Integer, b: Integer, c: Integer, d: Integer, e: Integer, f: Integer, blk: T.proc.void).void }
          def many_kinds_of_args(*a, b, c, d:, e: 42, **f, &blk)
          end

          class << self
            extend(T::Sig)

            sig { void }
            def quux
            end
          end
        end
      RUBY

      add_ruby_file("bar.rb", <<~RUBY)
        class Bar < T::Struct
          const :foo, Integer
          prop :bar, String
          const :baz, T::Hash[String, T.untyped]
          prop :quux, T.untyped, default: [1, 2, 3]
        end
      RUBY

      add_ruby_file("buzz.rb", <<~RUBY)
        class Buzz
          include T::Props::Constructor
          extend T::Props::ClassMethods

          const :foo, Integer
          prop :bar, String
          const :baz, T.proc.params(arg0: String).void
        end
      RUBY

      add_ruby_file("baz.rb", <<~RUBY)
        class Baz
          extend(T::Sig)
          extend(T::Helpers)

          abstract!

          sig { abstract.void }
          def do_it
          end
        end
      RUBY

      add_ruby_file("quux.rb", <<~RUBY)
        module Quux
          extend(T::Sig)
          extend(T::Helpers)

          interface!

          sig { abstract.returns(Integer) }
          def something
          end

          class Concrete
            extend(T::Sig)
            include Quux

            sig { returns(T::Array[Integer]) }
            attr_accessor :foo

            sig { returns(String) }
            attr_reader :bar

            sig { params(baz: T::Hash[String, Object]).returns(T::Hash[String, Object]) }
            attr_writer :baz

            sig { override.returns(Integer) }
            def something
            end
          end
        end
      RUBY

      add_ruby_file("adt.rb", <<~RUBY)
        module Adt
          extend(T::Sig)
          extend(T::Helpers)

          interface!
          sealed!

          class Foo; include Adt; end
          class Bar; include Adt; end
        end
      RUBY

      output = template(<<~RBI)
        module Adt
          interface!
          sealed!
        end

        class Adt::Bar
          include(::Adt)
        end

        class Adt::Foo
          include(::Adt)
        end

        class Bar < ::T::Struct
          const :foo, Integer
          prop :bar, String
          const :baz, T::Hash[String, T.untyped]
          prop :quux, T.untyped, default: T.unsafe(nil)

          class << self
            def inherited(s); end
          end
        end

        class Baz
          abstract!

          def initialize(*args, &blk); end

          sig { abstract.void }
          def do_it; end
        end

        class Buzz
          const :foo, Integer
          prop :bar, String
          const :baz, T.proc.params(arg0: String).void
        end

        class Foo
          sig { params(a: Integer, b: String).returns(Integer) }
          def bar(a, b:); end
          sig { type_parameters(:U).params(a: T.type_parameter(:U)).returns(T.type_parameter(:U)) }
          def baz(a); end
          sig { params(a: Integer, b: String).void }
          def foo(a, b:); end
          sig { params(a: Integer, b: Integer, c: Integer, d: Integer, e: Integer, f: Integer, blk: T.proc.void).void }
          def many_kinds_of_args(*a, b, c, d:, e: T.unsafe(nil), **f, &blk); end

          class << self
            sig { void }
            def quux; end
          end
        end

        module Quux
          interface!

          sig { abstract.returns(Integer) }
          def something; end
        end

        class Quux::Concrete
          include(::Quux)

          sig { returns(String) }
          def bar; end
          sig { params(baz: T::Hash[String, Object]).returns(T::Hash[String, Object]) }
          def baz=(baz); end
          sig { returns(T::Array[Integer]) }
          def foo; end
          def foo=(_arg0); end
          sig { override.returns(Integer) }
          def something; end
        end
      RBI

      assert_equal(output, compile)
    end

    it("compiles structs with default values") do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo < T::Struct
          extend T::Sig

          prop :a, T.nilable(Integer), default: nil
          prop :b, T::Boolean, default: true
          prop :c, T::Boolean, default: false
          prop :d, Symbol, default: :Bar
          prop :e, String, default: "Foo"
          prop :f, Integer, default: 42
          prop :g, Float, default: 4.2
          prop :h, T::Array[String], default: ["1", "2"]
          prop :i, T::Hash[String, Integer], default: {"1": 1, "2": 2}

          prop :k, Foo, default: Foo.new(a: 10, h: ["a", "b"])
          prop :l, T::Array[Foo], default: [Foo.new(a: 10, h: ["a", "b"])]
          prop :m, T::Hash[Foo, Foo], default: {Foo.new(a: 10, h: ["a", "b"]) => Foo.new(a: 10, h: ["a", "b"])}
          prop :n, Foo, default: T.unsafe(nil)
        end
      RUBY

      output = template(<<~RBI)
        class Foo < ::T::Struct
          prop :a, T.nilable(Integer), default: T.unsafe(nil)
          prop :b, T::Boolean, default: T.unsafe(nil)
          prop :c, T::Boolean, default: T.unsafe(nil)
          prop :d, Symbol, default: T.unsafe(nil)
          prop :e, String, default: T.unsafe(nil)
          prop :f, Integer, default: T.unsafe(nil)
          prop :g, Float, default: T.unsafe(nil)
          prop :h, T::Array[String], default: T.unsafe(nil)
          prop :i, T::Hash[String, Integer], default: T.unsafe(nil)
          prop :k, Foo, default: T.unsafe(nil)
          prop :l, T::Array[Foo], default: T.unsafe(nil)
          prop :m, T::Hash[Foo, Foo], default: T.unsafe(nil)
          prop :n, Foo, default: T.unsafe(nil)

          class << self
            def inherited(s); end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it("skips signatures if they raise") do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          extend(T::Sig)

          sig { raise ArgumentError }
          def foo(a, b:)
          end

          sig { raise LoadError }
          def bar(a, b:)
          end

          sig { type_parameters(:U).params(a: T.type_parameter(:U)).returns(T.type_parameter(:U)) }
          def baz(a)
            a
          end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          def bar(*args, &blk); end
          sig { type_parameters(:U).params(a: T.type_parameter(:U)).returns(T.type_parameter(:U)) }
          def baz(a); end
          def foo(*args, &blk); end
        end
      RBI

      assert_equal(output, compile)
    end

    it("handles signatures with attached classes") do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          class FooAttachedClass; end
          class << self
            extend(T::Sig)

            sig { returns(T.attached_class) }
            def a
              Foo.new
            end

            sig { returns(T::Hash[T.attached_class, T::Array[T.attached_class]]) }
            def b
              { Foo.new => [Foo.new] }
            end

            sig { returns(FooAttachedClass) }
            def c
              FooAttachedClass.new
            end
          end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          class << self
            sig { returns(T.attached_class) }
            def a; end
            sig { returns(T::Hash[T.attached_class, T::Array[T.attached_class]]) }
            def b; end
            sig { returns(Foo::FooAttachedClass) }
            def c; end
          end
        end

        class Foo::FooAttachedClass
        end
      RBI

      assert_equal(output, compile)
    end
  end
end
