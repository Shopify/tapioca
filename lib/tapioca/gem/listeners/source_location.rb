# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class SourceLocation < Base
        extend T::Sig

        private

        sig { override.params(event: ConstNodeAdded).void }
        def on_const(event)
          file, line = Object.const_source_location(event.symbol)
          add_source_location_comment(event.node, file, line)
        end

        sig { override.params(event: ScopeNodeAdded).void }
        def on_scope(event)
          location = Runtime::Trackers::ConstantDefinition.locations_for(event.symbol)
          location = location.find do |loc|
            Pathname.new(loc.path).realpath.to_s.include?(@pipeline.gem.full_gem_path)
          end

          add_source_location_comment(event.node, location.path, location.lineno)
        end

        sig { override.params(event: MethodNodeAdded).void }
        def on_method(event)
          file, line = event.method.source_location
          add_source_location_comment(event.node, file, line)
        end

        sig { params(node: RBI::NodeWithComments, file: T.nilable(String), line: T.nilable(Integer)).void }
        def add_source_location_comment(node, file, line)
          return unless file && line

          gem = @pipeline.gem
          path = Pathname.new(file)
          return unless File.exist?(path)

          path = if path.realpath.to_s.start_with?(gem.full_gem_path)
            "#{gem.name}-#{gem.version}/#{path.realpath.relative_path_from(gem.full_gem_path)}"
          else
            path.sub("#{Bundler.bundle_path}/gems/", "")
          end

          node.comments << RBI::Comment.new("") if node.comments.any?
          node.comments << RBI::Comment.new("source://#{path}:#{line}")
        end
      end
    end
  end
end
