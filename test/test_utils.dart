import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as path;

final _decoder = Utf8Decoder();

// Map of project name to file paths to file contents
typedef TestProjects = Map<String, Map<String, String>>;

class PubyProcessResult {
  final String workingDirectory;
  final int exitCode;
  final String stdout;
  final String stderr;

  PubyProcessResult(
    this.workingDirectory,
    this.exitCode,
    this.stdout,
    this.stderr,
  );
}

Future<PubyProcessResult> testCommand(
  List<String> arguments, {
  TestProjects? projects,
  bool link = false,
  bool debug = false,
}) async {
  final workingDirectory = createTestResources(projects ?? defaultProjects());
  final puby = File(path.join('bin', 'puby.dart')).absolute.path;

  if (link) {
    // puby link was not working in the test environment
    await Process.run(
      'dart',
      [puby, 'get'],
      workingDirectory: workingDirectory,
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
    workingDirectory,
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

String createTestResources(Map<String, Map<String, String>> projects) {
  final directory = Directory.systemTemp.createTempSync('test_resources');
  for (final MapEntry(:key, :value) in projects.entries) {
    final project = key;
    final files = value;
    for (final MapEntry(:key, :value) in files.entries) {
      final file = key;
      final content = value;
      File(path.join(directory.path, project, file))
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
    }
  }
  return directory.path;
}

String pubspec(
  String name, {
  bool flutter = false,
  Set<String> dependencies = const {},
  Set<String> devDependencies = const {},
}) {
  var pubspec = '''
name: $name

environment:
  sdk: ^3.0.0
''';

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

String fvmrc(String version) => '''
{
  "flutter": "$version",
  "flavors": {}
}''';

TestProjects dartProject({
  Set<String> dependencies = const {},
  Set<String> devDependencies = const {},
}) =>
    {
      'dart_puby_test': {
        'pubspec.yaml': pubspec(
          'dart_puby_test',
          dependencies: dependencies,
          devDependencies: devDependencies,
        ),
        'example/pubspec.yaml': pubspec('example'),
      },
    };

TestProjects flutterProject({
  Set<String> dependencies = const {},
  Set<String> devDependencies = const {},
}) =>
    {
      'flutter_puby_test': {
        'pubspec.yaml': pubspec(
          'flutter_puby_test',
          flutter: true,
          dependencies: dependencies,
          devDependencies: devDependencies,
        ),
        'example/pubspec.yaml': pubspec('example', flutter: true),
      },
    };

TestProjects fvmProject({
  Set<String> dependencies = const {},
  Set<String> devDependencies = const {},
}) =>
    {
      'fvm_puby_test': {
        'pubspec.yaml': pubspec(
          'fvm_puby_test',
          flutter: true,
          dependencies: dependencies,
          devDependencies: devDependencies,
        ),
        'example/pubspec.yaml': pubspec('example', flutter: true),
        'nested/pubspec.yaml': pubspec('nested', flutter: true),
        '.fvmrc': fvmrc('3.10.0'),
      },
    };

TestProjects defaultProjects({
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
