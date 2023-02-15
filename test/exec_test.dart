import 'dart:io';

import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('puby exec', () async {
    final result = await testCommand(['exec', 'echo', 'foo']);
    final stdout = result.stdout;

    expect(result.exitCode, 0);
    // dart
    expectLine(stdout, [
      'dart_puby_test',
      '"echo foo"',
    ]);
    expectLine(stdout, [
      'dart_puby_test${Platform.pathSeparator}example',
      '"echo foo"',
    ]);

    // flutter
    expectLine(stdout, [
      'flutter_puby_test',
      '"echo foo"',
    ]);
    expectLine(stdout, [
      'flutter_puby_test${Platform.pathSeparator}example',
      '"echo foo"',
    ]);

    // fvm
    expectLine(stdout, [
      'fvm_puby_test',
      '"echo foo"',
    ]);
    expectLine(stdout, [
      'fvm_puby_test${Platform.pathSeparator}example',
      '"echo foo"',
    ]);
  });
}
