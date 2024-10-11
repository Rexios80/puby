import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils.dart';

const argString = 'pub upgrade --major-versions';

void main() {
  test(
    '[engine] mup',
    () async {
      final result = await testCommand(['mup']);
      final stdout = result.stdout;

      expect(result.exitCode, ExitCode.success.code);

      // dart
      expectLine(stdout, ['dart_puby_test', '"dart $argString"']);
      expectLine(
        stdout,
        [p.join('dart_puby_test', 'example'), '"dart $argString"'],
      );

      // flutter
      expectLine(stdout, ['flutter_puby_test', '"flutter $argString"']);
      expectLine(
        stdout,
        [p.join('flutter_puby_test', 'example'), '"flutter $argString"'],
      );

      // fvm
      expectLine(stdout, ['fvm_puby_test', '"fvm flutter $argString"']);
      expectLine(
        stdout,
        [p.join('fvm_puby_test', 'example'), '"fvm flutter $argString"'],
      );
    },
    timeout: Timeout.factor(1.5),
  );
}
