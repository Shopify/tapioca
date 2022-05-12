# typed: strict
# frozen_string_literal: true

require "net/http"

module Tapioca
  module Commands
    class Annotations < Command
      extend T::Sig

      sig do
        params(
          central_repo_root_uri: String,
          central_repo_index_path: String
        ).void
      end
      def initialize(central_repo_root_uri:, central_repo_index_path: CENTRAL_REPO_INDEX_PATH)
        super()
        @central_repo_root_uri = central_repo_root_uri
        @index = T.let(fetch_index, RepoIndex)
      end

      sig { override.void }
      def execute
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

      sig { returns(RepoIndex) }
      def fetch_index
        say("Retrieving index from central repository... ", [:blue, :bold])
        content = fetch_file(CENTRAL_REPO_INDEX_PATH)
        exit(1) unless content

        index = RepoIndex.from_json(content)
        say("Done", :green)
        index
      end

      sig { params(gem_names: T::Array[String]).returns(T::Array[String]) }
      def fetch_annotations(gem_names)
        say("Fetching gem annotations from central repository... ", [:blue, :bold])
        fetchable_gems = gem_names.select { |gem_name| @index.has_gem?(gem_name) }

        if fetchable_gems.empty?
          say(" Nothing to do")
          exit(0)
        end

        say("\n")
        fetched_gems = fetchable_gems.select { |name| fetch_annotation(name) }
        say("\nDone", :green)
        fetched_gems
      end

      sig { params(gem_name: String).void }
      def fetch_annotation(gem_name)
        content = fetch_file("#{CENTRAL_REPO_ANNOTATIONS_DIR}/#{gem_name}.rbi")
        return unless content

        content = add_header(gem_name, content)

        dir = DEFAULT_ANNOTATIONS_DIR
        FileUtils.mkdir_p(dir)
        say("\n  Fetched #{set_color(gem_name, :yellow, :bold)}", :green)
        create_file("#{dir}/#{gem_name}.rbi", content)
      end

      sig { params(path: String).returns(T.nilable(String)) }
      def fetch_file(path)
        if @central_repo_root_uri.start_with?(%r{https?://})
          fetch_http_file(path)
        else
          fetch_local_file(path)
        end
      end

      sig { params(path: String).returns(T.nilable(String)) }
      def fetch_local_file(path)
        File.read("#{@central_repo_root_uri}/#{path}")
      rescue => e
        say_error("\nCan't fetch file `#{path}` (#{e.message})", :bold, :red)
        nil
      end

      sig { params(path: String).returns(T.nilable(String)) }
      def fetch_http_file(path)
        uri = URI("#{@central_repo_root_uri}/#{path}")
        response = Net::HTTP.get_response(uri)
        case response
        when Net::HTTPSuccess
          response.body
        else
          say_error("\nCan't fetch file `#{path}` from #{@central_repo_root_uri} (#{response.class})", :bold, :red)
          nil
        end
      rescue SocketError, Errno::ECONNREFUSED => e
        say_error("\nCan't fetch file `#{path}` from #{@central_repo_root_uri} (#{e.message})", :bold, :red)
        nil
      end

      sig { params(name: String, content: String).returns(String) }
      def add_header(name, content)
        header = <<~COMMENT
          # DO NOT EDIT MANUALLY
          # This file was pulled from #{@central_repo_root_uri}.
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
    end
  end
end
