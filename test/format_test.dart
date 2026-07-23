import 'dart:io';

import 'package:io/io.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'test_utils.dart';

const _unformatted = 'void main(){print(1);}';

void main() {
  group('puby format', () {
    test('formats files while skipping build folders', () async {
      final result = await testCommand(
        ['format'],
        entities: {
          'lib': {'a.dart': _unformatted},
          'build': {'b.dart': _unformatted},
        },
      );

      expect(result.exitCode, ExitCode.success.code);
      expect(result.stdout, isNot(contains('Finding projects')));

      final formattedFile = File(
        path.join(result.testDirectory, 'lib', 'a.dart'),
      );
      final buildFile = File(
        path.join(result.testDirectory, 'build', 'b.dart'),
      );

      // The file outside of the build folder should have been reformatted
      expect(formattedFile.readAsStringSync(), isNot(_unformatted));
      // The file inside the build folder should be untouched
      expect(buildFile.readAsStringSync(), _unformatted);
    });

    test('forwards extra arguments to dart format', () async {
      final result = await testCommand(
        ['format', '--set-exit-if-changed'],
        entities: {
          'lib': {'a.dart': _unformatted},
        },
      );

      // dart format returns a non-zero exit code when changes were made and
      // --set-exit-if-changed is passed
      expect(result.exitCode, isNot(ExitCode.success.code));
    });

    test('succeeds with no dart files', () async {
      final result = await testCommand(
        ['format'],
        entities: const {},
      );

      expect(result.exitCode, ExitCode.success.code);
      expect(result.stdout, contains('No dart files found to format'));
    });
  });
}
