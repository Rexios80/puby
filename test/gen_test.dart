import 'package:io/io.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

import 'test_utils.dart';

const argString = 'run build_runner build --delete-conflicting-outputs';

void main() {
  test(
    'puby gen',
    () async {
      final result = await testCommand(
        ['gen'],
        entities: defaultProjects(devDependencies: {'build_runner: any'}),
        link: true,
      );
      final stdout = result.stdout;

      expect(result.exitCode, ExitCode.success.code);

      expectLine(stdout, ['dart_puby_test', 'dart $argString']);
      expectLine(stdout, [path.join('dart_puby_test', 'example'), 'Skip']);
      expectLine(stdout, ['flutter_puby_test', 'dart $argString']);
      expectLine(stdout, [path.join('flutter_puby_test', 'example'), 'Skip']);
      expectLine(stdout, ['fvm_puby_test', 'fvm dart $argString']);
      expectLine(stdout, [path.join('fvm_puby_test', 'example'), 'Skip']);
    },
    timeout: Timeout(const Duration(seconds: 120)),
  );
}
