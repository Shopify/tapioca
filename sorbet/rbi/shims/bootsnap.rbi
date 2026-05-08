# typed: true

# Bootsnap is loaded conditionally in `lib/tapioca/rbs/rewriter.rb` when
# `TAPIOCA_RBS_CACHE=1`. It isn't in the Gemfile, so this shim declares the
# minimal surface used there.
module Bootsnap
  def self.setup(**); end
  def self.log_stats!; end
end
