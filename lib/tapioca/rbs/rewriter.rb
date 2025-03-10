# typed: strict
# frozen_string_literal: true

require "ruby-next/language/runtime"

require "debug"

Module.include(T::Sig)

module Tapioca
  module RBS
    # Transpiles RBS comments to sig blocks
    # These sig blocks are then used by the SorbetSignatures listener to generate RBI files with the correct format
    class Rewriter < RubyNext::Language::Rewriters::Text
      NAME = "rbs_rewriter"

      #: (String source) -> String
      def rewrite(source)
        rbs_comments = collect_rbs_comments(source)
        rbs_comments.reverse_each do |rbs, node|
          scanner = Spoom::Sorbet::Sigs::Scanner.new(source)
          start_index = scanner.find_char_position(
            rbs.loc&.begin_line&.pred,
            rbs.loc&.begin_column,
          )
          end_index = scanner.find_char_position(
            rbs.loc&.end_line&.pred,
            rbs.loc&.end_column,
          )

          context.track!(self)
          sig = translate(rbs, node)
          source[start_index..end_index] = sig unless sig.empty?
        end

        source
      end

      private

      #: (RBI::RBSComment rbs, RBI::Node node) -> String
      def translate(rbs, node)
        case node
        when RBI::Method
          method_type = ::RBS::Parser.parse_method_type(rbs.text)
          RBI::RBS::MethodTypeTranslator.translate(node, method_type).string
        when RBI::Attr
          return "" if rbs.text == "nodoc:"

          RBI::Rewriters::TranslateRBSSigs.new.send(:translate_rbs_attr_type, node, rbs).string
        end
      rescue ::RBS::ParsingError
        ""
      end

      #: (String source) -> Array[[RBI::RBSComment, RBI::Node]]
      def collect_rbs_comments(source)
        tree = RBI::Parser.parse_string(source)
        visitor = RBSLocator.new
        visitor.visit(tree)

        visitor.rbs_comments
      end

      #: (String source) -> Integer
      def find_first_non_comment_line(source)
        lines = source.lines
        lines.each_with_index do |line, index|
          next if line.start_with?("#")

          return index
        end
        0
      end
    end

    class RBSLocator < RBI::Visitor
      #: Array[[RBI::RBSComment, (RBI::Method | RBI::Attr)]]
      attr_reader :rbs_comments

      #: -> void
      def initialize
        super
        @rbs_comments = T.let([], T::Array[[RBI::RBSComment, T.any(RBI::Method, RBI::Attr)]])
      end

      #: (RBI::Node? node) -> void
      def visit(node)
        return unless node

        case node
        when RBI::Method, RBI::Attr
          node.comments.each do |comment|
            @rbs_comments << [comment, node] if comment.is_a?(RBI::RBSComment)
          end
        when RBI::Tree
          visit_all(node.nodes)
        end
      end
    end
  end
end

RubyNext::Language.include_patterns.clear
RubyNext::Language.include_patterns << "**/*.rb"
# RubyNext::Language.include_patterns << "**/foo.rb"

# Only transform files from gems that have Sorbet configuration
# RequireHooks.source_transform(patterns: ["**/*.rb"]) do |path, source|
#   # Extract the potential gem root path from the file path
#   # For a path like "/opt/rubies/3.4.1/lib/ruby/gems/3.4.0/gems/rake-13.2.1/lib/rake/rake_module.rb"
#   # We want to check if "/opt/rubies/3.4.1/lib/ruby/gems/3.4.0/gems/rake-13.2.1" has a sorbet config

#   path_obj = Pathname.new(path)

#   # Find the lib directory in the path
#   lib_index = path_obj.each_filename.to_a.index("lib")

#   if lib_index
#     # The potential gem root is the directory containing the lib directory
#     potential_gem_root = path_obj.dirname.ascend.find { |p| p.basename.to_s == "lib" }&.dirname

#     # Check if this potential gem root has a sorbet/config.yml file
#     if potential_gem_root && File.exist?(File.join(potential_gem_root.to_s, "sorbet", "config.yml"))
#       puts "Transforming file from Sorbet-enabled gem: #{path}"
#       RubyNext::Language::Runtime.load(path, source)
#     else
#       # Skip transformation for gems without Sorbet config
#       source
#     end
#   else
#     # Not in a lib directory, skip transformation
#     source
#   end
# end

RubyNext::Language.rewriters = [Tapioca::RBS::Rewriter]

# # Clean up RBI namespace and loaded features
# if defined?(RBI)
#   # Get all constants under RBI namespace
#   rbi_constants = RBI.constants.map { |const| "RBI::#{const}" }

#   # Remove all RBI constants
#   rbi_constants.each do |const|
#     const_parts = const.split("::")
#     parent = const_parts[0...-1].inject(Object) { |mod, const_name| mod.const_get(const_name) }
#     const_name = const_parts.last
#     parent.send(:remove_const, const_name) if parent.const_defined?(const_name)
#   end

#   # Remove RBI itself
#   # Object.send(:remove_const, :RBI) if Object.const_defined?(:RBI)
# end

# # Remove all entries pointing to rbi gem path in LOADED_FEATURES
# if defined?(Gem) && Gem.loaded_specs["rbi"]
#   rbi_path = Gem.loaded_specs["rbi"].full_gem_path
#   $LOADED_FEATURES.reject! { |path| path.include?(rbi_path) }
# end

# require "rbi"
# puts "Loaded RBI"
