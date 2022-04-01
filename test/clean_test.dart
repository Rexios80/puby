import 'dart:io';

import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('[engine] clean', () async {
    final result = await testCommand(['clean']);
    final stdout = result.stdout;

    expect(result.exitCode, 0);

    // dart
    // Clean does not run in dart projects
    expectLine(stdout, ['dart_puby_test', 'Skip']);
    expectLine(
      stdout,
      ['dart_puby_test${Platform.pathSeparator}example', 'Skip'],
    );

    // flutter
    expectLine(stdout, ['flutter_puby_test', 'flutter clean']);
    expectLine(stdout, [
      'flutter_puby_test${Platform.pathSeparator}example',
      'flutter clean',
    ]);

    // fvm
    expectLine(stdout, ['fvm_puby_test', 'fvm flutter clean']);
    expectLine(stdout, [
      'fvm_puby_test${Platform.pathSeparator}example',
      'fvm flutter clean',
    ]);
  });
}
