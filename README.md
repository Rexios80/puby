Run pub commands for all sub projects in the current directory recursively

## Features
- Supports all pub commands
- Determines if a project uses dart or flutter automatically
- Convenience shortcuts for common pub commands

| Command  | Equivalent                                                              |
| -------- | ----------------------------------------------------------------------- |
| puby gen | [dart\|flutter] pub run build_runner build --delete-conflicting-outputs |

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