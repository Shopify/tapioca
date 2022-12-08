# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    class CompilerSpec < Minitest::Spec
      include Tapioca::Helpers::Test::DslCompiler

      describe "Tapioca::Dsl::Compiler" do
        before do
          add_ruby_file("post_compiler.rb", <<~RUBY)
            class PostCompiler < Tapioca::Dsl::Compiler
              extend T::Sig

              ConstantType = type_member { { fixed: T.class_of(Post) } }

              sig { override.void }
              def decorate
                methods = constant.instance_methods(false)

                root.create_class("Post") do |klass|
                  methods.each do |method|
                    create_method_from_def(klass, constant.instance_method(method))
                  end
                end
              end

              class << self
                extend T::Sig

                sig { override.returns(T::Enumerable[Module]) }
                def gather_constants
                  [::Post]
                end
              end
            end
          RUBY

          use_dsl_compiler(Object.const_get("PostCompiler"))
        end

        it "compiles a class with no methods" do
          add_ruby_file("post.rb", <<~RUBY)
            class Post
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Post; end
          RBI

          assert_equal(expected, rbi_for(:Post))
        end

        it "compiles a class with methods that have no signature" do
          add_ruby_file("post.rb", <<~RUBY)
            class Post
              def bar(a, b = 42, *c); end
              def foo(d:, e: 42, **f, &blk); end
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Post
              sig { params(a: T.untyped, b: T.untyped, c: T.untyped).returns(T.untyped) }
              def bar(a, b = T.unsafe(nil), *c); end

              sig { params(d: T.untyped, e: T.untyped, f: T.untyped, blk: T.untyped).returns(T.untyped) }
              def foo(d:, e: T.unsafe(nil), **f, &blk); end
            end
          RBI

          assert_equal(expected, rbi_for(:Post))
        end

        it "compiles a class with methods that have signatures" do
          add_ruby_file("post.rb", <<~RUBY)
            class Post
              extend T::Sig

              sig { params(a: String, b: Integer, c: Integer).void }
              def bar(a, b = 42, *c)
              end

              sig { params(d: String, e: Integer, f: Integer, blk: T.proc.params(a: String).returns(String)).returns(Integer) }
              def baz(d:, e: 42, **f, &blk)
              end

              sig { type_parameters(:U).params(a: T.type_parameter(:U)).returns(T.type_parameter(:U)) }
              def foo(a)
                a
              end

              sig { params(a: Integer, b: Integer, c: Integer, d: Integer, e: Integer, f: Integer, blk: T.proc.void).void }
              def many_kinds_of_args(*a, b, c, d:, e: 42, **f, &blk)
              end

              sig { params(proc: T.proc.void, blk: T.proc.returns(T.noreturn)).void }
              def method_with_procs(proc, &blk)
              end

              sig { returns(T.proc.params(x: String).void) }
              attr_reader :some_attribute
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Post
              sig { params(a: ::String, b: ::Integer, c: ::Integer).void }
              def bar(a, b = T.unsafe(nil), *c); end

              sig { params(d: ::String, e: ::Integer, f: ::Integer, blk: T.proc.params(a: ::String).returns(::String)).returns(::Integer) }
              def baz(d:, e: T.unsafe(nil), **f, &blk); end

              sig { params(a: T.type_parameter(:U)).returns(T.type_parameter(:U)) }
              def foo(a); end

              sig { params(a: ::Integer, b: ::Integer, c: ::Integer, d: ::Integer, e: ::Integer, f: ::Integer, blk: T.proc.void).void }
              def many_kinds_of_args(*a, b, c, d:, e: T.unsafe(nil), **f, &blk); end

              sig { params(proc: T.proc.void, blk: T.proc.returns(T.noreturn)).void }
              def method_with_procs(proc, &blk); end

              sig { returns(T.proc.params(x: ::String).void) }
              def some_attribute; end
            end
          RBI

          assert_equal(expected, rbi_for(:Post))
        end
      end
    end
  end
end
