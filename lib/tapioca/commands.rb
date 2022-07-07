# typed: true
# frozen_string_literal: true

module Tapioca
  module Commands
    autoload :Command, "tapioca/commands/command"
    autoload :Annotations, "tapioca/commands/annotations"
    autoload :CheckShims, "tapioca/commands/check_shims"
    autoload :Dsl, "tapioca/commands/dsl"
    autoload :Configure, "tapioca/commands/configure"
    autoload :Gem, "tapioca/commands/gem"
    autoload :Require, "tapioca/commands/require"
    autoload :Todo, "tapioca/commands/todo"
  end
end
