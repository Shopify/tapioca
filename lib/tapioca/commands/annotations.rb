# typed: strict
# frozen_string_literal: true

require "net/http"

module Tapioca
  module Commands
    class Annotations < Command
      extend T::Sig

      sig do
        params(
          central_repo_root_uris: T::Array[String],
          auth: T.nilable(String),
          central_repo_index_path: String
        ).void
      end
      def initialize(central_repo_root_uris:, auth: nil, central_repo_index_path: CENTRAL_REPO_INDEX_PATH)
        super()
        @central_repo_root_uris = central_repo_root_uris
        @auth = auth
        @indexes = T.let({}, T::Hash[String, RepoIndex])
      end

      sig { override.void }
      def execute
        @indexes = fetch_indexes
        project_gems = list_gemfile_gems
        remove_expired_annotations(project_gems)
        fetch_annotations(project_gems)
      end

      private

      sig { returns(T::Array[String]) }
      def list_gemfile_gems
        say("Listing gems from Gemfile.lock... ", [:blue, :bold])
        gemfile = Bundler.read_file("Gemfile.lock")
        parser = Bundler::LockfileParser.new(gemfile)
        gem_names = parser.specs.map(&:name)
        say("Done", :green)
        gem_names
      end

      sig { params(project_gems: T::Array[String]).void }
      def remove_expired_annotations(project_gems)
        say("Removing annotations for gems that have been removed... ", [:blue, :bold])

        annotations = Pathname.glob("#{DEFAULT_ANNOTATIONS_DIR}/*.rbi").map { |f| f.basename(".*").to_s }
        expired = annotations - project_gems

        if expired.empty?
          say(" Nothing to do")
          return
        end

        say("\n")
        expired.each do |gem_name|
          say("\n")
          path = "#{DEFAULT_ANNOTATIONS_DIR}/#{gem_name}.rbi"
          remove_file(path)
        end
        say("\nDone\n\n", :green)
      end

      sig { returns(T::Hash[String, RepoIndex]) }
      def fetch_indexes
        multiple_repos = @central_repo_root_uris.size > 1
        repo_number = 1
        indexes = T.let({}, T::Hash[String, RepoIndex])

        @central_repo_root_uris.each do |uri|
          index = fetch_index(uri, repo_number: multiple_repos ? repo_number : nil)
          next unless index

          indexes[uri] = index
          repo_number += 1
        end

        if indexes.empty?
          say_error("\nCan't fetch annotations without sources (no index fetched)", :bold, :red)
          exit(1)
        end

        indexes
      end

      sig { params(repo_uri: String, repo_number: T.nilable(Integer)).returns(T.nilable(RepoIndex)) }
      def fetch_index(repo_uri, repo_number:)
        say("Retrieving index from central repository#{repo_number ? " ##{repo_number}" : ""}... ", [:blue, :bold])
        content = fetch_file(repo_uri, CENTRAL_REPO_INDEX_PATH)
        return nil unless content

        index = RepoIndex.from_json(content)
        say("Done", :green)
        index
      end

      sig { params(gem_names: T::Array[String]).returns(T::Array[String]) }
      def fetch_annotations(gem_names)
        say("Fetching gem annotations from central repository... ", [:blue, :bold])
        fetchable_gems = T.let(Hash.new { |h, k| h[k] = [] }, T::Hash[String, T::Array[String]])

        gem_names.each_with_object(fetchable_gems) do |gem_name, hash|
          @indexes.each { |uri, index| hash[gem_name] << uri if index.has_gem?(gem_name) }
        end

        if fetchable_gems.empty?
          say(" Nothing to do")
          exit(0)
        end

        say("\n")
        fetched_gems = fetchable_gems.select { |gem_name, repo_uris| fetch_annotation(repo_uris, gem_name) }
        say("\nDone", :green)
        fetched_gems.keys.sort
      end

      sig { params(repo_uris: T::Array[String], gem_name: String).void }
      def fetch_annotation(repo_uris, gem_name)
        contents = repo_uris.map do |repo_uri|
          fetch_file(repo_uri, "#{CENTRAL_REPO_ANNOTATIONS_DIR}/#{gem_name}.rbi")
        end

        content = merge_files(gem_name, contents.compact)
        return unless content

        content = add_header(gem_name, content)

        dir = DEFAULT_ANNOTATIONS_DIR
        FileUtils.mkdir_p(dir)
        say("\n  Fetched #{set_color(gem_name, :yellow, :bold)}", :green)
        create_file("#{dir}/#{gem_name}.rbi", content)
      end

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
        uri = URI("#{repo_uri}/#{path}")

        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = @auth if @auth

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end

        case response
        when Net::HTTPSuccess
          response.body
        else
          say_error("\nCan't fetch file `#{path}` from #{repo_uri} (#{response.class})", :bold, :red)
          nil
        end
      rescue SocketError, Errno::ECONNREFUSED => e
        say_error("\nCan't fetch file `#{path}` from #{repo_uri} (#{e.message})", :bold, :red)
        nil
      end

      sig { params(name: String, content: String).returns(String) }
      def add_header(name, content)
        header = <<~COMMENT
          # DO NOT EDIT MANUALLY
          # This file was pulled from a central RBI files repository.
          # Please run `#{default_command(:annotations)}` to update it.
        COMMENT

        contents = content.split("\n")
        if contents[0]&.start_with?("# typed:") && contents[1]&.empty?
          contents.insert(2, header).join("\n")
        else
          say_error("Couldn't insert file header for content: #{content} due to unexpected file format")
          content
        end
      end

      sig { params(gem_name: String, contents: T::Array[String]).returns(T.nilable(String)) }
      def merge_files(gem_name, contents)
        return nil if contents.empty?

        rewriter = RBI::Rewriters::Merge.new(keep: RBI::Rewriters::Merge::Keep::NONE)

        contents.each do |content|
          rbi = RBI::Parser.parse_string(content)
          rewriter.merge(rbi)
        end

        tree = rewriter.tree
        return tree.string if tree.conflicts.empty?

        say_error("\n\n  Can't import RBI file for `#{gem_name}` as it contains conflicts:", :yellow)

        tree.conflicts.each do |conflict|
          say_error("    #{conflict}", :yellow)
        end

        nil
      rescue RBI::ParseError => e
        say_error("\n\n  Can't import RBI file for `#{gem_name}` as it contains errors:", :yellow)
        say_error("    Error: #{e.message} (#{e.location})")
        nil
      end
    end
  end
end
