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
          # Instead of using `const_source_location`, which always reports the first place where a constant is defined,
          # we filter the locations tracked by ConstantDefinition. This allows us to provide the correct location for
          # constants that are defined by multiple gems.
          locations = Runtime::Trackers::ConstantDefinition.locations_for(event.constant)
          location = locations.find do |loc|
            Pathname.new(loc.path).realpath.to_s.include?(@pipeline.gem.full_gem_path)
          end

          # The location may still be nil in some situations, like constant aliases (e.g.: MyAlias = OtherConst). These
          # are quite difficult to attribute a correct location, given that the source location points to the original
          # constants and not the alias
          add_source_location_comment(event.node, location.path, location.lineno) unless location.nil?
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

          # On native extensions, the source location may point to a shared object (.so, .bundle) file, which we cannot
          # use for jump to definition. Only add source comments on Ruby files
          return unless path.extname == ".rb"

          path = if path.realpath.to_s.start_with?(gem.full_gem_path)
            "#{gem.name}-#{gem.version}/#{path.realpath.relative_path_from(gem.full_gem_path)}"
          else
            path.sub("#{Bundler.bundle_path}/gems/", "").to_s
          end

          # Strip out the RUBY_ROOT prefix, which is different for each user
          path = path.sub(%r{^.*(?=/lib/ruby/[0-9\.]+)}, "RUBY_ROOT")

          node.comments << RBI::Comment.new("") if node.comments.any?
          node.comments << RBI::Comment.new("source://#{path}:#{line}")
        end
      end
    end
  end
end
