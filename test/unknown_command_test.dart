import 'package:io/io.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('Unknown command', () async {
    final result = await testCommand(['asdf']);
    final stdout = result.stdout;

    expect(result.exitCode, ExitCode.usage.code);
    expectLine(stdout, ['Unknown command. Exiting...']);
  });
}
