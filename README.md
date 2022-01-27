Run pub commands for all sub projects in the current directory recursively

## Features
- Supports all project-level pub commands
- Determines if a project uses dart or flutter automatically
- Convenience shortcuts for common dart/flutter commands
- Combined exit code for use in CI

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