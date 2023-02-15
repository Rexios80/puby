Run commands in all projects in the current directory. Handle monorepos with ease.

## Features
- No configuration necessary. Run `puby` anywhere. It won't complain.
- Supports all project-level pub commands
- Execute any command in all projects with `puby exec`
- Determines the project engine (`dart`, `flutter`, `fvm`) automatically
- Convenience shortcuts for common dart/flutter commands
- Combined exit code for use in CI
- Per-project command exclusions

| Command                | Equivalent                                                                   |
| ---------------------- | ---------------------------------------------------------------------------- |
| `puby [options]`       | `[engine] pub [options]`                                                     |
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

| Exclusion              | Example command excluded                     |
| ---------------------- | -------------------------------------------- |
| `test`                 | `[engine] test --coverage`            |
| `pub run build_runner` | `[engine] pub run build_runner build` |