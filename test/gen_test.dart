import 'dart:io';

import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('[engine] gen', () async {
    final result = await testCommand(['gen']);
    final stdout = result.stdout;

    // Since these projects have no code generation, the command should fail
    expect(result.exitCode, isNot(0));

    // dart
    expectLine(stdout, [
      'dart_puby_test',
      'dart pub run build_runner build --delete-conflicting-outputs',
    ]);
    // Explicit exclusion
    expectLine(
      stdout,
      ['dart_puby_test${Platform.pathSeparator}example', 'Skip'],
    );

    // flutter
    expectLine(stdout, [
      'flutter_puby_test',
      'flutter pub run build_runner build --delete-conflicting-outputs',
    ]);
    // Explicit exclusion
    expectLine(
      stdout,
      ['flutter_puby_test${Platform.pathSeparator}example', 'Skip'],
    );

    // fvm
    expectLine(stdout, [
      'fvm_puby_test',
      'fvm flutter pub run build_runner build --delete-conflicting-outputs',
    ]);
    // Explicit exclusion
    expectLine(
      stdout,
      ['fvm_puby_test${Platform.pathSeparator}example', 'Skip'],
    );
  });
}
