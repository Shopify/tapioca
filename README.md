# Tapioca

[![Build Status](https://travis-ci.org/Shopify/tapioca.svg?branch=master)](https://travis-ci.org/Shopify/tapioca)

Tapioca is a library used to generate RBI (Ruby interface) files for use with [Sorbet](https://sorbet.org). RBI files provide the structure (classes, modules, methods, parameters) of the gem/library to Sorbet to assist with typechecking.

As yet, no gem exports type information in a consumable format and it would be a huge effort to manually maintain such an interface file for all the gems that your codebase depends on. Thus, there is a need for an automated way to generate the appropriate RBI file for a given gem. The `tapioca` gem, developed at Shopify, is able to do exactly that to almost 99% accuracy. It can generate the definitions for all statically defined types and most of the runtime defined types exported from Ruby gems (non-Ruby gems are not handled yet).

When you run `tapioca sync` in a project, `tapioca` loads all the gems that are in your dependency list from the Gemfile into memory. It then performs runtime introspection on the loaded types to understand their structure and generates an appropriate RBI file for each gem with a versioned filename.

## Manual gem requires

For gems that have a normal default `require` and load all of their constants through such a require, everything works seamlessly. However, for gems that are marked as `require: false` in the Gemfile, or for gems that export optionally loaded types via different requires, where a single require does not load the whole gem code into memory, `tapioca` will not be able to load some of the types into memory and, thus, won't be able to generate complete RBIs for them. For this reason, we need to keep a small external file named `sorbet/tapioca/require.rb` that is executed after all the gems in the Gemfile have been required and before generation of gem RBIs have started. This file is responsible for adding the requires for additional files from gems, which are not covered by the default require.

For example, suppose you are using the class `BetterHtml::Parser` exported from the `better_html` gem. Just doing a `require "better_html"` (which is the default require) does not load that type:

```ruby
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

If you ever run into a case, where you add a gem or update the version of a gem and run `tapioca sync` but don't have some types you expect in the generated gem RBI files, you will need to make sure you have added the necessary requires to the `sorbet/tapioca/require.rb` file.

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
$ bundle exec tapioca
Commands:
  tapioca generate [gem...]  # generate RBIs from gems
  tapioca help [COMMAND]     # Describe available commands or one specific command
  tapioca init               # initializes folder structure
  tapioca require            # generate the list of files to be required by tapioca
  tapioca sync               # sync RBIs to Gemfile
  tapioca todo               # generate the list of unresolved constants

Options:
  --pre, -b, [--prerequire=file]              # A file to be required before Bundler.require is called
  --post, -a, [--postrequire=file]            # A file to be required after Bundler.require is called
  --out, -o, [--outdir=directory]             # The output directory for generated RBI files
                                              # Default: sorbet/rbi/gems
  --cmd, -c, [--generate-command=command]     # The command to run to regenerate RBI files
  --typed, -t, [--typed-overrides=gem:level]  # Overrides for typed sigils for generated gem RBIs
```

## Usage

### Initialize folder structure

Command: `tapioca init`

This will create the `sorbet/config` and `sorbet/tapioca/require.rb` files for you, if they don't exist. If any of the files already exist, they will not be changed.

### Generate for gems

Command: `tapioca generate [gems...]`

This will generate RBIs for the specified gems and place them in the RBI directory.

### Generate for all gems in Gemfile

Command: `tapioca sync`

This will sync the RBIs with the gems in the Gemfile and will add, update, and remove RBIs as necessary.

### Generate the list of all unresolved constants

Command: `tapioca todo`

This will generate the file `sorbet/rbi/todo.rbi` defining all unresolved constants as empty modules.

### Generate DSL RBI files

Command: `tapioca dsl [constant...]`

This will generate DSL RBIs for specified constants (or for all handled constants, if a constant name is not supplied). You can read about DSL RBI generators supplied by `tapioca` in [the manual](manual/generators.md).

### Flags

- `--prerequire [file]`: A file to be required before `Bundler.require` is called.
- `--postrequire [file]`: A file to be required after `Bundler.require` is called.
- `--out [directory]`: The output directory for generated RBI files, default to `sorbet/rbi/gems`.
- `--generate-command [command]`: The command to run to regenerate RBI files (used in header comment of the RBI files), defaults to the current command.
- `--typed-overrides [gem:level]`: Overrides typed sigils for generated gem RBIs for gem `gem` to level `level` (`level` can be one of `ignore`, `false`, `true`, `strict`, or `strong`, see [the Sorbet docs](https://sorbet.org/docs/static#file-level-granularity-strictness-levels) for more details).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/tapioca. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](https://github.com/Shopify/tapioca/blob/master/CODE_OF_CONDUCT.md) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/Shopify/tapioca/blob/master/LICENSE.txt).
