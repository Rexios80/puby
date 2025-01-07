import 'package:test/test.dart';

import '../bin/projects.dart';
import 'test_utils.dart';

void main() {
  group('projects', () {
    test('prints number of projects found', () async {
      final result1 = await testCommand(
        ['asdf'],
        projects: {...dartProject(includeExample: false)},
      );
      expect(result1.stdout, contains('Found 1 project'));

      final result2 = await testCommand(
        ['asdf'],
        projects: {...dartProject()},
      );
      expect(result2.stdout, contains('Found 2 projects'));
    });
  });
}
