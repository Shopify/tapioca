# typed: strict
# frozen_string_literal: true

require "tapioca/rbi/loc"
require "tapioca/rbi/model"
require "tapioca/rbi/visitor"
require "tapioca/rbi/index"
require "tapioca/rbi/rewriters/merge_trees"
require "tapioca/rbi/rewriters/nest_singleton_methods"
require "tapioca/rbi/rewriters/nest_non_public_methods"
require "tapioca/rbi/rewriters/group_nodes"
require "tapioca/rbi/rewriters/sort_nodes"
require "tapioca/rbi/parser"
require "tapioca/rbi/printer"
