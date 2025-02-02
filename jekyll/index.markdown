---
layout: default
title: Tapioca
nav_order: 0
has_toc: false
---

# Tapioca

<p align="center">
  <img alt="Tapioca logo" width="200" src="tapioca-logo.svg" />
</p>

Tapioca makes it easy to work with [Sorbet](https://sorbet.org) in your codebase.
It surfaces types and methods from many sources that Sorbet cannot otherwise see – such as gems,
Rails and other DSLs – compiles them into [RBI files](https://sorbet.org/docs/rbi) and makes it easy for you to add
gradual typing to your application.

## Installation

Add this line to your application's `Gemfile`:

```rb
group :development, :test do
  gem 'tapioca', require: false
end
```

Run `bundle install` and make sure Tapioca is properly installed:

<!-- START_HELP -->
```shell
$ tapioca help

Commands:
  tapioca --version, -v      # Show version
  tapioca annotations        # Pull gem RBI annotations from remote sources
  tapioca check-shims        # Check duplicated definitions in shim RBIs
  tapioca configure          # Initialize folder structure and type checking configuration
  tapioca dsl [constant...]  # Generate RBIs for dynamic methods
  tapioca gem [gem...]       # Generate RBIs from gems
  tapioca help [COMMAND]     # Describe available commands or one specific command
  tapioca init               # Get project ready for type checking
  tapioca require            # Generate the list of files to be required by tapioca
  tapioca todo               # Generate the list of unresolved constants

Options:
  -c, [--config=<config file path>]                  # Path to the Tapioca configuration file
                                                     # Default: sorbet/tapioca/config.yml
  -V, [--verbose], [--no-verbose], [--skip-verbose]  # Verbose output for debugging purposes
                                                     # Default: false

```
<!-- END_HELP -->

## Getting started

Execute this command to get started:

```shell
$ bundle exec tapioca init
```

This will:

1. create the [configuration file for Sorbet](https://sorbet.org/docs/cli#config-file), the [configuration file for Tapioca](#Configuration) and the [require.rb file](#manually-requiring-parts-of-a-gem)
2. install the [binstub](https://bundler.io/man/bundle-binstubs.1.html#DESCRIPTION) for Tapioca in your app's `bin/` folder, so that you can use `bin/tapioca` to run commands in your app
3. pull the community RBI annotations from the [central repository](https://github.com/Shopify/rbi-central) matching your app's gems
4. generate the RBIs for your app's gems
5. generate the RBI file for missing constants

See the following sections for more details about each step.

<!-- START_HELP_COMMAND_INIT -->
```shell
$ tapioca help init

Usage:
  tapioca init

Options:
  -c, [--config=<config file path>]                  # Path to the Tapioca configuration file
                                                     # Default: sorbet/tapioca/config.yml
  -V, [--verbose], [--no-verbose], [--skip-verbose]  # Verbose output for debugging purposes
                                                     # Default: false

Get project ready for type checking
```
<!-- END_HELP_COMMAND_INIT -->

## Usage

- [Generate RBI files for gems](rbi_files_for_gems)
- [Generate RBI files for Rails and other DSLs](rbi_files_for_dsls)
- [Pull RBI annotations from remote sources](rbi_annotation_from_remote_sources)
- [Create RBI files for missing constants and methods](rbi_files_for_missing_constants_and_methods)

## Configuration

Tapioca supports loading command defaults from a configuration file. The default configuration file location is `sorbet/tapioca/config.yml` but this default can be changed using the `--config` flag and supplying an alternative configuration file path.

Tapioca's configuration file must be a well-formed YAML file with top-level keys for the various Tapioca commands. Keys under each such top-level command should be the underscore version of a long option name for that command and the value for that key should be the value of the option.

For example, if you always want to generate gem RBIs with inline documentation, then you would create the file `sorbet/tapioca/config.yml` as:

```yaml
gem:
  doc: true
```

Additionally, if you always want to exclude the `AASM` and `ActiveRecordFixtures` DSL compilers in your DSL RBI generation runs, your config file would then look like this:

```yaml
gem:
  doc: true
dsl:
  exclude:
  - UrlHelpers
  - ActiveRecordFixtures
```

The full configuration file, with each option and its default value, would look something like this:
<!-- START_CONFIG_TEMPLATE -->
```yaml
---
require:
  postrequire: sorbet/tapioca/require.rb
todo:
  todo_file: sorbet/rbi/todo.rbi
  file_header: true
dsl:
  outdir: sorbet/rbi/dsl
  file_header: true
  only: []
  exclude: []
  verify: false
  quiet: false
  workers: 1
  rbi_max_line_length: 120
  environment: development
  list_compilers: false
  app_root: "."
  halt_upon_load_error: true
  skip_constant: []
  compiler_options: {}
gem:
  outdir: sorbet/rbi/gems
  file_header: true
  all: false
  prerequire: ''
  postrequire: sorbet/tapioca/require.rb
  exclude: []
  include_dependencies: false
  typed_overrides:
    activesupport: 'false'
  verify: false
  doc: true
  loc: true
  exported_gem_rbis: true
  workers: 1
  auto_strictness: true
  dsl_dir: sorbet/rbi/dsl
  rbi_max_line_length: 120
  environment: development
  halt_upon_load_error: true
check_shims:
  gem_rbi_dir: sorbet/rbi/gems
  dsl_rbi_dir: sorbet/rbi/dsl
  shim_rbi_dir: sorbet/rbi/shims
  annotations_rbi_dir: sorbet/rbi/annotations
  todo_rbi_file: sorbet/rbi/todo.rbi
  payload: true
  workers: 1
annotations:
  sources:
  - https://raw.githubusercontent.com/Shopify/rbi-central/main
  netrc: true
  netrc_file: ''
  typed_overrides: {}
```
<!-- END_CONFIG_TEMPLATE -->
