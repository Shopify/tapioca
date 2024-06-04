# typed: strict
# frozen_string_literal: true

module RubyLsp
  module Tapioca
    class Client
      extend T::Sig

      sig { void }
      def initialize
        $stderr.puts "Initializing client"
      end

      sig { void }
      def sync_gems
        $stderr.puts "Sync gems"
      end

      sig { params(constants: T::Array[String]).void }
      def dsl(constants)
        $stderr.puts "DSL"
        $stderr.puts constants
      end
    end
  end
end
