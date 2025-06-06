# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `cityhash` gem.
# Please instead update this file by running `bin/tapioca gem cityhash`.


# source://cityhash//lib/cityhash/version.rb#1
module CityHash
  class << self
    # source://cityhash//lib/cityhash.rb#22
    def hash128(input, seed = T.unsafe(nil)); end

    # source://cityhash//lib/cityhash.rb#8
    def hash32(input); end

    # source://cityhash//lib/cityhash.rb#14
    def hash64(input, seed1 = T.unsafe(nil), seed2 = T.unsafe(nil)); end

    # source://cityhash//lib/cityhash.rb#59
    def packed_seed(seed); end

    # source://cityhash//lib/cityhash.rb#63
    def unpacked_digest(digest); end
  end
end

# source://cityhash//lib/cityhash.rb#6
CityHash::HIGH64_MASK = T.let(T.unsafe(nil), Integer)

module CityHash::Internal
  class << self
    # source://cityhash//lib/cityhash.rb#2
    def hash128(_arg0); end

    # source://cityhash//lib/cityhash.rb#2
    def hash128_with_seed(_arg0, _arg1); end

    # source://cityhash//lib/cityhash.rb#2
    def hash32(_arg0); end

    # source://cityhash//lib/cityhash.rb#2
    def hash64(_arg0); end

    # source://cityhash//lib/cityhash.rb#2
    def hash64_with_seed(_arg0, _arg1); end

    # source://cityhash//lib/cityhash.rb#2
    def hash64_with_seeds(_arg0, _arg1, _arg2); end
  end
end

# source://cityhash//lib/cityhash.rb#5
CityHash::LOW64_MASK = T.let(T.unsafe(nil), Integer)

# source://cityhash//lib/cityhash/version.rb#2
CityHash::VERSION = T.let(T.unsafe(nil), String)
