import 'dart:io';

import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('[engine] test', () async {
    final result = await testCommand(['test', '--coverage']);
    final stdout = result.stdout;

    expectLine(stdout, ['dart_puby_test', 'dart test --coverage']);
    expectLine(stdout, ['flutter_puby_test', 'flutter test --coverage']);
    // TODO: Add the ability to skip certain commands for certain projects
    expectLine(stdout, [
      'flutter_puby_test${Platform.pathSeparator}example',
      'flutter test --coverage',
    ]);
    // TODO: fvm
  });
}
