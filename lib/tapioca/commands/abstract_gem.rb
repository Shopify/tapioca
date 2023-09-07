# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class AbstractGem < Command
      include SorbetHelper
      include RBIFilesHelper

      abstract!

      sig do
        params(
          gem_names: T::Array[String],
          exclude: T::Array[String],
          include_dependencies: T::Boolean,
          prerequire: T.nilable(String),
          postrequire: String,
          typed_overrides: T::Hash[String, String],
          outpath: Pathname,
          file_header: T::Boolean,
          include_doc: T::Boolean,
          include_loc: T::Boolean,
          include_annotations: T::Boolean,
          include_exported_rbis: T::Boolean,
          annotations_sources: T::Array[String],
          annotations_auth: T.nilable(String),
          annotations_netrc_file: T.nilable(String),
          excluded_annotations: T::Array[String],
          number_of_workers: T.nilable(Integer),
          auto_strictness: T::Boolean,
          dsl_dir: String,
          rbi_formatter: RBIFormatter,
          halt_upon_load_error: T::Boolean,
        ).void
      end
      def initialize(
        gem_names:,
        exclude:,
        include_dependencies:,
        prerequire:,
        postrequire:,
        typed_overrides:,
        outpath:,
        file_header:,
        include_doc:,
        include_loc:,
        include_annotations:,
        include_exported_rbis:,
        annotations_sources:,
        annotations_auth: nil,
        annotations_netrc_file: nil,
        excluded_annotations: [],
        number_of_workers: nil,
        auto_strictness: true,
        dsl_dir: DEFAULT_DSL_DIR,
        rbi_formatter: DEFAULT_RBI_FORMATTER,
        halt_upon_load_error: true
      )
        @gem_names = gem_names
        @exclude = exclude
        @include_dependencies = include_dependencies
        @prerequire = prerequire
        @postrequire = postrequire
        @typed_overrides = typed_overrides
        @outpath = outpath
        @file_header = file_header
        @number_of_workers = number_of_workers
        @auto_strictness = auto_strictness
        @dsl_dir = dsl_dir
        @rbi_formatter = rbi_formatter

        super()

        @bundle = T.let(Gemfile.new(exclude), Gemfile)
        @existing_rbis = T.let(nil, T.nilable(T::Hash[String, String]))
        @expected_rbis = T.let(nil, T.nilable(T::Hash[String, String]))
        @include_doc = T.let(include_doc, T::Boolean)
        @include_loc = T.let(include_loc, T::Boolean)
        @include_annotations = include_annotations
        @include_exported_rbis = include_exported_rbis
        @annotations_sources = annotations_sources
        @annotations_auth = annotations_auth
        @annotations_netrc_file = annotations_netrc_file
        @annotation_netrc_info = T.let(nil, T.nilable(Netrc))
        @excluded_annotations = excluded_annotations
        @tokens = T.let(repo_tokens, T::Hash[String, T.nilable(String)])
        @indexes = T.let({}, T::Hash[String, RepoIndex])
        @halt_upon_load_error = halt_upon_load_error
      end

      private

      sig { params(repo_uri: String, path: String).returns(T.nilable(String)) }
      def fetch_file(repo_uri, path)
        if repo_uri.start_with?(%r{https?://})
          fetch_http_file(repo_uri, path)
        else
          fetch_local_file(repo_uri, path)
        end
      end

      sig { params(repo_uri: String, path: String).returns(T.nilable(String)) }
      def fetch_local_file(repo_uri, path)
        File.read("#{repo_uri}/#{path}")
      rescue => e
        say_error("\nCan't fetch file `#{path}` (#{e.message})", :bold, :red)
        nil
      end

      sig { params(repo_uri: String, path: String).returns(T.nilable(String)) }
      def fetch_http_file(repo_uri, path)
        auth = @tokens[repo_uri]
        uri = URI("#{repo_uri}/#{path}")

        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = auth if auth

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end

        case response
        when Net::HTTPSuccess
          response.body
        else
          say_http_error(path, repo_uri, message: response.class)
          nil
        end
      rescue SocketError, Errno::ECONNREFUSED => e
        say_http_error(path, repo_uri, message: e.message)
        nil
      end

      sig { params(repo_uri: String, repo_number: T.nilable(Integer)).returns(T.nilable(RepoIndex)) }
      def fetch_annotation_source_index(repo_uri, repo_number:)
        say("Retrieving index from central repository#{repo_number ? " ##{repo_number}" : ""}... ", [:blue, :bold])
        content = fetch_file(repo_uri, CENTRAL_REPO_INDEX_PATH)
        return unless content

        index = RepoIndex.from_json(content)
        say("Done", :green)
        index
      end

      sig { returns(T::Hash[String, RepoIndex]) }
      def fetch_annotation_source_indexes
        multiple_repos = @annotations_sources.size > 1
        repo_number = 1
        indexes = T.let({}, T::Hash[String, RepoIndex])

        @annotations_sources.each do |uri|
          index = fetch_annotation_source_index(uri, repo_number: multiple_repos ? repo_number : nil)
          next unless index

          indexes[uri] = index
          repo_number += 1
        end

        if indexes.empty?
          raise Thor::Error, set_color(
            "Can't fetch annotations without sources (no index fetched)." \
              "Use `--no-annotations` to disable annotations.",
            :bold,
            :red,
          )
        end

        indexes
      end

      sig { params(gem_names: T::Array[String]).returns(T::Array[Gemfile::GemSpec]) }
      def gems_to_generate(gem_names)
        return @bundle.dependencies if gem_names.empty?

        gem_names.each_with_object([]) do |gem_name, gems|
          gem = @bundle.gem(gem_name)

          if gem.nil?
            raise Thor::Error, set_color("Error: Cannot find gem '#{gem_name}'", :red)
          end

          gems.concat(gem_dependencies(gem)) if @include_dependencies
          gems << gem
        end
      end

      sig do
        params(
          gem: Gemfile::GemSpec,
          dependencies: T::Array[Gemfile::GemSpec],
        ).returns(T::Array[Gemfile::GemSpec])
      end
      def gem_dependencies(gem, dependencies = [])
        direct_dependencies = gem.dependencies.filter_map { |dependency| @bundle.gem(dependency.name) }
        gems = dependencies | direct_dependencies

        if direct_dependencies.empty?
          gems
        else
          direct_dependencies.reduce(gems) { |result, gem| gem_dependencies(gem, result) }
        end
      end

      sig { params(gem: Gemfile::GemSpec).void }
      def compile_gem_rbi(gem)
        rbi = RBI::File.new(strictness: @typed_overrides[gem.name] || "true")

        @rbi_formatter.write_header!(
          rbi,
          default_command(:gem, gem.name),
          reason: "types exported from the `#{gem.name}` gem",
        ) if @file_header

        rbi.root = Tapioca::Gem::Pipeline.new(gem, include_doc: @include_doc, include_loc: @include_loc).compile

        annotation = fetch_annotation(gem.name) if @include_annotations
        merge_with_annotation(annotation, rbi) if annotation
        merge_with_exported_rbi(gem, rbi) if @include_exported_rbis

        formatted_gem_name = set_color(gem.name, :yellow, :bold)
        if rbi.empty?
          @rbi_formatter.write_empty_body_comment!(rbi)
          say("Compiled #{formatted_gem_name} (empty output)", :yellow)
        else
          annotation_msg = " with external annotations" if annotation
          say("Compiled #{formatted_gem_name}#{annotation_msg}", :green)
        end

        rbi_string = @rbi_formatter.print_file(rbi)
        create_file(@outpath / gem.rbi_file_name, rbi_string)

        T.unsafe(Pathname).glob((@outpath / "#{gem.name}@*.rbi").to_s) do |file|
          remove_file(file) unless file.basename.to_s == gem.rbi_file_name
        end
      end

      sig { void }
      def perform_removals
        say("Removing RBI files of gems that have been removed:", [:blue, :bold])
        puts

        anything_done = T.let(false, T::Boolean)

        gems = removed_rbis

        shell.indent do
          if gems.empty?
            say("Nothing to do.")
          else
            gems.each do |removed|
              filename = existing_rbi(removed)
              remove_file(filename)
            end

            anything_done = true
          end
        end

        puts

        anything_done
      end

      sig { void }
      def perform_additions
        say("Generating RBI files of gems that are added or updated:", [:blue, :bold])
        puts

        anything_done = T.let(false, T::Boolean)

        gems = added_rbis

        shell.indent do
          if gems.empty?
            say("Nothing to do.")
          else
            Loaders::Gem.load_application(
              bundle: @bundle,
              prerequire: @prerequire,
              postrequire: @postrequire,
              default_command: default_command(:require),
              halt_upon_load_error: @halt_upon_load_error,
            )

            Executor.new(gems, number_of_workers: @number_of_workers).run_in_parallel do |gem_name|
              filename = expected_rbi(gem_name)

              if gem_rbi_exists?(gem_name)
                old_filename = existing_rbi(gem_name)
                move(old_filename, filename) unless old_filename == filename
              end

              gem = T.must(@bundle.gem(gem_name))
              compile_gem_rbi(gem)
              puts
            end
          end

          anything_done = true
        end

        puts

        anything_done
      end

      sig { returns(T::Array[String]) }
      def removed_rbis
        (existing_rbis.keys - expected_rbis.keys).sort
      end

      sig { params(gem_name: String).returns(Pathname) }
      def existing_rbi(gem_name)
        gem_rbi_filename(gem_name, T.must(existing_rbis[gem_name]))
      end

      sig { returns(T::Array[String]) }
      def added_rbis
        expected_rbis.select do |name, value|
          existing_rbis[name] != value
        end.keys.sort
      end

      sig { params(gem_name: String).returns(Pathname) }
      def expected_rbi(gem_name)
        gem_rbi_filename(gem_name, T.must(expected_rbis[gem_name]))
      end

      sig { params(gem_name: String).returns(T::Boolean) }
      def gem_rbi_exists?(gem_name)
        existing_rbis.key?(gem_name)
      end

      sig { params(diff: T::Hash[String, Symbol], command: Symbol).void }
      def report_diff_and_exit_if_out_of_date(diff, command)
        if diff.empty?
          say("Nothing to do, all RBIs are up-to-date.")
        else
          reasons = diff.group_by(&:last).sort.map do |cause, diff_for_cause|
            build_error_for_files(cause, diff_for_cause.map(&:first))
          end.join("\n")

          raise Thor::Error, <<~ERROR
            #{set_color("RBI files are out-of-date. In your development environment, please run:", :green)}
              #{set_color("`#{default_command(command)}`", :green, :bold)}
            #{set_color("Once it is complete, be sure to commit and push any changes", :green)}

            #{set_color("Reason:", :red)}
            #{reasons}
          ERROR
        end
      end

      sig { params(old_filename: Pathname, new_filename: Pathname).void }
      def move(old_filename, new_filename)
        say("-> Moving: #{old_filename} to #{new_filename}")
        old_filename.rename(new_filename.to_s)
      end

      sig { returns(T::Hash[String, String]) }
      def existing_rbis
        @existing_rbis ||= Pathname.glob((@outpath / "*@*.rbi").to_s)
          .to_h { |f| T.cast(f.basename(".*").to_s.split("@", 2), [String, String]) }
      end

      sig { returns(T::Hash[String, String]) }
      def expected_rbis
        @expected_rbis ||= @bundle.dependencies
          .reject { |gem| @exclude.include?(gem.name) }
          .to_h { |gem| [gem.name, gem.version.to_s] }
      end

      sig { params(gem_name: String, version: String).returns(Pathname) }
      def gem_rbi_filename(gem_name, version)
        @outpath / "#{gem_name}@#{version}.rbi"
      end

      sig { params(cause: Symbol, files: T::Array[String]).returns(String) }
      def build_error_for_files(cause, files)
        "  File(s) #{cause}:\n  - #{files.join("\n  - ")}"
      end

      sig { params(gem_name: String, contents: T::Array[String]).returns(T.nilable(RBI::Tree)) }
      def combine_annotation_sources(gem_name, contents)
        return if contents.empty?

        rewriter = RBI::Rewriters::Merge.new(keep: RBI::Rewriters::Merge::Keep::NONE)

        contents.each do |content|
          rbi = RBI::Parser.parse_string(content)
          rewriter.merge(rbi)
        end

        tree = rewriter.tree
        return tree if tree.conflicts.empty?

        say_error("\n\n  Can't import annotation for `#{gem_name}` as it contains conflicts:", :yellow)

        tree.conflicts.each do |conflict|
          say_error("    #{conflict}", :yellow)
        end

        nil
      rescue RBI::ParseError => e
        say_error("\n\n  Can't import annotation for `#{gem_name}` as it contains errors:", :yellow)
        say_error("    Error: #{e.message} (#{e.location})")
        nil
      end

      sig { params(gem: Gemfile::GemSpec, file: RBI::File).void }
      def merge_with_exported_rbi(gem, file)
        return file unless gem.export_rbi_files?

        tree = gem.exported_rbi_tree

        unless tree.conflicts.empty?
          say_error("\n\n  RBIs exported by `#{gem.name}` contain conflicts and can't be used:", :yellow)

          tree.conflicts.each do |conflict|
            say_error("\n    #{conflict}", :yellow)
            say_error("    Found at:", :yellow)
            say_error("      #{conflict.left.loc}", :yellow)
            say_error("      #{conflict.right.loc}", :yellow)
          end

          return file
        end

        file.root = RBI::Rewriters::Merge.merge_trees(file.root, tree, keep: RBI::Rewriters::Merge::Keep::LEFT)
      rescue RBI::ParseError => e
        say_error("\n\n  RBIs exported by `#{gem.name}` contain errors and can't be used:", :yellow)
        say_error("Cause: #{e.message} (#{e.location})")
      end

      sig { params(annotation: RBI::Tree, file: RBI::File).void }
      def merge_with_annotation(annotation, file)
        file.root = RBI::Rewriters::Merge.merge_trees(
          file.root,
          annotation,
          keep: RBI::Rewriters::Merge::Keep::LEFT,
        )
      end

      sig { params(gem_name: String).returns(T.nilable(RBI::Tree)) }
      def fetch_annotation(gem_name)
        return if @excluded_annotations.include?(gem_name)

        sources = @indexes.select { |_, index| index.has_gem?(gem_name) }.keys

        contents = sources.map do |repo_uri|
          fetch_file(
            repo_uri,
            "#{CENTRAL_REPO_ANNOTATIONS_DIR}/#{gem_name}.rbi",
          )
        end

        tree = combine_annotation_sources(gem_name, contents.compact)
        tree&.comments&.clear
        tree
      end

      sig { returns(T::Hash[String, T.nilable(String)]) }
      def repo_tokens
        @annotation_netrc_info = Netrc.read(@annotations_netrc_file) if @annotations_netrc_file
        @annotations_sources.filter_map do |uri|
          if @annotations_auth
            [uri, @annotations_auth]
          else
            [uri, token_for(uri)]
          end
        end.to_h
      end

      sig { params(path: String, repo_uri: String, message: String).void }
      def say_http_error(path, repo_uri, message:)
        say_error("\nCan't fetch file `#{path}` from #{repo_uri} (#{message})\n\n", :bold, :red)
        say_error(<<~ERROR)
          Tapioca can't access the annotations at #{repo_uri}.

          Are you trying to access a private repository?
          If so, please specify your Github credentials in your ~/.netrc file or by specifying the --auth option.

          See https://github.com/Shopify/tapioca#using-a-netrc-file for more details.
        ERROR
      end

      sig { params(repo_uri: String).returns(T.nilable(String)) }
      def token_for(repo_uri)
        return unless @annotation_netrc_info

        host = URI(repo_uri).host
        return unless host

        creds = @annotation_netrc_info[host]
        return unless creds

        token = creds.to_a.last
        return unless token

        "token #{token}"
      end
    end
  end
end
