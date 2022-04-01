import 'dart:io';

import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('[engine] test', () async {
    final result = await testCommand(['test', '--coverage']);
    final stdout = result.stdout;

    // Since these projects have no tests, the command should fail
    expect(result.exitCode, isNot(0));

    // dart
    expectLine(stdout, ['dart_puby_test', 'dart test --coverage']);
    // TODO: Skip with skip project feature
    expectLine(stdout, [
      'dart_puby_test${Platform.pathSeparator}example',
      'dart test --coverage',
    ]);

    // flutter
    expectLine(stdout, ['flutter_puby_test', 'flutter test --coverage']);
    // TODO: Skip with skip project feature
    expectLine(stdout, [
      'flutter_puby_test${Platform.pathSeparator}example',
      'flutter test --coverage',
    ]);
    
    // fvm
    expectLine(stdout, ['fvm_puby_test', 'fvm flutter test --coverage']);
    // TODO: Skip with skip project feature
    expectLine(stdout, [
      'fvm_puby_test${Platform.pathSeparator}example',
      'fvm flutter test --coverage',
    ]);
  });
}
