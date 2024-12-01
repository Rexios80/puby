import 'package:io/io.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

const argString = 'run build_runner build --delete-conflicting-outputs';

void main() {
  test(
    '[engine] gen',
    () async {
      final result = await testCommand(
        ['gen'],
        projects: defaultProjects(devDependencies: {'build_runner: any'}),
        debug: true,
      );
      final stdout = result.stdout;

      expect(result.exitCode, ExitCode.success.code);

      expectLine(stdout, ['dart_puby_test', 'dart $argString']);
      expectLine(stdout, ['dart_puby_test/example', 'Skip']);
      expectLine(stdout, ['flutter_puby_test', 'dart $argString']);
      expectLine(stdout, ['flutter_puby_test/example', 'Skip']);
      expectLine(stdout, ['fvm_puby_test', 'fvm dart $argString']);
      expectLine(stdout, ['fvm_puby_test/example', 'Skip']);
    },
    timeout: Timeout.factor(1.5),
  );
}
