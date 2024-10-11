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
  bool debug = false,
}) async {
  final workingDirectory = createTestResources(projects ?? defaultProjects);
  final puby = File(path.join('bin', 'puby.dart')).absolute.path;

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

String pubspec(String name, {bool flutter = false}) {
  var pubspec = '''
name: $name

environment:
  sdk: ^3.0.0
''';

  if (flutter) {
    pubspec += '''
dependencies:
  flutter:
    sdk: flutter
''';
  }

  return pubspec;
}

String fvmrc(String version) => '''
{
  "flutter": "$version",
  "flavors": {}
}''';

final dartProject = {
  'dart_puby_test': {
    'pubspec.yaml': pubspec('dart_puby_test'),
    'example/pubspec.yaml': pubspec('example'),
  },
};

final flutterProject = {
  'flutter_puby_test': {
    'pubspec.yaml': pubspec('flutter_puby_test', flutter: true),
    'example/pubspec.yaml': pubspec('example', flutter: true),
  },
};

final fvmProject = {
  'fvm_puby_test': {
    'pubspec.yaml': pubspec('fvm_puby_test', flutter: true),
    'example/pubspec.yaml': pubspec('example', flutter: true),
    'nested/pubspec.yaml': pubspec('nested', flutter: true),
    '.fvmrc': fvmrc('3.10.0'),
  },
};

final defaultProjects = {
  ...dartProject,
  ...flutterProject,
  ...fvmProject,
};
