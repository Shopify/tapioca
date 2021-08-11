> :warning: **Note**: This software is currently under active development. The API and interface should be considered unstable until a v1.0.0 release.

# Tapioca

![Build Status](https://github.com/Shopify/tapioca/workflows/CI/badge.svg)

Tapioca is a library used to generate RBI (Ruby interface) files for use with [Sorbet](https://sorbet.org). RBI files provide the structure (classes, modules, methods, parameters) of the gem/library to Sorbet to assist with typechecking.

As yet, no gem exports type information in a consumable format and it would be a huge effort to manually maintain such an interface file for all the gems that your codebase depends on. Thus, there is a need for an automated way to generate the appropriate RBI file for a given gem. The `tapioca` gem, developed at Shopify, is able to do exactly that to almost 99% accuracy. It can generate the definitions for all statically defined types and most of the runtime defined types exported from Ruby gems (non-Ruby gems are not handled yet).

When you run `tapioca sync` in a project, `tapioca` loads all the gems that are in your dependency list from the Gemfile into memory. It then performs runtime introspection on the loaded types to understand their structure and generates an appropriate RBI file for each gem with a versioned filename.

## Manual gem requires

See "[Manual Gem Requires](https://github.com/Shopify/tapioca/wiki/Manual-Gem-Requires)" in our wiki for more information.

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
  tapioca --version, -v      # show version
  tapioca dsl [constant...]  # generate RBIs for dynamic methods
  tapioca generate [gem...]  # generate RBIs from gems
  tapioca help [COMMAND]     # Describe available commands or one specific command
  tapioca init               # initializes folder structure
  tapioca require            # generate the list of files to be required by tapioca
  tapioca sync               # sync RBIs to Gemfile
  tapioca todo               # generate the list of unresolved constants

Options:
  --pre, -b, [--prerequire=file]                              # A file to be required before Bundler.require is called
  --post, -a, [--postrequire=file]                            # A file to be required after Bundler.require is called
  --out, -o, [--outdir=directory]                             # The output directory for generated RBI files
  --cmd, -c, [--generate-command=command]                     # The command to run to regenerate RBI files
  -x, [--exclude=gem [gem ...]]                               # Excludes the given gem(s) from RBI generation
  --typed, -t, [--typed-overrides=gem:level [gem:level ...]]  # Overrides for typed sigils for generated gem RBIs
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
- `--generate-command [command]`: **[DEPRECATED]** The command to run to regenerate RBI files (used in header comment of the RBI files), defaults to the current command.
- `--typed-overrides [gem:level]`: Overrides typed sigils for generated gem RBIs for gem `gem` to level `level` (`level` can be one of `ignore`, `false`, `true`, `strict`, or `strong`, see [the Sorbet docs](https://sorbet.org/docs/static#file-level-granularity-strictness-levels) for more details).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/tapioca. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](https://github.com/Shopify/tapioca/blob/main/CODE_OF_CONDUCT.md) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/Shopify/tapioca/blob/main/LICENSE.txt).
