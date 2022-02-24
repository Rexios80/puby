import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

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

void main(List<String> arguments) async {
  if (arguments.isEmpty ||
      arguments.first == '-h' ||
      arguments.first == '--help') {
    print(
      '''
Usage:
  puby [options]          [dart|flutter] pub [options]
  puby gen [options]      [dart|flutter] pub run build_runner build --delete-conflicting-outputs [options]
  puby test [options]     [dart|flutter] test [options]
  puby clean [options]    flutter clean [options] (only runs in flutter projects)''',
    );
    exit(1);
  }

  final List<String> args;
  final firstArg = arguments.first;
  if (convenienceCommands.containsKey(firstArg)) {
    args = convenienceCommands[firstArg]! + arguments.sublist(1);
  } else {
    args = ['pub', ...arguments];
  }
  final argString = args.join(' ');

  final projects = await findProjects();

  int exitCode = 0;
  for (final project in projects) {
    if (shouldSkipProject(project, projects.length, args)) {
      continue;
    }

    final pathString = project.path == '.' ? 'current directory' : project.path;
    print('\nRunning "${project.engine.name} $argString" in $pathString...');
    final process = await Process.start(
      project.engine.name,
      args,
      workingDirectory: project.path,
      runInShell: true,
    );
    // Piping directly to stdout and stderr can cause unexpected behavior
    process.stdout.listen((e) => stdout.write(decoder.convert(e)));
    process.stderr.listen((e) => stderr.write(decoder.convert(e)));

    final processExitCode = await process.exitCode;

    // Combine exit codes
    exitCode = exitCode | processExitCode;
  }

  if (exitCode != 0) {
    print('\nOne or more commands failed');
  } else {
    print('\nAll commands succeeded');
  }

  exit(exitCode);
}

bool shouldSkipProject(Project project, int projectCount, List<String> args) {
  if (project.hidden) {
    // Skip hidden folders
    print('\nSkipping hidden project: ${project.path}');
    return true;
  } else if (projectCount >= 2 &&
      project.engine == Engine.flutter &&
      project.example &&
      args.length >= 2 &&
      args[0] == 'pub' &&
      args[1] == 'get') {
    // Skip flutter pub get in example projects since flutter does it anyways
    // If the only project is an example, don't skip it
    print('\nSkipping flutter example project: ${project.path}');
    return true;
  } else if (project.engine == Engine.dart && args[0] == 'clean') {
    // dart clean is not a valid command
    print('\nSkipping dart project: ${project.path}');
    return true;
  } else {
    return false;
  }
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
  final bool example;
  final bool hidden;

  Project._({
    required this.engine,
    required this.path,
    required this.example,
    required this.hidden,
  });

  static Future<Project> fromPubspecEntity(FileSystemEntity entity) async {
    final pubspec = await loadYaml(File(entity.path).readAsStringSync());

    final Engine engine;
    if (pubspec['dependencies']?['flutter'] != null) {
      engine = Engine.flutter;
    } else {
      engine = Engine.dart;
    }

    final path = relative(entity.parent.path);
    final example = path.endsWith('${Platform.pathSeparator}example');
    final hidden = path
        .split(Platform.pathSeparator)
        .any((e) => e.length > 1 && e.startsWith('.'));

    return Project._(
      engine: engine,
      path: path,
      example: example,
      hidden: hidden,
    );
  }
}

enum Engine {
  dart,
  flutter,
}
