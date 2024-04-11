import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('FVM version not installed', () async {
    final result = await testCommand(
      ['get'],
      workingDirectory: 'test_resources_2/fvm_version_not_installed_test',
    );
    final stdout = result.stdout;

    expect(result.exitCode, isNot(0));
    expectLine(stdout, ['Run `fvm install 1.17.0` first']);
  });
}
