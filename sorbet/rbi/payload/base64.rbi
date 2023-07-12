# typed: __STDLIB_INTERNAL

module Base64
  private

  def decode64(str); end
  def encode64(bin); end
  def strict_decode64(str); end
  def strict_encode64(bin); end
  def urlsafe_decode64(str); end
  def urlsafe_encode64(bin, padding: T.unsafe(nil)); end

  class << self
    def decode64(str); end
    def encode64(bin); end
    def strict_decode64(str); end
    def strict_encode64(bin); end
    def urlsafe_decode64(str); end
    def urlsafe_encode64(bin, padding: T.unsafe(nil)); end
  end
end
