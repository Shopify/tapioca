# typed: __STDLIB_INTERNAL

class GetoptLong
  def initialize(*arguments); end

  def each; end
  def each_option; end
  def error; end
  def error?; end
  def error_message; end
  def get; end
  def get_option; end
  def ordering; end
  def ordering=(ordering); end
  def quiet; end
  def quiet=(_arg0); end
  def quiet?; end
  def set_options(*arguments); end
  def terminate; end
  def terminated?; end

  protected

  def set_error(type, message); end
end

class GetoptLong::AmbiguousOption < ::GetoptLong::Error; end
class GetoptLong::Error < ::StandardError; end
class GetoptLong::InvalidOption < ::GetoptLong::Error; end
class GetoptLong::MissingArgument < ::GetoptLong::Error; end
class GetoptLong::NeedlessArgument < ::GetoptLong::Error; end
