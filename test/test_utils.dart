import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

@immutable
class PubyProcessResult {
  final String testDirectory;
  final int exitCode;
  final String stdout;
  final String stderr;

  const PubyProcessResult(
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
  final puby = _ensurePubyKernel();
  final environment = _testEnvironment();

  if (link) {
    // Creates workspace metadata (workspace_ref.json) the same way `pub get` does.
    final prepare = await Process.run(
      Platform.resolvedExecutable,
      [puby, 'get'],
      workingDirectory: testDirectory,
      environment: environment,
    );
    if (prepare.exitCode != 0) {
      fail(
        'Preparing the test project failed with exit code ${prepare.exitCode}\n'
        '${prepare.stdout}${prepare.stderr}',
      );
    }
  }

  final process = await Process.start(
    Platform.resolvedExecutable,
    [puby, ...arguments],
    workingDirectory: workingDirectory,
    environment: environment,
  );

  final processStdout = _capture(process.stdout, debug: debug);
  final processStderr = _capture(process.stderr, debug: debug);

  final exitCode = await process.exitCode;
  return PubyProcessResult(
    testDirectory,
    exitCode,
    await processStdout,
    await processStderr,
  );
}

/// Concatenate process output without inserting breaks between chunks.
///
/// Joining chunks with newlines splits a line that arrives in two reads and
/// makes assertions on that line fail intermittently.
Future<String> _capture(Stream<List<int>> stream, {required bool debug}) {
  return stream.transform(utf8.decoder).map((chunk) {
    if (debug) stdout.write(chunk);
    return chunk;
  }).join();
}

/// Compiles puby once per source revision.
///
/// `dart bin/puby.dart` recompiles the bundled pub solver on every launch,
/// which costs several seconds. A kernel snapshot starts in a fraction of that
/// and is shared by every test process.
String _ensurePubyKernel() {
  final stamp = _kernelStamp();
  final dir = Directory(path.join(Directory.systemTemp.path, 'puby_kernels'));
  dir.createSync(recursive: true);
  final dill = File(path.join(dir.path, '$stamp.dill'));
  final lock = File(path.join(dir.path, '$stamp.lock'));

  for (var attempt = 0; attempt < 3; attempt++) {
    if (dill.existsSync() && dill.lengthSync() > 0) return dill.path;

    var ownsLock = false;
    try {
      lock.createSync(exclusive: true);
      ownsLock = true;
    } on FileSystemException {
      ownsLock = false;
    }

    if (!ownsLock) {
      for (var i = 0; i < 2400; i++) {
        if (dill.existsSync() && dill.lengthSync() > 0) return dill.path;
        if (!lock.existsSync()) break;
        sleep(const Duration(milliseconds: 50));
      }
      continue;
    }

    try {
      if (dill.existsSync() && dill.lengthSync() > 0) return dill.path;
      final partial = File('${dill.path}.partial');
      if (partial.existsSync()) partial.deleteSync();
      final result = Process.runSync(
        Platform.resolvedExecutable,
        [
          'compile',
          'kernel',
          '-o',
          partial.path,
          path.join('bin', 'puby.dart'),
        ],
      );
      if (result.exitCode != 0) {
        fail(
          'Failed to compile puby test kernel (exit ${result.exitCode})\n'
          '${result.stdout}${result.stderr}',
        );
      }
      partial.renameSync(dill.path);
      return dill.path;
    } finally {
      if (lock.existsSync()) lock.deleteSync();
    }
  }

  fail('Failed to compile puby test kernel');
}

/// Stable fingerprint of the sources baked into the test kernel.
String _kernelStamp() {
  var hash = 0x811c9dc5;
  for (final file in _kernelInputs()) {
    for (final byte in file.readAsBytesSync()) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    hash ^= 0xFF;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16);
}

List<File> _kernelInputs() {
  final files = <File>[
    File('pubspec.yaml'),
    File(path.join('.dart_tool', 'package_config.json')),
  ];
  for (final dirName in ['bin', 'lib']) {
    files.addAll(
      Directory(dirName)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
    );
  }
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

/// Point `dart`, `flutter`, and `fvm` at the stubs in `test/stubs`.
///
/// The real tools download packages and boot SDKs, which is both slow and
/// sensitive to network and machine load. `PUBY_TEST_MODE` skips the pub
/// solver inside `puby link` for the same reason.
Map<String, String> _testEnvironment() {
  final env = Map<String, String>.from(Platform.environment);
  final stubDir = path.join(Directory.current.path, 'test', 'stubs');
  final separator = Platform.isWindows ? ';' : ':';
  env['PATH'] = '$stubDir$separator${env['PATH'] ?? ''}';
  env['PUBY_TEST_MODE'] = '1';
  return env;
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
  final directory = Directory.systemTemp.createTempSync('puby_test_');
  addTearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });
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

/// Minimal `pubspec.lock` whose package keys are [packages].
String lockFile(Set<String> packages) {
  final sorted = packages.toList()..sort();
  final buffer = StringBuffer('packages:\n');
  for (final package in sorted) {
    buffer
      ..writeln('  $package:')
      ..writeln('    version: "0.0.0"');
  }
  return buffer.toString();
}

/// `workspace_ref.json` for a member that is a direct child of the workspace.
///
/// Pub stores this under `<member>/.dart_tool/pub` and the path is relative to
/// that directory.
const directMemberWorkspaceRef = '{"workspaceRoot":"../../.."}';

Map<String, Object> dartProject({
  Set<String> dependencies = const {},
  Set<String> devDependencies = const {},
  bool includeExample = true,
  bool workspace = false,
  Map<String, String> extraFiles = const {},
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
        ...extraFiles,
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
