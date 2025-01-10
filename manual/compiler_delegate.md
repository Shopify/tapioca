## Delegate

`Tapioca::Dsl::Compilers::Delegate` generates RBI files for classes that use the `delegate` method
from ActiveSupport.

For a class like:

```ruby
class Delegator
 sig { returns(Target) }
 attr_reader :target

 delegate :method, to: :target
end

class Target
 sig { returns(String) }
 def method = "hi"
end
```

This compiler will generate the following RBI file:

```rbi
class Delegator
 sig { returns(Target) }
 attr_reader :target

 sig { returns(String) }
 def method; end
end
```

The `delegate` method can also take the `prefix`, `private` and `allow_nil` options but is not intelligent
about discovering types from instance variables, class_variables and constants - if you delegate to a target
whose type is not discoverable statically, the type will default to T.untyped

Delegates that _themselves_ return a `T.untyped` value will not be generated in the RBI file, since Sorbet
already generates a `T.untyped` return by default
