import 'dart:io';

import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test(
    '[engine] mup',
    () async {
      final result = await testCommand(['mup']);
      final stdout = result.stdout;

      expect(result.exitCode, 0);

      // dart
      expectLine(stdout, [
        'dart_puby_test',
        '"dart pub upgrade --major-versions"',
      ]);
      expectLine(stdout, [
        'dart_puby_test${Platform.pathSeparator}example',
        '"dart pub upgrade --major-versions"',
      ]);

      // flutter
      expectLine(stdout, [
        'flutter_puby_test',
        '"flutter pub upgrade --major-versions"',
      ]);
      expectLine(stdout, [
        'flutter_puby_test${Platform.pathSeparator}example',
        '"flutter pub upgrade --major-versions"',
      ]);

      // fvm
      expectLine(stdout, [
        'fvm_puby_test',
        '"fvm flutter pub upgrade --major-versions"',
      ]);
      expectLine(stdout, [
        'fvm_puby_test${Platform.pathSeparator}example',
        '"fvm flutter pub upgrade --major-versions"',
      ]);
    },
    timeout: Timeout.factor(1.5),
  );
}
