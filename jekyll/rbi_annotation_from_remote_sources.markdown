---
layout: default
title: Pull RBI annotations from remote sources
parent: Tapioca
nav_order: 3
---

# Pulling RBI annotations from remote sources

Since Tapioca does not perform any type inference, the RBI files generated for the gems do not contain any type signatures. Instead, Tapioca relies on the community to provide high-quality, manually written RBI annotations for public gems.

To pull the annotations relevant to your project from the central repository, run the `annotations` command:

```shell
$ bin/tapioca annotations

Retrieving index from central repository... Done
Listing gems from Gemfile.lock... Done
Removing annotations for gems that have been removed...  Nothing to do
Fetching gem annotations from central repository...

  Fetched activesupport
   created  sorbet/rbi/annotations/activesupport.rbi

Done
```

<!-- START_HELP_COMMAND_ANNOTATIONS -->
```shell
$ tapioca help annotations

Usage:
  tapioca annotations

Options:
               [--sources=one two three]                      # URIs of the sources to pull gem RBI annotations from
                                                              # Default: "https://raw.githubusercontent.com/Shopify/rbi-central/main"
               [--netrc], [--no-netrc], [--skip-netrc]        # Use .netrc to authenticate to private sources
                                                              # Default: true
               [--netrc-file=NETRC_FILE]                      # Path to .netrc file
               [--auth=AUTH]                                  # HTTP authorization header for private sources
  --typed, -t, [--typed-overrides=gem:level [gem:level ...]]  # Override for typed sigils for pulled annotations
  -c,          [--config=<config file path>]                  # Path to the Tapioca configuration file
                                                              # Default: sorbet/tapioca/config.yml
  -V,          [--verbose], [--no-verbose], [--skip-verbose]  # Verbose output for debugging purposes
                                                              # Default: false

Pull gem RBI annotations from remote sources
```
<!-- END_HELP_COMMAND_ANNOTATIONS -->

By default, Tapioca will pull the annotations stored in the central repository located at https://github.com/Shopify/rbi-central. It is possible to use a custom repository by changing the value of the `--sources` options. For example if your repository is stored on Github:

```shell
$ bin/tapioca annotations --sources https://raw.githubusercontent.com/$USER/$REPO/$BRANCH
```

Tapioca also supports pulling annotations from multiple sources:

```shell
$ bin/tapioca annotations --sources https://raw.githubusercontent.com/$USER/$REPO1/$BRANCH https://raw.githubusercontent.com/$USER/$REPO2/$BRANCH
```

## Basic authentication

Private repositories can be used as sources by passing the option `--auth` with an authentication string. For Github, this string is `token $TOKEN` where `$TOKEN` is a [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token):

```shell
$ bin/tapioca annotations --sources https://raw.githubusercontent.com/$USER/$PRIVATE_REPO/$BRANCH --auth "token $TOKEN"
```

## Using a .netrc file

Tapioca supports reading credentials from a [netrc](https://www.gnu.org/software/inetutils/manual/html_node/The-_002enetrc-file.html) file (defaulting to `~/.netrc`).

Given these lines in your netrc:

```netrc
machine raw.githubusercontent.com
  login $USERNAME
  password $TOKEN
```

where `$USERNAME` is your Github username and `$TOKEN` is a [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token), then, if you run Tapioca with the `--netrc` option (enabled by default), your annotation requests should be authenticated properly.

The `--netrc-file` option can be specified to read from a file other than `~/.netrc`:

```shell
$ bin/tapioca annotations --netrc-file /path/to/my/netrc/file
```

Similar to `--netrc-file`, you can also specify an alternative netrc file by using the `TAPIOCA_NETRC_FILE` environment variable:

```shell
$ TAPIOCA_NETRC_FILE=/path/to/my/netrc/file bin/tapioca annotations
```

Tapioca will first try to find the netrc file as specified by the `--netrc-file` option. If that option is not supplied, it will try the `TAPIOCA_NETRC_FILE` environment variable value. If that value is not supplied either, it will fallback to `~/.netrc`.

## Changing the typed strictness of annotations files

Sometimes the annotations files pulled by Tapioca will create type errors in your project because of incompatibilities.
It is possible to ignore such files by switching their strictness level `--typed-overrides` option:

```shell
$ bin/tapioca annotations --typed-overrides gemA:ignore gemB:false
```

Or through the configuration file:

```yaml
annotations:
  typed_overrides:
    gemA: "ignore"
    gemB: "false"
```
