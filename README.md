> :warning: **Note**: This software is currently under active development. The API and interface should be considered unstable until a v1.0.0 release.

<p align="center">
  <img alt="Tapioca logo" width="200" src="misc/tapioca-logo.svg" />
</p>

# Tapioca - The swiss army knife of RBI generation

![Build Status](https://github.com/Shopify/tapioca/workflows/CI/badge.svg)

Tapioca makes it easy to work with [Sorbet](https://sorbet.org) in your codebase. It surfaces types and methods from many sources that Sorbet cannot otherwise see – such as gems, Rails and other DSLs – compiles them into [RBI files](https://sorbet.org/docs/rbi) and makes it easy for you to add gradual typing to your application.

**Features**:

* Easy installation and configuration
* Generation of RBI files for the gems used in your application
  * Automatic generation from your application's Gemfile
  * Importing of signatures from the source code of gems
  * Importing of documentation from the source code of gems
  * Synchronization validation for your CI
* Generation of RBI files for various DSL patterns that relies on meta-programming
  * Automatic generation from your application's content
  * Support many DSL patterns such as Rails, Google Protobuf, SmartProperties and more out of the box
  * Extensible interface that allows you to write your own DSL compilers for other DSL patterns
  * Automatic generation of signatures for methods from known DSLs
  * Synchronization validation for your CI
* Management of shim RBI files
  * Find useless definitions in shim RBI files from gems generated RBI files
  * Find useless definitions in shim RBI files from DSL generated RBI files
  * Find useless definitions in shim RBI files from Sorbet's embedded RBI for core and stdlib
  * Synchronization validation for your CI

## Installation

Add this line to your application's `Gemfile`:

```rb
group :development do
  gem 'tapioca', require: false
end
```

Run `bundle install` and make sure Tapioca is properly installed:

```sh
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

## Getting started

Execute this command to get started:

```sh
$ bundle exec tapioca init
      create  sorbet/config
      create  sorbet/tapioca/config.yml
      create  sorbet/tapioca/require.rb
      create  bin/tapioca
```

This will:

* create the [configuration file for Sorbet](https://sorbet.org/docs/cli#config-file), the [configuration file for Tapioca](#Configuration) and the [require.rb file](#manually-requiring-parts-of-a-gem)
* install the [binstub](https://bundler.io/man/bundle-binstubs.1.html#DESCRIPTION) for Tapioca in your app's `bin/` folder, so that you can use `bin/tapioca` to run commands in your app

<!-- START_HELP_COMMAND_INIT -->
```shell
$ tapioca help init

Usage:
  tapioca init

Options:
  -c, [--config=<config file path>]  # Path to the Tapioca configuration file
                                     # Default: sorbet/tapioca/config.yml
  -V, [--verbose], [--no-verbose]    # Verbose output for debugging purposes

initializes folder structure
```
<!-- END_HELP_COMMAND_INIT -->

## Usage

### Generating RBI files for gems

Sorbet does not read the code in your gem dependencies, so it does not know the constants and methods declared inside gems. Tapioca is able to load your gem dependencies from your application's `Gemfile` and compile RBI files to represent their content.

In order to generate the RBI files for the gems used in your application, run the following command:

```sh
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
                                                              # Default: true
          [--exported-gem-rbis], [--no-exported-gem-rbis]     # Include RBIs found in the `rbi/` directory of the gem
                                                              # Default: true
  -w, [--workers=N]                                           # EXPERIMENTAL: Number of parallel workers to use when generating RBIs
                                                              # Default: 1
          [--auto-strictness], [--no-auto-strictness]         # Autocorrect strictness in gem RBIs in case of conflict with the DSL RBIs
                                                              # Default: true
  --dsl-dir, [--dsl-dir=directory]                            # The DSL directory used to correct gems strictnesses
                                                              # Default: sorbet/rbi/dsl
          [--rbi-max-line-length=N]                           # Set the max line length of generated RBIs. Signatures longer than the max line length will be wrapped
                                                              # Default: 120
  -c, [--config=<config file path>]                           # Path to the Tapioca configuration file
                                                              # Default: sorbet/tapioca/config.yml
  -V, [--verbose], [--no-verbose]                             # Verbose output for debugging purposes

generate RBIs from gems
```
<!-- END_HELP_COMMAND_GEM -->

By default, running `tapioca gem` will only generate the RBI files for gems that have been added to or removed from the project's `Gemfile` this means that Tapioca will not regenerate the RBI files for untouched gems. However, when changing Tapioca configuration or bumping its version, it may be useful to force the regeneration of the RBI files previsouly generated. This can be done with the `--all` option:

```shell
bin/tapioca gems --all
```

> Are you coming from `srb rbi`? [See how `tapioca gem` compares to `srb rbi`](https://github.com/Shopify/tapioca/wiki/How-does-tapioca-compare-to-%22srb-rbi-gems%22-%3F).

#### Manually requiring parts of a gem

It may happen that the RBI file generated for a gem listed inside your `Gemfile.lock` is missing some definitions that you would expect it to be exporting.

For gems that have a normal default `require` and that load all of their constants through that, everything should work seamlessly. However, for gems that are marked as `require: false` in the `Gemfile`, or for gems that export constants optionally via different requires, where a single require does not load the whole gem code into memory, Tapioca will not be able to load some of the types into memory and, thus, won't be able to generate complete RBIs for them. For this reason, we need to keep a small external file named `sorbet/tapioca/require.rb` that is executed after all the gems in the `Gemfile` have been required and before generation of gem RBIs have started. This file is responsible for adding the requires for additional files from gems, which are not covered by the default require.

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

```sh
$ bin/tapioca require

Compiling sorbet/tapioca/require.rb, this may take a few seconds... Done

All requires from this application have been written to sorbet/tapioca/require.rb.
Please review changes and commit them, then run `bin/tapioca gem`.
```

Once the file is generated, you should review it, remove all unnecessary requires and commit it.

#### Excluding a gem from RBI generation

It may be useful to exclude some gems from the generation process. For example for gems that are in Bundle's debug group or gems of which the contents are dependent on the architecture they are loaded on. A typical example is `fakefs`, which, if loaded into memory, changes `File` operations to be no-ops and breaks Tapioca RBI file generation altogether.

To do so you can pass the list of gems you want to exclude in the command line with the `--exclude` option:

```sh
$ bin/tapioca gems --exclude gemA gemB
```

Or through the configuration file:

```yaml
gem:
  exclude:
    - gemA
    - gemB
```

#### Changing the strictness level of the RBI for a gem

By default, all RBI files for gems are generated with the [strictness level](https://sorbet.org/docs/static#file-level-granularity-strictness-levels) `typed: true`. Sometimes, this strictness level can create type-checking errors when a gem contains definitions that conflict with [Sorbet internal definitions for Ruby core and standard library](https://sorbet.org/docs/faq#it-looks-like-sorbets-types-for-the-stdlib-are-wrong).

Tapioca comes with an automatic detection (option `--auto-strictness`, enabled by default) of such cases and will switch the strictness level to `typed: false` in RBI files containing conflicts with the core and standard library definitions. It is nonetheless possible to manually switch the strictness level for a gem using the `--typed-overrides` option:

```sh
$ bin/tapioca gems --typed-overrides gemA:false gemB:false
```

Or through the configuration file:

```yaml
gem:
  typed_overrides:
    gemA: "false"
    gemB: "false"
```

#### Keeping RBI files for gems up-to-date

To ensure all RBI files for gems are up-to-date with the latest changes in your `Gemfile.lock`, Tapioca provides a `--verify` option:

```sh
$ bin/tapioca gems --verify

Checking for out-of-date RBIs...

Nothing to do, all RBIs are up-to-date.
```

This option can be used on CI to make sure the RBI files are always up-to-date and ensure accurate type checking. **Warning**: doing so will break your normal Dependabot workflow as every pull-request opened to bump a gem version will fail CI since the RBI will be out-of-date and will require you to manually run `bin/tapioca gems` to update them.

### Generating RBI files for Rails and other DSLs

Sorbet by itself does not understand DSLs involving meta-programming, such as Rails. This means that Sorbet won't know about constants and methods generated by `ActiveRecord` or `ActiveSupport`.
To solve this, Tapioca can load your application and introspect it to find the constants and methods that would exist at runtime and compile them into RBI files.

To generate the RBI files for the DSLs used in your application, run the following command:

```sh
$ bin/tapioca dsl

Loading Rails application... Done
Loading DSL compiler classes... Done
Compiling DSL RBI files...

      create  sorbet/rbi/dsl/my_model.rbi
      ...

Done
```

This will generate DSL RBIs for specified constants (or for all handled constants, if a constant name is not supplied). You can read about DSL RBI compilers supplied by `tapioca` in [the manual](manual/compilers.md).

<!-- START_HELP_COMMAND_DSL -->
```shell
$ tapioca help dsl

Usage:
  tapioca dsl [constant...]

Options:
  --out, -o, [--outdir=directory]              # The output directory for generated DSL RBI files
                                               # Default: sorbet/rbi/dsl
          [--file-header], [--no-file-header]  # Add a "This file is generated" header on top of each generated RBI file
                                               # Default: true
          [--only=compiler [compiler ...]]     # Only run supplied DSL compiler(s)
          [--exclude=compiler [compiler ...]]  # Exclude supplied DSL compiler(s)
          [--verify], [--no-verify]            # Verifies RBIs are up-to-date
  -q, [--quiet], [--no-quiet]                  # Suppresses file creation output
  -w, [--workers=N]                            # EXPERIMENTAL: Number of parallel workers to use when generating RBIs
                                               # Default: 1
          [--rbi-max-line-length=N]            # Set the max line length of generated RBIs. Signatures longer than the max line length will be wrapped
                                               # Default: 120
  -c, [--config=<config file path>]            # Path to the Tapioca configuration file
                                               # Default: sorbet/tapioca/config.yml
  -V, [--verbose], [--no-verbose]              # Verbose output for debugging purposes

generate RBIs for dynamic methods
```
<!-- END_HELP_COMMAND_DSL -->

#### Keeping RBI files for DSLs up-to-date

To ensure all RBI files for DSLs are up-to-date with the latest changes in your application or database, Tapioca provide a `--verify` option:

```sh
$ bin/tapioca dsl --verify

Loading Rails application... Done
Loading DSL compiler classes... Done
Checking for out-of-date RBIs...


RBI files are out-of-date. In your development environment, please run:
  `bin/tapioca dsl`
Once it is complete, be sure to commit and push any changes

Reason:
  File(s) changed:
  - sorbet/rbi/dsl/my_model.rbi
```

This option can be used on CI to make sure the RBI files are always up-to-date and ensure accurate type checking.

#### Writing custom DSL compilers

It is possible to create your own compilers for DSLs not supported by Tapioca out of the box.

Let's take for example this `Encryptable` module that uses the [`included` hook](https://ruby-doc.org/core-3.1.1/Module.html#method-i-included) to dynamically add a few methods to the classes that include it:

```rb
module Encryptable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def attr_encrypted(attr_name)
      encrypted_attributes << attr_name

      attr_accessor(attr_name)

      encrypted_attr_name = :"#{attr_name}_encrypted"

      define_method(encrypted_attr_name) do
        value = send(attr_name)
        encrypt(value)
      end

      define_method("#{encrypted_attr_name}=") do |value|
        send("#{attr_name}=", decrypt(value))
      end
    end

    def encrypted_attributes
      @encrypted_attributes ||= []
    end
  end

  private

  def encrypt(value)
    value.unpack("H*").first
  end

  def decrypt(value)
    [value].pack("H*")
  end
end
```

When `Encryptable` is included in a class like this one, it makes it possible to call `attr_encrypted` to define an attribute, its accessors and its encrypted accessors:

```rb
class CreditCard
  include Encryptable

  attr_encrypted :number
end
```

These accessors can then be used on the `CreditCard` instance without having to define them in the class:

```rb
# typed: true
# file: example.rb

card = CreditCard.new
card.number = "1234 5678 9012 3456"

p card.number             # => "1234 5678 9012 3456"
p card.number_encrypted   # => "31323334203536373820393031322033343536"

card.number_encrypted = "31323334203536373820393031322033343536"
p card.number             # => "1234 5678 9012 3456"
```

Sadly, since these methods have been created dynamically at runtime, when our `attr_encryptable` method was run, there are no static traces of the `number`, `number=`, `number_encrypted` and `number_encrypted=` methods. Since Sorbet does not run the Ruby code but analyses it statically, it can't see these methods and running type-checking will show a bunch of errors:

```shell
$ bundle exec srb tc

lib/example.rb:5: Method number= does not exist on CreditCard https://srb.help/7003
lib/example.rb:7: Method number does not exist on CreditCard https://srb.help/7003
lib/example.rb:8: Method number_encrypted does not exist on CreditCard https://srb.help/7003
lib/example.rb:10: Method number_encrypted= does not exist on CreditCard https://srb.help/7003
lib/example.rb:11: Method number does not exist on CreditCard https://srb.help/7003

Errors: 5
```

To solve this you will have to create your own DSL compiler able that understands the `Encryptable` DSL and can generate the RBI definitions representing the actual shape of `CreditCard` at runtime.

To do so, create the new DSL compiler inside the `sorbet/tapioca/compilers` directory of your application with the following contents:

```rb
module Tapioca
  module Compilers
    class Encryptable < Tapioca::Dsl::Compiler
      extend T::Sig

      ConstantType = type_member {{ fixed: T.class_of(Encryptable) }}

      sig { override.returns(T::Enumerable[Module]) }
      def self.gather_constants
        # Collect all the classes that include Encryptable
        all_classes.select { |c| c < ::Encryptable }
      end

      sig { override.void }
      def decorate
        # Create a RBI definition for each class that includes Encryptable
        root.create_path(constant) do |klass|
          # For each encrypted attribute we find in the class
          constant.encrypted_attributes.each do |attr_name|
            # Create the RBI definitions for all the missing methods
            klass.create_method(attr_name, return_type: "String")
            klass.create_method("#{attr_name}=", parameters: [ create_param("value", type: "String") ], return_type: "void")
            klass.create_method("#{attr_name}_encrypted", return_type: "String")
            klass.create_method("#{attr_name}_encrypted=", parameters: [ create_param("value", type: "String") ], return_type: "void")
          end
        end
      end
    end
  end
end
```

There are two main parts to the DSL compiler API: `gather_constants` and `decorate`:

* The `gather_constants` class method collects all classes (or modules) that should be processed by this specific DSL compiler.
* The `decorate` method defines how to generate the necessary RBI definitions for the gathered constants.

You can now run the new RBI compiler through the normal DSL generation process (your custom compiler will be loaded automatically by Tapioca):

```shell
$ bin/tapioca dsl

Loading Rails application... Done
Loading DSL compiler classes... Done
Compiling DSL RBI files...

      create  sorbet/rbi/dsl/credit_card.rbi

Done
```

And then run Sorbet without error:

```shell
$ bundle exec srb tc

No errors! Great job.
```

For more concrete and advanced examples, take a look at [Tapioca's default DSL compilers](https://github.com/Shopify/tapioca/tree/main/lib/tapioca/dsl/compilers).

### RBI files for missing constants and methods

Even after generating the RBIs, it is possible that some constants or methods are still undefined for Sorbet.

This might be for multiple reasons, with the most frequents ones being:

* The constant or method comes from a part of the gem that Tapioca cannot load (optional dependency, wrong architecture, etc.)
* The constant or method comes from a DSL or meta-programming that Tapioca doesn't support yet
* The constant or method only exists when a specific code path is executed

The best way to deal with such occurrences is to manually create RBI files (shims) for them so you can also add types but depending on the amount of meta-programming used in your project this can mean an overwhelming amount of manual work.

#### Generating the RBI file for missing constants

To get you started quickly, Tapioca can create a RBI file containing a stub of all the missing constants so you can typecheck your project without missing constants and shim them later as you need them.

To generate the RBI file for the missing constants used in your application run the following command:

```sh
$ bin/tapioca todo

Compiling sorbet/rbi/todo.rbi, this may take a few seconds... Done
All unresolved constants have been written to sorbet/rbi/todo.rbi.
Please review changes and commit them.
```

This will generate the file `sorbet/rbi/todo.rbi` defining all unresolved constants as empty modules. Since the constants are "missing", Tapioca does not know if they should be marked as modules or classes and will use modules as a safer default. This file should be reviewed, corrected, if necessary, and then committed in your repository.

<!-- START_HELP_COMMAND_TODO -->
```shell
$ tapioca help todo

Usage:
  tapioca todo

Options:
      [--todo-file=TODO_FILE]              # Path to the generated todo RBI file
                                           # Default: sorbet/rbi/todo.rbi
      [--file-header], [--no-file-header]  # Add a "This file is generated" header on top of each generated RBI file
                                           # Default: true
  -c, [--config=<config file path>]        # Path to the Tapioca configuration file
                                           # Default: sorbet/tapioca/config.yml
  -V, [--verbose], [--no-verbose]          # Verbose output for debugging purposes

generate the list of unresolved constants
```
<!-- END_HELP_COMMAND_TODO -->

#### Manually writing RBI definitions (shims)

A _shim_ is a hand-crafted RBI file that tells Sorbet about constants, ancestors, methods, etc. that it can't understand statically and aren't already generated by Tapioca.

These shims are usually placed in the `sorbet/rbi/shims` directory. From there, conventionally, you should follow the directory structure of the project to the file you'd like to shim. For example, say you had a `person.rb` file found at `app/models/person.rb`. If you were to add a shim for it, you'd want to create your RBI file at `sorbet/rbi/shims/app/models/person.rbi`.

A shim might be as simple as the class definition with an empty method body as below:

```ruby
# typed: true

class Person
  sig { void }
  def some_method_sorbet_cannot_find; end
end
```

As you migrate to newer versions of Sorbet or Tapioca, some shims may become useless as Sorbet's internal definitions for Ruby's core and standard library is enhanced or Tapioca is able to generate definitions for new DSLs. To avoid keeping outdated or useless definitions inside your application shims, Tapioca provides the `check-shims` command:

```sh
$ bin/tapioca check-shims

Loading Sorbet payload...  Done
Loading shim RBIs from sorbet/rbi/shims...  Done
Loading gem RBIs from sorbet/rbi/gems...  Done
Loading gem RBIs from sorbet/rbi/dsl...  Done
Looking for duplicates...  Done

Duplicated RBI for ::MyModel#title:
  * sorbet/rbi/shims/my_model.rbi:2:2-2:14
  * sorbet/rbi/dsl/my_model.rbi:2:2-2:14

Duplicated RBI for ::String#capitalize:
  * https://github.com/sorbet/sorbet/tree/master/rbi/core/string.rbi#L406
  * sorbet/rbi/shims/core/string.rbi:3:2-3:23

Please remove the duplicated definitions from the sorbet/rbi/shims directory.
```

This command can be used on CI to make sure the RBI shims are always up-to-date and non-redundant with generated files.

<!-- START_HELP_COMMAND_CHECK_SHIMS -->
```shell
$ tapioca help check_shims

Usage:
  tapioca check-shims

Options:
      [--gem-rbi-dir=GEM_RBI_DIR]    # Path to gem RBIs
                                     # Default: sorbet/rbi/gems
      [--dsl-rbi-dir=DSL_RBI_DIR]    # Path to DSL RBIs
                                     # Default: sorbet/rbi/dsl
      [--shim-rbi-dir=SHIM_RBI_DIR]  # Path to shim RBIs
                                     # Default: sorbet/rbi/shims
      [--payload], [--no-payload]    # Check shims against Sorbet's payload
                                     # Default: true
  -c, [--config=<config file path>]  # Path to the Tapioca configuration file
                                     # Default: sorbet/tapioca/config.yml
  -V, [--verbose], [--no-verbose]    # Verbose output for debugging purposes

check duplicated definitions in shim RBIs
```
<!-- END_HELP_COMMAND_CHECK_SHIMS -->

### Configuration

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
  doc: true
  exported_gem_rbis: true
  workers: 1
  auto_strictness: true
  dsl_dir: sorbet/rbi/dsl
  rbi_max_line_length: 120
check_shims:
  gem_rbi_dir: sorbet/rbi/gems
  dsl_rbi_dir: sorbet/rbi/dsl
  shim_rbi_dir: sorbet/rbi/shims
  payload: true
annotations:
  repo_uri: https://raw.githubusercontent.com/Shopify/rbi-central/main
```
<!-- END_CONFIG_TEMPLATE -->

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/tapioca. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](https://github.com/Shopify/tapioca/blob/main/CODE_OF_CONDUCT.md) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/Shopify/tapioca/blob/main/LICENSE.txt).
