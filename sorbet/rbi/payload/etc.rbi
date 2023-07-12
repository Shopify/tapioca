# typed: __STDLIB_INTERNAL

module Etc
  private

  def confstr(_arg0); end
  def endgrent; end
  def endpwent; end
  def getgrent; end
  def getgrgid(*_arg0); end
  def getgrnam(_arg0); end
  def getlogin; end
  def getpwent; end
  def getpwnam(_arg0); end
  def getpwuid(*_arg0); end
  def group; end
  def nprocessors; end
  def passwd; end
  def setgrent; end
  def setpwent; end
  def sysconf(_arg0); end
  def sysconfdir; end
  def systmpdir; end
  def uname; end

  class << self
    def confstr(_arg0); end
    def endgrent; end
    def endpwent; end
    def getgrent; end
    def getgrgid(*_arg0); end
    def getgrnam(_arg0); end
    def getlogin; end
    def getpwent; end
    def getpwnam(_arg0); end
    def getpwuid(*_arg0); end
    def group; end
    def nprocessors; end
    def passwd; end
    def setgrent; end
    def setpwent; end
    def sysconf(_arg0); end
    def sysconfdir; end
    def systmpdir; end
    def uname; end
  end
end

class Etc::Group < ::Struct
  extend ::Enumerable

  def gid; end
  def gid=(_); end
  def mem; end
  def mem=(_); end
  def name; end
  def name=(_); end
  def passwd; end
  def passwd=(_); end

  class << self
    def [](*_arg0); end
    def each; end
    def inspect; end
    def keyword_init?; end
    def members; end
    def new(*_arg0); end
  end
end

class Etc::Passwd < ::Struct
  extend ::Enumerable

  def change; end
  def change=(_); end
  def dir; end
  def dir=(_); end
  def expire; end
  def expire=(_); end
  def gecos; end
  def gecos=(_); end
  def gid; end
  def gid=(_); end
  def name; end
  def name=(_); end
  def passwd; end
  def passwd=(_); end
  def shell; end
  def shell=(_); end
  def uclass; end
  def uclass=(_); end
  def uid; end
  def uid=(_); end

  class << self
    def [](*_arg0); end
    def each; end
    def inspect; end
    def keyword_init?; end
    def members; end
    def new(*_arg0); end
  end
end
