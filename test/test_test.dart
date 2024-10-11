import 'package:io/io.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('[engine] test', () async {
    final result = await testCommand(['test', '--coverage']);
    final stdout = result.stdout;

    // Since these projects have no tests, the command should fail
    expect(result.exitCode, isNot(ExitCode.success.code));

    expectLine(stdout, ['dart_puby_test', 'flutter test --coverage']);
    expectLine(stdout, ['flutter_puby_test', 'flutter test --coverage']);
    expectLine(stdout, ['fvm_puby_test', 'fvm flutter test --coverage']);
  });
}
