import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('--no-fvm', () async {
    final result = await testCommand(['get', '--no-fvm']);
    final stdout = result.stdout;

    expect(result.exitCode, 0);
    expectLine(
      stdout,
      ['fvm_puby_test', 'Project uses FVM, but FVM support is disabled'],
    );
  });

  test('--no-fvm on convenience command', () async {
    final result = await testCommand(['mup', '--no-fvm']);
    final stdout = result.stdout;

    expect(result.exitCode, 0);
    expectLine(
      stdout,
      ['fvm_puby_test', 'Project uses FVM, but FVM support is disabled'],
    );
  });
}
