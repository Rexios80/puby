import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils.dart';

const argString = 'pub run build_runner build --delete-conflicting-outputs';

void main() {
  test('[engine] gen', () async {
    final result = await testCommand(['gen']);
    final stdout = result.stdout;

    // Since these projects have no code generation, the command should fail
    expect(result.exitCode, isNot(ExitCode.success.code));

    // dart
    expectLine(stdout, ['dart_puby_test', 'dart $argString']);
    // Explicit exclusion
    expectLine(stdout, [p.join('dart_puby_test', 'example'), 'Skip']);

    // flutter
    expectLine(stdout, ['flutter_puby_test', 'flutter $argString']);
    // Explicit exclusion
    expectLine(stdout, [p.join('flutter_puby_test', 'example'), 'Skip']);

    // fvm
    expectLine(stdout, ['fvm_puby_test', 'fvm flutter $argString']);
    // Explicit exclusion
    expectLine(stdout, [p.join('fvm_puby_test', 'example'), 'Skip']);
  });
}
