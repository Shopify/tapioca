# typed: true

module URI
  def self.register_scheme(scheme, klass); end

  class File
    attr_reader :path

    def initialize(scheme, userinfo, host, port, registry, path, opaque, query, fragment, parser = DEFAULT_PARSER, arg_check = false); end
  end

  class Source
    sig { returns(String) }
    attr_reader :host

    sig { returns(String) }
    attr_reader :fragment
  end

  class WS; end
end
