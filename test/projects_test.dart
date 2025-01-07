import 'dart:io';

import 'package:puby/project.dart';
import 'package:test/test.dart';

import '../bin/projects.dart';
import 'test_utils.dart';

void main() {
  group('projects', () {
    test('prints number of projects found', () async {
      final result1 = await testCommand(
        ['asdf'],
        entities: dartProject(includeExample: false),
      );
      expect(result1.stdout, contains('Found 1 project\n'));

      final result2 = await testCommand(
        ['asdf'],
        entities: dartProject(),
      );
      expect(result2.stdout, contains('Found 2 projects\n'));
    });

    group('finds dependencies', () {
      test('without lock file', () {
        final workingDirectory = createTestResources(
          dartProject(
            devDependencies: {'rexios_lints: any'},
            includeExample: false,
          ),
        );

        final dependencies =
            findProjects(directory: Directory(workingDirectory))
                .first
                .dependencies;
        expect(dependencies, contains('rexios_lints'));
        expect(dependencies, isNot(contains('custom_lint')));
      });

      test('with lock file', () async {
        final result = await testCommand(
          ['get'],
          entities: dartProject(
            devDependencies: {'rexios_lints: any'},
            includeExample: false,
          ),
        );

        final dependencies =
            findProjects(directory: Directory(result.workingDirectory))
                .first
                .dependencies;
        expect(dependencies, contains('rexios_lints'));
        expect(dependencies, contains('custom_lint'));
      });

      group('in workspace', () {
        test('without lock file', () {
          final workingDirectory = createTestResources(
            {
              'pubspec.yaml': workspacePubspec,
              ...dartProject(
                devDependencies: {'rexios_lints: any'},
                includeExample: false,
                workspace: true,
              ),
            },
          );

          final dependencies =
              findProjects(directory: Directory(workingDirectory))
                  .firstWhere((e) => e.type == ProjectType.workspaceMember)
                  .dependencies;
          expect(dependencies, contains('rexios_lints'));
          expect(dependencies, isNot(contains('custom_lint')));
        });

        test('with lock file', () async {
          final result = await testCommand(
            ['get'],
            entities: {
              'pubspec.yaml': workspacePubspec,
              ...dartProject(
                devDependencies: {'rexios_lints: any'},
                includeExample: false,
                workspace: true,
              ),
            },
          );

          final dependencies =
              findProjects(directory: Directory(result.workingDirectory))
                  .firstWhere((e) => e.type == ProjectType.workspaceMember)
                  .dependencies;
          expect(dependencies, contains('rexios_lints'));
          expect(dependencies, contains('custom_lint'));
        });
      });
    });
  });
}
