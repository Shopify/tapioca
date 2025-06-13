# typed: strict
# frozen_string_literal: true

module Tapioca
  class RepoIndex
    extend T::Sig
    class << self
      extend T::Sig

      #: (String json) -> RepoIndex
      def from_json(json)
        RepoIndex.from_hash(JSON.parse(json))
      end

      #: (Hash[String, Hash[untyped, untyped]] hash) -> RepoIndex
      def from_hash(hash)
        hash.each_with_object(RepoIndex.new) do |(name, _), index|
          index << name
        end
      end
    end

    #: -> void
    def initialize
      @entries = Set.new #: Set[String]
    end

    #: (String gem_name) -> void
    def <<(gem_name)
      @entries.add(gem_name)
    end

    #: -> T::Enumerable[String]
    def gems
      @entries.sort
    end

    #: (String gem_name) -> bool
    def has_gem?(gem_name)
      @entries.include?(gem_name)
    end
  end
end
