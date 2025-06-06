# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `bcrypt` gem.
# Please instead update this file by running `bin/tapioca gem bcrypt`.


# A Ruby library implementing OpenBSD's bcrypt()/crypt_blowfish algorithm for
# hashing passwords.
#
# source://bcrypt//lib/bcrypt.rb#3
module BCrypt; end

# A Ruby wrapper for the bcrypt() C extension calls and the Java calls.
#
# source://bcrypt//lib/bcrypt/engine.rb#3
class BCrypt::Engine
  class << self
    # Autodetects the cost from the salt string.
    #
    # source://bcrypt//lib/bcrypt/engine.rb#129
    def autodetect_cost(salt); end

    # Returns the cost factor which will result in computation times less than +upper_time_limit_in_ms+.
    #
    # Example:
    #
    #   BCrypt::Engine.calibrate(200)  #=> 10
    #   BCrypt::Engine.calibrate(1000) #=> 12
    #
    #   # should take less than 200ms
    #   BCrypt::Password.create("woo", :cost => 10)
    #
    #   # should take less than 1000ms
    #   BCrypt::Password.create("woo", :cost => 12)
    #
    # source://bcrypt//lib/bcrypt/engine.rb#119
    def calibrate(upper_time_limit_in_ms); end

    # Returns the cost factor that will be used if one is not specified when
    # creating a password hash.  Defaults to DEFAULT_COST if not set.
    #
    # source://bcrypt//lib/bcrypt/engine.rb#32
    def cost; end

    # Set a default cost factor that will be used if one is not specified when
    # creating a password hash.
    #
    # Example:
    #
    #   BCrypt::Engine::DEFAULT_COST            #=> 12
    #   BCrypt::Password.create('secret').cost  #=> 12
    #
    #   BCrypt::Engine.cost = 8
    #   BCrypt::Password.create('secret').cost  #=> 8
    #
    #   # cost can still be overridden as needed
    #   BCrypt::Password.create('secret', :cost => 6).cost  #=> 6
    #
    # source://bcrypt//lib/bcrypt/engine.rb#49
    def cost=(cost); end

    # Generates a random salt with a given computational cost.
    #
    # source://bcrypt//lib/bcrypt/engine.rb#81
    def generate_salt(cost = T.unsafe(nil)); end

    # Given a secret and a valid salt (see BCrypt::Engine.generate_salt) calculates
    # a bcrypt() password hash. Secrets longer than 72 bytes are truncated.
    #
    # source://bcrypt//lib/bcrypt/engine.rb#55
    def hash_secret(secret, salt, _ = T.unsafe(nil)); end

    # Returns true if +salt+ is a valid bcrypt() salt, false if not.
    #
    # @return [Boolean]
    #
    # source://bcrypt//lib/bcrypt/engine.rb#98
    def valid_salt?(salt); end

    # Returns true if +secret+ is a valid bcrypt() secret, false if not.
    #
    # @return [Boolean]
    #
    # source://bcrypt//lib/bcrypt/engine.rb#103
    def valid_secret?(secret); end

    private

    # source://bcrypt//lib/bcrypt.rb#12
    def __bc_crypt(_arg0, _arg1); end

    # source://bcrypt//lib/bcrypt.rb#12
    def __bc_salt(_arg0, _arg1, _arg2); end
  end
end

# The default computational expense parameter.
#
# source://bcrypt//lib/bcrypt/engine.rb#5
BCrypt::Engine::DEFAULT_COST = T.let(T.unsafe(nil), Integer)

# The maximum cost supported by the algorithm.
#
# source://bcrypt//lib/bcrypt/engine.rb#9
BCrypt::Engine::MAX_COST = T.let(T.unsafe(nil), Integer)

# Maximum possible size of bcrypt() salts.
#
# source://bcrypt//lib/bcrypt/engine.rb#19
BCrypt::Engine::MAX_SALT_LENGTH = T.let(T.unsafe(nil), Integer)

# Maximum possible size of bcrypt() secrets.
# Older versions of the bcrypt library would truncate passwords longer
# than 72 bytes, but newer ones do not. We truncate like the old library for
# forward compatibility. This way users upgrading from Ubuntu 18.04 to 20.04
# will not have their user passwords invalidated, for example.
# A max secret length greater than 255 leads to bcrypt returning nil.
# https://github.com/bcrypt-ruby/bcrypt-ruby/issues/225#issuecomment-875908425
#
# source://bcrypt//lib/bcrypt/engine.rb#17
BCrypt::Engine::MAX_SECRET_BYTESIZE = T.let(T.unsafe(nil), Integer)

# The minimum cost supported by the algorithm.
#
# source://bcrypt//lib/bcrypt/engine.rb#7
BCrypt::Engine::MIN_COST = T.let(T.unsafe(nil), Integer)

# source://bcrypt//lib/bcrypt/error.rb#3
class BCrypt::Error < ::StandardError; end

