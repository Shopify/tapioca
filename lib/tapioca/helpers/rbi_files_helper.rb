# typed: strict
# frozen_string_literal: true

module Tapioca
  # @requires_ancestor: Thor::Shell
  # @requires_ancestor: SorbetHelper
  module RBIFilesHelper
    extend T::Sig
    #: (RBI::Index index, String kind, String file) -> void
    def index_rbi(index, kind, file)
      return unless File.exist?(file)

      say("Loading #{kind} RBIs from #{file}... ")
      time = Benchmark.realtime do
        parse_and_index_files(index, [file], number_of_workers: 1)
      end
      say(" Done ", :green)
      say("(#{time.round(2)}s)")
    end

    #: (RBI::Index index, String kind, String dir, number_of_workers: Integer?) -> void
    def index_rbis(index, kind, dir, number_of_workers:)
      return unless Dir.exist?(dir) && !Dir.empty?(dir)

      if kind == "payload"
        say("Loading Sorbet payload... ")
      else
        say("Loading #{kind} RBIs from #{dir}... ")
      end
      time = Benchmark.realtime do
        files = Dir.glob("#{dir}/**/*.rbi").sort
        parse_and_index_files(index, files, number_of_workers: number_of_workers)
      end
      say(" Done ", :green)
      say("(#{time.round(2)}s)")
    end

    #: (RBI::Index index, shim_rbi_dir: String, todo_rbi_file: String) -> Hash[String, Array[RBI::Node]]
    def duplicated_nodes_from_index(index, shim_rbi_dir:, todo_rbi_file:)
      duplicates = {}
      say("Looking for duplicates... ")
      time = Benchmark.realtime do
        index.keys.each do |key|
          nodes = index[key]
          next unless shims_or_todos_have_duplicates?(nodes, shim_rbi_dir: shim_rbi_dir, todo_rbi_file: todo_rbi_file)

          duplicates[key] = nodes
        end
      end
      say(" Done ", :green)
      say("(#{time.round(2)}s)")
      duplicates
    end

    #: (RBI::Loc loc, path_prefix: String?) -> String
    def location_to_payload_url(loc, path_prefix:)
      return loc.to_s unless path_prefix

      url = loc.file || ""
      return loc.to_s unless url.start_with?(path_prefix)

      url = url.sub(path_prefix, SorbetHelper::SORBET_PAYLOAD_URL)
      url = "#{url}#L#{loc.begin_line}"
      url
    end

    #: (command: String, gem_dir: String, dsl_dir: String, auto_strictness: bool, ?gems: Array[Gemfile::GemSpec], ?compilers: T::Enumerable[singleton(Dsl::Compiler)]) -> void
    def validate_rbi_files(command:, gem_dir:, dsl_dir:, auto_strictness:, gems: [], compilers: [])
      error_url_base = Spoom::Sorbet::Errors::DEFAULT_ERROR_URL_BASE

      say("Checking generated RBI files... ")
      res = sorbet(
        "--no-config",
        "--error-url-base=#{error_url_base}",
        "--stop-after namer",
        dsl_dir,
        gem_dir,
      )
      say(" Done", :green)

      errors = Spoom::Sorbet::Errors::Parser.parse_string(res.err || "")

      if errors.empty?
        say("  No errors found\n\n", [:green, :bold])

        return
      end

      parse_errors = errors.select { |error| error.code < 4000 }

      error_messages = []

      if parse_errors.any?
        error_messages << set_color(<<~ERR, :red)
          ##### INTERNAL ERROR #####

          There are parse errors in the generated RBI files.

          This seems related to a bug in Tapioca.
          Please open an issue at https://github.com/Shopify/tapioca/issues/new with the following information:

          Tapioca v#{Tapioca::VERSION}

          Command:
            #{command}
        ERR

        error_messages << set_color(<<~ERR, :red) if gems.any?
          Gems:
          #{gems.map { |gem| "  #{gem.name} (#{gem.version})" }.join("\n")}
        ERR

        error_messages << set_color(<<~ERR, :red) if compilers.any?
          Compilers:
          #{compilers.map { |compiler| "  #{compiler.name}" }.join("\n")}
        ERR

        error_messages << set_color(<<~ERR, :red)
          Errors:
          #{parse_errors.map { |error| "  #{error}" }.join("\n")}

          ##########################
        ERR
      end

      if auto_strictness
        redef_errors = errors.select { |error| error.code == 4010 }
        update_gem_rbis_strictnesses(redef_errors, gem_dir)
      end

      Kernel.raise Tapioca::Error, error_messages.join("\n") if parse_errors.any?
    end

    private

    #: (RBI::Index index, Array[String] files, number_of_workers: Integer?) -> void
    def parse_and_index_files(index, files, number_of_workers:)
      executor = Executor.new(files, number_of_workers: number_of_workers)

      trees = executor.run_in_parallel do |file|
        next if Spoom::Sorbet::Sigils.file_strictness(file) == "ignore"

        RBI::Parser.parse_file(file)
      rescue RBI::ParseError => e
        say_error("\nWarning: #{e} (#{e.location})", :yellow)
        nil
      end.compact

      index.visit_all(trees)
    end

    # Do the list of `nodes` sharing the same name have duplicates?
    #: (Array[RBI::Node] nodes, shim_rbi_dir: String, todo_rbi_file: String) -> bool
    def shims_or_todos_have_duplicates?(nodes, shim_rbi_dir:, todo_rbi_file:)
      # If there is only one node, there are no duplicates
      return false if nodes.size == 1

      # Extract the nodes from the sorbet/rbi/shims/ directory and the todo.rbi file
      shims_or_todos = extract_shims_and_todos(nodes, shim_rbi_dir: shim_rbi_dir, todo_rbi_file: todo_rbi_file)
      return false if shims_or_todos.empty?

      # First let's look into scopes (classes, modules, sclass) for duplicates
      has_duplicated_scopes?(nodes, shims_or_todos) ||
        # Then let's look into mixins
        has_duplicated_mixins?(shims_or_todos) ||
        # Finally, let's compare the methods and attributes with the same name
        has_duplicated_methods_and_attrs?(nodes, shims_or_todos)
    end

    #: (Array[RBI::Node], Array[RBI::Node]) -> bool
    def has_duplicated_scopes?(all_nodes, shims_or_todos)
      shims_or_todos_scopes = shims_or_todos.grep(RBI::Scope)
      return false if shims_or_todos_scopes.empty?

      # Extract the empty scopes from the shims or todos
      # We do not care about non-empty scopes because they hold definitions that we will check against Tapioca's
      # generated RBI files in another iteration.
      shims_or_todos_empty_scopes = shims_or_todos_scopes.select(&:empty?)

      # Extract the nodes that are not shims or todos (basically the nodes from the RBI files generated by Tapioca)
      not_shims_or_todos = all_nodes - shims_or_todos

      shims_or_todos_empty_scopes.any? do |scope|
        # Empty modules are always duplicates
        break true unless scope.is_a?(RBI::Class)

        # Empty classes without parents are also duplicates
        parent_name = scope.superclass_name
        break true unless parent_name

        # Empty classes that are not redefining the parent are also duplicates
        break true if not_shims_or_todos.any? do |node|
          node.is_a?(RBI::Class) && node.superclass_name == parent_name
        end
      end
    end

    #: (Array[RBI::Node] shims_or_todos) -> bool
    def has_duplicated_mixins?(shims_or_todos)
      # Don't forget `shims_or_todos` is a list of nodes with the same qualified name, so if we find two mixins of the
      # same name, they _are_ about the same thing, like two `include(A)` or two `requires_ancestor(A)` so this is a
      # duplicate
      shims_or_todos.any? { |node| node.is_a?(RBI::Mixin) || node.is_a?(RBI::RequiresAncestor) }
    end

    #: (Array[RBI::Node] nodes, Array[RBI::Node] shims_or_todos) -> bool
    def has_duplicated_methods_and_attrs?(nodes, shims_or_todos)
      shims_or_todos_props = extract_methods_and_attrs(shims_or_todos)
      if shims_or_todos_props.any?
        shims_or_todos_props.each do |shim_or_todo_prop|
          other_nodes = extract_methods_and_attrs(nodes) - [shim_or_todo_prop]

          if shim_or_todo_prop.sigs.empty?
            # If the node doesn't have a signature and is an attribute accessor, we have a duplicate
            return true if shim_or_todo_prop.is_a?(RBI::Attr)

            # Now we know it's a method

            # If the node has no parameters and we compare it against an attribute of the same name, it's a duplicate
            return true if shim_or_todo_prop.params.empty? && other_nodes.grep(RBI::Attr).any?

            # If the node has parameters, we compare them against all the other methods
            # If at least one of them has the same parameters, it's a duplicate
            return true if other_nodes.grep(RBI::Method).any? { |other| shim_or_todo_prop.params == other.params }
          end

          # We compare the shim or todo prop with all the other props of the same name
          other_nodes.each do |node|
            # Another prop has the same sig, we have a duplicate
            return true if shim_or_todo_prop.sigs.any? { |sig| node.sigs.include?(sig) }
          end
        end
      end

      false
    end

    #: (Array[RBI::Node] nodes, shim_rbi_dir: String, todo_rbi_file: String) -> Array[RBI::Node]
    def extract_shims_and_todos(nodes, shim_rbi_dir:, todo_rbi_file:)
      nodes.select do |node|
        node.loc&.file&.start_with?(shim_rbi_dir) || node.loc&.file == todo_rbi_file
      end
    end

    #: (Array[RBI::Node] nodes) -> Array[(RBI::Method | RBI::Attr)]
    def extract_methods_and_attrs(nodes)
      T.cast(
        nodes.select do |node|
          node.is_a?(RBI::Method) || node.is_a?(RBI::Attr)
        end,
        T::Array[T.any(RBI::Method, RBI::Attr)],
      )
    end

    #: (Array[Spoom::Sorbet::Errors::Error] errors, String gem_dir) -> void
    def update_gem_rbis_strictnesses(errors, gem_dir)
      files = []

      errors.each do |error|
        # Collect the file with error
        files << error.file
        error.more.each do |line|
          # Also collect the conflicting definition file paths
          next unless line.include?("Previous definition")

          files << line.split(":").first&.strip
        end
      end

      files
        .uniq
        .sort
        .select { |file| file.start_with?(gem_dir) }
        .each do |file|
          Spoom::Sorbet::Sigils.change_sigil_in_file(file, "false")
          say("\n  Changed strictness of #{file} to `typed: false` (conflicting with DSL files)", [:yellow, :bold])
        end

      say("\n")
    end

    #: (String path) -> String
    def gem_name_from_rbi_path(path)
      T.must(File.basename(path, ".rbi").split("@").first)
    end
  end
end
