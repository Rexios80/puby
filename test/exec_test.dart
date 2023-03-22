import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('puby exec', () async {
    final result = await testCommand(['exec', 'echo', 'foo']);
    final stdout = result.stdout;

    expect(result.exitCode, 0);
    // dart
    expectLine(stdout, [
      'dart_puby_test',
      '"echo foo"',
    ]);
    expectLine(stdout, [p.join('dart_puby_test', 'example'), '"echo foo"']);

    // flutter
    expectLine(stdout, [
      'flutter_puby_test',
      '"echo foo"',
    ]);
    expectLine(stdout, [p.join('flutter_puby_test', 'example'), '"echo foo"']);

    // fvm
    expectLine(stdout, [
      'fvm_puby_test',
      '"echo foo"',
    ]);
    expectLine(stdout, [p.join('fvm_puby_test', 'example'), '"echo foo"']);
  });
}
