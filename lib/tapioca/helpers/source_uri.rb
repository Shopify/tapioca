# typed: true
# frozen_string_literal: true

require "uri/file"

module Tapioca
  class SourceURI < URI::File
    extend T::Sig

    COMPONENT = [
      :scheme,
      :gem_name,
      :gem_version,
      :path,
      :line_number,
    ].freeze #: Array[Symbol]

    # `uri` for Ruby 3.4 switched the default parser from RFC2396 to RFC3986. The new parser emits a deprecation
    # warning on a few methods and delegates them to RFC2396, namely `extract`/`make_regexp`/`escape`/`unescape`.
    # On earlier versions of the uri gem, the RFC2396_PARSER constant doesn't exist, so it needs some special
    # handling to select a parser that doesn't emit deprecations. While it was backported to Ruby 3.1, users may
    # have the uri gem in their own bundle and thus not use a compatible version.
    PARSER = const_defined?(:RFC2396_PARSER) ? RFC2396_PARSER : DEFAULT_PARSER #: RFC2396_Parser

    #: String?
    attr_reader :gem_version

    class << self
      extend T::Sig

      #: (gem_name: String, gem_version: String?, path: String, line_number: String?) -> instance
      def build(gem_name:, gem_version:, path:, line_number:)
        super(
          {
            scheme: "source",
            host: gem_name,
            path: PARSER.escape("/#{gem_version}/#{path}"),
            fragment: line_number,
          }
        )
      end
    end

    #: -> String?
    def gem_name
      host
    end

    #: -> String?
    def line_number
      fragment
    end

    #: (String? v) -> void
    def set_path(v) # rubocop:disable Naming/AccessorMethodName
      return if v.nil?

      @gem_version, @path = v.split("/", 2)
    end

    #: (String? v) -> bool
    def check_host(v)
      return true unless v

      if /[A-Za-z][A-Za-z0-9\-_]*/ !~ v
        raise InvalidComponentError,
          "bad component(expected gem name): #{v}"
      end

      true
    end

    #: -> String
    def to_s
      "source://#{gem_name}/#{gem_version}#{path}##{line_number}"
    end

    if URI.respond_to?(:register_scheme)
      URI.register_scheme("SOURCE", self)
    else
      @@schemes["SOURCE"] = self
    end
  end
end
