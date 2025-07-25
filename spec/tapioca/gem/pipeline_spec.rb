# typed: strict
# frozen_string_literal: true

require "spec_helper"
require "pathname"
require "tmpdir"
require "bundler"

class Tapioca::Gem::PipelineSpec < Minitest::HooksSpec
  include Tapioca::Helpers::Test::Content
  include Tapioca::Helpers::Test::Template
  include Tapioca::Helpers::Test::Isolation
  include Tapioca::SorbetHelper

  DEFAULT_GEM_NAME = "the-default-gem" #: String
  NO_UNHANDLED_PIPELINE_COMPILATION_ERRORS_MESSAGE = <<~MSG
    Tapioca::Gem::Pipeline#compile should not have any unhandled errors reported.
    Please either fix your changes to ensure no errors are reported, or explicity pass
    in a custom `error_handler: ->(err) { ... }` to the `compile()` method to handle
    expected errors.
  MSG

  private

  #: (?String gem_name, ?include_doc: bool, ?include_loc: bool, ?reported_errors_expected: bool) -> String
  def compile(gem_name = DEFAULT_GEM_NAME, include_doc: false, include_loc: false, reported_errors_expected: false)
    mock_gem_path = mock_gems[gem_name]

    # If we are compiling for a mock gem, we need to create a fake gemspec
    if mock_gem_path
      spec = ::Gem::Specification.new(gem_name, "1.0.0") do |spec|
        spec.platform = nil
        spec.full_gem_path = mock_gem_path
        spec.require_paths = ["lib"]
      end

      # add spec to the list of gem specification stubs
      Gem::Specification.add_spec(spec)
    end

    # wrap it in our gemspec wrapper
    gem = Tapioca::Gemfile::GemSpec.new(Gem::Specification.find_by_name(gem_name))

    # clear out previously reported errors
    reported_errors.clear

    # push it through the pipeline
    tree = Tapioca::Gem::Pipeline.new(
      gem,
      include_doc: include_doc,
      include_loc: include_loc,
      error_handler: ->(error) { reported_errors << error },
    ).compile

    # NOTE: This is not returning a `RBI::File`.
    # The following test suite is based on the string output of the `RBI::Tree` rather
    # than the, now used, `RBI::File`. The file output includes the sigils, comments, etc.
    # We should eventually update these tests to be based on the `RBI::File`.
    Tapioca::DEFAULT_RBI_FORMATTER.format_tree(tree)

    assert_empty(reported_errors, NO_UNHANDLED_PIPELINE_COMPILATION_ERRORS_MESSAGE) unless reported_errors_expected
    tree.string
  end

  #: (String gem_name) { -> void } -> void
  def mock_gem(gem_name, &block)
    current_tmp_path = tmp_path

    @tmp_path = mock_gems.fetch(gem_name) { mock_gems[gem_name] = Dir.mktmpdir }

    block.call
  ensure
    @tmp_path = current_tmp_path
  end

  #: -> Hash[String, String]
  def mock_gems
    @gems ||= {} #: Hash[String, String]?
    @gems[DEFAULT_GEM_NAME] = tmp_path if @gems.empty?
    @gems
  end

  #: -> Array[String]
  def reported_errors
    @reported_errors ||= [] #: Array[String]?
  end

  describe Tapioca::Gem::Pipeline do
    before do
      # We need to undefine and unload `ActiveSupport` so that the test object
      # space is as clean as possible.
      #
      # This is inside a `before` block instead of a `before(:all)` block because
      # it looks like `before(:all)` blocks run in the parent process, but we don't
      # want to mess with the object space of the parent process.
      if defined?(::ActiveSupport)
        Object.send(:remove_const, :ActiveSupport) # rubocop:disable RSpec/RemoveConst
        $LOADED_FEATURES.delete_if { |path| path.include?("active_support") }
      end
    end

    after do
      # clean up any lingering reported errors
      reported_errors.clear
    end

    it "compiles DelegateClass" do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
        end
      RUBY

      add_ruby_file("foo.rb", <<~RUBY)
        class Foo < DelegateClass(Bar)
        end
      RUBY

      output = template(<<~RBI)
        class Bar; end
        class Foo; end
      RBI

      assert_equal(output, compile)
    end

    it "does not compile Sorbet related constants" do
      add_ruby_file("bar.rb", <<~RUBY)
        module Bar
          extend(::T::Sig)
          extend(::T::Helpers)
          extend(T::Generic)

          Elem = type_template(:in) {{fixed: Integer}}
          K = type_member {{upper: Numeric}}
          V = type_member {{lower: String}}

          interface!

          Arr = T.let([1,2,3], T::Array[Integer])
          Foo = ::T.type_alias { T.any(String, Symbol) }
        end

        module Base
          include T::Props
          extend T::Helpers

          module Signatures
            include T::Props::ClassMethods
            include T::Sig
            include T::Helpers
          end

          mixes_in_class_methods Signatures
        end
      RUBY

      output = template(<<~RBI)
        module Bar
          extend T::Generic

          interface!

          Elem = type_template(:in) { { fixed: Integer } }
          K = type_member { { upper: Numeric } }
          V = type_member { { lower: String } }
        end

        Bar::Arr = T.let(T.unsafe(nil), Array)
        Bar::Foo = T.type_alias { T.any(::String, ::Symbol) }

        module Base
          include ::T::Props
          extend ::T::Props::ClassMethods

          mixes_in_class_methods ::Base::Signatures
        end

        module Base::Signatures
          include ::T::Props::ClassMethods
        end
      RBI

      assert_equal(output, compile)
    end

    it "correctly compiles abstract methods" do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          extend T::Sig
          extend T::Helpers

          abstract!

          sig { abstract.void }
          def foo; end
        end
      RUBY

      output = template(<<~RBI)
        class Bar
          abstract!

          sig { abstract.void }
          def foo; end
        end
      RBI

      assert_equal(output, compile)
    end

    it "correctly compiles abstract singleton methods" do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          extend T::Sig
          extend T::Helpers

          abstract!

          sig { abstract.void }
          def self.foo; end
        end
      RUBY

      output = template(<<~RBI)
        class Bar
          abstract!

          class << self
            sig { abstract.void }
            def foo; end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it "correctly compiles abstract singleton methods nested" do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          extend T::Helpers

          abstract!

          class << self
            extend T::Sig

            sig { abstract.void }
            def foo; end
          end
        end
      RUBY

      output = template(<<~RBI)
        class Bar
          abstract!

          class << self
            sig { abstract.void }
            def foo; end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it "correctly compiles abstract singleton methods all nested" do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          class << self
            extend T::Sig
            extend T::Helpers

            abstract!

            sig { abstract.void }
            def foo; end
          end
        end
      RUBY

      output = template(<<~RBI)
        class Bar
          abstract!

          class << self
            sig { abstract.void }
            def foo; end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it "correctly compiles new method definitions in classes and modules" do
      add_ruby_file("abstract.rb", <<~RUBY)
        module Foo
          extend T::Helpers

          abstract!
        end

        class Bar
          extend T::Helpers

          abstract!
        end

        class Baz
          def self.new(a, b)
          end
        end

        module Quux
          def self.new(a, b)
          end
        end
      RUBY

      output = template(<<~RBI)
        class Bar
          abstract!
        end

        class Baz
          class << self
            def new(a, b); end
          end
        end

        module Foo
          abstract!
        end

        module Quux
          class << self
            def new(a, b); end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it "compiles complex type aliases" do
      add_ruby_file("bar.rb", <<~RUBY)
        module Bar
          module A
            class B; end

            Foo = ::T.type_alias { T.any(String, Symbol, A, B) }
          end
        end
      RUBY

      output = template(<<~RBI)
        module Bar; end
        module Bar::A; end
        class Bar::A::B; end
        Bar::A::Foo = T.type_alias { T.any(::Bar::A, ::Bar::A::B, ::String, ::Symbol) }
      RBI

      assert_equal(output, compile)
    end

    it "compiles extensions to existing classes if it only adds to the singleton class" do
      add_ruby_file("json_ext.rb", <<~RUBY)
        module JSON
          def self.foo
          end
        end
      RUBY

      output = template(<<~RBI)
        module JSON
          class << self
            def foo; end
          end
        end
      RBI

      assert_includes(compile, output)
    end

    it "compiles extensions to BasicObject, Object and <main> object" do
      add_ruby_file("ext.rb", <<~RUBY)
        class BasicObject
          def hello
          end
        end

        class Object
          def hello
          end
        end

        # Addition to <main> object,
        # which should be a private method on Object
        def log
        end
      RUBY

      basic_object_output = template(<<~RBI)
        class BasicObject
          def hello; end
        end
      RBI

      object_output = template(<<~RBI)
        class Object < ::BasicObject
          include ::Kernel

          def hello; end

          private

          def log; end
        end
      RBI

      compiled = compile.gsub(/^\s+include ::PP::ObjectMixin\s/, "")

      assert_includes(compiled, basic_object_output)
      assert_includes(compiled, object_output)
    end

    it "compiles dynamic includes into Object" do
      add_ruby_file("ext.rb", <<~RUBY)
        module Foo
          # This class will trigger an include into
          # Object every time it is included. This will end
          # up triggering a mixin from `DynamicMixinCompiler`
          # which will mess up mixin attribution if we have
          # not disabled mixin tracking from dynamic mixin
          # compiler.
          module API
            def self.included(_mod)
              Object.send(:include, Foo::ObjectMethods)
            end
          end

          module ObjectMethods; end
        end

        module Bar
          include Foo::API
        end
      RUBY

      output = template(<<~RBI)
        class Object < ::BasicObject
          include ::Kernel
          include ::Foo::ObjectMethods
        end
      RBI

      compiled = compile.gsub(/^\s+include ::PP::ObjectMixin\s/, "")

      assert_includes(compiled, output)
    end

    it "must do mixin attribution properly when include occurs in other gem" do
      mock_gem("some_engine") do
        add_ruby_file("lib/some_engine.rb", <<~RUBY)
          require "action_controller"

          module SomeEngine
            class SomeController < ActionController::Base
              # This method triggers a dynamic mixin which should be attributed to this gem
              # and not actionpack, even though the real `include` happens inside actionpack
              helper_method :foo
            end
          end
        RUBY
      end

      output = template(<<~RBI)
        module SomeEngine; end

        class SomeEngine::SomeController < ::ActionController::Base
          private

          def _layout(lookup_context, formats); end

          class << self
            def _helper_methods; end
            def middleware_stack; end
          end
        end

        module SomeEngine::SomeController::HelperMethods
          include ::ActionController::Base::HelperMethods

          def foo(*args, **_arg1, &block); end
        end
      RBI

      assert_equal(output, compile("some_engine"))
    end

    it "must generate RBIs for constants defined in a different gem but with mixins in this gem" do
      mock_gem("foo") do
        add_ruby_file("lib/foo.rb", <<~RBI)
          class Foo
            def baz; end
            def buzz; end
          end
        RBI
      end

      mock_gem("bar") do
        add_ruby_file("lib/bar.rb", <<~RBI)
          module Bar; end

          Foo.prepend(Bar)
        RBI
      end

      output = <<~RBI
        module Bar; end

        class Foo
          include ::Bar
        end
      RBI

      assert_equal(output, compile("bar"))
    end

    it "must not generate RBIs for constants that have dynamic mixins performed in other gems" do
      mock_gem("bar") do
        add_ruby_file("lib/bar.rb", <<~RBI)
          module Bar; end
        RBI
      end

      mock_gem("foo") do
        add_ruby_file("lib/foo.rb", <<~RBI)
          class Foo; end
          String.prepend(Bar)
        RBI
      end

      output = <<~RBI
        module Bar; end
      RBI

      assert_equal(output, compile("bar"))
    end

    it "must generate RBIs for constants that have dynamic mixins performed in the gem" do
      mock_gem("bar") do
        add_ruby_file("lib/bar.rb", <<~RBI)
          class Bar
            def bar; end
          end
        RBI
      end

      mock_gem("foo") do
        add_ruby_file("lib/foo.rb", <<~RBI)
          module Foo; end
          class Baz < Bar; end

          Bar.prepend(Foo)
        RBI
      end

      output = <<~RBI
        class Bar
          include ::Foo
        end

        class Baz < ::Bar; end
        module Foo; end
      RBI

      assert_equal(output, compile("foo"))
    end

    it "properly attributes dynamically-generated methods" do
      mock_gem("bar") do
        add_ruby_file("lib/bar.rb", <<~RUBY)
          module ModuleFromBar
            def add_method_to_me(method_name)
              define_method(method_name) { 42 }
            end
          end
        RUBY
      end

      mock_gem("foo") do
        add_ruby_file("lib/foo.rb", <<~RUBY)
          class Foo
            extend ModuleFromBar

            def foo; end

            add_method_to_me :bar
          end
        RUBY
      end

      output = <<~RBI
        class Foo
          extend ::ModuleFromBar

          def bar; end
          def foo; end
        end
      RBI

      assert_equal(output, compile("foo"))
    end

    it "must generate RBIs for foreign constants whose singleton class overrides #inspect" do
      mock_gem("bar") do
        add_ruby_file("lib/bar.rb", <<~RBI)
          class Bar
            def self.inspect
              "Override!"
            end
          end
        RBI
      end

      mock_gem("foo") do
        add_ruby_file("lib/foo.rb", <<~RBI)
          module Foo; end

          Bar.singleton_class.include(Foo)
        RBI
      end

      output = <<~RBI
        class Bar
          extend ::Foo
        end

        module Foo; end
      RBI

      assert_equal(output, compile("foo"))
    end

    it "generates documentation only for the gem that defines it" do
      mock_gem("foo") do
        add_ruby_file("lib/foo.rb", <<~RB)
          # Most objects are cloneable
          class Object
            def foo; end
          end
        RB
      end
      mock_gem("bar") do
        add_ruby_file("lib/bar.rb", <<~RB)
          class Object
            def bar; end
          end
        RB
      end
      mock_gem("baz") do
        add_ruby_file("lib/baz.rb", <<~RB)
          def baz; end
        RB
      end

      documentation = <<~RBI
        # Most objects are cloneable
      RBI

      assert_includes(compile("foo", include_doc: true), documentation)
      refute_includes(compile("bar", include_doc: true), documentation)
      refute_includes(compile("baz", include_doc: true), documentation)
    end

    it "does not generate RBI if namespace contains alias from different gem" do
      mock_gem("foo") do
        add_ruby_file("lib/foo.rb", <<~RB)
          module Foo; end
          F = Foo
        RB
      end

      mock_gem("bar") do
        add_ruby_file("lib/bar.rb", <<~RB)
          module Foo
            module Bar; end
          end
          F::B = Foo::Bar
        RB
      end

      assert_equal(<<~RBI, compile("foo"))
        F = Foo
        module Foo; end
      RBI

      assert_equal(<<~RBI, compile("bar"))
        module Foo; end
        Foo::B = Foo::Bar
        module Foo::Bar; end
      RBI
    end

    it "must do mixin attribution properly" do
      # This is pattern is taken from the private `typed_parameters` gem.
      add_ruby_file("lib/typed_parameters.rb", <<~RUBY)
        require "action_controller"

        module TypedParameters
        end

        # This dynamic mixin should be generated in the gem RBI
        ActionController::Parameters.include(TypedParameters)
      RUBY

      # actionpack RBI should have nothing in it about `TypedParameters`
      refute_includes(compile("actionpack"), "TypedParameters")

      output = <<~RBI
        class ActionController::Parameters
          include ::TypedParameters
        end

        module TypedParameters; end
      RBI

      assert_equal(output, compile)
    end

    it "compiles mixins in the correct order" do
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
          include ::ModuleA
          include ::ModuleB
          include ::ModuleC
          extend ::ModuleC
          extend ::ModuleB
          extend ::ModuleA
        end

        module ModuleA; end
        module ModuleB; end
        module ModuleC; end
      RBI

      assert_equal(output, compile)
    end

    it "compiles classes that have overridden == method that errors" do
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

    it "compiles classes defined as static fields" do
      add_ruby_file("symbol_table_compiler_test.rb", <<~RUBY)
        SymbolTableCompilerTest = Class.new
      RUBY

      output = template(<<~RBI)
        class SymbolTableCompilerTest; end
      RBI

      assert_equal(output, compile)
    end

    it "compiles extensions to core types" do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          def to_s
            "Foo"
          end
          def bar
            "bar"
          end

          module Bar; end
        end
      RUBY

      add_ruby_file("ext.rb", <<~RUBY)
        class String
          include Foo::Bar

          def to_foo(base = "def")
            "abc" + base
          end
        end

        class Hash
          extend Foo::Bar

          def to_bar
            {}
          end
        end

        class Array
          prepend Foo::Bar

          def foo_int; end
        end

        class Symbol
          def bar; end
        end
      RUBY

      output = template(<<~RBI)
        class Array
          include ::Foo::Bar
          include ::Enumerable

          def foo_int; end
        end

        class Foo
          def bar; end
          def to_s; end
        end

        module Foo::Bar; end

        class Hash
          include ::Enumerable
          extend ::Foo::Bar

          def to_bar; end
        end

        class String
          include ::Comparable
          include ::Foo::Bar

          def to_foo(base = T.unsafe(nil)); end
        end

        class Symbol
          include ::Comparable

          def bar; end
        end
      RBI

      compiled = compile
        .gsub(/^\s+String::BLANK_RE = .+/, "")
        .gsub(/^\s+String::ENCODED_BLANKS = .+/, "")
        .rstrip.concat("\n")

      assert_equal(output, compiled)
    end

    it "compiles extensions to core types without adding methods" do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          def to_s
            "Foo"
          end

          def bar
            "bar"
          end

          module Bar; end
        end
      RUBY

      add_ruby_file("ext.rb", <<~RUBY)
        class String
          include Foo::Bar
        end

        class Hash
          extend Foo::Bar
        end

        class Array
          prepend Foo::Bar
        end
      RUBY

      output = template(<<~RBI)
        class Array
          include ::Foo::Bar
          include ::Enumerable
        end

        class Foo
          def bar; end
          def to_s; end
        end

        module Foo::Bar; end

        class Hash
          include ::Enumerable
          extend ::Foo::Bar
        end

        class String
          include ::Comparable
          include ::Foo::Bar
        end
      RBI

      assert_equal(output, compile)
    end

    it "compiles extensions to core types via #extend, #include, and #prepend methods" do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          def to_s
            "Foo"
          end

          def bar
            "bar"
          end

          module Bar; end
        end
      RUBY

      add_ruby_file("ext.rb", <<~RUBY)
        String.include(Foo::Bar)
        Hash.extend(Foo::Bar)
        Array.prepend(Foo::Bar)
      RUBY

      output = template(<<~RBI)
        class Array
          include ::Foo::Bar
          include ::Enumerable
        end

        class Foo
          def bar; end
          def to_s; end
        end

        module Foo::Bar; end

        class Hash
          include ::Enumerable
          extend ::Foo::Bar
        end

        class String
          include ::Comparable
          include ::Foo::Bar
        end
      RBI

      assert_equal(output, compile)
    end

    it "compiles dynamic mixin to singleton class" do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          module Bar; end
        end
      RUBY

      add_ruby_file("ext.rb", <<~RUBY)
        Class.singleton_class.prepend(Foo::Bar)
      RUBY

      output = template(<<~RBI)
        class Class < ::Module
          extend ::Foo::Bar
        end

        class Foo; end
        module Foo::Bar; end
      RBI

      assert_equal(output, compile)
    end

    it "compiles without annotations" do
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

    it "compiles methods and leaves spacing" do
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

    it "compiles constants assignments" do
      add_ruby_file("a.rb", <<~RUBY)
        module A
          ABC = 1
          DEF = ABC.to_s
        end
      RUBY

      output = template(<<~RBI)
        module A; end
        <% if ruby_version(">= 2.4.0") %>
        A::ABC = T.let(T.unsafe(nil), Integer)
        <% else %>
        A::ABC = T.let(T.unsafe(nil), Fixnum)
        <% end %>
        A::DEF = T.let(T.unsafe(nil), String)
      RBI

      assert_equal(output, compile)
    end

    it "compiles simple arguments" do
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

    it "compiles default arguments" do
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

    it "compiles modules" do
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

    it "compiles compact SymbolTableCompilerTests" do
      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
        end

        module Foo::Bar
          def num(a)
          end
        end
      RUBY

      output = template(<<~RBI)
        module Foo; end

        module Foo::Bar
          def num(a); end
        end
      RBI

      assert_equal(output, compile)
    end

    it "compiles nested namespaces" do
      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
          class Bar
            def num(a)
            end
          end
        end
      RUBY

      output = template(<<~RBI)
        module Foo; end

        class Foo::Bar
          def num(a); end
        end
      RBI

      assert_equal(output, compile)
    end

    it "compiles compact namespaces nested" do
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
        module Foo; end
        module Foo::Bar; end

        class Foo::Bar::Baz
          def num(a); end
        end
      RBI

      assert_equal(output, compile)
    end

    it "compiles deeply nested namespaces" do
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
        module Foo; end
        class Foo::Bar; end

        class Foo::Bar::Baz
          def num(a); end
        end
      RBI

      assert_equal(output, compile)
    end

    it "compiles a class with a superclass" do
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
        class Bar < ::Baz; end

        class Baz
          def toto; end
        end
      RBI

      assert_equal(output, compile)
    end

    it "compiles a class with a relative superclass" do
      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
          class Baz
          end
          class Bar < Baz
          end
        end
      RUBY

      output = template(<<~RBI)
        module Foo; end
        class Foo::Bar < ::Foo::Baz; end
        class Foo::Baz; end
      RBI

      assert_equal(output, compile)
    end

    it "does not drop absolute namespacing" do
      add_ruby_file("foo.rb", <<~RUBY)
        class Bar; end

        class Foo
          extend T::Sig

          class Bar; end
          class String; end

          sig { params(x: T.any(::String, ::Bar)).returns(::Bar) }
          def bar(x); end

          sig { params(x: ::String).returns(::String) }
          def string(x); end

          sig { params(x: Bar).returns(Bar) }
          def local_bar(x); end

          sig { params(x: String).returns(String) }
          def local_string(x); end
        end
      RUBY

      output = template(<<~RBI)
        class Bar; end

        class Foo
          sig { params(x: T.any(::Bar, ::String)).returns(::Bar) }
          def bar(x); end

          sig { params(x: ::Foo::Bar).returns(::Foo::Bar) }
          def local_bar(x); end

          sig { params(x: ::Foo::String).returns(::Foo::String) }
          def local_string(x); end

          sig { params(x: ::String).returns(::String) }
          def string(x); end
        end

        class Foo::Bar; end
        class Foo::String; end
      RBI

      assert_equal(output, compile)
    end

    it "compiles a class alias that is pointing to a constant which has been overwritten" do
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
        class WebAgent; end
        WebAgent::CookieManager = HTTPClient::CookieManager
        class WebMockHTTPClient; end
      RBI

      assert_equal(output, compile)
    end

    it "compiles a constant which is aliased to a constant that has been overwritten as a placeholder" do
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
        class MockClient; end
        module MockModule; end
        MyClient = MockClient
        MyModule = MockModule
        module SomeModule; end
        SomeModule::OriginalClient = Class.new
        SomeModule::OriginalModule = Module.new
      RBI

      assert_equal(output, compile)
    end

    it "compiles a class with an anchored superclass" do
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
        class Baz; end
        module Foo; end
        class Foo::Bar < ::Baz; end
      RBI

      assert_equal(output, compile)
    end

    it "compiles a class with an private superclass" do
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
        module Toto; end
        class Toto::Baz; end
        module Toto::Foo; end
        class Toto::Foo::Bar < ::Toto::Baz; end
      RBI

      assert_equal(output, compile)
    end

    it "compiles constants that have a hash method on the constant which does not return an Integer" do
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

    it "compiles constants that have horrible eql? or equal? overrides" do
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
        module Foo; end

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

    it "compiles a class which effectively has itself as a superclass" do
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

        class Foo::Bar < ::Numeric; end
        Foo::Baz = Foo::Bar
      RBI

      assert_equal(output, compile)
    end

    it "compiles a class with mixins" do
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
          include ::Tutu
          include ::Foo
          extend ::Toto
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

    it "compiles a module with mixins" do
      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
          def foo
          end
        end
      RUBY

      add_ruby_file("bar.rb", <<~RUBY)
        module Bar
          def bar
          end
        end
      RUBY

      add_ruby_file("quux.rb", <<~RUBY)
        module Quux
        end
      RUBY

      add_ruby_file("baz.rb", <<~RUBY)
        module Baz
          include Foo
          extend Bar
          prepend Quux
          include Kernel
           # The following should be ignored
           # since `Kernel` is already included into `Module`
           # and the singleton class of `Baz` is a subclass of `Module`
          extend Kernel
        end
      RUBY

      output = template(<<~RBI)
        module Bar
          def bar; end
        end

        module Baz
          include ::Quux
          include ::Foo
          include ::Kernel
          extend ::Bar
        end

        module Foo
          def foo; end
        end

        module Quux; end
      RBI

      assert_equal(output, compile)
    end

    it "compiles Structs, Classes, and Modules" do
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
        class C1; end

        class C2
          def foo; end
        end

        class C3; end
        module M1; end

        module M2
          def foo; end
        end

        module M3; end
        class S1 < ::Struct; end

        class S2 < ::Struct
          def foo; end
          def foo=(_); end

          class << self
            def [](*_arg0); end
            def inspect; end
            def keyword_init?; end
            def members; end
            def new(*_arg0); end
          end
        end

        class S3 < ::Struct
          def foo; end
          def foo=(_); end

          class << self
            def [](*_arg0); end
            def inspect; end
            def keyword_init?; end
            def members; end
            def new(*_arg0); end
          end
        end

        class S4 < ::Struct; end
      RBI

      assert_equal(output, compile)
    end

    it "handles dynamic mixins" do
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
          include ::Foo
          include ::Baz

          class << self
            def abc; end
          end
        end

        module Baz; end
        module Foo; end
      RBI

      assert_equal(output, compile)
    end

    it "compiles methods on the class's singleton class" do
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

    it "doesn't compile non-static singleton class reopening" do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          obj = Object.new

          class << obj
            define_method(:foo) {}
          end
        end
      RUBY

      output = template(<<~RBI)
        class Bar; end
      RBI

      assert_equal(output, compile)
    end

    it "compiles method that is also prepended" do
      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
          def bar
            super
          end
        end

        class Baz
          prepend Foo

          def bar; end
        end
      RUBY

      output = template(<<~RBI)
        class Baz
          include ::Foo

          def bar; end
        end

        module Foo
          def bar; end
        end
      RBI

      assert_equal(output, compile)
    end

    it "compiles a method that is prepended without calling super" do
      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
          def bar; end
        end

        class Baz
          prepend Foo

          def bar; end
        end
      RUBY

      output = template(<<~RBI)
        class Baz
          include ::Foo

          def bar; end
        end

        module Foo
          def bar; end
        end
      RBI

      assert_equal(output, compile)
    end

    it "ignores methods on other objects" do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          a = Object.new

          def a.num(a)
          end
        end
      RUBY

      output = template(<<~RBI)
        class Bar; end
      RBI

      assert_equal(output, compile)
    end

    it "compiles a singleton class" do
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

    it "compiles blocks" do
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

    it "compiles attr_reader/attr_writer/attr_accessor" do
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

    it "ignores methods with invalid names" do
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

    it "ignores method calls" do
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

    it "ignores loops" do
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
        class Toto; end
      RBI

      assert_equal(output, compile)
    end

    it "renames unnamed splats" do
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

    it "ignores ivar and cvar assigns" do
      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
          @@mod_var = 1
          @ivar = 2
          @ivar ||= 1
        end
      RUBY

      output = template(<<~RBI)
        module Foo; end
      RBI

      assert_equal(output, compile)
    end

    it "ignores things done in the file body" do
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
        module Foo; end
      RBI

      assert_equal(output, compile)
    end

    it "compiles methods of all visibility for classes" do
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

    it "compiles methods of all visibility for modules" do
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

    it "removes useless spacing" do
      add_ruby_file("bar.rb", <<~RUBY)
        class Bar
          a = b = c = 1
          a
          b
          c
        end
      RUBY

      output = template(<<~RBI)
        class Bar; end
      RBI

      assert_equal(output, compile)
    end

    it "compiles initialize" do
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

    it "understands redefined attr_accessor" do
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

    it "handles inheritance properly when the parent is a method call" do
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

        class Baz::Bar; end
        class Baz::Toto < ::Baz::Bar; end
      RBI

      assert_equal(output, compile)
    end

    it "handles multiple assign of constants" do
      add_ruby_file("toto.rb", <<~RUBY)
        module Toto
          A, B, C, *D, e = "1.2.3.4".split(".")
          NUMS = [A, B, C, *D]
        end
      RUBY

      output = template(<<~RBI)
        module Toto; end
        Toto::A = T.let(T.unsafe(nil), String)
        Toto::B = T.let(T.unsafe(nil), String)
        Toto::C = T.let(T.unsafe(nil), String)
        Toto::D = T.let(T.unsafe(nil), Array)
        Toto::NUMS = T.let(T.unsafe(nil), Array)
      RBI

      assert_equal(output, compile)
    end

    it "handles constants that override #!" do
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

    it "handles ranges properly" do
      add_ruby_file("toto.rb", <<~RUBY)
        module Toto
          A = ('a'...'z')
        end
      RUBY

      output = template(<<~RBI)
        module Toto; end
        Toto::A = T.let(T.unsafe(nil), Range)
      RBI

      assert_equal(output, compile)
    end

    it "handles weak maps properly" do
      add_ruby_file("weak_map.rb", <<~RUBY)
        Foo = ObjectSpace::WeakMap.new
      RUBY

      output = template(<<~RBI)
        Foo = T.let(T.unsafe(nil), ObjectSpace::WeakMap)
      RBI

      assert_equal(output, compile)
    end

    it "doesn't output prepend for modules unreachable via constants" do
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
        module Foo; end
      RBI

      assert_equal(output, compile)
    end

    it "doesn't output include for modules unreachable via constants" do
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
        module Foo; end
      RBI

      assert_equal(output, compile)
    end

    it "can handle BasicObjects" do
      add_ruby_file("basic_object_test.rb", <<~RUBY)
        module BasicObjectTest
          class B < ::BasicObject
          end

          Basic = B.new
          VeryBasic = ::BasicObject.new
        end
      RUBY

      output = template(<<~RBI)
        module BasicObjectTest; end
        class BasicObjectTest::B < ::BasicObject; end
        BasicObjectTest::Basic = T.let(T.unsafe(nil), BasicObjectTest::B)
        BasicObjectTest::VeryBasic = T.let(T.unsafe(nil), BasicObject)
      RBI

      assert_equal(output, compile)
    end

    it "adds mixes_in_class_methods to modules that extend base classes" do
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

      add_ruby_file("module_with_included_method.rb", <<~RUBY)
        module ModuleWithIncludedMethod
          def included(base)
            base.include(FooConcern)
            base.include(BarConcern)
          end
        end
      RUBY

      add_ruby_file("baz.rb", <<~RUBY)
        module Baz
          extend ModuleWithIncludedMethod
        end
      RUBY

      output = template(<<~RBI)
        module BarConcern
          mixes_in_class_methods ::BarConcern::Something

          class << self
            private

            def included(base); end
          end
        end

        module BarConcern::Something
          def another_class_method; end
        end

        module Baz
          extend ::ModuleWithIncludedMethod
          include ::FooConcern
          include ::BarConcern

          mixes_in_class_methods ::FooConcern::CustomClassMethods
          mixes_in_class_methods ::BarConcern::Something
        end

        module Concern
          def included(base); end
        end

        module FooConcern
          extend ::Concern

          mixes_in_class_methods ::FooConcern::CustomClassMethods

          def a_normal_method; end
        end

        module FooConcern::CustomClassMethods
          def wow_a_class_method; end
        end

        module ModuleWithIncludedMethod
          def included(base); end
        end
      RBI

      assert_equal(output, compile)
    end

    it "safely bails out of generating mixes_in_class_methods for modules that do weird things" do
      add_ruby_file("concern_that_requires_random_stuff.rb", <<~RUBY)
        module ConcernThatRequiresRandomStuff
          def self.included(base)
            require "non_existent_require_path"
          end
        end
      RUBY

      add_ruby_file("concern_that_explicitly_raises.rb", <<~RUBY)
        module ConcernThatExplicitlyRaises
          def self.included(base)
            raise "I ran into an exception case"
          end
        end
      RUBY

      add_ruby_file("concern_that_performs_an_illegal_operation.rb", <<~RUBY)
        module ConcernThatPerformsAnIllegalOperation
          def self.included(base)
            sum(2)
          end

          def self.sum(a, b)
            a + b
          end
        end
      RUBY

      output = template(<<~RBI)
        module ConcernThatExplicitlyRaises
          class << self
            def included(base); end
          end
        end

        module ConcernThatPerformsAnIllegalOperation
          class << self
            def included(base); end
            def sum(a, b); end
          end
        end

        module ConcernThatRequiresRandomStuff
          class << self
            def included(base); end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it "adds mixes_in_class_methods(ClassMethods) to modules that extend from ActiveSupport::Concern" do
      add_ruby_file("validations.rb", <<~RUBY)
        require "active_support"
        require "active_support/concern"

        module Validations
          extend ActiveSupport::Concern

          module HelperMethods
          end
          private_constant :HelperMethods

          module ClassMethods
          end

          included do
            extend  HelperMethods
            include HelperMethods
          end
        end
      RUBY

      add_ruby_file("super_validations.rb", <<~RUBY)
        require "active_support"
        require "active_support/concern"

        module SuperValidations
          extend ActiveSupport::Concern
          include Validations

          class_methods {}
        end
      RUBY

      output = template(<<~RBI)
        module SuperValidations
          extend ::ActiveSupport::Concern
          include ::Validations::HelperMethods
          include ::Validations

          mixes_in_class_methods ::Validations::ClassMethods
          mixes_in_class_methods ::Validations::HelperMethods
          mixes_in_class_methods ::SuperValidations::ClassMethods
        end

        module SuperValidations::ClassMethods; end

        module Validations
          extend ::ActiveSupport::Concern
          include ::Validations::HelperMethods

          mixes_in_class_methods ::Validations::ClassMethods
          mixes_in_class_methods ::Validations::HelperMethods
        end

        module Validations::ClassMethods; end
        module Validations::HelperMethods; end
      RBI

      assert_equal(output, compile)
    end

    it "properly treats pre-Rails 6.1 ActiveSupport::Deprecation::DeprecatedConstantProxy instances" do
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
        module ActiveSupport; end
        class ActiveSupport::Deprecation; end

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

    it "properly treats post-Rails 6.1 ActiveSupport::Deprecation::DeprecatedConstantProxy instances" do
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
        module ActiveSupport; end
        class ActiveSupport::Deprecation; end

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

    it "properly filters out T::Private modules" do
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

    it "doesn't filter out T::Props modules" do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          extend(T::Props)
          extend(T::Props::Constructor)

          def self.name
            "SomethingElse"
          end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          extend ::T::Props
          extend ::T::Props::Plugin
          extend ::T::Props::Optional
          extend ::T::Props::WeakConstructor
          extend ::T::Props::Constructor

          class << self
            def name; end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it "doesn't crash when `singleton_class` is overloaded" do
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
          extend ::Foo::Bar
        end

        module Foo::Bar
          private

          def singleton_class(klass); end
        end
      RBI

      assert_equal(output, compile)
    end

    it "sanitize parameter names created through meta-programming" do
      add_ruby_file("foo.rb", template(<<~RUBY))
        class Foo
        <% if ruby_version(">= 2.7.0") %>
          module_eval("def foo(...); end")
        <% end %>
        end
      RUBY

      output = template(<<~RBI)
        <% if ruby_version(">= 3.1") %>
        class Foo
          def foo(*_arg0, **_arg1, &_arg2); end
        end
        <% else %>
        class Foo
          def foo(*_arg0, &_arg1); end
        end
        <% end %>
      RBI

      assert_equal(output, compile)
    end

    it "compiles T::Enum" do
      add_ruby_file("foo.rb", <<~RUBY)
        class Bar
          class Baz < T::Enum
            enums do
              A = new('abc')
              B = new
            end
          end
        end

        class Foo < T::Enum
          enums do
            A = new
            B = new('xyz')
          end

          CONSTANT = 123

          class C
          end
        end
      RUBY

      output = template(<<~RBI)
        class Bar; end

        class Bar::Baz < ::T::Enum
          enums do
            A = new
            B = new
          end
        end

        class Foo < ::T::Enum
          enums do
            A = new
            B = new
          end
        end

        class Foo::C; end
        Foo::CONSTANT = T.let(T.unsafe(nil), Integer)
      RBI

      assert_equal(output, compile)
    end

    it "does not think random types that override < are T::Enum" do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          def self.<(other)
            true
          end

          def self.values
            []
          end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          class << self
            def <(other); end
            def values; end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it "compiles constants and methods marked as final properly" do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          extend T::Sig
          extend T::Helpers

          final!

          sig(:final) { void }
          def foo
          end

          sig(:final) { params(a: Integer, b: String).returns(Integer) }
          def bar(a, b:)
          end

          sig(:final) { returns(T.proc.params(x: String).void) }
          attr_reader :some_attribute

          class << self
            extend(T::Sig)

            sig(:final) { void }
            def quux
            end
          end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          final!

          sig(:final) { params(a: ::Integer, b: ::String).returns(::Integer) }
          def bar(a, b:); end

          sig(:final) { void }
          def foo; end

          sig(:final) { returns(T.proc.params(x: ::String).void) }
          def some_attribute; end

          class << self
            sig(:final) { void }
            def quux; end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it "compiles signatures and structs in source files" do
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

          sig { returns(T.proc.params(x: String).void) }
          attr_reader :some_attribute

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
          const :quuz, Integer, factory: -> { 1 }
          prop :fuzz, T.proc.returns(String), default: -> { "" }
          prop :buzz, T.proc.void, factory: -> { 42 }
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

      add_ruby_file("class_methods.rb", <<~RUBY)
        module ClassMethods
          extend(T::Generic)

          has_attached_class!
        end

        module ClassMethodsWithVariance
          extend(T::Generic)

          has_attached_class!(:out) { {upper: String} }
        end
      RUBY

      add_ruby_file("generic.rb", <<~RUBY)
        module Generics
          class ComplexGenericType
            extend(T::Generic)

            A = type_template(:in)
            B = type_template(:out)
            C = type_template

            D = type_member { { fixed: Integer } }
            E = type_member { { fixed: Integer, upper: T::Array[Numeric] } }
            F = type_member { {
              fixed: Integer,
              lower: T.any(Complex, T::Hash[Symbol, T::Array[Integer]]),
              upper: T.nilable(Numeric),
            } }
            G = type_member(:in) { { fixed: Integer } }
            H = type_member(:in) { { fixed: Integer, upper: Numeric } }
            I = type_member(:in) { { fixed: Integer, lower: Complex, upper: Numeric } }

            class << self
              extend(T::Generic)

              A = type_template(:in)
              B = type_template(:out)
              C = type_template

              D = type_member { { fixed: Integer } }
              E = type_member { { fixed: Integer, upper: Numeric } }
              F = type_member { { fixed: Integer, lower: Complex, upper: Numeric } }
              G = type_member(:in) { { fixed: Integer } }
              H = type_member(:in) { { fixed: Integer, upper: Numeric } }
              I = type_member(:in) { { fixed: Integer, lower: Complex, upper: Numeric } }
            end
          end

          class SimpleGenericType
            extend T::Sig
            extend T::Generic

            Template = type_template
            Elem = type_member

            sig { params(foo: Elem).void }
            def initialize(foo)
              @foo = foo
            end

            sig { params(foo: Template).returns(Template) }
            def something(foo); end

            sig { params(foo: T::Hash[T::Array[Template], T::Set[Elem]]).void }
            def complex(foo); end

            NullGenericType = SimpleGenericType[Integer].new(0)
          end

          module ForwardDeclaration
            extend T::Sig
            extend T::Generic

            Elem = type_member { { fixed: LateDeclaredModule }}

            module LateDeclaredModule
            end
          end
        end
      RUBY

      output = template(<<~RBI)
        module Adt
          interface!
          sealed!
        end

        class Adt::Bar
          include ::Adt
        end

        class Adt::Foo
          include ::Adt
        end

        class Bar < ::T::Struct
          const :foo, ::Integer
          prop :bar, ::String
          const :baz, T::Hash[::String, T.untyped]
          prop :quux, T.untyped, default: T.unsafe(nil)
          const :quuz, ::Integer, default: T.unsafe(nil)
          prop :fuzz, T.proc.returns(::String), default: T.unsafe(nil)
          prop :buzz, T.proc.void, default: T.unsafe(nil)
        end

        class Baz
          abstract!

          sig { abstract.void }
          def do_it; end
        end

        class Buzz
          include ::T::Props
          include ::T::Props::Plugin
          include ::T::Props::Optional
          include ::T::Props::WeakConstructor
          include ::T::Props::Constructor
          extend ::T::Props::ClassMethods
          extend ::T::Props::Plugin::ClassMethods

          const :foo, ::Integer
          prop :bar, ::String
          const :baz, T.proc.params(arg0: ::String).void
        end

        module ClassMethods
          extend T::Generic

          has_attached_class!
        end

        module ClassMethodsWithVariance
          extend T::Generic

          has_attached_class!(:out) { { upper: String } }
        end

        class Foo
          sig { params(a: ::Integer, b: ::String).returns(::Integer) }
          def bar(a, b:); end

          sig { type_parameters(:U).params(a: T.type_parameter(:U)).returns(T.type_parameter(:U)) }
          def baz(a); end

          sig { params(a: ::Integer, b: ::String).void }
          def foo(a, b:); end

          sig { params(a: ::Integer, b: ::Integer, c: ::Integer, d: ::Integer, e: ::Integer, f: ::Integer, blk: T.proc.void).void }
          def many_kinds_of_args(*a, b, c, d:, e: T.unsafe(nil), **f, &blk); end

          sig { returns(T.proc.params(x: ::String).void) }
          def some_attribute; end

          class << self
            sig { void }
            def quux; end
          end
        end

        module Generics; end

        class Generics::ComplexGenericType
          extend T::Generic

          A = type_template(:in)
          B = type_template(:out)
          C = type_template
          D = type_member { { fixed: Integer } }
          E = type_member { { fixed: Integer, upper: T::Array[::Numeric] } }
          F = type_member { { fixed: Integer, lower: T.any(::Complex, T::Hash[::Symbol, T::Array[::Integer]]), upper: T.nilable(::Numeric) } }
          G = type_member(:in) { { fixed: Integer } }
          H = type_member(:in) { { fixed: Integer, upper: Numeric } }
          I = type_member(:in) { { fixed: Integer, lower: Complex, upper: Numeric } }

          class << self
            extend T::Generic

            A = type_template(:in)
            B = type_template(:out)
            C = type_template
            D = type_member { { fixed: Integer } }
            E = type_member { { fixed: Integer, upper: Numeric } }
            F = type_member { { fixed: Integer, lower: Complex, upper: Numeric } }
            G = type_member(:in) { { fixed: Integer } }
            H = type_member(:in) { { fixed: Integer, upper: Numeric } }
            I = type_member(:in) { { fixed: Integer, lower: Complex, upper: Numeric } }
          end
        end

        module Generics::ForwardDeclaration
          extend T::Generic

          Elem = type_member { { fixed: Generics::ForwardDeclaration::LateDeclaredModule } }
        end

        module Generics::ForwardDeclaration::LateDeclaredModule; end

        class Generics::SimpleGenericType
          extend T::Generic

          Template = type_template
          Elem = type_member

          sig { params(foo: Elem).void }
          def initialize(foo); end

          sig { params(foo: T::Hash[T::Array[Template], T::Set[Elem]]).void }
          def complex(foo); end

          sig { params(foo: Template).returns(Template) }
          def something(foo); end
        end

        Generics::SimpleGenericType::NullGenericType = T.let(T.unsafe(nil), Generics::SimpleGenericType[::Integer])

        module Quux
          interface!

          sig { abstract.returns(::Integer) }
          def something; end
        end

        class Quux::Concrete
          include ::Quux

          sig { returns(::String) }
          def bar; end

          sig { params(baz: T::Hash[::String, ::Object]).returns(T::Hash[::String, ::Object]) }
          def baz=(baz); end

          sig { returns(T::Array[::Integer]) }
          def foo; end

          def foo=(_arg0); end

          sig { override.returns(::Integer) }
          def something; end
        end
      RBI

      assert_equal(output, compile)
    end

    it "compiles fixed hashes in params properly" do
      add_ruby_file("sigs_with_fixed_hash_with_symbols_and_string.rb", <<~RUBY)
        class Foo
          extend T::Sig

          sig { params(params: { "foo" => Integer, bar: String, :"foo bar" => Class }).void }
          def foo(params)
          end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          sig { params(params: {"foo" => ::Integer, bar: ::String, :"foo bar" => ::Class}).void }
          def foo(params); end
        end
      RBI

      assert_equal(output, compile)
    end

    it "can compile sealed generics" do
      add_ruby_file("sealed_generic.rb", <<~RUBY)
        class Foo
          extend T::Sig
          extend T::Helpers
          extend T::Generic

          sealed!

          Elem = type_member
        end

        Foo[Integer] # this should not trigger an error
      RUBY

      output = template(<<~RBI)
        class Foo
          extend T::Generic

          sealed!

          Elem = type_member
        end
      RBI

      assert_equal(output, compile)
    end

    it "can compile generic constant types" do
      add_ruby_file("optional.rb", <<~RUBY)
        class Foo
          extend T::Generic

          Elem = type_member
        end

        FOO = Foo.new

        class Bar
          extend T::Generic

          Key = type_member
          Value = type_member
        end

        BAR = Bar.new

        class Fuz
          extend T::Generic

          Elem = type_member { { fixed: NilClass } }
        end

        FUZ = Fuz.new

        class Baz
          extend T::Generic

          Key = type_member { { fixed: Symbol } }
          Value = type_member
        end

        BAZ = Baz.new
      RUBY

      output = template(<<~RBI)
        BAR = T.let(T.unsafe(nil), Bar[T.untyped, T.untyped])
        BAZ = T.let(T.unsafe(nil), Baz[T.untyped])

        class Bar
          extend T::Generic

          Key = type_member
          Value = type_member
        end

        class Baz
          extend T::Generic

          Key = type_member { { fixed: Symbol } }
          Value = type_member
        end

        FOO = T.let(T.unsafe(nil), Foo[T.untyped])
        FUZ = T.let(T.unsafe(nil), Fuz)

        class Foo
          extend T::Generic

          Elem = type_member
        end

        class Fuz
          extend T::Generic

          Elem = type_member { { fixed: NilClass } }
        end
      RBI

      assert_equal(output, compile)
    end

    it "can compile generics in type variable arguments" do
      add_ruby_file("service.rb", <<~RUBY)
        class Result
          extend T::Generic

          OkType = type_member
          ErrType = type_member
        end

        class Service
          extend T::Generic

          InputType = type_member { { upper: Result[Integer, String] } }
          ReturnType = type_member { { fixed: Result[Integer, String] } }
          TempType = type_member { { lower: Result[Integer, String] } }
        end
      RUBY

      output = template(<<~RBI)
        class Result
          extend T::Generic

          OkType = type_member
          ErrType = type_member
        end

        class Service
          extend T::Generic

          InputType = type_member { { upper: Result[::Integer, ::String] } }
          ReturnType = type_member { { fixed: Result[::Integer, ::String] } }
          TempType = type_member { { lower: Result[::Integer, ::String] } }
        end
      RBI

      assert_equal(output, compile)
    end

    it "can compile typed struct generics" do
      add_ruby_file("tstruct_generic.rb", <<~RUBY)
        class Foo < T::Struct
          extend T::Generic

          Elem = type_member

          const :foo, Elem
        end

        Foo[Integer] # this should not trigger an error
      RUBY

      output = template(<<~RBI)
        class Foo < ::T::Struct
          extend T::Generic

          Elem = type_member

          const :foo, Elem

          class << self
            def inherited(s); end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it "can compile generics that prohibit subclasses" do
      add_ruby_file("non_subclassable_generic.rb", <<~RUBY)
        class Foo
          extend T::Generic

          Elem = type_member

          def self.inherited(s)
            super(s)
            raise "Cannot subclass Foo"
          end
        end

        Foo[Integer] # this should not trigger an error
      RUBY

      output = template(<<~RBI)
        class Foo
          extend T::Generic

          Elem = type_member

          class << self
            def inherited(s); end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it "compiles nested generic interfaces" do
      add_ruby_file("generic.rb", <<~RUBY)
        module Root
          extend T::Sig
          extend T::Generic
          Elem = type_member
          abstract!

          sig { abstract.returns(T::Array[Node[Elem]]) }
          def children; end

          sig { abstract.returns(T::Array[Node[Elem]]) }
          def abstract_but_not_overridden_children; end

          sig { returns(T::Array[Node[Elem]]) }
          def non_abstract_children
            []
          end

          sig { returns(T::Array[Node[Elem]]) }
          def non_abstract_but_overridden_children
            []
          end
        end

        module Node
          extend T::Sig
          extend T::Helpers
          extend T::Generic
          Elem = type_member
        end

        class OtherRoot
          include ::Root
          extend T::Sig
          extend T::Generic
          Elem = type_member { { fixed: Integer } }

          sig { override.returns(T::Array[Node[Integer]]) }
          def children
            []
          end

          sig { override.returns(T::Array[Node[Integer]]) }
          def non_abstract_but_overridden_children
            []
          end
        end
      RUBY

      output = template(<<~RBI)
        module Node
          extend T::Generic

          Elem = type_member
        end

        class OtherRoot
          extend T::Generic
          include ::Root

          Elem = type_member { { fixed: Integer } }

          sig { override.returns(T::Array[Node[::Integer]]) }
          def children; end

          sig { override.returns(T::Array[Node[::Integer]]) }
          def non_abstract_but_overridden_children; end
        end

        module Root
          extend T::Generic

          abstract!

          Elem = type_member

          sig { abstract.returns(T::Array[Node[Elem]]) }
          def abstract_but_not_overridden_children; end

          sig { abstract.returns(T::Array[Node[Elem]]) }
          def children; end

          sig { returns(T::Array[Node[Elem]]) }
          def non_abstract_but_overridden_children; end

          sig { returns(T::Array[Node[Elem]]) }
          def non_abstract_children; end
        end
      RBI

      assert_equal(output, compile)
    end

    it "compiles constants of generic types" do
      add_ruby_file("generic.rb", <<~RUBY)
        module GenericInterface
          extend T::Generic

          interface!

          Parameter = type_member
        end

        class Concrete
          extend T::Generic

          include GenericInterface
          Parameter = type_member
        end

        GENERIC_CONSTANT = T.let(
          Concrete.new,
          GenericInterface[Numeric]
        )
      RUBY

      output = template(<<~RBI)
        class Concrete
          extend T::Generic
          include ::GenericInterface

          Parameter = type_member
        end

        GENERIC_CONSTANT = T.let(T.unsafe(nil), Concrete[T.untyped])

        module GenericInterface
          extend T::Generic

          interface!

          Parameter = type_member
        end
      RBI

      assert_equal(output, compile)
    end

    it "compiles generics with anonymous type arguments" do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          class << self
            extend T::Sig

            class Bar; end

            sig { returns(T::Array[Bar]) }
            def foo; end
          end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          class << self
            sig { returns(T::Array[::T.untyped]) }
            def foo; end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it "compiles structs with default values" do
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
          prop :a, T.nilable(::Integer), default: T.unsafe(nil)
          prop :b, T::Boolean, default: T.unsafe(nil)
          prop :c, T::Boolean, default: T.unsafe(nil)
          prop :d, ::Symbol, default: T.unsafe(nil)
          prop :e, ::String, default: T.unsafe(nil)
          prop :f, ::Integer, default: T.unsafe(nil)
          prop :g, ::Float, default: T.unsafe(nil)
          prop :h, T::Array[::String], default: T.unsafe(nil)
          prop :i, T::Hash[::String, ::Integer], default: T.unsafe(nil)
          prop :k, ::Foo, default: T.unsafe(nil)
          prop :l, T::Array[::Foo], default: T.unsafe(nil)
          prop :m, T::Hash[::Foo, ::Foo], default: T.unsafe(nil)
          prop :n, ::Foo, default: T.unsafe(nil)
        end
      RBI

      assert_equal(output, compile)
    end

    it "never sorts mixins" do
      add_ruby_file("foo.rb", <<~RUBY)
        module ActiveSupport
          module Rescuable
            module ClassMethods; end
          end

          module Callbacks
            module ClassMethods; end
          end

          module DescendantsTracker; end
        end

        module ActionMailbox
          module Routing
            module ClassMethods; end
          end

          module Callbacks
            module ClassMethods; end
          end
        end

        class ActionMailbox::Base
          include ::ActiveSupport::Rescuable
          include ::ActionMailbox::Routing
          include ::ActiveSupport::Callbacks
          include ::ActionMailbox::Callbacks
          extend ::ActiveSupport::Rescuable::ClassMethods
          extend ::ActionMailbox::Routing::ClassMethods
          extend ::ActiveSupport::Callbacks::ClassMethods
          extend ::ActiveSupport::DescendantsTracker
          extend ::ActionMailbox::Callbacks::ClassMethods
        end
      RUBY

      output = template(<<~RBI)
        module ActionMailbox; end

        class ActionMailbox::Base
          include ::ActiveSupport::Rescuable
          include ::ActionMailbox::Routing
          include ::ActiveSupport::Callbacks
          include ::ActionMailbox::Callbacks
          extend ::ActiveSupport::Rescuable::ClassMethods
          extend ::ActionMailbox::Routing::ClassMethods
          extend ::ActiveSupport::Callbacks::ClassMethods
          extend ::ActiveSupport::DescendantsTracker
          extend ::ActionMailbox::Callbacks::ClassMethods
        end

        module ActionMailbox::Callbacks; end
        module ActionMailbox::Callbacks::ClassMethods; end
        module ActionMailbox::Routing; end
        module ActionMailbox::Routing::ClassMethods; end
        module ActiveSupport; end
        module ActiveSupport::Callbacks; end
        module ActiveSupport::Callbacks::ClassMethods; end
        module ActiveSupport::DescendantsTracker; end
        module ActiveSupport::Rescuable; end
        module ActiveSupport::Rescuable::ClassMethods; end
      RBI

      assert_equal(output, compile)
    end

    it "skips signatures and reports the errors if the sig block raises" do
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
        <% if ruby_version(">= 3.1") %>
          def bar(*args, **_arg1, &blk); end
        <% else %>
          def bar(*args, &blk); end
        <% end %>

          sig { type_parameters(:U).params(a: T.type_parameter(:U)).returns(T.type_parameter(:U)) }
          def baz(a); end

        <% if ruby_version(">= 3.1") %>
          def foo(*args, **_arg1, &blk); end
        <% else %>
          def foo(*args, &blk); end
        <% end %>
        end
      RBI

      assert_equal(output, compile(reported_errors_expected: true))
      assert_equal(reported_errors, [
        <<~ERROR,
          Unable to compile signature for method: Foo#bar
            Exception raised when loading signature: #<LoadError: LoadError>
        ERROR
        <<~ERROR,
          Unable to compile signature for method: Foo#foo
            Exception raised when loading signature: #<ArgumentError: ArgumentError>
        ERROR
      ])
    end

    it "handles signatures with attached classes" do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          class FooAttachedClass; end
          class AttachedClass; end
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

            sig { returns(T.any(FooAttachedClass, AttachedClass)) }
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

            sig { returns(T.any(::Foo::AttachedClass, ::Foo::FooAttachedClass)) }
            def c; end
          end
        end

        class Foo::AttachedClass; end
        class Foo::FooAttachedClass; end
      RBI

      assert_equal(output, compile)
    end

    it "handles class attributes created inside included blocks" do
      require "active_support/concern"

      add_ruby_file("foo.rb", <<~RUBY)
        module Taggeable
          extend ActiveSupport::Concern

          included do
            class_attribute :tag, :description, :body
            class_attribute :name, instance_reader: false
            class_attribute :no_check, instance_predicate: false
            class_attribute :secret, instance_accessor: false, instance_reader: false, instance_writer: false, instance_predicate: false
          end
        end
      RUBY

      output = template(<<~RBI)
        module Taggeable
          extend ::ActiveSupport::Concern
          include GeneratedInstanceMethods

          mixes_in_class_methods GeneratedClassMethods

          module GeneratedClassMethods
            def body; end
            def body=(value); end
            def body?; end
            def description; end
            def description=(value); end
            def description?; end
            def name; end
            def name=(value); end
            def name?; end
            def no_check; end
            def no_check=(value); end
            def secret; end
            def secret=(value); end
            def tag; end
            def tag=(value); end
            def tag?; end
          end

          module GeneratedInstanceMethods
            def body; end
            def body=(value); end
            def body?; end
            def description; end
            def description=(value); end
            def description?; end
            def name=(value); end
            def no_check; end
            def no_check=(value); end
            def tag; end
            def tag=(value); end
            def tag?; end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it "handles class_eval created classes and modules" do
      add_ruby_file("container.rb", <<~RUBY)
        class Container
          class_eval <<~EOF
            class FooClass
            end

            module FooModule
            end

            Bar = 42
          EOF

          class_eval <<~EOF, __FILE__, __LINE__ + 1
            class Baz
            end
          EOF
        end
      RUBY

      output = template(<<~RBI)
        class Container; end
        Container::Bar = T.let(T.unsafe(nil), Integer)
        class Container::Baz; end
        class Container::FooClass; end
        module Container::FooModule; end
      RBI

      assert_equal(output, compile)
    end

    it "handles class_eval created methods" do
      add_ruby_file("container.rb", <<~'RUBY')
        class Foo
          class_eval <<~EOF
            def foo; end
            def bar; end
          EOF

          class_eval <<~EOF, __FILE__, __LINE__ + 1
            def baz; end
            def qux; end
          EOF

          # Somehow defining methods in a loop triggers a different behavior
          # in backtrace locations where the absolute path ends up being `nil`.
          %w[string integer float boolean date datetime decimal money].each do |attr_type|
            class_eval <<-EOV, __FILE__, __LINE__ + 1
              def #{attr_type}
              end
            EOV
          end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          def bar; end
          def baz; end
          def boolean; end
          def date; end
          def datetime; end
          def decimal; end
          def float; end
          def foo; end
          def integer; end
          def money; end
          def qux; end
          def string; end
        end
      RBI

      assert_equal(output, compile)
    end

    it "includes comment documentation from sources when doc is true" do
      add_ruby_file("foo.rb", <<~RUBY)
        # frozen_string_literal: true

        # Namespace
        #
        # Here you'll find some super useful code
        module Namespace
          # Foo
          #
          # The Foo class is in the core of our application
          class Foo
            extend T::Sig

            # This secret constant unlocks the magic behind Foo
            CONSTANT = "SECRET"

            # Method bar
            #
            # This method does something really important
            #
            # @param a [String]
            # @return [void]
            sig { params(a: String).void }
            def bar(a); end

            # Method no_sig
            #
            # This method does not have a signature
            #
            # @param a [String, Integer] The `a` to use
            # @return [void]
            def no_sig(a); end

            sig { void }
            def no_yard_docs_but_sig; end

            def no_yard_docs_nor_sig; end

            # @deprecated Do not use me!
            # Method only_docs
            #
            # This method only has documentation
            def only_docs(a); end

            # Method baz
            #
            # This is a singleton method
            #
            # @param t [Integer, String]
            # @return [void]
            # @example My example
            #   a = "hello world"
            #   a.reverse
            # @deprecated Use something else instead of this method because
            #   it uses a library that is no longer supported in Ruby 1.9.
            #   The new method accepts the same parameters.
            sig { params(t: Integer).void }
            def self.baz(t); end

            class << self
              extend T::Sig
              # Method something
              #
              # This is another singleton method
              #
              # @return [void]
              sig { void }
              def something; end
            end
          end
        end
      RUBY

      output = template(<<~RBI)
        # Namespace
        #
        # Here you'll find some super useful code
        module Namespace; end

        # Foo
        #
        # The Foo class is in the core of our application
        class Namespace::Foo
          # Method bar
          #
          # This method does something really important
          sig { params(a: ::String).void }
          def bar(a); end

          # Method no_sig
          #
          # This method does not have a signature
          #
          # @param a [String, Integer] The `a` to use
          # @return [void]
          def no_sig(a); end

          sig { void }
          def no_yard_docs_but_sig; end

          def no_yard_docs_nor_sig; end

          # Method only_docs
          #
          # This method only has documentation
          #
          # @deprecated Do not use me!
          def only_docs(a); end

          class << self
            # Method baz
            #
            # This is a singleton method
            #
            # @deprecated Use something else instead of this method because
            #   it uses a library that is no longer supported in Ruby 1.9.
            #   The new method accepts the same parameters.
            # @example My example
            #   a = "hello world"
            #   a.reverse
            sig { params(t: ::Integer).void }
            def baz(t); end

            # Method something
            #
            # This is another singleton method
            sig { void }
            def something; end
          end
        end

        # This secret constant unlocks the magic behind Foo
        Namespace::Foo::CONSTANT = T.let(T.unsafe(nil), String)
      RBI

      assert_equal(output, compile(include_doc: true))
    end

    it "doesn't include YARD docs by default" do
      add_ruby_file("foo.rb", <<~RUBY)
        # Namespace
        #
        # Here you'll find some super useful code
        module Namespace
          # Foo
          #
          # The Foo class is in the core of our application
          class Foo
            extend T::Sig

            # This secret constant unlocks the magic behind Foo
            CONSTANT = "SECRET"

            # Method bar
            #
            # This method does something really important
            #
            # @param a [String]
            # @return [void]
            sig { params(a: String).void }
            def bar(a); end

            # Method no_sig
            #
            # This method does not have a signature
            #
            # @param a [String]
            # @return [void]
            def no_sig(a); end

            sig { void }
            def no_yard_docs; end

            # Method only_docs
            #
            # This method only has documentation
            def only_docs(a); end

            # Method baz
            #
            # This is a singleton method
            #
            # @param t [Integer]
            # @return [void]
            sig { params(t: Integer).void }
            def self.baz(t); end

            class << self
              extend T::Sig
              # Method something
              #
              # This is another singleton method
              #
              # @return [void]
              sig { void }
              def something; end
            end
          end
        end
      RUBY

      output = template(<<~RBI)
        module Namespace; end

        class Namespace::Foo
          sig { params(a: ::String).void }
          def bar(a); end

          def no_sig(a); end

          sig { void }
          def no_yard_docs; end

          def only_docs(a); end

          class << self
            sig { params(t: ::Integer).void }
            def baz(t); end

            sig { void }
            def something; end
          end
        end

        Namespace::Foo::CONSTANT = T.let(T.unsafe(nil), String)
      RBI

      assert_equal(output, compile(include_doc: false))
    end

    it "properly processes void in type aliases" do
      add_ruby_file("foo.rb", <<~RUBY)
        module Foo
          MyType = T.type_alias { T.proc.params(val: T.untyped).void }
        end
      RUBY

      output = template(<<~RBI)
        module Foo; end
        Foo::MyType = T.type_alias { T.proc.params(val: T.untyped).void }
      RBI

      assert_equal(output, compile)
    end

    it "compile required ancestors" do
      add_ruby_file("foo.rb", <<~RUBY)
        class Base
          extend T::Helpers

          requires_ancestor { ::Helper }

          module Helper; end
        end

        module Helper
          extend T::Helpers

          requires_ancestor { Kernel }
        end

        module TestHelper
          extend T::Helpers

          requires_ancestor { Base::Helper }
          requires_ancestor { ViewHelpers::UrlHelper }
          requires_ancestor { Assertions }
          requires_ancestor { Hooks }
          requires_ancestor { T.class_of(String) }

          module Assertions; end
          module Hooks; end
        end

        module ViewHelpers
          module UrlHelper; end
        end
      RUBY

      output = template(<<~RBI)
        class Base
          requires_ancestor { Helper }
        end

        module Base::Helper; end

        module Helper
          requires_ancestor { Kernel }
        end

        module TestHelper
          requires_ancestor { Base::Helper }
          requires_ancestor { T.class_of(String) }
          requires_ancestor { TestHelper::Assertions }
          requires_ancestor { TestHelper::Hooks }
          requires_ancestor { ViewHelpers::UrlHelper }
        end

        module TestHelper::Assertions; end
        module TestHelper::Hooks; end
        module ViewHelpers; end
        module ViewHelpers::UrlHelper; end
      RBI

      assert_equal(output, compile)
    end

    it "compiles proc bindings" do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          extend T::Sig

          sig { params(block: T.proc.bind(String).void).void }
          def bar(&block); end

          sig { params(block: T.proc.params(arg0: Integer).bind(String).void).void }
          def baz(&block); end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          sig { params(block: T.proc.bind(::String).void).void }
          def bar(&block); end

          sig { params(block: T.proc.bind(::String).params(arg0: ::Integer).void).void }
          def baz(&block); end
        end
      RBI

      assert_equal(output, compile)
    end

    it "compile RBIs with location from gem source" do
      add_ruby_file("bar.rb", <<~RB)
        module Bar
          extend T::Sig

          # Some documentation
          sig { void }
          def bar; end

          # Some documentation
          def self.bar; end

          BAR = 123

          # We shouldn't add the documentation when it points to things like `(eval)`
          eval("def foo1; end")
          define_method(:foo2) {}
        end
      RB

      add_ruby_file("foo.rb", <<~RB)
        class Foo
          extend T::Helpers

          requires_ancestor { ::Helper }

          module Helper
            def helper_method; end
          end
        end

        class Baz
          extend T::Helpers
          abstract!
        end

        class Quux < T::Struct
        end

        class String
          def foo; end
        end

        class BasicFoo < BasicObject
          extend ::T::Sig

          sig { void }
          def foo; end
        end

        NewClass = Class.new
      RB

      output = template(<<~RBI)
        # source://#{DEFAULT_GEM_NAME}//lib/bar.rb#1
        module Bar
          # Some documentation
          #
          # source://#{DEFAULT_GEM_NAME}//lib/bar.rb#6
          sig { void }
          def bar; end

          # source://the-default-gem//lib/bar.rb#14
          def foo1; end

          # source://#{DEFAULT_GEM_NAME}//lib/bar.rb#15
          def foo2; end

          class << self
            # Some documentation
            #
            # source://#{DEFAULT_GEM_NAME}//lib/bar.rb#9
            def bar; end
          end
        end

        # source://#{DEFAULT_GEM_NAME}//lib/bar.rb#11
        Bar::BAR = T.let(T.unsafe(nil), Integer)

        # source://#{DEFAULT_GEM_NAME}//lib/foo.rb#23
        class BasicFoo < ::BasicObject
          # source://#{DEFAULT_GEM_NAME}//lib/foo.rb#27
          sig { void }
          def foo; end
        end

        # @abstract It cannot be directly instantiated. Subclasses must implement the `abstract` methods below.
        #
        # source://#{DEFAULT_GEM_NAME}//lib/foo.rb#11
        class Baz
          abstract!
        end

        # source://#{DEFAULT_GEM_NAME}//lib/foo.rb#1
        class Foo; end

        # source://#{DEFAULT_GEM_NAME}//lib/foo.rb#6
        module Foo::Helper
          # source://#{DEFAULT_GEM_NAME}//lib/foo.rb#7
          def helper_method; end
        end

        # source://#{DEFAULT_GEM_NAME}//lib/foo.rb#30
        class NewClass; end

        # source://#{DEFAULT_GEM_NAME}//lib/foo.rb#16
        class Quux < ::T::Struct; end

        # source://#{DEFAULT_GEM_NAME}//lib/foo.rb#19
        class String
          include ::Comparable

          # source://#{DEFAULT_GEM_NAME}//lib/foo.rb#20
          def foo; end
        end
      RBI

      compiled = compile(include_doc: true, include_loc: true)
        .gsub(%r{\s+# source://activesupport/.+?\nString::.+$}m, "")
        .rstrip.concat("\n")

      assert_equal(output, compiled)
    end

    it "compiles constants with nil values" do
      add_ruby_file("foo.rb", <<~RUBY)
        class Foo
          BAR = nil
        end
      RUBY

      output = template(<<~RBI)
        class Foo; end
        Foo::BAR = T.let(T.unsafe(nil), T.untyped)
      RBI

      assert_equal(output, compile)
    end

    it "compiles RBS signatures" do
      add_ruby_file("foo.rb", <<~RUBY)
        # typed: strict

        class Foo
          #: String
          attr_accessor :foo

          #: (Integer a, b: String) -> void
          def bar(a, b:); end

          #: -> (^(String) -> void)
          def self.baz; end

          # @without_runtime
          #: -> NotExisting
          def qux; end

          class << self
            extend T::Sig

            #: -> void
            def qux; end
          end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          sig { params(a: ::Integer, b: ::String).void }
          def bar(a, b:); end

          sig { returns(::String) }
          def foo; end

          def foo=(_arg0); end
          def qux; end

          class << self
            sig { returns(T.proc.params(arg0: ::String).void) }
            def baz; end

            sig { void }
            def qux; end
          end
        end
      RBI

      assert_equal(output, compile)
    end

    it "compiles RBS signatures with nested namespaces" do
      add_ruby_file("foo.rb", <<~RUBY)
        # typed: true

        class Foo
          class Bar; end

          class Baz
            #: -> Bar
            def foo
              Bar.new
            end
          end
        end
      RUBY

      output = template(<<~RBI)
        class Foo; end
        class Foo::Bar; end

        class Foo::Baz
          sig { returns(::Foo::Bar) }
          def foo; end
        end
      RBI

      assert_equal(output, compile)
    end

    it "does not compile yard comments as RBS" do
      add_ruby_file("foo.rb", <<~RUBY)
        # typed: true

        class Foo
          #:nodoc:
          attr_reader :bar

          #:yields:
          def foo; end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          def bar; end
          def foo; end
        end
      RBI

      assert_equal(output, compile)
    end

    it "does not compile RBS comments as yard documentation" do
      add_ruby_file("foo.rb", <<~RUBY)
        # typed: true

        # @requires_ancestor: Kernel
        class Foo
          #: -> void
          #:comment:
          def foo; end

          #: -> Array[
          #| String
          #| ]
          def bar; end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          requires_ancestor { Kernel }

          sig { returns(T::Array[::String]) }
          def bar; end

          # :comment:
          sig { void }
          def foo; end
        end
      RBI

      assert_equal(output, compile(include_doc: true))
    end

    it "ignores RBS signatures that contain errors" do
      add_ruby_file("foo.rb", <<~RUBY)
        # typed: true

        class Foo
          #: \o/
          attr_reader :bar

          #: foo
          def foo; end

          #: -> void
          def qux; end
        end
      RUBY

      output = template(<<~RBI)
        class Foo
          sig { returns(T.untyped) }
          def bar; end

          def foo; end

          sig { void }
          def qux; end
        end
      RBI

      assert_equal(output, compile)
    end
  end
end
