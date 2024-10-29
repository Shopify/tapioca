# typed: false
# frozen_string_literal: true

require "tapioca/internal"
require "objspace"

$runs = 1

module RubyLsp
  module Tapioca
    class ServerAddon < ::RubyLsp::Rails::ServerAddon
      def name
        "Tapioca"
      end

      def execute(request, params)
        case request
        when "dsl"
          dsl(params)
        end
        reset_runtime_tracker_state
        puts "Mixins to constants size: #{ObjectSpace.memsize_of(::Tapioca::Runtime::Trackers::Mixin.instance_variable_get(:@mixins_to_constants))}"
      end

      private

      def dsl(params)
        GC.compact
        ObjectSpace.trace_object_allocations_start
        load("tapioca/cli.rb") # Reload the CLI to reset thor defaults between requests
        ::Tapioca::Cli.start(["dsl", "--lsp_addon", "--workers=1"] + params[:constants])
        # Object.const_get("Shop")
        ObjectSpace.trace_object_allocations_stop
        ObjectSpace.dump_all(output: File.open("tmp/tapioca-#{$runs}", "w+"))
        $runs += 1
      end

      def reset_runtime_tracker_state
        ::Tapioca::Runtime::Trackers.reset_state
      end
    end
  end
end
