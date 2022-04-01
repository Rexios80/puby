import 'dart:io';

import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('[engine] clean', () async {
    final result = await testCommand(['gen']);
    final stdout = result.stdout;

    expectLine(stdout, [
      'dart_puby_test',
      'dart pub run build_runner build --delete-conflicting-outputs',
    ]);
    expectLine(stdout, [
      'flutter_puby_test',
      'flutter pub run build_runner build --delete-conflicting-outputs',
    ]);
    // TODO: Skip with skip project feature
    expectLine(stdout, [
      'flutter_puby_test${Platform.pathSeparator}example',
      'flutter pub run build_runner build --delete-conflicting-outputs',
    ]);
    // TODO: fvm
  });
}
