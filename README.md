Run commands in all projects in the current directory. Handle monorepos with ease.

## Features

- No configuration necessary. Run `puby` anywhere. It won't complain.
- Execute `pub get` in seconds rather than minutes with `puby link`
- Reclaim disk space with `puby clean`
- Supports all project-level pub commands
- Execute any command in all projects with `puby exec`
- Determines the project engine (`dart`, `flutter`, `fvm`) automatically
- Convenience shortcuts for common dart/flutter commands
- Combined exit code for use in CI
- Per-project command exclusions

| Command               | Equivalent                                                 |
| --------------------- | ---------------------------------------------------------- |
| `puby [args]`         | `[engine] pub [args]`                                      |
| `puby link`           | Warm the pub cache and run `[engine] pub get --offline`    |
| `puby gen`            | `dart run build_runner build --delete-conflicting-outputs` |
| `puby run`            | `dart run`                                                 |
| `puby test`           | `[engine] test`                                            |
| `puby clean`          | `flutter clean`                                            |
| `puby mup`            | `[engine] pub upgrade --major-versions`                    |
| `puby reset`          | `puby clean && puby get`                                   |
| `puby relink`         | `puby clean && puby link`                                  |
| `puby exec [command]` | `command`                                                  |

For projects configured with FVM, `fvm flutter` and `fvm dart` are used. FVM support can be disabled with the `--no-fvm` option.

## Use as an executable

### Installation

```console
$ dart pub global activate puby
```

### Usage

```console
$ puby get
$ puby upgrade --major-versions
...
```

## Notes on `puby link`

This command is based on `flutter update-packages`. All of the dependencies required by all of the projects in the current directory are cataloged and cached if necessary, then `pub get --offline` can safely run in all the projects in parallel.

This command no longer requires existing `pubspec.lock` files to function and instead uses the same version resolution strategy from the `pub` command to catalog dependencies.

The `puby link` command can run _many times faster_ than `puby get`, so it is very useful for large mono-repos.

Benchmarks in the [flutter/packages](https://github.com/flutter/packages) repo:

| Command           | Duration |
| ----------------- | -------- |
| `puby get`        | 9:01.97  |
| `melos bootstrap` | 47.810   |
| `puby link`       | 25.881   |

Benchmark setup:

- M3 MacBook Pro
- Gigabit internet connection
- Run `puby clean && dart pub cache clean` before each run
- `melos bootstrap` is run with a [custom branch of flutter/packages](https://github.com/Rexios80/packages_flutter/tree/puby_benchmarking) with the required setup

## Notes on `puby gen` and `puby run`

Commands that map to `dart run [package]` will not run in projects that do not depend on the required package. For example, `puby gen` will skip projects that do not depend on `build_runner`. Transitive dependencies are included in this check, however a `pub get` must be run in the project at least once for the check to work.

## Notes on `puby exec`

Paths relative to the directory you are running `puby` in will not work. For example:

- `puby exec ./foo.sh` will not work
- `puby exec $PWD/foo.sh` will work

## Configuration

Create a `puby.yaml` file in the root of the project you want to configure

### Exclusions

Add command exclusions to prevent them from running in a project

```yaml
exclude:
  - test
  - run build_runner
```

Exclusions match from the start of a command, and the entire exclusion string must be present. Here are some examples:

| Exclusion          | Example command excluded      |
| ------------------ | ----------------------------- |
| `test`             | `[engine] test --coverage`    |
| `run build_runner` | `dart run build_runner build` |
