import 'package:io/io.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('FVM version not installed', () async {
    final result = await testCommand(
      ['get'],
      // TODO: FIX THIS
      // workingDirectory: 'test_resources_2/fvm_version_not_installed_test',
    );
    final stdout = result.stdout;

    expect(result.exitCode, isNot(ExitCode.success.code));
    expectLine(stdout, ['Run `fvm install 1.17.0` first']);
  });
}
