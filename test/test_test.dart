import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('[engine] test', () async {
    final result = await testCommand(['test', '--coverage']);
    final stdout = result.stdout;

    // Since these projects have no tests, the command should fail
    expect(result.exitCode, isNot(0));

    // dart
    expectLine(stdout, ['dart_puby_test', 'flutter test --coverage']);
    // Explicit exclusion
    expectLine(stdout, [p.join('dart_puby_test', 'example'), 'Skip']);

    // flutter
    expectLine(stdout, ['flutter_puby_test', 'flutter test --coverage']);
    // Explicit exclusion
    expectLine(stdout, [p.join('flutter_puby_test', 'example'), 'Skip']);

    // fvm
    expectLine(stdout, ['fvm_puby_test', 'fvm flutter test --coverage']);
    // Explicit exclusion
    expectLine(stdout, [p.join('fvm_puby_test', 'example'), 'Skip']);
  });
}
