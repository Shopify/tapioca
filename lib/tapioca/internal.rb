# typed: strict
# frozen_string_literal: true

require "bundler"
require "erb"
require "etc"
require "fileutils"
require "json"
require "logger"
require "net/http"
require "netrc"
require "parallel"
require "pathname"
require "set"
require "shellwords"
require "spoom"
require "tempfile"
require "thor"
require "yaml"
require "yard-sorbet"

require "tapioca"

require "tapioca/runtime/reflection"
require "tapioca/runtime/trackers"
require "tapioca/runtime/dynamic_mixin_compiler"
require "tapioca/helpers/gem_helper"
require "tapioca/runtime/loader"

require "tapioca/helpers/sorbet_helper"
require "tapioca/helpers/rbi_helper"
require "tapioca/sorbet_ext/fixed_hash_patch"
require "tapioca/sorbet_ext/name_patch"
require "tapioca/sorbet_ext/generic_name_patch"
require "tapioca/runtime/generic_type_registry"

require "tapioca/helpers/cli_helper"
require "tapioca/helpers/config_helper"
require "tapioca/helpers/rbi_files_helper"
require "tapioca/helpers/env_helper"

require "tapioca/repo_index"
require "tapioca/gemfile"
require "tapioca/executor"

require "tapioca/static/symbol_table_parser"
require "tapioca/static/symbol_loader"
require "tapioca/static/requires_compiler"

require "tapioca/gem"
require "tapioca/dsl"
require "tapioca/commands"
require "tapioca/cli"
