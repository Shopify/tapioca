# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class Annotations < CommandWithoutTracker
      extend T::Sig

      #: (central_repo_root_uris: Array[String], ?auth: String?, ?netrc_file: String?, ?central_repo_index_path: String, ?typed_overrides: Hash[String, String]) -> void
      def initialize(
        central_repo_root_uris:,
        auth: nil,
        netrc_file: nil,
        central_repo_index_path: CENTRAL_REPO_INDEX_PATH,
        typed_overrides: {}
      )
        super()
        @outpath = Pathname.new(DEFAULT_ANNOTATIONS_DIR) #: Pathname
        @central_repo_root_uris = central_repo_root_uris
        @auth = auth
        @netrc_file = netrc_file
        @netrc_info = nil #: Netrc?
        @tokens = repo_tokens #: Hash[String, String?]
        @indexes = {} #: Hash[String, RepoIndex]
        @typed_overrides = typed_overrides
      end

      private

      # @override
      #: -> void
      def execute
        @indexes = fetch_indexes
        project_gems = list_gemfile_gems

        remove_expired_annotations(project_gems)
        fetch_annotations(project_gems)
      ensure
        GitAttributes.create_vendored_attribute_file(@outpath)
      end

      #: -> Array[GemInfo]
      def list_gemfile_gems
        say("Listing gems from Gemfile.lock... ", [:blue, :bold])
        gemfile = Bundler.read_file("Gemfile.lock")
        parser = Bundler::LockfileParser.new(gemfile)
        gem_info = parser.specs.map { |spec| GemInfo.from_spec(spec) }
        say("Done", :green)
        gem_info
      end

      #: (Array[GemInfo] project_gems) -> void
      def remove_expired_annotations(project_gems)
        say("Removing annotations for gems that have been removed... ", [:blue, :bold])

        annotations = Pathname.glob(@outpath.join("*.rbi")).map { |f| f.basename(".*").to_s }
        expired = annotations - project_gems.map(&:name)

        if expired.empty?
          say(" Nothing to do")
          return
        end

        say("\n")
        expired.each do |gem_name|
          say("\n")
          path = @outpath.join("#{gem_name}.rbi")
          remove_file(path)
        end
        say("\nDone\n\n", :green)
      end

      #: -> Hash[String, RepoIndex]
      def fetch_indexes
        multiple_repos = @central_repo_root_uris.size > 1
        repo_number = 1
        indexes = {} #: Hash[String, RepoIndex]

        @central_repo_root_uris.each do |uri|
          index = fetch_index(uri, repo_number: multiple_repos ? repo_number : nil)
          next unless index

          indexes[uri] = index
          repo_number += 1
        end

        if indexes.empty?
          raise Tapioca::Error, set_color("Can't fetch annotations without sources (no index fetched)", :bold, :red)
        end

        indexes
      end

      #: (String repo_uri, repo_number: Integer?) -> RepoIndex?
      def fetch_index(repo_uri, repo_number:)
        say("Retrieving index from central repository#{repo_number ? " ##{repo_number}" : ""}... ", [:blue, :bold])
        content = fetch_file(repo_uri, CENTRAL_REPO_INDEX_PATH)
        return unless content

        index = RepoIndex.from_json(content)
        say("Done", :green)
        index
      end

      #: (Array[GemInfo] project_gems) -> Array[String]
      def fetch_annotations(project_gems)
        say("Fetching gem annotations from central repository... ", [:blue, :bold])
        fetchable_gems = Hash.new { |h, k| h[k] = [] } #: Hash[GemInfo, Array[String]]

        project_gems.each_with_object(fetchable_gems) do |gem_info, hash|
          @indexes.each do |uri, index|
            T.must(hash[gem_info]) << uri if index.has_gem?(gem_info.name)
          end
        end

        if fetchable_gems.empty?
          say(" Nothing to do")

          return []
        end

        say("\n")
        fetched_gems = fetchable_gems.select { |gem_info, repo_uris| fetch_annotation(repo_uris, gem_info) }
        say("\nDone", :green)
        fetched_gems.keys.map(&:name).sort
      end

      sig { params(repo_uris: T::Array[String], gem_info: GemInfo).returns(T::Boolean) }
      def fetch_annotation(repo_uris, gem_info)
        gem_name = gem_info.name
        gem_version = gem_info.version

        contents = repo_uris.map do |repo_uri|
          fetch_file(repo_uri, "#{CENTRAL_REPO_ANNOTATIONS_DIR}/#{gem_name}.rbi")
        end

        content = merge_files(gem_name, contents.compact)
        return false unless content

        content = apply_typed_override(gem_name, content)
        content = filter_versions(gem_version, content)
        content = add_header(gem_name, content)

        say("\n  Fetched #{set_color(gem_name, :yellow, :bold)}", :green)
        create_file(@outpath.join("#{gem_name}.rbi"), content)
        true
      end

      #: (String repo_uri, String path) -> String?
      def fetch_file(repo_uri, path)
        if repo_uri.start_with?(%r{https?://})
          fetch_http_file(repo_uri, path)
        else
          fetch_local_file(repo_uri, path)
        end
      end

      #: (String repo_uri, String path) -> String?
      def fetch_local_file(repo_uri, path)
        File.read("#{repo_uri}/#{path}")
      rescue => e
        say_error("\nCan't fetch file `#{path}` (#{e.message})", :bold, :red)
        nil
      end

      #: (String repo_uri, String path) -> String?
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

      #: (String name, String content) -> String
      def add_header(name, content)
        # WARNING: Changing this header could impact how GitHub determines if the file should be hidden:
        # https://github.com/github/linguist/pull/6143
        header = <<~COMMENT
          # DO NOT EDIT MANUALLY
          # This file was pulled from a central RBI files repository.
          # Please run `#{default_command(:annotations)}` to update it.
        COMMENT

        # Split contents into newlines and ensure trailing empty lines are included
        contents = content.split("\n", -1)
        if contents[0]&.start_with?("# typed:") && contents[1]&.empty?
          contents.insert(2, header).join("\n")
        else
          say_error("Couldn't insert file header for content: #{content} due to unexpected file format")
          content
        end
      end

      #: (String name, String content) -> String
      def apply_typed_override(name, content)
        strictness = @typed_overrides[name]
        return content unless strictness

        unless Spoom::Sorbet::Sigils.strictness_in_content(content)
          return "# typed: #{strictness}\n\n#{content}"
        end

        Spoom::Sorbet::Sigils.update_sigil(content, strictness)
      end

      #: (::Gem::Version gem_version, String content) -> String
      def filter_versions(gem_version, content)
        rbi = RBI::Parser.parse_string(content)
        rbi.filter_versions!(gem_version)

        rbi.string
      end

      #: (String gem_name, Array[String] contents) -> String?
      def merge_files(gem_name, contents)
        return if contents.empty?

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

      #: -> Hash[String, String?]
      def repo_tokens
        @netrc_info = Netrc.read(@netrc_file) if @netrc_file
        @central_repo_root_uris.filter_map do |uri|
          if @auth
            [uri, @auth]
          else
            [uri, token_for(uri)]
          end
        end.to_h
      end

      #: (String repo_uri) -> String?
      def token_for(repo_uri)
        return unless @netrc_info

        host = URI(repo_uri).host
        return unless host

        creds = @netrc_info[host]
        return unless creds

        token = creds.to_a.last
        return unless token

        "token #{token}"
      end

      #: (String path, String repo_uri, message: String) -> void
      def say_http_error(path, repo_uri, message:)
        say_error("\nCan't fetch file `#{path}` from #{repo_uri} (#{message})\n\n", :bold, :red)
        say_error(<<~ERROR)
          Tapioca can't access the annotations at #{repo_uri}.

          Are you trying to access a private repository?
          If so, please specify your Github credentials in your ~/.netrc file or by specifying the --auth option.

          See https://github.com/Shopify/tapioca#using-a-netrc-file for more details.
        ERROR
      end
    end
  end
end
