# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class YardDoc < Base
        extend T::Sig

        IGNORED_COMMENTS = T.let(
          [
            ":doc:",
            ":nodoc:",
            "typed:",
            "frozen_string_literal:",
            "encoding:",
            "warn_indent:",
            "shareable_constant_value:",
            "rubocop:",
          ],
          T::Array[String],
        )

        IGNORED_SIG_TAGS = T.let(["param", "return"], T::Array[String])

        RBS_SIGNATURE_PREFIX = T.let(":", String)

        #: (Pipeline pipeline) -> void
        def initialize(pipeline)
          YARD::Registry.clear
          super(pipeline)
          pipeline.gem.parse_yard_docs
        end

        private

        # @override
        #: (ConstNodeAdded event) -> void
        def on_const(event)
          event.node.comments, _ = documentation_comments(event.symbol)
        end

        # @override
        #: (ScopeNodeAdded event) -> void
        def on_scope(event)
          event.node.comments, _ = documentation_comments(event.symbol)
        end

        # @override
        #: (MethodNodeAdded event) -> void
        def on_method(event)
          separator = event.constant.singleton_class? ? "." : "#"
          name = "#{event.symbol}#{separator}#{event.node.name}"
          event.node.comments, event.node.rbs_sigs = documentation_comments(name, sigs: event.node.sigs)
        end

        #: (String name, ?sigs: Array[RBI::Sig]) -> [Array[RBI::Comment], Array[RBI::RBSSig]]
        def documentation_comments(name, sigs: [])
          yard_docs = YARD::Registry.at(name)
          return [], [] unless yard_docs

          docstring = yard_docs.docstring
          return [], [] if /(copyright|license)/i.match?(docstring)

          comments = []
          rbs_sigs = []

          docstring.lines
            .reject { |line| IGNORED_COMMENTS.any? { |comment| line.include?(comment) } }
            .map! do |line|
              if line.strip.start_with?(RBS_SIGNATURE_PREFIX)
                rbs_sigs << create_rbs_sig(line)
              else
                comments << RBI::Comment.new(line)
              end
            end

          tags = yard_docs.tags
          tags.reject! { |tag| IGNORED_SIG_TAGS.include?(tag.tag_name) } unless sigs.empty?

          comments << RBI::Comment.new("") if comments.any? && tags.any?

          tags.sort_by(&:tag_name).each do |tag|
            line = +"@#{tag.tag_name}"

            tag_name = tag.name
            line << " #{tag_name}" if tag_name

            tag_types = tag.types
            line << " [#{tag_types.join(", ")}]" if tag_types&.any?

            tag_text = tag.text
            if tag_text && !tag_text.empty?
              text_lines = tag_text.lines

              # Example are a special case because we want the text to start on the next line
              line << " #{text_lines.shift&.strip}" unless tag.tag_name == "example"

              text_lines.each do |text_line|
                line << "\n  #{text_line.strip}"
              end
            end

            comments << RBI::Comment.new(line)
          end

          [comments, rbs_sigs]
        end

        #: (String line) -> RBI::RBSSig
        def create_rbs_sig(line)
          sig = T.must(line[1..]).strip

          # attr_* methods don't have to specify "->" in their signatures but since we convert it
          # to a regular method definitions we need to have "->" to represent the return type.
          # Also we need becareful of proc types since they contain a "->" already.
          if !sig.include?("->")
            sig = "-> #{sig}"
          elsif sig.include?("^") # Proc type
            # Check if there's a "->" that's not inside a proc type
            # A proc type will have the form (^(Arg1, Arg2) -> ReturnType)
            outer_arrow_present = !/\([^()]*->[^()]*\)/.match?(sig)
            sig = "-> #{sig}" unless outer_arrow_present
          end

          RBI::RBSSig.new(sig)
        end

        # @override
        #: (NodeAdded event) -> bool
        def ignore?(event)
          event.is_a?(Tapioca::Gem::ForeignScopeNodeAdded)
        end
      end
    end
  end
end
