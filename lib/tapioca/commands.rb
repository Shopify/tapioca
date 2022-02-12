# typed: true
# frozen_string_literal: true

module Tapioca
  module Commands
    autoload :Command, "tapioca/commands/command"
    autoload :Dsl, "tapioca/commands/dsl"
    autoload :Init, "tapioca/commands/init"
    autoload :Gem, "tapioca/commands/gem"
    autoload :Require, "tapioca/commands/require"
    autoload :Todo, "tapioca/commands/todo"
  end
end
