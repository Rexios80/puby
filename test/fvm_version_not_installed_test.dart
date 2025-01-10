import 'package:io/io.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('FVM version not installed', () {
    test('SDK Version', () async {
      final result = await testCommand(
        ['get'],
        entities: {
          'fvm_version_not_installed_test': {
            'pubspec.yaml': pubspec('fvm_version_not_installed_test'),
            '.fvmrc': fvmrc('1.17.0'),
          },
        },
      );
      final stdout = result.stdout;

      expect(result.exitCode, isNot(ExitCode.success.code));
      expectLine(stdout, ['Run `fvm install 1.17.0` first']);
    });

    test('Channel', () async {
      final result = await testCommand(
        ['get'],
        entities: {
          'fvm_version_not_installed_test': {
            'pubspec.yaml': pubspec('fvm_version_not_installed_test'),
            '.fvmrc': fvmrc('stable'),
          },
        },
      );
      final stdout = result.stdout;

      expect(result.exitCode, isNot(ExitCode.success.code));
      expectLine(stdout, ['Run `fvm install stable` first']);
    });
  });
}
