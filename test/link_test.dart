import 'dart:io';

import 'package:io/io.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('puby link', () async {
    // A pub get must be done before link will work
    await testCommand(['get']);
    final result = await testCommand(['link']);
    final stdout = result.stdout;

    expect(result.exitCode, ExitCode.success.code);

    // dart
    expectLine(stdout, ['dart_puby_test', 'Resolved dependencies for']);
    expectLine(stdout, ['dart_puby_test', 'dart pub get --offline']);
    // The pub get should NOT run in the example app
    expectLine(
      stdout,
      [path.join('dart_puby_test', 'example'), 'dart pub get --offline'],
      matches: false,
    );

    // flutter
    expectLine(stdout, ['flutter_puby_test', 'Resolved dependencies for']);
    expectLine(stdout, ['flutter_puby_test', 'flutter pub get --offline']);
    // The link should run in the example app
    expectLine(
      stdout,
      [path.join('flutter_puby_test', 'example'), 'Resolved dependencies for'],
    );
    // The pub get should NOT run in the example app
    expectLine(
      stdout,
      [path.join('flutter_puby_test', 'example'), 'flutter pub get --offline'],
      matches: false,
    );

    // fvm
    expectLine(stdout, ['fvm_puby_test', 'Resolved dependencies for']);
    expectLine(stdout, ['fvm_puby_test', 'fvm flutter pub get --offline']);
    // Ensure the correct flutter version was used
    expect(
      File(
        path.join(
          result.workingDirectory,
          'fvm_puby_test',
          '.dart_tool',
          'version',
        ),
      ).readAsStringSync(),
      '3.10.0',
    );
  });
}
