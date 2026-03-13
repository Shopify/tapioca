# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class SourceLocation < Base
        include GemHelper

        #: (Pipeline pipeline) -> void
        def initialize(pipeline)
          super
          @realpath_cache = {} #: Hash[String, String]
          @gem_full_path = pipeline.gem.full_gem_path #: String
          @spec_lookup = Gemfile::GemSpec.spec_lookup_by_file_path #: Hash[String, Gemfile::GemSpec]
        end

        private

        #: (String file) -> String
        def cached_realpath(file)
          @realpath_cache[file] ||= to_realpath(file)
        end

        # @override
        #: (ConstNodeAdded event) -> void
        def on_const(event)
          file, line = Object.const_source_location(event.symbol)
          add_source_location_comment(event.node, file, line)
        end

        # @override
        #: (ScopeNodeAdded event) -> void
        def on_scope(event)
          # Instead of using `const_source_location`, which always reports the first place where a constant is defined,
          # we filter the locations tracked by ConstantDefinition. This allows us to provide the correct location for
          # constants that are defined by multiple gems.
          locations = Runtime::Trackers::ConstantDefinition.locations_for(event.constant)
          gem_path_prefix = @gem_full_path + "/"
          location = locations.find do |loc|
            rp = cached_realpath(loc.file)
            rp.start_with?(gem_path_prefix) || rp == @gem_full_path
          end

          # The location may still be nil in some situations, like constant aliases (e.g.: MyAlias = OtherConst). These
          # are quite difficult to attribute a correct location, given that the source location points to the original
          # constants and not the alias
          add_source_location_comment(event.node, location.file, location.line) unless location.nil?
        end

        # @override
        #: (MethodNodeAdded event) -> void
        def on_method(event)
          definition = @pipeline.method_definition_in_gem(event.method.name, event.constant)

          if Pipeline::MethodInGemWithLocation === definition
            loc = definition.location
            add_source_location_comment(event.node, loc.file, loc.line)
          end
        end

        #: (RBI::NodeWithComments node, String? file, Integer? line) -> void
        def add_source_location_comment(node, file, line)
          return unless file && line
          return unless file.end_with?(".rb")

          realpath = cached_realpath(file)
          gem = @spec_lookup[realpath]
          return if gem.nil?

          # Use string manipulation instead of Pathname for relative path
          relative = string_relative_path(realpath, gem)

          # Build package URL string directly instead of constructing PackageURL objects.
          # Format: pkg:gem/NAME@VERSION#SUBPATH or pkg:gem/NAME#SUBPATH
          url_prefix = gem_url_prefix(gem)
          url = "#{url_prefix}##{relative}:#{line}"

          node.comments << RBI::Comment.new("") if node.comments.any?
          node.comments << RBI::Comment.new(url)
        end

        #: (Gemfile::GemSpec gem) -> String
        def gem_url_prefix(gem)
          @url_prefix_cache ||= {} #: Hash[String, String]?
          @url_prefix_cache[gem.name] ||= begin
            version = gem.version
            version = "" if gem == @pipeline.gem
            if version.empty?
              "pkg:gem/#{gem.name}"
            else
              "pkg:gem/#{gem.name}@#{version}"
            end
          end
        end

        #: (String realpath, Gemfile::GemSpec gem) -> String
        def string_relative_path(realpath, gem)
          if gem.respond_to?(:default_gem?) && gem.send(:default_gem?)
            base = RbConfig::CONFIG["rubylibdir"]
          else
            base = gem.full_gem_path
          end
          prefix = base.end_with?("/") ? base : "#{base}/"
          if realpath.start_with?(prefix)
            realpath[prefix.length..]
          else
            # Fallback to Pathname for edge cases
            Pathname.new(realpath).relative_path_from(base).to_s
          end
        end
      end
    end
  end
end
