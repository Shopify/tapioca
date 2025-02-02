---
layout: default
title: RBI files for gems
parent: Tapioca
nav_order: 1
---

# Generating RBI files for gems

Sorbet does not read the code in your gem dependencies, so it does not know the constants and methods declared inside gems. Tapioca is able to load your gem dependencies from your application's `Gemfile` and compile RBI files to represent their content.

In order to generate the RBI files for the gems used in your application, run the following command:

```shell
$ bin/tapioca gems [gems...]

Removing RBI files of gems that have been removed:

  Nothing to do.

Generating RBI files of gems that are added or updated:

  Requiring all gems to prepare for compiling...    Done

  Compiled ansi
      create  sorbet/rbi/gems/ansi@1.5.0.rbi

  ...

All operations performed in working directory.
Please review changes and commit them.
```

This will load your application, find all the gems required by it and generate an RBI file for each gem under the `sorbet/rbi/gems` directory for each of those gems. This process will also import signatures that can be found inside each gem sources, and, optionally, any YARD documentation inside the gem.

<!-- START_HELP_COMMAND_GEM -->
```shell
$ tapioca help gem

Usage:
  tapioca gem [gem...]

Options:
  --out, -o,   [--outdir=directory]                                                                  # The output directory for generated gem RBI files
                                                                                                     # Default: sorbet/rbi/gems
               [--file-header], [--no-file-header], [--skip-file-header]                             # Add a "This file is generated" header on top of each generated RBI file
                                                                                                     # Default: true
               [--all], [--no-all], [--skip-all]                                                     # Regenerate RBI files for all gems
                                                                                                     # Default: false
  --pre, -b,   [--prerequire=file]                                                                   # A file to be required before Bundler.require is called
  --post, -a,  [--postrequire=file]                                                                  # A file to be required after Bundler.require is called
                                                                                                     # Default: sorbet/tapioca/require.rb
  -x,          [--exclude=gem [gem ...]]                                                             # Exclude the given gem(s) from RBI generation
               [--include-dependencies], [--no-include-dependencies], [--skip-include-dependencies]  # Generate RBI files for dependencies of the given gem(s)
                                                                                                     # Default: false
  --typed, -t, [--typed-overrides=gem:level [gem:level ...]]                                         # Override for typed sigils for generated gem RBIs
                                                                                                     # Default: {"activesupport" => "false"}
               [--verify], [--no-verify], [--skip-verify]                                            # Verify RBIs are up-to-date
                                                                                                     # Default: false
               [--doc], [--no-doc], [--skip-doc]                                                     # Include YARD documentation from sources when generating RBIs. Warning: this might be slow
                                                                                                     # Default: true
               [--loc], [--no-loc], [--skip-loc]                                                     # Include comments with source location when generating RBIs
                                                                                                     # Default: true
               [--exported-gem-rbis], [--no-exported-gem-rbis], [--skip-exported-gem-rbis]           # Include RBIs found in the `rbi/` directory of the gem
                                                                                                     # Default: true
  -w,          [--workers=N]                                                                         # Number of parallel workers to use when generating RBIs (default: auto)
               [--auto-strictness], [--no-auto-strictness], [--skip-auto-strictness]                 # Autocorrect strictness in gem RBIs in case of conflict with the DSL RBIs
                                                                                                     # Default: true
  --dsl-dir,   [--dsl-dir=directory]                                                                 # The DSL directory used to correct gems strictnesses
                                                                                                     # Default: sorbet/rbi/dsl
               [--rbi-max-line-length=N]                                                             # Set the max line length of generated RBIs. Signatures longer than the max line length will be wrapped
                                                                                                     # Default: 120
  -e,          [--environment=ENVIRONMENT]                                                           # The Rack/Rails environment to use when generating RBIs
                                                                                                     # Default: development
               [--halt-upon-load-error], [--no-halt-upon-load-error], [--skip-halt-upon-load-error]  # Halt upon a load error while loading the Rails application
                                                                                                     # Default: true
  -c,          [--config=<config file path>]                                                         # Path to the Tapioca configuration file
                                                                                                     # Default: sorbet/tapioca/config.yml
  -V,          [--verbose], [--no-verbose], [--skip-verbose]                                         # Verbose output for debugging purposes
                                                                                                     # Default: false

Generate RBIs from gems
```
<!-- END_HELP_COMMAND_GEM -->

By default, running `tapioca gem` will only generate the RBI files for gems that have been added to or removed from the project's `Gemfile` this means that Tapioca will not regenerate the RBI files for untouched gems. If you want to force the regeneration you can supply gem names to the `tapioca gem` command. When supplying gem names if you want to generate RBI files for their dependencies as well, you can use the `--include-dependencies` option. When changing Tapioca configuration or bumping its version, it may be useful to force the regeneration of all the RBI files previously generated. This can be done with the `--all` option:

```shell
bin/tapioca gems --all
```

