> :warning: **Note**: This software is currently under active development. The API and interface should be considered unstable until a v1.0.0 release.

# Tapioca

![Build Status](https://github.com/Shopify/tapioca/workflows/CI/badge.svg)

Tapioca is a library used to generate RBI (Ruby interface) files for use with [Sorbet](https://sorbet.org). RBI files provide the structure (classes, modules, methods, parameters) of the gem/library to Sorbet to assist with typechecking.

### Why use Tapioca?

As yet, no gem exports type information in a consumable format and it would be a huge effort to manually maintain such an interface file for all the gems that your codebase depends on. Thus, there is a need for an automated way to generate the appropriate RBI file for a given gem. The `tapioca` gem, developed at Shopify, is able to do exactly that to almost 99% accuracy. It can generate the definitions for all statically defined types and most of the runtime defined types exported from Ruby gems (non-Ruby gems are not handled yet).

When you run `tapioca sync` in a project, `tapioca` loads all the gems that are in your dependency list from the Gemfile into memory. It then performs runtime introspection on the loaded types to understand their structure and generates an appropriate RBI file for each gem with a versioned filename.

Tapioca helps simplify your setup too. Gems such as `sorbet-typed`, `sorbet-rails` are ways to provide accurate typing information for DSLs and gems. However, Tapioca aims to provide the complete tooling to generating RBIs for gems and DSLs, and does not require being combined with other gems, such as `sorbet-rails`, which can be removed from your gemfile.


## Installing Tapioca in a project with no existing RBI files (i.e. a fresh Sorbet project)

### Add Tapioca to your application's `Gemfile`

```ruby
group :development do
  gem 'tapioca', require: false
end
```
and run `bundle install`

### Initialize the folder structure

Command: `tapioca init`

This will create the `sorbet/config` and `sorbet/tapioca/require.rb` files for you, if they don't exist. If any of the files already exist, they will not be changed.

### Generate gems RBIs

Command: `tapioca gem [gem...]`

This will generate RBIs for the specified gems and place them in the RBI directory.

or:

Command: `tapioca gem`

This will sync the RBIs with the gems in the Gemfile and will add, update, and remove RBIs as necessary.

### Generate the list of all unresolved constants

Command: `tapioca todo`

This will generate the file `sorbet/rbi/todo.rbi` defining all unresolved constants as empty modules.

### Generate DSL RBI files

Command: `tapioca dsl [constant...]`

This will generate DSL RBIs for specified constants (or for all handled constants, if a constant name is not supplied). You can read about DSL RBI generators supplied by `tapioca` in [the manual](manual/generators.md).

## Installing Tapioca into a project that already uses Sorbet (and has RBI files)

The RBI files that Tapioca generates **should not be added** on top of those that Sorbet has already generated for you. Tapioca needs to run afresh. Tapioca also supercedes the need for gems like `sorbet-rails` or `sorbet-typed`. In order to start using Tapioca you will need to remove these gems and regenerate all of your automatically generated RBI files. 

### 1. Remove current RBIs

Tapioca does not require other solutions to work. Therefore all gem and DSL RBIs should be generated with it and not an alternative solution. The easiest way to adapt is to start over by removing the entire `sorbet/rbi` folder.

**Note**: if your application has shims (hand written RBI files), keep them saved somewhere in case you need to restore some of them. Chances are, less shims will be needed after transitioning to Tapioca.

Additionally, don't forget to keep your `sorbet/config` file too.

If the previously used alternatives had their own configuration files, remove them as well.

### 2. Remove other solutions

As mentioned, Tapioca is meant to be used on its own. Remove `sorbet-rails` or other such alternative solutions from the `Gemfile`.

### 3. Add Tapioca

```rb
group :development do
  gem "tapioca"
end
```
and run `bundle install`

### 4. Run Tapioca init

Re-initialize the `sorbet` folder structure with `bundle exec tapioca init`. You still need to run this step if you kept the shims around.

### 5. Run Tapioca generate

This step is the iterative process to generate the RBIs necessary for your application's gems. This part may vary depending on your setup.

1. Run `bin/tapioca gem`. This generates RBIs for the gems in your application
2. Try to run the type checker (`bundle exec srb tc`)
3. If you notice that definitions are missing for gems, you might need to add the gem for which those definitions belong to in `sorbet/tapioca/require.rb`. Before manually adding requires, try running `bin/tapioca require` so that Tapioca can figure out the requires. If this still does not work, proceed to write manual requires
4. After requiring the gems inside that file, go back to 1. until there are no more errors coming from gems

### 6. Run Tapioca DSL

With all the gem RBIs in place, now Tapioca can generate DSL RBIs. DSL RBIs are definitions that only exist in runtime. For example,
```rb
class Post < ApplicationRecord
  # Belongs to will create a few methods in this class
  # to be able to access the associated author. Sorbet
  # does not know about them, since they only exist during
  # runtime. Tapioca can generate the definitions in RBIs
  # for methods like this one.
  belongs_to :author
end
```
Run `bin/tapioca dsl` to generate the runtime definitions for your application.

While going through steps 5. and 6., you might realize that some shims have become obsolete or incorrect. Make sure to edit or remove existing shims that are causing errors.

### 7. Run Tapioca todo

After steps 5. and 6., if there are still errors for missing definitions, you may want to try bringing back the shims you saved for later.

If the previous shims do not satisfy all errors, you can also skip fixing them for later with the todo command. Running `bin/tapioca todo` will generate a file with empty definitions, and allows developers to track which definitions are still missing. This is optional, you might want to actually write the complete signatures in shims.

### 8. Bump strictness on files

After all the RBIs are generated and no type errors are occurring, some files might actually be ready to move from `typed: false` to `typed: true`. [Spoom](https://github.com/Shopify/spoom) can automatically bump files to `true` if doing so produces no new typing errors.

To bump all possible files to `true`, simply run `bundle exec spoom bump`.

### Things that do not need to happen

Here are some things that do not need to be run for the migration (or ever in some cases).

1. `bin/tapioca sync`: this command is meant to be used **after** the initial setup is complete to update RBIs for gems that have been upgraded. It does not need to be used as part of the migration process, but should be used later
2. `bundle exec srb rbi hidden-definitions`: not necessary at all, ever
3. `bundle exec srb rbi suggest-typed`: not necessary at all, ever. Prefer `bundle exec spoom bump`

Done! Your application should be all set and type checking should pass.

## How does tapioca compare to "srb rbi gems" ?

[Please see the detailed answer on our wiki](https://github.com/Shopify/tapioca/wiki/How-does-tapioca-compare-to-%22srb-rbi-gems%22-%3F)


## Tapioca commands

Do not forget to execute `tapioca` using `bundler`:

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


### Flags

- `--prerequire [file]`: A file to be required before `Bundler.require` is called.
- `--postrequire [file]`: A file to be required after `Bundler.require` is called.
- `--out [directory]`: The output directory for generated RBI files, default to `sorbet/rbi/gems`.
- `--generate-command [command]`: **[DEPRECATED]** The command to run to regenerate RBI files (used in header comment of the RBI files), defaults to the current command.
- `--typed-overrides [gem:level]`: Overrides typed sigils for generated gem RBIs for gem `gem` to level `level` (`level` can be one of `ignore`, `false`, `true`, `strict`, or `strong`, see [the Sorbet docs](https://sorbet.org/docs/static#file-level-granularity-strictness-levels) for more details).


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

If you ever run into a case, where you add a gem or update the version of a gem and run `tapioca sync` but don't have some types you expect in the generated gem RBI files, you will need to make sure you have added the necessary requires to the `sorbet/tapioca/require.rb` file.

You can use the command `tapioca require` to auto-populate the `sorbet/tapioca/require.rb` file with all the requires found
in your application. Once the file generated, you should review it, remove all unnecessary requires and commit it.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/tapioca. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](https://github.com/Shopify/tapioca/blob/main/CODE_OF_CONDUCT.md) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/Shopify/tapioca/blob/main/LICENSE.txt).
