import 'package:test/test.dart';

import '../bin/utils.dart';
import 'test_utils.dart';

void main() async {
  final fvmEnabled = await fvmInstalled();

  test(
    'FVM not installed warning',
    () async {
      final result = await testCommand(['get']);
      final stdout = result.stdout;

      expect(result.exitCode, 0);

      expectLine(stdout, ['This project uses FVM, but FVM is not installed']);
    },
    skip: fvmEnabled ? 'FVM is installed' : false,
  );
}
