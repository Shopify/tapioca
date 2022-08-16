# typed: true
# frozen_string_literal: true

require "uri/file"

module URI
  class Source < URI::File
    extend T::Sig

    COMPONENT = T.let([
      :scheme,
      :gem_name,
      :gem_version,
      :path,
      :line_number,
    ].freeze, T::Array[Symbol])

    alias_method(:gem_name, :host)
    alias_method(:line_number, :fragment)

    sig { returns(T.nilable(String)) }
    attr_reader :gem_version

    class << self
      extend T::Sig

      sig do
        params(
          gem_name: String,
          gem_version: T.nilable(String),
          path: String,
          line_number: T.nilable(String)
        ).returns(URI::Source)
      end
      def build(gem_name:, gem_version:, path:, line_number:)
        super(
          {
            scheme: "source",
            host: gem_name,
            path: DEFAULT_PARSER.escape("/#{gem_version}/#{path}"),
            fragment: line_number,
          }
        )
      end
    end

    sig { params(v: T.nilable(String)).void }
    def set_path(v) # rubocop:disable Naming/AccessorMethodName
      return if v.nil?

      @gem_version, @path = v.split("/", 2)
    end

    sig { params(v: T.nilable(String)).returns(T::Boolean) }
    def check_host(v)
      return true unless v

      if /[A-Za-z][A-Za-z0-9\-_]*/ !~ v
        raise InvalidComponentError,
          "bad component(expected gem name): #{v}"
      end

      true
    end

    sig { returns(String) }
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
