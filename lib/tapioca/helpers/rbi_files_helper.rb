# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBIFilesHelper
    extend T::Sig
    extend T::Helpers

    requires_ancestor { Thor::Shell }
    requires_ancestor { SorbetHelper }

    sig { params(index: RBI::Index, dir: String).void }
    def index_payload(index, dir)
      return unless Dir.exist?(dir)

      say("Loading Sorbet payload... ")
      files = Dir.glob("#{dir}/**/*.rbi").sort
      parse_and_index_files(index, files)
      say(" Done", :green)
    end

    sig { params(index: RBI::Index, kind: String, dir: String).void }
    def index_rbis(index, kind, dir)
      return unless Dir.exist?(dir) && !Dir.empty?(dir)

      say("Loading #{kind} RBIs from #{dir}... ")
      files = Dir.glob("#{dir}/**/*.rbi").sort
      parse_and_index_files(index, files)
      say(" Done", :green)
    end

    sig { params(index: RBI::Index, shim_rbi_dir: String).returns(T::Hash[String, T::Array[RBI::Node]]) }
    def duplicated_nodes_from_index(index, shim_rbi_dir)
      duplicates = {}
      say("Looking for duplicates... ")
      index.keys.each do |key|
        nodes = index[key]
        next unless shims_have_duplicates?(nodes, shim_rbi_dir)

        duplicates[key] = nodes
      end
      say(" Done", :green)
      duplicates
    end

    sig { params(loc: RBI::Loc, path_prefix: T.nilable(String)).returns(String) }
    def location_to_payload_url(loc, path_prefix:)
      return loc.to_s unless path_prefix

      url = loc.file || ""
      return loc.to_s unless url.start_with?(path_prefix)

      url = url.sub(path_prefix, SorbetHelper::SORBET_PAYLOAD_URL)
      url = "#{url}#L#{loc.begin_line}"
      url
    end

    sig do
      params(
        command: String,
        gem_dir: String,
        dsl_dir: String,
        auto_strictness: T::Boolean,
        gems: T::Array[Gemfile::GemSpec],
        compilers: T::Enumerable[Class]
      ).void
    end
    def validate_rbi_files(command:, gem_dir:, dsl_dir:, auto_strictness:, gems: [], compilers: [])
      error_url_base = Spoom::Sorbet::Errors::DEFAULT_ERROR_URL_BASE

      say("Checking generated RBI files... ")
      res = sorbet(
        "--no-config",
        "--error-url-base=#{error_url_base}",
        "--stop-after namer",
        dsl_dir,
        gem_dir
      )
      say(" Done", :green)

      errors = Spoom::Sorbet::Errors::Parser.parse_string(res.err)

      if errors.empty?
        say("  No errors found\n\n", [:green, :bold])
        return
      end

      parse_errors = errors.select { |error| error.code < 4000 }

      if parse_errors.any?
        say_error(<<~ERR, :red)

          ##### INTERNAL ERROR #####

          There are parse errors in the generated RBI files.

          This seems related to a bug in Tapioca.
          Please open an issue at https://github.com/Shopify/tapioca/issues/new with the following information:

          Tapioca v#{Tapioca::VERSION}

          Command:
            #{command}

        ERR

        say_error(<<~ERR, :red) if gems.any?
          Gems:
          #{gems.map { |gem| "  #{gem.name} (#{gem.version})" }.join("\n")}

        ERR

        say_error(<<~ERR, :red) if compilers.any?
          Compilers:
          #{compilers.map { |compiler| "  #{compiler.name}" }.join("\n")}

        ERR

        say_error(<<~ERR, :red)
          Errors:
          #{parse_errors.map { |error| "  #{error}" }.join("\n")}

          ##########################

        ERR
      end

      if auto_strictness
        redef_errors = errors.select { |error| error.code == 4010 }
        update_gem_rbis_strictnesses(redef_errors, gem_dir)
      end

      Kernel.exit(1) if parse_errors.any?
    end

    private

    sig { params(index: RBI::Index, files: T::Array[String]).void }
    def parse_and_index_files(index, files)
      trees = files.map do |file|
        RBI::Parser.parse_file(file)
      rescue RBI::ParseError => e
        say_error("\nWarning: #{e} (#{e.location})", :yellow)
      end.compact
      index.visit_all(trees)
    end

    sig { params(nodes: T::Array[RBI::Node], shim_rbi_dir: String).returns(T::Boolean) }
    def shims_have_duplicates?(nodes, shim_rbi_dir)
      return false if nodes.size == 1

      shims = extract_shims(nodes, shim_rbi_dir)
      return false if shims.empty?

      props = extract_methods_and_attrs(shims)
      return false if props.empty?

      shims_with_sigs = extract_nodes_with_sigs(props)
      shims_with_sigs.each do |shim|
        shim_sigs = shim.sigs

        extract_methods_and_attrs(nodes).each do |node|
          next if node == shim
          return true if shim_sigs.all? { |sig| node.sigs.include?(sig) }
        end

        return false
      end

      true
    end

    sig { params(nodes: T::Array[RBI::Node], shim_rbi_dir: String).returns(T::Array[RBI::Node]) }
    def extract_shims(nodes, shim_rbi_dir)
      nodes.select do |node|
        node.loc&.file&.start_with?(shim_rbi_dir)
      end
    end

    sig { params(nodes: T::Array[RBI::Node]).returns(T::Array[T.any(RBI::Method, RBI::Attr)]) }
    def extract_methods_and_attrs(nodes)
      T.cast(nodes.select do |node|
        node.is_a?(RBI::Method) || node.is_a?(RBI::Attr)
      end, T::Array[T.any(RBI::Method, RBI::Attr)])
    end

    sig { params(nodes: T::Array[T.any(RBI::Method, RBI::Attr)]).returns(T::Array[T.any(RBI::Method, RBI::Attr)]) }
    def extract_nodes_with_sigs(nodes)
      nodes.reject { |node| node.sigs.empty? }
    end

    sig { params(errors: T::Array[Spoom::Sorbet::Errors::Error], gem_dir: String).void }
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

    sig { params(path: String).returns(String) }
    def gem_name_from_rbi_path(path)
      T.must(File.basename(path, ".rbi").split("@").first)
    end
  end
end
