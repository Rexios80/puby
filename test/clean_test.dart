import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('[engine] clean', () async {
    final result = await testCommand(['clean']);
    final stdout = result.stdout;

    expect(result.exitCode, ExitCode.success.code);

    // dart
    expectLine(stdout, ['dart_puby_test', 'flutter clean']);
    expectLine(stdout, [p.join('dart_puby_test', 'example'), 'flutter clean']);

    // flutter
    expectLine(stdout, ['flutter_puby_test', 'flutter clean']);
    expectLine(
      stdout,
      [p.join('flutter_puby_test', 'example'), 'flutter clean'],
    );

    // fvm
    expectLine(stdout, ['fvm_puby_test', 'fvm flutter clean']);
    expectLine(
      stdout,
      [p.join('fvm_puby_test', 'example'), 'fvm flutter clean'],
    );
  });
}
