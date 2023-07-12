# typed: __STDLIB_INTERNAL

module SecureRandom
  class << self
    def bytes(n); end
    def gen_random(n); end

    private

    def gen_random_openssl(n); end
    def gen_random_urandom(n); end
  end
end
