import 'dart:io';

import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('--no-fvm', () async {
    final result = await testCommand(['get', '--no-fvm']);
    final stdout = result.stdout;

    expect(result.exitCode, 0);
    expectLine(
      stdout,
      ['fvm_puby_test', 'Project uses FVM, but FVM support is disabled'],
    );
    // Ensure the FVM Flutter version was not used
    expect(
      File('test_resources/fvm_puby_test/.dart_tool/version')
          .readAsStringSync(),
      isNot('3.10.0'),
    );
  });

  test('--no-fvm on convenience command', () async {
    final result = await testCommand(['mup', '--no-fvm']);
    final stdout = result.stdout;

    expect(result.exitCode, 0);
    expectLine(
      stdout,
      ['fvm_puby_test', 'Project uses FVM, but FVM support is disabled'],
    );
  });
}
