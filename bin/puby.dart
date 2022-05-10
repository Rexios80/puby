import 'dart:convert';
import 'dart:io';
import 'package:ansicolor/ansicolor.dart';
import 'package:path/path.dart';
import 'package:pub_update_checker/pub_update_checker.dart';
import 'package:yaml/yaml.dart';

import 'config.dart';

final decoder = Utf8Decoder();
final convenienceCommands = {
  'gen': [
    'pub',
    'run',
    'build_runner',
    'build',
    '--delete-conflicting-outputs',
  ],
  'test': ['test'],
  'clean': ['clean'],
};

final magentaPen = AnsiPen()..magenta();
final greenPen = AnsiPen()..green();
final yellowPen = AnsiPen()..yellow();
final redPen = AnsiPen()..red();

void main(List<String> arguments) async {
  final newVersion = await PubUpdateChecker.check();
  if (newVersion != null) {
    print(
      yellowPen(
        'There is an update available: $newVersion. Run `dart pub global activate puby` to update.',
      ),
    );
  }

  if (arguments.isEmpty ||
      arguments.first == '-h' ||
      arguments.first == '--help') {
    print(
      magentaPen(
        '''
Usage:
  puby [options]          [dart|flutter] pub [options]
  puby gen [options]      [dart|flutter] pub run build_runner build --delete-conflicting-outputs [options]
  puby test [options]     [dart|flutter] test [options]
  puby clean [options]    flutter clean [options] (only runs in flutter projects)''',
      ),
    );
    exit(1);
  }

  final List<String> transformedArgs;
  final firstArg = arguments.first;
  if (convenienceCommands.containsKey(firstArg)) {
    transformedArgs = convenienceCommands[firstArg]! + arguments.sublist(1);
  } else {
    transformedArgs = ['pub', ...arguments];
  }

  final projects = await findProjects();

  if (projects.isEmpty) {
    print(redPen('No projects found in the current folder.'));
    exit(1);
  }

  int exitCode = 0;
  for (final project in projects) {
    // Fvm is a layer on top of flutter, so don't add the prefix args for these checks
    if (explicitExclude(project, transformedArgs) ||
        defaultExclude(project, projects.length, transformedArgs)) {
      continue;
    }

    final finalArgs = project.engine.prefixArgs + transformedArgs;

    final argString = finalArgs.join(' ');
    final pathString = project.path == '.' ? 'current directory' : project.path;
    print(
      greenPen(
        '\nRunning "${project.engine.name} $argString" in $pathString...',
      ),
    );

    final process = await Process.start(
      project.engine.name,
      finalArgs,
      workingDirectory: project.path,
      runInShell: true,
    );

    // Piping directly to stdout and stderr can cause unexpected behavior
    process.stdout.listen((e) => stdout.write(decoder.convert(e)));
    process.stderr.listen((e) => stderr.write(redPen(decoder.convert(e))));

    final processExitCode = await process.exitCode;

    // Combine exit codes
    exitCode = exitCode | processExitCode;
  }

  if (exitCode != 0) {
    print(redPen('\nOne or more commands failed'));
  } else {
    print(greenPen('\nAll commands succeeded'));
  }

  exit(exitCode);
}

bool defaultExclude(Project project, int projectCount, List<String> args) {
  final bool skip;
  final String? message;
  if (project.hidden) {
    // Skip hidden folders
    message = 'Skipping hidden project: ${project.path}';
    skip = true;
  } else if (project.engine.isFlutter &&
      project.example &&
      args.length >= 2 &&
      args[0] == 'pub' &&
      args[1] == 'get') {
    // Skip flutter pub get in example projects since flutter does it anyways
    // If the only project is an example, don't skip it
    message = 'Skipping flutter example project: ${project.path}';
    skip = true;
  } else if (project.engine == Engine.dart && args[0] == 'clean') {
    // dart clean is not a valid command
    message = 'Skipping dart project: ${project.path}';
    skip = true;
  } else {
    message = null;
    skip = false;
  }

  if (message != null) {
    print(yellowPen('\n$message'));
  }
  return skip;
}

bool explicitExclude(Project project, List<String> args) {
  final argString = args.join(' ');

  final skip = project.config.excludes.any(argString.startsWith);
  if (skip) {
    print(yellowPen('\nSkipping project with exclusion: ${project.path}'));
  }

  return skip;
}

Future<List<Project>> findProjects() async {
  final pubspecEntities =
      Directory.current.listSync(recursive: true, followLinks: false).where(
            (entity) => entity is File && entity.path.endsWith('pubspec.yaml'),
          );

  final projects = <Project>[];
  for (final pubspecEntity in pubspecEntities) {
    final project = await Project.fromPubspecEntity(pubspecEntity);
    projects.add(project);
  }
  return projects;
}

class Project {
  final Engine engine;
  final String path;
  final PubyConfig config;
  final bool example;
  final bool hidden;

  Project._({
    required this.engine,
    required this.path,
    required this.config,
    required this.example,
    required this.hidden,
  });

  static Future<Project> fromPubspecEntity(FileSystemEntity entity) async {
    final pubspec = await loadYaml(File(entity.path).readAsStringSync());
    final path = relative(entity.parent.path);
    final config = PubyConfig.fromProjectPath(path);

    final Engine engine;
    if (Directory('$path/.fvm').existsSync()) {
      engine = Engine.fvm;
    } else if (pubspec['dependencies']?['flutter'] != null) {
      engine = Engine.flutter;
    } else {
      engine = Engine.dart;
    }

    final example = path.split(Platform.pathSeparator).last == 'example';
    final hidden = path
        .split(Platform.pathSeparator)
        .any((e) => e.length > 1 && e.startsWith('.'));

    return Project._(
      engine: engine,
      path: path,
      config: config,
      example: example,
      hidden: hidden,
    );
  }
}

enum Engine {
  dart,
  flutter,
  fvm,
}

extension on Engine {
  bool get isFlutter => this == Engine.flutter || this == Engine.fvm;

  List<String> get prefixArgs {
    switch (this) {
      case Engine.dart:
      case Engine.flutter:
        return [];
      case Engine.fvm:
        return ['flutter'];
    }
  }
}
