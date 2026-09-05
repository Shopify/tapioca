# typed: strict
# frozen_string_literal: true

return unless defined?(RuboCop::Cop::Base)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::RubocopNodePattern` generates RBI files for subclasses of
      # [`RuboCop::Cop::Base`](https://docs.rubocop.org/rubocop-ast/node_pattern.html)
      # that use `def_node_matcher` or `def_node_search` macros.
      #
      # For example, with the following cop:
      #
      # ~~~rb
      # class MyCop < RuboCop::Cop::Base
      #   def_node_matcher :using_bang?, <<~PATTERN
      #     (send nil? :bang)
      #   PATTERN
      #
      #   def_node_search :find_lvar_nodes, <<~PATTERN
      #     (lvar $_)
      #   PATTERN
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `my_cop.rbi` with the following content:
      #
      # ~~~rbi
      # # my_cop.rbi
      # # typed: true
      # class MyCop
      #   sig { params(param0: ::RuboCop::AST::Node).returns(T::Boolean) }
      #   def using_bang?(param0 = T.unsafe(nil)); end
      #
      #   sig { params(param0: ::RuboCop::AST::Node, block: T.nilable(T.proc.params(node: ::RuboCop::AST::Node).void)).returns(T::Enumerator[::RuboCop::AST::Node]) }
      #   def find_lvar_nodes(param0, &block); end
      # end
      # ~~~
      #: [ConstantType = singleton(::RuboCop::Cop::Base)]
      class RubocopNodePattern < Compiler
        # @override
        #: -> void
        def decorate
          methods = macro_methods_for(constant)
          return if methods.empty?

          root.create_path(constant) do |scope|
            methods.each do |method_name, macro_type, capture_count, extra_arg_count|
              parameters = build_parameters(macro_type, extra_arg_count)
              return_type = build_return_type(method_name.to_s, macro_type, capture_count)

              if macro_type == :def_node_search && !method_name.to_s.end_with?("?")
                parameters << create_block_param("block", type: "T.nilable(T.proc.params(node: ::RuboCop::AST::Node).void)")
              end

              scope.create_method(
                method_name.to_s,
                parameters: parameters,
                return_type: return_type,
              )
            end
          end
        end

        class << self
          # @override
          #: -> Enumerable[Module[top]]
          def gather_constants
            descendants_of(::RuboCop::Cop::Base)
          end
        end

        private

        #: (Module constant) -> Array[[Symbol, Symbol, Integer, Integer]]
        def macro_methods_for(constant)
          results = [] #: Array[[Symbol, Symbol, Integer, Integer]]

          constant.instance_methods(false).each do |method_name|
            method_def = constant.instance_method(method_name)
            params = method_def.parameters

            next unless node_pattern_method?(params)

            macro_type = detect_macro_type(params)
            next unless macro_type

            pattern = extract_pattern(method_def)
            next unless pattern

            capture_count = count_captures(pattern)
            extra_arg_count = count_extra_args(params)

            results << [method_name, macro_type, capture_count, extra_arg_count]
          end

          results.sort_by(&:first)
        end

        #: (Array[[Symbol, Symbol]] params) -> bool
        def node_pattern_method?(params)
          return false if params.empty?

          params.any? { |_, name| name.to_s.start_with?("param") }
        end

        #: (Array[[Symbol, Symbol]] params) -> Symbol?
        def detect_macro_type(params)
          first_param = params.first
          return unless first_param

          case first_param
          in [:opt, :param0]
            :def_node_matcher
          in [:req, :param0]
            :def_node_search
          else
            nil
          end
        end

        #: (UnboundMethod method_def) -> String?
        def extract_pattern(method_def)
          source_file, source_line = method_def.source_location
          return unless source_file && source_line

          begin
            lines = File.readlines(source_file)
            line = lines[source_line - 1]
            return unless line

            if line.match?(/def_node_matcher|def_node_search/)
              pattern = extract_pattern_from_source(lines, source_line - 1)
              return pattern
            end
          rescue Errno::ENOENT, Errno::EACCES
            nil
          end
        end

        #: (Array[String] lines, Integer start_index) -> String?
        def extract_pattern_from_source(lines, start_index)
          line = lines[start_index]
          return unless line

          if line.include?("<<~")
            heredoc_lines = []
            terminator = line[/<<~(\w+)/, 1]
            return unless terminator

            i = start_index + 1
            while i < lines.length
              current = lines[i]
              break if current&.strip == terminator

              heredoc_lines << current if current
              i += 1
            end
            heredoc_lines.join.strip
          elsif (match = line.match(/['"](.*)['"]\s*$/))
            match[1]
          end
        end

        #: (String pattern) -> Integer
        def count_captures(pattern)
          RuboCop::AST::NodePattern.new(pattern).captures
        rescue StandardError
          0
        end

        #: (Array[[Symbol, Symbol]] params) -> Integer
        def count_extra_args(params)
          params.count { |_, name| name.to_s.match?(/\Aparam[1-9]\d*\z/) }
        end

        #: (Symbol macro_type, Integer extra_arg_count) -> Array[RBI::TypedParam]
        def build_parameters(macro_type, extra_arg_count)
          parameters = [] #: Array[RBI::TypedParam]

          if macro_type == :def_node_matcher
            parameters << create_opt_param("param0", type: "::RuboCop::AST::Node", default: "T.unsafe(nil)")
          else
            parameters << create_param("param0", type: "::RuboCop::AST::Node")
          end

          extra_arg_count.times do |i|
            parameters << create_param("param#{i + 1}", type: "T.untyped")
          end

          parameters
        end

        #: (String method_name, Symbol macro_type, Integer capture_count) -> String
        def build_return_type(method_name, macro_type, capture_count)
          if macro_type == :def_node_matcher
            if capture_count == 0
              "T::Boolean"
            else
              "T.untyped"
            end
          elsif method_name.end_with?("?")
            "T::Boolean"
          else
            "T::Enumerator[::RuboCop::AST::Node]"
          end
        end
      end
    end
  end
end
