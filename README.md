Run pub commands for all sub projects in the current directory recursively

## Features
- Supports all project-level pub commands
- Determines if a project uses dart or flutter automatically
- FVM support
- Convenience shortcuts for common dart/flutter commands
- Combined exit code for use in CI
- Per-project command exclusions

| Command                | Equivalent                                                                          |
| ---------------------- | ----------------------------------------------------------------------------------- |
| `puby [options]`       | `[dart\|flutter] pub [options]`                                                     |
| `puby gen [options]`   | `[dart\|flutter] pub run build_runner build --delete-conflicting-outputs [options]` |
| `puby test [options]`  | `[dart\|flutter] test [options]`                                                    |
| `puby clean [options]` | `flutter clean [options]` (only runs in flutter projects)                           |

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
| `test`                 | `[dart\|flutter] test --coverage`            |
| `pub run build_runner` | `[dart\|flutter] pub run build_runner build` |