import 'dart:io';

import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('[engine] pub get', () async {
    final result = await testCommand(['get']);
    final stdout = result.stdout;

    expect(result.exitCode, 0);

    // dart
    expectLine(stdout, ['dart_puby_test', 'dart pub get']);
    expectLine(
      stdout,
      ['dart_puby_test${Platform.pathSeparator}example', 'dart pub get'],
    );

    // flutter
    expectLine(stdout, ['flutter_puby_test', 'flutter pub get']);
    // Skip flutter example projects
    expectLine(
      stdout,
      ['flutter_puby_test${Platform.pathSeparator}example', 'Skip'],
    );
    // Flutter pub get should run in the example project anyways
    expectLine(stdout, ['example', 'flutter pub get']);

    // fvm
    expectLine(stdout, ['fvm_puby_test', 'fvm flutter pub get']);
    // Skip flutter example projects
    expectLine(
      stdout,
      ['fvm_puby_test${Platform.pathSeparator}example', 'Skip'],
    );
    // Flutter pub get should run in the example project anyways
    // Can't test this with fvm since the output is the same as flutter
    // expectLine(stdout, ['example', 'fvm flutter pub get']);
  });
}
