# typed: true

module RubyLsp; end
module RubyIndexer; end

class RubyIndexer::Index; end
class RubyIndexer::Entry; end
class RubyIndexer::Entry::Class; end
class RubyIndexer::Entry::Module; end

class RubyLsp::Addon
  abstract!

  sig { abstract.void }
  def name; end

  sig { abstract.void }
  def deactivate; end
end
