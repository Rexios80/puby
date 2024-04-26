import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('puby link', () async {
    final result = await testCommand(['link']);
    final stdout = result.stdout;

    expect(result.exitCode, 0);

    // dart
    expectLine(stdout, ['dart_puby_test', 'Resolved dependencies for']);
    expectLine(stdout, ['dart_puby_test', 'dart pub get --offline']);
    expectLine(
      stdout,
      [p.join('dart_puby_test', 'example'), 'dart pub get --offline'],
    );

    // flutter
    expectLine(stdout, ['flutter_puby_test', 'Resolved dependencies for']);
    expectLine(stdout, ['flutter_puby_test', 'flutter pub get --offline']);

    // fvm
    expectLine(stdout, ['fvm_puby_test', 'Resolved dependencies for']);
    expectLine(stdout, ['fvm_puby_test', 'fvm flutter pub get --offline']);
    // Ensure the correct flutter version was used
    expect(
      File('test_resources/fvm_puby_test/.dart_tool/version')
          .readAsStringSync(),
      '3.10.0',
    );
  });
}
