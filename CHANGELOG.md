## 1.31.0
- Display the packages as they are cached by `puby link`

## 1.30.0
- Fixes `--no-fvm` flag for convenience commands
- Uses `TaskQueue` from `flutter_tools_task_queue`

## 1.29.0
- Use `fvm` if `.fvm` configuration folder exists in any parent directory

## 1.28.0
- Run `puby clean` in parallel

## 1.27.1
- Adds `puby link` to help output

## 1.27.0
- Adds `puby link` to link all locked dependencies
- Only search for projects once
- Fixes platform path separator issues
- More informational timers

## 1.26.0
- Adds `puby exec` to run any command in all projects
- Fixes a race condition with command output

## 1.25.0
- Project-level error if FVM required flutter version is not installed

## 1.24.0
- Exit immediately if pub returns an unknown subcommand error

## 1.23.0
- Adds `puby reset` as an alias for `puby clean && puby get`

## 1.22.0
- Adds the ability to disable FVM support with the `--no-fvm` option

## 1.21.0
- `puby mup` now only runs `pub upgrade --major-versions`
  - > Fix a bug in dart pub upgrade --major-versions where packages not requiring major updates would be held back unless needed.
  - https://github.com/dart-lang/sdk/blob/main/CHANGELOG.md#pub
- Updates minimum Dart SDK to 2.19.0

## 1.20.0
- Retry with `flutter` engine if `dart` command fails with 'Flutter users should run `flutter pub get` instead of `dart pub get`.'

## 1.19.0
- Adds `puby mup` convenience command for `puby upgrade --major-versions && puby upgrade`

## 1.18.0
- Run `flutter clean` in dart projects

## 1.17.0
- Prints failed projects to the console

## 1.16.1
- Fixed typo

## 1.16.0
- Commands no longer run in build folders
- Uses pubspec_parse package for pubspec parsing

## 1.15.0
- Show elapsed time after command completion

## 1.14.1
- Handle empty pubspec files

## 1.14.0
- Exit if there are no projects found in the current directory

## 1.13.1
- Fixed readme layout

## 1.13.0
- FVM support
- Config file to allow per-project command exclusions
- Added tests

## 1.12.2
- Updated pub_update_checker

## 1.12.1
- Print the update text in yellow

## 1.12.0
- Added update checking

## 1.11.0
- Fixed flutter example project skipping if example folder is in current directory

## 1.10.0
- Skip projects in hidden folders
- Colored outputs

## 1.9.1
- Fixed skipping flutter example projects on Windows

## 1.9.0
- Fixed running on Windows

## 1.8.0
- Don't skip a Flutter example project if it is the only project found

## 1.7.0
- Added more useful help text

## 1.6.0
- Fixed issue with unicode characters in output

## 1.5.0
- Combined exit code for use in CI

## 1.4.0
- Added `puby test` and `puby clean`
- Use relative paths

## 1.3.0
- Added `puby gen` shortcut for `[dart|flutter] pub run build_runner build --delete-conflicting-outputs`

## 1.2.3
- Fixed crash with no dependencies listed in pubspec

## 1.2.2
- Print process output in real time

## 1.2.1
- Updated flutter detection

## 1.2.0
- Don't search symlinks for pubspec files

## 1.1.2
- Exit with message if no arguments are passed

## 1.1.1
- Updated readme

## 1.1.0
- Determine if a project uses dart or flutter automatically
- Skip flutter pub get for flutter example projects

## 1.0.0
- Initial version
