> :warning: **Note**: This software is currently under active development. The API and interface should be considered unstable until a v1.0.0 release.

# Tapioca

![Build Status](https://github.com/Shopify/tapioca/workflows/CI/badge.svg)

Tapioca is a library used to generate RBI (Ruby interface) files for use with [Sorbet](https://sorbet.org). RBI files provide the structure (classes, modules, methods, parameters) of the gem/library to Sorbet to assist with typechecking.

As yet, no gem exports type information in a consumable format and it would be a huge effort to manually maintain such an interface file for all the gems that your codebase depends on. Thus, there is a need for an automated way to generate the appropriate RBI file for a given gem. The `tapioca` gem, developed at Shopify, is able to do exactly that to almost 99% accuracy. It can generate the definitions for all statically defined types and most of the runtime defined types exported from Ruby gems (non-Ruby gems are not handled yet).

When you run `tapioca gem` in a project, `tapioca` loads all the gems that are in your dependency list from the Gemfile into memory. It then performs runtime introspection on the loaded types to understand their structure and generates an appropriate RBI file for each gem with a versioned filename.

## Manual gem requires

For gems that have a normal default `require` and load all of their constants through such a require, everything works seamlessly. However, for gems that are marked as `require: false` in the Gemfile, or for gems that export optionally loaded types via different requires, where a single require does not load the whole gem code into memory, `tapioca` will not be able to load some of the types into memory and, thus, won't be able to generate complete RBIs for them. For this reason, we need to keep a small external file named `sorbet/tapioca/require.rb` that is executed after all the gems in the Gemfile have been required and before generation of gem RBIs have started. This file is responsible for adding the requires for additional files from gems, which are not covered by the default require.

For example, suppose you are using the class `BetterHtml::Parser` exported from the `better_html` gem. Just doing a `require "better_html"` (which is the default require) does not load that type:

```shell
$ bundle exec pry
[1] pry(main)> require 'better_html'
=> true
[2] pry(main)> BetterHtml
=> BetterHtml
[3] pry(main)> BetterHtml::Parser
NameError: uninitialized constant BetterHtml::Parser
from (pry):3:in `__pry__`
[4] pry(main)> require 'better_html/parser'
=> true
[5] pry(main)> BetterHtml::Parser
=> BetterHtml::Parser
```

In order to make sure that `tapioca` can reflect on that type, we need to add the line `require "better_html/parser"` to the `sorbet/tapioca/require.rb` file. This will make sure `BetterHtml::Parser` is loaded into memory and a type annotation is generated for it in the `better_html.rbi` file. If this extra `require` line is not added to `sorbet/tapioca/require.rb` file, then the definition for that type will be missing from the RBI file.

If you ever run into a case, where you add a gem or update the version of a gem and run `tapioca gem` but don't have some types you expect in the generated gem RBI files, you will need to make sure you have added the necessary requires to the `sorbet/tapioca/require.rb` file.

You can use the command `tapioca require` to auto-populate the `sorbet/tapioca/require.rb` file with all the requires found
in your application. Once the file generated, you should review it, remove all unnecessary requires and commit it.

## How does tapioca compare to "srb rbi gems" ?

[Please see the detailed answer on our wiki](https://github.com/Shopify/tapioca/wiki/How-does-tapioca-compare-to-%22srb-rbi-gems%22-%3F)

## Installation

Add this line to your application's `Gemfile`:

```ruby
group :development do
  gem 'tapioca', require: false
end
```

and do not forget to execute `tapioca` using `bundler`:

```shell
$ bundle exec tapioca help
Commands:
  tapioca --version, -v      # show version
  tapioca clean-shims        # clean duplicated definitions in shim RBIs
  tapioca dsl [constant...]  # generate RBIs for dynamic methods
  tapioca gem [gem...]       # generate RBIs from gems
  tapioca help [COMMAND]     # Describe available commands or one specific command
  tapioca init               # initializes folder structure
  tapioca require            # generate the list of files to be required by tapioca
  tapioca todo               # generate the list of unresolved constants

Options:
  -c, [--config=<config file path>]  # Path to the Tapioca configuration file
                                     # Default: sorbet/tapioca/config.yml
  -V, [--verbose], [--no-verbose]    # Verbose output for debugging purposes
```

## Usage

### Initialize folder structure

Command: `tapioca init`

This will create the `sorbet/config` and `sorbet/tapioca/require.rb` files for you, if they don't exist. If any of the files already exist, they will not be changed.

<!-- START_HELP_COMMAND_INIT -->
```shell
Usage:
  tapioca init

Options:
  -c, [--config=<config file path>]  # Path to the Tapioca configuration file
                                     # Default: sorbet/tapioca/config.yml
  -V, [--verbose], [--no-verbose]    # Verbose output for debugging purposes

initializes folder structure
```
<!-- END_HELP_COMMAND_INIT -->

### Generate RBI files for gems

Command: `tapioca gem [gems...]`

This will generate RBIs for the specified gems and place them in the RBI directory.

<!-- START_HELP_COMMAND_GEM -->
```shell
Usage:
  tapioca gem [gem...]

Options:
  --out, -o, [--outdir=directory]                             # The output directory for generated gem RBI files
                                                              # Default: sorbet/rbi/gems
          [--file-header], [--no-file-header]                 # Add a "This file is generated" header on top of each generated RBI file
                                                              # Default: true
          [--all], [--no-all]                                 # Regenerate RBI files for all gems
  --pre, -b, [--prerequire=file]                              # A file to be required before Bundler.require is called
  --post, -a, [--postrequire=file]                            # A file to be required after Bundler.require is called
                                                              # Default: sorbet/tapioca/require.rb
  -x, [--exclude=gem [gem ...]]                               # Exclude the given gem(s) from RBI generation
  --typed, -t, [--typed-overrides=gem:level [gem:level ...]]  # Override for typed sigils for generated gem RBIs
                                                              # Default: {"activesupport"=>"false"}
          [--verify], [--no-verify]                           # Verify RBIs are up-to-date
          [--doc], [--no-doc]                                 # Include YARD documentation from sources when generating RBIs. Warning: this might be slow
          [--exported-gem-rbis], [--no-exported-gem-rbis]     # Include RBIs found in the `rbi/` directory of the gem
                                                              # Default: true
  -w, [--workers=N]                                           # EXPERIMENTAL: Number of parallel workers to use when generating RBIs
                                                              # Default: 1
  -c, [--config=<config file path>]                           # Path to the Tapioca configuration file
                                                              # Default: sorbet/tapioca/config.yml
  -V, [--verbose], [--no-verbose]                             # Verbose output for debugging purposes

generate RBIs from gems
```
<!-- END_HELP_COMMAND_GEM -->

### Generate the list of all unresolved constants

Command: `tapioca todo`

This will generate the file `sorbet/rbi/todo.rbi` defining all unresolved constants as empty modules.

<!-- START_HELP_COMMAND_TODO -->
```shell
Usage:
  tapioca todo

Options:
      [--todo-file=TODO_FILE]              
                                           # Default: sorbet/rbi/todo.rbi
      [--file-header], [--no-file-header]  # Add a "This file is generated" header on top of each generated RBI file
                                           # Default: true
  -c, [--config=<config file path>]        # Path to the Tapioca configuration file
                                           # Default: sorbet/tapioca/config.yml
  -V, [--verbose], [--no-verbose]          # Verbose output for debugging purposes

generate the list of unresolved constants
```
<!-- END_HELP_COMMAND_TODO -->

### Generate DSL RBI files

Command: `tapioca dsl [constant...]`

This will generate DSL RBIs for specified constants (or for all handled constants, if a constant name is not supplied). You can read about DSL RBI generators supplied by `tapioca` in [the manual](manual/generators.md).

<!-- START_HELP_COMMAND_DSL -->
```shell
Usage:
  tapioca dsl [constant...]

Options:
  --out, -o, [--outdir=directory]                # The output directory for generated DSL RBI files
                                                 # Default: sorbet/rbi/dsl
          [--file-header], [--no-file-header]    # Add a "This file is generated" header on top of each generated RBI file
                                                 # Default: true
          [--only=generator [generator ...]]     # Only run supplied DSL generator(s)
          [--exclude=generator [generator ...]]  # Exclude supplied DSL generator(s)
          [--verify], [--no-verify]              # Verifies RBIs are up-to-date
  -q, [--quiet], [--no-quiet]                    # Supresses file creation output
  -w, [--workers=N]                              # EXPERIMENTAL: Number of parallel workers to use when generating RBIs
                                                 # Default: 1
  -c, [--config=<config file path>]              # Path to the Tapioca configuration file
                                                 # Default: sorbet/tapioca/config.yml
  -V, [--verbose], [--no-verbose]                # Verbose output for debugging purposes

generate RBIs for dynamic methods
```
<!-- END_HELP_COMMAND_DSL -->

## Configuration

Tapioca supports loading command defaults from a configuration file. The default configuration
file location is `sorbet/tapioca/config.yml` but this default can be changed using the `--config` flag
and supplying an alternative configuration file path.

A configuration file must be a well-formed YAML file with top-level keys for the various Tapioca commands. Keys under each such top-level command should be the underscore version of a long option name for that command and the value for that key should be the value of the option.

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
gem:
  outdir: sorbet/rbi/gems
  file_header: true
  all: false
  prerequire: ''
  postrequire: sorbet/tapioca/require.rb
  exclude: []
  typed_overrides:
    activesupport: 'false'
  verify: false
  doc: false
  exported_gem_rbis: true
  workers: 1
clean_shims:
  gem_rbi_dir: sorbet/rbi/gems
  dsl_rbi_dir: sorbet/rbi/dsl
  shim_rbi_dir: sorbet/rbi/shims
```
<!-- END_CONFIG_TEMPLATE -->

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/tapioca. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](https://github.com/Shopify/tapioca/blob/main/CODE_OF_CONDUCT.md) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/Shopify/tapioca/blob/main/LICENSE.txt).
