## ActiveSupportEnvironmentInquirer

`Tapioca::Dsl::Compilers::ActiveSupportEnvironmentInquirer` decorates an RBI file for non-default environment
files in the `config/environments` directory.

For example, in a Rails application with the following files:

- config/environments/development.rb
- config/environments/demo.rb
- config/environments/production.rb
- config/environments/staging.rb
- config/environments/test.rb

this compiler will produce an RBI file with the following content:
~~~rbi
# typed: true

class ActiveSupport::EnvironmentInquirer
  sig { returns(T::Boolean) }
  def demo?; end

  sig { returns(T::Boolean) }
  def staging?; end
end
~~~
