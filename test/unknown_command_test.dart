import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('Unknown command', () async {
    final result = await testCommand(['asdf']);
    final stdout = result.stdout;

    expect(result.exitCode, 1);
    expectLine(stdout, ['Unknown command: asdf']);
  });
}
