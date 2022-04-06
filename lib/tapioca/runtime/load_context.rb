# typed: true
# frozen_string_literal: true

require "singleton"

module Tapioca
  extend T::Sig

  sig { params(type: Symbol, blk: T.proc.params(arg0: T.untyped).void).void }
  def self.loader_for(type, &blk)
    LoadContext.instance.add(type, blk)
  end

  class LoadContext
    extend T::Sig
    include Singleton

    def add(type, blk)
      @loaders[type] = blk
    end

    def run_load_commands_for(command)
      @command = command
      instance_exec(&@loaders[:dsl])
    end

    sig { void }
    def initialize
      @loader = T.let(Tapioca::Runtime::Loader.new, Tapioca::Runtime::Loader)
    end

    sig { void }
    def load_for_dsl
      @command.run_default_load_actions(@loader)
    end
  end
end
