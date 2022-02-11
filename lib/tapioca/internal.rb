# typed: strict
# frozen_string_literal: true

require "tapioca"
require "tapioca/sorbet_ext/generic_name_patch"
require "tapioca/sorbet_ext/fixed_hash_patch"
require "tapioca/runtime/loader"
require "tapioca/runtime/generic_type_registry"
require "tapioca/helpers/cli_helper"
require "tapioca/helpers/config_helper"
require "tapioca/helpers/rbi_helper"
require "tapioca/helpers/shims_helper"
require "tapioca/helpers/sorbet_helper"
require "tapioca/generators"
require "tapioca/cli"
require "tapioca/gemfile"
require "tapioca/executor"
require "tapioca/static/requires_compiler"
require "tapioca/static/symbol_table_parser"
require "tapioca/static/symbol_loader"
require "tapioca/compilers/gem/events"
require "tapioca/compilers/gem/listeners"
require "tapioca/compilers/symbol_table_compiler"
require "tapioca/dsl/pipeline"