# source://bcrypt//lib/bcrypt/error.rb#6
module BCrypt::Errors; end

# The cost parameter provided to bcrypt() is invalid.
#
# source://bcrypt//lib/bcrypt/error.rb#15
class BCrypt::Errors::InvalidCost < ::BCrypt::Error; end

# The hash parameter provided to bcrypt() is invalid.
#
# source://bcrypt//lib/bcrypt/error.rb#12
class BCrypt::Errors::InvalidHash < ::BCrypt::Error; end

# The salt parameter provided to bcrypt() is invalid.
#
# source://bcrypt//lib/bcrypt/error.rb#9
class BCrypt::Errors::InvalidSalt < ::BCrypt::Error; end

# The secret parameter provided to bcrypt() is invalid.
#
# source://bcrypt//lib/bcrypt/error.rb#18
class BCrypt::Errors::InvalidSecret < ::BCrypt::Error; end

# A password management class which allows you to safely store users' passwords and compare them.
#
# Example usage:
#
#   include BCrypt
#
#   # hash a user's password
#   @password = Password.create("my grand secret")
#   @password #=> "$2a$12$C5.FIvVDS9W4AYZ/Ib37YuWd/7ozp1UaMhU28UKrfSxp2oDchbi3K"
#
#   # store it safely
#   @user.update_attribute(:password, @password)
#
#   # read it back
#   @user.reload!
#   @db_password = Password.new(@user.password)
#
#   # compare it after retrieval
#   @db_password == "my grand secret" #=> true
#   @db_password == "a paltry guess"  #=> false
#
# source://bcrypt//lib/bcrypt/password.rb#23
class BCrypt::Password < ::String
  # Initializes a BCrypt::Password instance with the data from a stored hash.
  #
  # @return [Password] a new instance of Password
  #
  # source://bcrypt//lib/bcrypt/password.rb#55
  def initialize(raw_hash); end

  # Compares a potential secret against the hash. Returns true if the secret is the original secret, false otherwise.
  #
  # Comparison edge case/gotcha:
  #
  #    secret = "my secret"
  #    @password = BCrypt::Password.create(secret)
  #
  #    @password == secret              # => True
  #    @password == @password           # => False
  #    @password == @password.to_s      # => False
  #    @password.to_s == @password      # => True
  #    @password.to_s == @password.to_s # => True
  #
  # source://bcrypt//lib/bcrypt/password.rb#76
  def ==(secret); end

  # The hash portion of the stored password hash.
  #
  # source://bcrypt//lib/bcrypt/password.rb#25
  def checksum; end

  # The cost factor used to create the hash.
  #
  # source://bcrypt//lib/bcrypt/password.rb#31
  def cost; end

  # Compares a potential secret against the hash. Returns true if the secret is the original secret, false otherwise.
  #
  # Comparison edge case/gotcha:
  #
  #    secret = "my secret"
  #    @password = BCrypt::Password.create(secret)
  #
  #    @password == secret              # => True
  #    @password == @password           # => False
  #    @password == @password.to_s      # => False
  #    @password.to_s == @password      # => True
  #    @password.to_s == @password.to_s # => True
  #
  # source://bcrypt//lib/bcrypt/password.rb#79
  def is_password?(secret); end

  # The salt of the store password hash (including version and cost).
  #
  # source://bcrypt//lib/bcrypt/password.rb#27
  def salt; end

  # The version of the bcrypt() algorithm used to create the hash.
  #
  # source://bcrypt//lib/bcrypt/password.rb#29
  def version; end

  private

  # call-seq:
  #   split_hash(raw_hash) -> version, cost, salt, hash
  #
  # Splits +h+ into version, cost, salt, and hash and returns them in that order.
  #
  # source://bcrypt//lib/bcrypt/password.rb#92
  def split_hash(h); end

  # Returns true if +h+ is a valid hash.
  #
  # @return [Boolean]
  #
  # source://bcrypt//lib/bcrypt/password.rb#84
  def valid_hash?(h); end

  class << self
    # Hashes a secret, returning a BCrypt::Password instance. Takes an optional <tt>:cost</tt> option, which is a
    # logarithmic variable which determines how computational expensive the hash is to calculate (a <tt>:cost</tt> of
    # 4 is twice as much work as a <tt>:cost</tt> of 3). The higher the <tt>:cost</tt> the harder it becomes for
    # attackers to try to guess passwords (even if a copy of your database is stolen), but the slower it is to check
    # users' passwords.
    #
    # Example:
    #
    #   @password = BCrypt::Password.create("my secret", :cost => 13)
    #
    # @raise [ArgumentError]
    #
    # source://bcrypt//lib/bcrypt/password.rb#43
    def create(secret, options = T.unsafe(nil)); end

    # @return [Boolean]
    #
    # source://bcrypt//lib/bcrypt/password.rb#49
    def valid_hash?(h); end
  end
end
