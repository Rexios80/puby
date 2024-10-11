import 'package:io/io.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('[engine] pub get', () {
    test('runs in all projects', () async {
      final result = await testCommand(['get']);
      final stdout = result.stdout;

      expect(result.exitCode, ExitCode.success.code);

      expectLine(stdout, ['dart_puby_test', 'dart pub get']);
      expectLine(stdout, ['flutter_puby_test', 'flutter pub get']);
      expectLine(stdout, ['fvm_puby_test', 'fvm flutter pub get']);
      expectLine(
        stdout,
        [path.join('fvm_puby_test', 'nested'), 'fvm flutter pub get'],
      );
    });

    test('invlaid pubspec', () async {
      final result = await testCommand(
        ['get'],
        projects: {
          'invalid_pubspec_test': {
            'pubspec.yaml': 'invalid',
          },
        },
      );
      final stdout = result.stdout;

      expect(result.exitCode, ExitCode.usage.code);

      expectLine(stdout, ['invalid_pubspec_test', 'Error parsing pubspec']);
    });

    group('exclusions', () {
      test('project in build folder', () async {
        final result = await testCommand(
          ['get'],
          projects: {
            'build_folder_test': {
              'build/web/pubspec.yaml': pubspec('web'),
            },
          },
        );
        final stdout = result.stdout;

        expect(result.exitCode, ExitCode.success.code);

        expectLine(
          stdout,
          [path.join('build_folder_test', 'build', 'web'), 'Skip'],
        );
      });

      group('example projects', () {
        Future<void> skipsExample(
          TestProjects projects, {
          String match = 'Resolving dependencies in `./example`...',
        }) async {
          final result = await testCommand(['get'], projects: projects);
          final stdout = result.stdout;

          expect(result.exitCode, ExitCode.success.code);

          expectLine(
            stdout,
            [path.join(projects.keys.first, 'example'), 'Skip'],
          );
          expectLine(stdout, [match]);
        }

        test('dart', () async {
          await skipsExample(dartProject);
        });

        test('flutter', () async {
          await skipsExample(flutterProject);
        });

        test('fvm', () async {
          await skipsExample(
            fvmProject,
            // This is different because of the older Flutter version
            match: 'Resolving dependencies in ./example...',
          );
        });
      });
    });
  });
}
