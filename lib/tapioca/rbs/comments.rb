# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBS
    # Parses RBS comments (e.g. `#: -> void`, `#| continuation`, `# @abstract`,
    # `# @requires_ancestor: Kernel`, `#: [A, B]`) out of a stream of raw comment
    # strings that immediately precede a Ruby construct (method, attr, class).
    #
    # The result is a {Comments::Parsed} object exposing parsed signatures
    # and annotations, classified into class-level and method-level annotations.
    #
    # This implementation mirrors the logic in `Spoom::RBS::ExtractRBSComments`,
    # but operates on plain `[comment_string, line]` tuples (as obtained from
    # Rubydex or any other comment provider) rather than Prism nodes, so it can
    # be used without re-parsing source files.
    module Comments
      Signature = Struct.new(:string, :line)
      Annotation = Struct.new(:string, :line)

      CLASS_ANNOTATION_PATTERN = /\A(@abstract|@interface|@sealed|@final|@requires_ancestor:)/ #: Regexp
      METHOD_ANNOTATION_NAMES = [
        "@abstract",
        "@final",
        "@override",
        "@override(allow_incompatible: true)",
        "@override(allow_incompatible: :visibility)",
        "@overridable",
        "@without_runtime",
      ].freeze #: Array[String]
      private_constant :CLASS_ANNOTATION_PATTERN, :METHOD_ANNOTATION_NAMES

      class Parsed
        #: Array[Signature]
        attr_reader :signatures

        #: Array[Annotation]
        attr_reader :annotations

        #: -> void
        def initialize
          @signatures = [] #: Array[Signature]
          @annotations = [] #: Array[Annotation]
        end

        #: -> bool
        def empty?
          @signatures.empty? && @annotations.empty?
        end

        #: -> Array[Annotation]
        def class_annotations
          @annotations.select { |a| a.string.match?(CLASS_ANNOTATION_PATTERN) }
        end

        #: -> Array[Annotation]
        def method_annotations
          @annotations.select { |a| METHOD_ANNOTATION_NAMES.include?(a.string) }
        end
      end

      class << self
        # Parses a list of `[comment_string, line]` tuples (ordered by line, top to
        # bottom) into a {Parsed} object.
        #
        # The tuples must be the contiguous block of comments that immediately
        # precedes the construct of interest; callers are responsible for
        # selecting the right block.
        #: (Array[[String, Integer]] comments) -> Parsed
        def parse(comments)
          result = Parsed.new

          continuation_comments = [] #: Array[[String, Integer]]

          comments.reverse_each do |string, line|
            if string.start_with?("# @")
              annotation = string.delete_prefix("#").strip
              result.annotations.unshift(Annotation.new(annotation, line))
            elsif string.start_with?("#: ") || string == "#:"
              sig_string = string.delete_prefix("#:").strip

              # Continuation comments are accumulated by pushing while we walk
              # source comments in reverse order (so they sit in
              # last-line-first order in the array). Walking the array in
              # reverse here puts them back in forward source order before
              # we append them to the signature string.
              continuation_comments.reverse_each do |cont_string, _cont_line|
                sig_string = "#{sig_string}#{cont_string.delete_prefix("#|")}"
              end
              continuation_comments.clear

              result.signatures.unshift(Signature.new(sig_string, line))
            elsif string.start_with?("#|")
              continuation_comments << [string, line]
            else
              continuation_comments.clear
            end
          end

          result
        end
      end
    end
  end
end
