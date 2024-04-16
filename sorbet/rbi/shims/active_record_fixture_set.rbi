# typed: strict

# ActiveRecord::TestFixtures can't be loaded outside of a Rails application

class ActiveRecord::FixtureSet
  sig { params(name: String).returns(String) }
  def self.default_fixture_model_name(name); end
end

class ActiveRecord::FixtureSet::File
  sig { returns(T.nilable(String)) }
  def modle_class; end

  sig params(filename: String, blk: T.proc.params(arg0: ActiveRecord::FixtureSet::File).void)
  def self.open(filename, &block); end
end
