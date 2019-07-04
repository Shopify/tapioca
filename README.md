# Tapioca

[![Build Status](https://travis-ci.com/Shopify/tapioca.svg?token=AuiMGLmuYDrK2mb81pyq&branch=master)](https://travis-ci.com/Shopify/tapioca)

Tapioca is a library used to generate RBI (Ruby interface) files for use with [Sorbet](https://sorbet.org). RBI files provide the structure (classes, modules, methods, parameters) of the gem/library to Sorbet to assist with typechecking. 

## Installation

Add this line to your application's `Gemfile`:

```ruby
group :development do
  gem 'tapioca', '~> 0.1.2', require: false
end
```

and do not forget to execute `tapioca` using `bundler`:

```shell
$ bundle exec tapioca
Commands:
  tapioca bundle             # sync RBIs to Gemfile
  tapioca generate [gem...]  # generate RBIs from gems
  tapioca help [COMMAND]     # Describe available commands or one specific command

Options:
  --pre, -b, [--prerequire=file]              # A file to be required before Bundler.require is called
  --post, -a, [--postrequire=file]            # A file to be required after Bundler.require is called
  --out, -o, [--outdir=directory]             # The output directory for generated RBI files
                                              # Default: sorbet/rbi/gems
  --cmd, -c, [--generate-command=command]     # The command to run to regenerate RBI files
  --typed, -t, [--typed-overrides=gem:level]  # Overrides for typed sigils for generated gem RBIs
```

## Usage

### Generate for gems

Command: `tapioca generate [gems...]`

This will generate RBIs for the specified gems and place them in the RBI directory.

### Generate for all gems in Gemfile

Command: `tapioca bundle`

This will sync the RBIs with the gems in the Gemfile and will add, update, and remove RBIs as necessary.

### Flags

- `--prerequire [file]`: A file to be required before `Bundler.require` is called.
- `--postrequire [file]`: A file to be required after `Bundler.require` is called.
- `--out [directory]`: The output directory for generated RBI files, default to `sorbet/rbi/gems`.
- `--generate_command [command]`: The command to run to regenerate RBI files (used in header comment of the RBI files), defaults to the current command.
- `--typed_overrides [gem:level]`: Overrides typed sigils for generated gem RBIs for gem `gem` to level `level` (`level` can be one of `ignore`, `false`, `true`, `strict`, or `strong`, see [the Sorbet docs](https://sorbet.org/docs/static#file-level-granularity-strictness-levels) for more details).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/tapioca. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
