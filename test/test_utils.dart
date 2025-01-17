import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as path;

final _decoder = Utf8Decoder();

class PubyProcessResult {
  final String testDirectory;
  final int exitCode;
  final String stdout;
  final String stderr;

  PubyProcessResult(
    this.testDirectory,
    this.exitCode,
    this.stdout,
    this.stderr,
  );
}

Future<PubyProcessResult> testCommand(
  List<String> arguments, {
  Map<String, Object>? entities,
  bool link = false,
  bool debug = false,
  String workingPath = '',
}) async {
  final testDirectory = createTestResources(entities ?? defaultProjects());
  final workingDirectory = path.join(testDirectory, workingPath);
  final puby = File(path.join('bin', 'puby.dart')).absolute.path;

  if (link) {
    // puby link was not working in the test environment
    await Process.run(
      'dart',
      [puby, 'get'],
      workingDirectory: testDirectory,
    );
  }

  final process = await Process.start(
    'dart',
    [puby, ...arguments],
    workingDirectory: workingDirectory,
  );

  String handleLine(dynamic line) {
    final decoded = _decoder.convert(line);
    if (debug) stdout.write(decoded);
    return decoded;
  }

  final processStdout = process.stdout.map(handleLine).join('\n');
  final processStderr = process.stderr.map(handleLine).join('\n');

  final exitCode = await process.exitCode;
  return PubyProcessResult(
    testDirectory,
    exitCode,
    await processStdout,
    await processStderr,
  );
}

void expectLine(String stdout, List<String> matchers, {bool matches = true}) {
  final lines = stdout.split('\n');
  expect(
    lines.any(
      (line) =>
          matchers.fold(true, (prev, next) => prev && line.contains(next)),
    ),
    matches,
  );
}

String createTestResources(Map<String, Object> entities) {
  final directory = Directory.systemTemp.createTempSync('test_resources');
  for (final MapEntry(key: entityName, value: entityContent)
      in entities.entries) {
    if (entityContent is String) {
      File(path.join(directory.path, entityName))
        ..createSync(recursive: true)
        ..writeAsStringSync(entityContent);
    } else if (entityContent is Map<String, String>) {
      for (final MapEntry(key: filePath, value: fileContent)
          in entityContent.entries) {
        File(path.join(directory.path, entityName, filePath))
          ..createSync(recursive: true)
          ..writeAsStringSync(fileContent);
      }
    }
  }
  return directory.path;
}

String pubspec(
  String name, {
  bool flutter = false,
  bool workspace = false,
  Set<String> dependencies = const {},
  Set<String> devDependencies = const {},
}) {
  var pubspec = '''
name: $name

environment:
  sdk: ^3.5.0
''';

  if (workspace) {
    pubspec += '\nresolution: workspace\n';
  }

  if (flutter || dependencies.isNotEmpty) {
    pubspec += '\ndependencies:\n';
  }

  if (flutter) {
    pubspec += '''
  flutter:
    sdk: flutter
''';
  }

  for (final dependency in dependencies) {
    pubspec += '  $dependency\n';
  }

  if (devDependencies.isNotEmpty) {
    pubspec += '\ndev_dependencies:\n';
  }

  for (final dependency in devDependencies) {
    pubspec += '  $dependency\n';
  }

  return pubspec;
}

const workspacePubspec = '''
name: workspace
environment:
  sdk: ^3.5.0

workspace:
  - dart_puby_test
''';

String fvmrc(String version) => '''
{
  "flutter": "$version",
  "flavors": {}
}''';

Map<String, Object> dartProject({
  Set<String> dependencies = const {},
  Set<String> devDependencies = const {},
  bool includeExample = true,
  bool workspace = false,
}) =>
    {
      'dart_puby_test': {
        'pubspec.yaml': pubspec(
          'dart_puby_test',
          workspace: workspace,
          dependencies: dependencies,
          devDependencies: devDependencies,
        ),
        if (includeExample) 'example/pubspec.yaml': pubspec('example'),
      },
    };

Map<String, Object> flutterProject({
  Set<String> dependencies = const {},
  Set<String> devDependencies = const {},
  bool includeExample = true,
  bool workspace = false,
}) =>
    {
      'flutter_puby_test': {
        'pubspec.yaml': pubspec(
          'flutter_puby_test',
          flutter: true,
          workspace: workspace,
          dependencies: dependencies,
          devDependencies: devDependencies,
        ),
        if (includeExample)
          'example/pubspec.yaml': pubspec('example', flutter: true),
      },
    };

Map<String, Object> fvmProject({
  Set<String> dependencies = const {},
  Set<String> devDependencies = const {},
  bool includeExample = true,
  bool workspace = false,
}) =>
    {
      'fvm_puby_test': {
        'pubspec.yaml': pubspec(
          'fvm_puby_test',
          flutter: true,
          workspace: workspace,
          dependencies: dependencies,
          devDependencies: devDependencies,
        ),
        if (includeExample)
          'example/pubspec.yaml': pubspec('example', flutter: true),
        'nested/pubspec.yaml': pubspec('nested', flutter: true),
        '.fvmrc': fvmrc('3.24.0'),
      },
    };

Map<String, Object> defaultProjects({
  Set<String> dependencies = const {},
  Set<String> devDependencies = const {},
}) =>
    {
      ...dartProject(
        dependencies: dependencies,
        devDependencies: devDependencies,
      ),
      ...flutterProject(
        dependencies: dependencies,
        devDependencies: devDependencies,
      ),
      ...fvmProject(
        dependencies: dependencies,
        devDependencies: devDependencies,
      ),
    };
