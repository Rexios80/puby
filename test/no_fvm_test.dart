import 'dart:io';

import 'package:io/io.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

import 'test_utils.dart';

const message = 'Project uses FVM, but FVM support is disabled';

void main() {
  group('--no-fvm', () {
    test('on pub get', () async {
      final result = await testCommand(['get', '--no-fvm']);
      final stdout = result.stdout;

      expect(result.exitCode, ExitCode.success.code);
      expectLine(stdout, ['fvm_puby_test', message]);
      // Ensure the FVM Flutter version was not used
      expect(
        File(
          path.join(
            result.workingDirectory,
            'fvm_puby_test',
            '.dart_tool',
            'version',
          ),
        ).readAsStringSync(),
        isNot('3.10.0'),
      );
    });

    test('on convenience command', () async {
      final result = await testCommand(['mup', '--no-fvm']);
      final stdout = result.stdout;

      expect(result.exitCode, ExitCode.success.code);
      expectLine(stdout, ['fvm_puby_test', message]);
    });

    test('on link command', () async {
      final result = await testCommand(['link', '--no-fvm']);
      final stdout = result.stdout;

      expect(result.exitCode, ExitCode.success.code);
      expectLine(stdout, ['fvm_puby_test', message]);
      expectLine(stdout, [path.join('fvm_puby_test', 'example'), message]);
      expectLine(stdout, [path.join('fvm_puby_test', 'nested'), message]);
    });
  });
}
