## RuboCop

`Tapioca::Dsl::Compilers::RuboCop` generates types for RuboCop cops.
RuboCop uses macros to define methods leveraging "AST node patterns".
For example, in this cop

  class MyCop < Base
    def_node_matcher :matches_some_pattern?, "..."

    def on_send(node)
      return unless matches_some_pattern?(node)
      # ...
    end
  end

the use of `def_node_matcher` will generate the method
`matches_some_pattern?`, for which this compiler will generate a `sig`.

More complex uses are also supported, including:

- Usage of `def_node_search`
- Parameter specification
- Default parameter specification, including generating sigs for
  `without_defaults_*` methods
