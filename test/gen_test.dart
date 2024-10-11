import 'package:io/io.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

const argString = 'pub run build_runner build --delete-conflicting-outputs';

void main() {
  test('[engine] gen', () async {
    final result = await testCommand(['gen']);
    final stdout = result.stdout;

    expect(result.exitCode, isNot(ExitCode.success.code));

    expectLine(stdout, ['dart_puby_test', 'dart $argString']);
    expectLine(stdout, ['flutter_puby_test', 'flutter $argString']);
    expectLine(stdout, ['fvm_puby_test', 'fvm flutter $argString']);
  });
}
