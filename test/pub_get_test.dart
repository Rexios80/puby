import 'dart:io';

import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('[engine] pub get', () async {
    final result = await testCommand(['get']);
    final stdout = result.stdout;

    expectLine(stdout, ['dart_puby_test', 'dart pub get']);
    expectLine(stdout, ['flutter_puby_test', 'flutter pub get']);
    // Skip flutter example projects
    expectLine(
      stdout,
      ['flutter_puby_test${Platform.pathSeparator}example', 'Skip'],
    );
    // Flutter pub get should run in the example project anyways
    expectLine(stdout, ['example', 'flutter pub get']);
    // TODO: fvm
  });
}
