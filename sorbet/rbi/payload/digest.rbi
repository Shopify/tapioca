# typed: __STDLIB_INTERNAL

module Digest
  private

  def hexencode(_arg0); end

  class << self
    def const_missing(name); end
    def hexencode(_arg0); end
  end
end

class Digest::Base < ::Digest::Class
  def <<(_arg0); end
  def block_length; end
  def digest_length; end
  def reset; end
  def update(_arg0); end

  private

  def finish; end
  def initialize_copy(_arg0); end
end

class Digest::Class
  include ::Digest::Instance

  def initialize; end

  class << self
    def base64digest(str, *args); end
    def digest(*_arg0); end
    def file(name, *args); end
    def hexdigest(*_arg0); end
  end
end

module Digest::Instance
  def <<(_arg0); end
  def ==(_arg0); end
  def base64digest(str = T.unsafe(nil)); end
  def base64digest!; end
  def block_length; end
  def digest(*_arg0); end
  def digest!; end
  def digest_length; end
  def file(name); end
  def hexdigest(*_arg0); end
  def hexdigest!; end
  def inspect; end
  def length; end
  def new; end
  def reset; end
  def size; end
  def to_s; end
  def update(_arg0); end

  private

  def finish; end
end

class Digest::SHA1 < ::Digest::Base; end

class Digest::SHA2 < ::Digest::Class
  def initialize(bitlen = T.unsafe(nil)); end

  def <<(str); end
  def block_length; end
  def digest_length; end
  def inspect; end
  def reset; end
  def update(str); end

  private

  def finish; end
  def initialize_copy(other); end
end

class Digest::SHA256 < ::Digest::Base; end
class Digest::SHA384 < ::Digest::Base; end
class Digest::SHA512 < ::Digest::Base; end
