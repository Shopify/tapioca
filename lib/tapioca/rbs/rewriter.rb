# typed: strict
# frozen_string_literal: true

require "ruby-next/language/runtime"

# Load all files from the RBI gem
# Dir["#{Gem.loaded_specs["rbi"].full_gem_path}/lib/**/*.rb"].sort.each do |file|
#   load file
# end

module Tapioca
  module RBS
    # Transpiles RBS comments to sig blocks
    # These sig blocks are then used by the SorbetSignatures listener to generate RBI files with the correct format
    class Rewriter < RubyNext::Language::Rewriters::Text
      NAME = "rbs_rewriter"

      #: (String source) -> String
      def rewrite(source)
        # Add Module.include(T::Sig) at the start of the file after any magic comments
        lines = source.lines
        first_non_comment_line = find_first_non_comment_line(source)
        lines.insert(first_non_comment_line, "Module.include(T::Sig)\n\n")

        context.track!(self)
        source = lines.join

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
          source[start_index...end_index] = sig unless sig.empty?
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
RubyNext::Language.rewriters = [Tapioca::RBS::Rewriter]
