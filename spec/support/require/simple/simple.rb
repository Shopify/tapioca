# frozen_string_literal: true
#
# rubocop:disable Layout/ExtraSpacing
# rubocop:disable Layout/SpaceBeforeFirstArg
# rubocop:disable Lint/LiteralAsCondition
# rubocop:disable Lint/ParenthesesAsGroupedExpression
# rubocop:disable Style/RedundantParentheses/
require 'a'
require "b"
require ("c")
require'd'
require"e"
require("f")
require_relative 'z'

if true
  require 'g'
  require_relative "z"
else
  require   ('h')
  require   'i'
  require  "j"
end
