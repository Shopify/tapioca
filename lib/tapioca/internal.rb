# typed: strict
# frozen_string_literal: true

require "set"

require "tapioca"
require "tapioca/runtime/helpers"
require "tapioca/runtime/reflection"
require "tapioca/runtime/trackers"

require "tapioca/runtime/dynamic_mixin_compiler"
require "tapioca/sorbet_ext/backcompat_patches"
require "tapioca/sorbet_ext/name_patch"
require "tapioca/sorbet_ext/generic_name_patch"
require "tapioca/sorbet_ext/proc_bind_patch"
require "tapioca/sorbet_ext/void_patch"
require "tapioca/runtime/generic_type_registry"

# Make `sig {}` blocks available to every class/module without requiring an
# explicit `extend T::Sig`. Gems and applications that rely on bare `sig`
# in their classes used to get this behavior from the load-time RBS
# rewriter; we now install the include directly so that the same
# convention keeps working after the rewriter was removed.
Module.include(T::Sig)

require "spoom"

require "benchmark"
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
require "shellwords"
require "tempfile"
require "thor"
require "yaml"
require "rubydex"
require "prism"

require "tapioca/rbs/comments"
require "tapioca/rbs/type_qualifier"
require "tapioca/rbs/dsl_signatures"

require "tapioca/helpers/gem_helper"
require "tapioca/helpers/git_attributes"
require "tapioca/helpers/sorbet_helper"
require "tapioca/helpers/rbi_helper"

require "tapioca/helpers/package_url"
require "tapioca/helpers/cli_helper"
require "tapioca/helpers/config_helper"
require "tapioca/helpers/rbi_files_helper"
require "tapioca/helpers/env_helper"

require "tapioca/repo_index"
require "tapioca/gemfile"
require "tapioca/gem_info"
require "tapioca/executor"

require "tapioca/static/symbol_table_parser"
require "tapioca/static/symbol_loader"
require "tapioca/static/requires_compiler"

require "tapioca/loaders/loader"
require "tapioca/loaders/gem"
require "tapioca/loaders/dsl"

require "tapioca/gem"
require "tapioca/dsl"
require "tapioca/commands"
require "tapioca/cli"
