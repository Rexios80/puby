## 1.14.1
- Handle empty pubspec files
- Only use FVM if it is installed

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
