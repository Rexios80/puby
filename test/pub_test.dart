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

    test('handles invlaid pubspec', () async {
      final result = await testCommand(
        ['get'],
        entities: {
          'invalid_pubspec_test': {
            'pubspec.yaml': 'invalid',
          },
        },
      );
      final stdout = result.stdout;

      expect(result.exitCode, ExitCode.usage.code);

      expectLine(stdout, ['invalid_pubspec_test', 'Error parsing pubspec']);
    });

    group('excludes', () {
      test('project in build folder', () async {
        final result = await testCommand(
          ['get'],
          entities: {
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
        Future<void> skipsExample(Map<String, Object> entities) async {
          final result = await testCommand(['get'], entities: entities);
          final stdout = result.stdout;

          expect(result.exitCode, ExitCode.success.code);

          expectLine(
            stdout,
            [path.join(entities.keys.first, 'example'), 'Skip'],
          );
          expectLine(stdout, ['Resolving dependencies in `./example`...']);
        }

        test('dart', () async {
          await skipsExample(dartProject());
        });

        test('flutter', () async {
          await skipsExample(flutterProject());
        });

        test('fvm', () async {
          await skipsExample(fvmProject());
        });

        test('workspace member example', () async {
          final result = await testCommand(
            ['get'],
            entities: {
              'pubspec.yaml': workspacePubspec,
              ...dartProject(workspace: true),
            },
          );
          final stdout = result.stdout;

          expect(result.exitCode, ExitCode.success.code);

          // pub get should run in workspace member example where the example
          // is not a workspace member
          expectLine(stdout, ['dart_puby_test/example', 'dart pub get']);
        });

        test('standalone example folder', () async {
          final result = await testCommand(
            ['get'],
            entities: {
              'example': {
                'pubspec.yaml': pubspec('example'),
              },
            },
          );
          final stdout = result.stdout;

          expect(result.exitCode, ExitCode.success.code);

          // pub get should run in standalone example
          expectLine(stdout, ['Running "dart pub get" in example...']);
        });
      });

      test('workspace members', () async {
        final result = await testCommand(
          ['get'],
          entities: {
            'pubspec.yaml': workspacePubspec,
            ...dartProject(workspace: true),
          },
        );
        final stdout = result.stdout;

        expect(result.exitCode, ExitCode.success.code);

        // Pub get should run in the workspace
        expectLine(stdout, ['Running "dart pub get" in current directory...']);

        // Pub get should NOT run in workspace members
        expectLine(stdout, ['dart_puby_test', 'Skip']);
      });
    });
  });
}
