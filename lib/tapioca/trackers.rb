# typed: strict
# frozen_string_literal: true

# The load order below is important:
# ----------------------------------
# We want the mixin tracker to be the first thing that is
# loaded because other trackers might apply their own mixins
# into core types (like `Module` and `Kernel`). In order to
# catch and filter those mixins as coming from Tapioca, we need
# the mixin tracker to be in place, before any mixin operations
# are performed.
require "tapioca/trackers/mixin"
require "tapioca/trackers/constant_definition"
require "tapioca/trackers/autoload"
require "tapioca/trackers/required_ancestor"
