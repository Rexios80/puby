Run commands in all projects in the current directory. Handle monorepos with ease.

## Features
- No configuration necessary. Run `puby` anywhere. It won't complain.
- Execute `pub get` up to five times faster with `puby link`
- Supports all project-level pub commands
- Execute any command in all projects with `puby exec`
- Determines the project engine (`dart`, `flutter`, `fvm`) automatically
- Convenience shortcuts for common dart/flutter commands
- Combined exit code for use in CI
- Per-project command exclusions

| Command                | Equivalent                                                                   |
| ---------------------- | ---------------------------------------------------------------------------- |
| `puby [options]`       | `[engine] pub [options]`                                                     |
| `puby link`            | Warm the pub cache and run `[engine] pub get --offline` (see below)          |
| `puby gen [options]`   | `[engine] pub run build_runner build --delete-conflicting-outputs [options]` |
| `puby test [options]`  | `[engine] test [options]`                                                    |
| `puby clean [options]` | `flutter clean [options]`                                                    |
| `puby mup [options]`   | `[engine] pub upgrade --major-versions [options]`                            |
| `puby reset`           | `puby clean && puby get`                                                     |
| `puby exec [command]`  | `command`                                                                    |

For projects configured with FVM, `fvm flutter` is used. FVM support can be disabled with the `--no-fvm` option.

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

The `pubspec.lock` file is used to catalog the required dependencies, so for this command to run successfully you must check in your `pubspec.lock` files to version control.

The `puby link` command can run up to _five times faster_ than `puby get`, so it is very useful for large mono-repos.

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
  - pub run build_runner
```

Exclusions match from the start of a command, and the entire exclusion string must be present. Here are some examples:

| Exclusion              | Example command excluded              |
| ---------------------- | ------------------------------------- |
| `test`                 | `[engine] test --coverage`            |
| `pub run build_runner` | `[engine] pub run build_runner build` |