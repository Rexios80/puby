import 'dart:convert';
import 'dart:io';
import 'package:ansicolor/ansicolor.dart';
import 'package:path/path.dart';
import 'package:pub_update_checker/pub_update_checker.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import 'config.dart';

final decoder = Utf8Decoder();
final convenienceCommands = <String, List<List<String>>>{
  'gen': [
    [
      'pub',
      'run',
      'build_runner',
      'build',
      '--delete-conflicting-outputs',
    ],
  ],
  'test': [
    ['test'],
  ],
  'clean': [
    ['clean'],
  ],
  'mup': [
    ['pub', 'upgrade', '--major-versions'],
    ['pub', 'upgrade'],
  ],
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
  puby clean [options]    flutter clean [options]
  puby mup [options]      puby upgrade --major-versions [options] && puby upgrade [options]''',
      ),
    );
    exit(1);
  }

  final firstArg = arguments.first;

  final commands = <List<String>>[];
  if (convenienceCommands.containsKey(firstArg)) {
    for (final command in convenienceCommands[firstArg]!) {
      commands.add(command + arguments.sublist(1));
    }
  } else {
    commands.add(['pub', ...arguments]);
  }

  int exitCode = 0;
  for (final command in commands) {
    exitCode |= await runAll(command);
  }

  exit(exitCode);
}

Future<int> runAll(List<String> args) async {
  final stopwatch = Stopwatch()..start();

  final projects = await findProjects(engineOverride: engineOverride(args));

  if (projects.isEmpty) {
    print(redPen('No projects found in the current directory'));
    exit(1);
  }

  int exitCode = 0;
  final List<String> failures = [];
  for (final project in projects) {
    final processExitCode = await run(project, projects.length, args);

    if (processExitCode != 0) {
      failures.add(project.path);
    }

    // Combine exit codes
    exitCode |= processExitCode;
  }

  final elapsed = stopwatch.elapsedMilliseconds;
  final String time;
  if (elapsed > 1000) {
    time = '${(elapsed / 1000).toStringAsFixed(1)}s';
  } else {
    time = '${elapsed}ms';
  }

  if (exitCode != 0) {
    print(redPen('\nOne or more commands failed ($time)'));
    print(redPen('Failures:'));
    for (final failure in failures) {
      print(redPen('  $failure'));
    }
  } else {
    print(greenPen('\nAll commands succeeded ($time)'));
  }

  return exitCode;
}

Future<int> run(Project project, int projectCount, List<String> args) async {
  // Fvm is a layer on top of flutter, so don't add the prefix args for these checks
  if (explicitExclude(project, args) ||
      defaultExclude(project, projectCount, args)) {
    return 0;
  }

  final finalArgs = project.engine.prefixArgs + args;

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
  final err = <String>[];
  process.stdout.listen((e) => stdout.write(decoder.convert(e)));
  process.stderr.listen((e) {
    final line = decoder.convert(e);
    err.add(line);
    stderr.write(redPen(line));
  });

  final processExitCode = await process.exitCode;

  if (err.any(
    (e) => e.contains(
      'Flutter users should run `flutter pub get` instead of `dart pub get`.',
    ),
  )) {
    // If a project doesn't explicitly depend on flutter, it is not possible
    // to know if it's dependencies require flutter. So retry if that's the
    // reason for failure.
    print(yellowPen('\nRetrying with "flutter" engine'));
    return run(project.copyWith(engine: Engine.flutter), projectCount, args);
  }

  return processExitCode;
}

Engine? engineOverride(List<String> args) {
  final Engine? engine;
  final String? message;
  if (args[0] == 'clean') {
    engine = Engine.flutter;
    message = 'Overriding engine to "flutter" for "clean" command';
  } else if (args.length >= 2 && args[0] == 'test' && args[1] == '--coverage') {
    engine = Engine.flutter;
    message = 'Overriding engine to "flutter" for "test --coverage" command';
  } else {
    engine = null;
    message = null;
  }

  if (message != null) {
    print(yellowPen(message));
  }
  return engine;
}

bool defaultExclude(Project project, int projectCount, List<String> args) {
  final bool skip;
  final String? message;
  if (project.hidden) {
    // Skip hidden folders
    message = 'Skipping hidden project: ${project.path}';
    skip = true;
  } else if (project.path.startsWith('build/') ||
      project.path.contains('/build/')) {
    message = 'Skipping project in build folder: ${project.path}';
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

Future<List<Project>> findProjects({Engine? engineOverride}) async {
  final pubspecEntities = Directory.current
      .listSync(recursive: true, followLinks: false)
      .where(
        (entity) => entity is File && entity.path.endsWith('pubspec.yaml'),
      )
      .cast<File>();

  final projects = <Project>[];
  for (final pubspecEntity in pubspecEntities) {
    final project = await Project.fromPubspecEntity(
      pubspecEntity,
      engineOverride: engineOverride,
    );
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

  static Future<Project> fromPubspecEntity(
    File entity, {
    Engine? engineOverride,
  }) async {
    final path = relative(entity.parent.path);
    final config = PubyConfig.fromProjectPath(path);

    late final Pubspec? pubspec;
    try {
      pubspec = Pubspec.parse(entity.readAsStringSync());
    } catch (e) {
      print(redPen('Error parsing pubspec: $path'));
      pubspec = null;
    }

    final Engine engine;
    if (engineOverride != null) {
      engine = engineOverride;
    } else if (Directory('$path/.fvm').existsSync()) {
      engine = Engine.fvm;
    } else if (pubspec?.dependencies['flutter'] != null) {
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

  Project copyWith({Engine? engine}) {
    return Project._(
      engine: engine ?? this.engine,
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
