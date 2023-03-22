import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test(
    '[engine] mup',
    () async {
      final result = await testCommand(['mup']);
      final stdout = result.stdout;

      expect(result.exitCode, 0);

      // dart
      expectLine(stdout, [
        'dart_puby_test',
        '"dart pub upgrade --major-versions"',
      ]);
      expectLine(stdout, [
        p.join('dart_puby_test', 'example'),
        '"dart pub upgrade --major-versions"',
      ]);

      // flutter
      expectLine(stdout, [
        'flutter_puby_test',
        '"flutter pub upgrade --major-versions"',
      ]);
      expectLine(stdout, [
        p.join('flutter_puby_test', 'example'),
        '"flutter pub upgrade --major-versions"',
      ]);

      // fvm
      expectLine(stdout, [
        'fvm_puby_test',
        '"fvm flutter pub upgrade --major-versions"',
      ]);
      expectLine(stdout, [
        p.join('fvm_puby_test', 'example'),
        '"fvm flutter pub upgrade --major-versions"',
      ]);
    },
    timeout: Timeout.factor(1.5),
  );
}
