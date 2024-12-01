import 'package:io/io.dart';
import 'package:test/test.dart';

import 'test_utils.dart';
import 'package:path/path.dart' as path;

void main() {
  group('config', () {
    test('exclude', () async {
      final result = await testCommand(
        ['gen'],
        projects: {
          'puby_yaml_test': {
            'pubspec.yaml': pubspec(
              'puby_yaml_test',
              devDependencies: {'build_runner: any'},
            ),
            'puby.yaml': '''
exclude:
  - pub run build_runner
''',
          },
        },
      );
      final stdout = result.stdout;

      // Since the code generation doesn't actually run the command should succeed
      expect(result.exitCode, ExitCode.success.code);

      expectLine(stdout, [path.join('puby_yaml_test'), 'Skip']);
    });
  });
}
