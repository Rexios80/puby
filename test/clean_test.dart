import 'dart:io';

import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('[engine] clean', () async {
    final result = await testCommand('dart', ['../bin/puby.dart', 'clean']);
    final stdout = result.stdout;

    // Clean does not run in dart projects
    expectLine(stdout, ['dart_puby_test', 'Skip']);
    expectLine(stdout, ['flutter_puby_test', 'flutter clean']);
    expectLine(stdout, [
      'flutter_puby_test${Platform.pathSeparator}example',
      'flutter clean',
    ]);
    // TODO: fvm
  });
}
