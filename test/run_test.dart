import 'package:io/io.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

import 'test_utils.dart';

void main() {
  test('puby run', () async {
    final result = await testCommand(
      ['run', 'custom_lint'],
      projects: defaultProjects(devDependencies: {'custom_lint: any'}),
      link: true,
    );
    final stdout = result.stdout;

    expect(result.exitCode, ExitCode.success.code);

    expectLine(stdout, ['dart_puby_test', 'dart run custom_lint']);
    expectLine(stdout, [path.join('dart_puby_test', 'example'), 'Skip']);
    expectLine(stdout, ['flutter_puby_test', 'dart run custom_lint']);
    expectLine(stdout, [path.join('flutter_puby_test', 'example'), 'Skip']);
    expectLine(stdout, ['fvm_puby_test', 'fvm dart run custom_lint']);
    expectLine(stdout, [path.join('fvm_puby_test', 'example'), 'Skip']);
  });
}