> Are you coming from `srb rbi`? [See how `tapioca gem` compares to `srb rbi`](https://github.com/Shopify/tapioca/wiki/How-does-tapioca-compare-to-%22srb-rbi-gems%22-%3F).

## Manually requiring parts of a gem

It may happen that the RBI file generated for a gem listed inside your `Gemfile.lock` is missing some definitions that you would expect it to be exporting.

For gems that have a normal default `require` and that load all of their constants through that, everything should work seamlessly. However, for gems that are marked as `require: false` in the `Gemfile`, or for gems that export constants optionally via different requires, where a single require does not load the whole gem code into memory, Tapioca will not be able to load some of the types into memory and, thus, won't be able to generate complete RBIs for them. For this reason, we need to keep a small external file named `sorbet/tapioca/require.rb` that is executed after all the gems in the `Gemfile` have been required and before generation of gem RBIs have started. This file is responsible for adding the requires for additional files from gems, which are not covered by the default require.

For example, suppose you are using the class `BetterHtml::Parser` exported from the `better_html` gem. Just doing a `require "better_html"` (which is the default require) does not load that type:

```shell
$ bundle exec irb

irb(main):001> require 'better_html'
=> true
irb(main):002> BetterHtml
=> BetterHtml
irb(main):003> BetterHtml::Parser
(irb):3:in '<main>': uninitialized constant BetterHtml::Parser (NameError)
Did you mean?  BetterHtml::ParserError
irb(main):004> require 'better_html/parser'
=> true
irb(main):005> BetterHtml::Parser
=> BetterHtml::Parser
```

In order to make sure that `tapioca` can reflect on that type, we need to add the line `require "better_html/parser"` to the `sorbet/tapioca/require.rb` file. This will make sure `BetterHtml::Parser` is loaded into memory and a type annotation is generated for it in the `better_html.rbi` file. If this extra `require` line is not added to `sorbet/tapioca/require.rb` file, then Tapioca will be able to generate definitions for `BetterHtml` and other constants, but not for `BetterHtml::Parser`, which will be missing from the RBI file.

For example, you can take a look at Tapioca's own [`require.rb` file](https://github.com/Shopify/tapioca/blob/main/sorbet/tapioca/require.rb):

```rb
# typed: strict
# frozen_string_literal: true

require "ansi/code"
require "google/protobuf"
require "rails/all"
require "rails/generators"
require "rails/generators/app_base"
require "rake/testtask"
require "rubocop/rake_task"
```

If you ever run into a case, where you add a gem or update the version of a gem and run `tapioca gem` but don't have some types you expect in the generated gem RBI files, you will need to make sure you have added the necessary requires to the `sorbet/tapioca/require.rb` file and regenerate the RBI file for that gem explicitly using `bin/tapioca gem <gem-name>`.

To help you get started, you can use the command `tapioca require` to auto-populate the contents of the `sorbet/tapioca/require.rb` file with all the requires found in your application:

```shell
$ bin/tapioca require

Compiling sorbet/tapioca/require.rb, this may take a few seconds... Done

All requires from this application have been written to sorbet/tapioca/require.rb.
Please review changes and commit them, then run `bin/tapioca gem`.
```

Once the file is generated, you should review it, remove all unnecessary requires and commit it.

## Excluding a gem from RBI generation

It may be useful to exclude some gems from the generation process. For example for gems that are in Bundle's debug group or gems of which the contents are dependent on the architecture they are loaded on.

To do so you can pass the list of gems you want to exclude in the command line with the `--exclude` option:

```shell
$ bin/tapioca gems --exclude gemA gemB
```

Or through the configuration file:

```yaml
gem:
  exclude:
    - gemA
    - gemB
```

There are a few development/test environment gems that can cause RBI generation issues, so Tapioca skips them by default:

* `debug`
* `fakefs`

## Changing the strictness level of the RBI for a gem

By default, all RBI files for gems are generated with the [strictness level](https://sorbet.org/docs/static#file-level-granularity-strictness-levels) `typed: true`. Sometimes, this strictness level can create type-checking errors when a gem contains definitions that conflict with [Sorbet internal definitions for Ruby core and standard library](https://sorbet.org/docs/faq#it-looks-like-sorbets-types-for-the-stdlib-are-wrong).

Tapioca comes with an automatic detection (option `--auto-strictness`, enabled by default) of such cases and will switch the strictness level to `typed: false` in RBI files containing conflicts with the core and standard library definitions. It is nonetheless possible to manually switch the strictness level for a gem using the `--typed-overrides` option:

```shell
$ bin/tapioca gems --typed-overrides gemA:false gemB:false
```

Or through the configuration file:

```yaml
gem:
  typed_overrides:
    gemA: "false"
    gemB: "false"
```

## Keeping RBI files for gems up-to-date

To ensure all RBI files for gems are present and have the correct version based on your `Gemfile.lock`, Tapioca provides a `--verify` option:

```shell
$ bin/tapioca gems --verify

Checking for out-of-date RBIs...

Nothing to do, all RBIs are up-to-date.
```

This option can be used in CI to make sure the RBI files are *up-to-date* and ensure accurate type checking.

**Warning**: doing so will break your normal automated dependency update workflow as every pull request opened to bump a gem version will fail CI since the RBI will be out-of-date. You will need to either set up additional automation (eg [Dependabot](https://github.com/dependabot/dependabot-core/issues/5962#issuecomment-1303781931)), or manually run `bin/tapioca gems` and commit the results.

**Warning**: Verification ONLY ensures the RBI files are present, used and have the correct version based on the gem version in your `Gemfile.lock`. It's possible for your RBIs to be out-of-date if RBIs were not regenerated following an update to tapioca itself or if a another gem that injects functionality (e.g. `turbo-rails`) was installed/updated/removed. To ensure RBIs are completely up-to-date, you must run `bin/tapioca gems --all` but it's not recommended to do this in CI as it's an expensive operation.

## Importing hand written signatures from gem's `rbi/` folder

Tapioca will import any signatures found in the `rbi/` folder of a given gem and combine them with the RBIs it generates. This is useful when a gem doesn't want to depend on `sorbet-runtime` but still wants to provide type safety to users during static checks. Note that the `rbi/` folder needs to be included in the gem release using the `.gemspec` file. Applications can choose not to import these signatures using the `--no-exported-gem-rbis` flag.
