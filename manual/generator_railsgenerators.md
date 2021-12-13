## RailsGenerators

`Tapioca::Compilers::Dsl::RailsGenerators` generates RBI files for Rails generators

For example, with the following generator:

~~~rb
# lib/generators/sample_generator.rb
class ServiceGenerator < Rails::Generators::NamedBase
  argument :result_type, type: :string

  class_option :skip_comments, type: :boolean, default: false
end
~~~

this compiler will produce the RBI file `service_generator.rbi` with the following content:

~~~rbi
# service_generator.rbi
# typed: strong

class ServiceGenerator
  sig { returns(::String)}
  def result_type; end

  sig { returns(T::Boolean)}
  def skip_comments; end
end
~~~
