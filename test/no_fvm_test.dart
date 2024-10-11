import 'dart:io';

import 'package:io/io.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import 'test_utils.dart';

const message = 'Project uses FVM, but FVM support is disabled';

void main() {
  test('--no-fvm', () async {
    final result = await testCommand(['get', '--no-fvm']);
    final stdout = result.stdout;

    expect(result.exitCode, ExitCode.success.code);
    expectLine(stdout, ['fvm_puby_test', message]);
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

    expect(result.exitCode, ExitCode.success.code);
    expectLine(stdout, ['fvm_puby_test', message]);
  });

  test('--no-fvm on link command', () async {
    final result = await testCommand(['link', '--no-fvm']);
    final stdout = result.stdout;

    expect(result.exitCode, ExitCode.success.code);
    expectLine(stdout, ['fvm_puby_test', message]);
    expectLine(stdout, [p.join('fvm_puby_test', 'example'), message]);
    expectLine(stdout, [p.join('fvm_puby_test', 'nested'), message]);
  });
}
