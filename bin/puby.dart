import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_tools_task_queue/flutter_tools_task_queue.dart';
import 'package:pub_update_checker/pub_update_checker.dart';
import 'package:puby/command.dart';
import 'package:puby/engine.dart';
import 'package:puby/pens.dart';
import 'package:puby/project.dart';
import 'package:puby/time.dart';

import 'link.dart';

const decoder = Utf8Decoder();
final clean = Command(
  (engineArgs) => [...engineArgs, 'clean'],
  parallel: true,
  silent: true,
);
final link = Command(
  (engineArgs) => [...engineArgs, 'pub', 'get', '--offline'],
  parallel: true,
  silent: true,
);
final convenienceCommands = <String, List<Command>>{
  'gen': [
    Command((engineArgs) => [
          ...engineArgs,
          'pub',
          'run',
          'build_runner',
          'build',
          '--delete-conflicting-outputs',
        ]),
  ],
  'test': [
    Command((engineArgs) => [...engineArgs, 'test']),
  ],
  'clean': [
    clean,
  ],
  'mup': [
    Command(
      (engineArgs) => [...engineArgs, 'pub', 'upgrade', '--major-versions'],
    ),
  ],
  'reset': [
    clean,
    Command((engineArgs) => [...engineArgs, 'pub', 'get']),
  ],
};

const help = '''
Commands:
  puby [options]          [engine] pub [options]
  puby link               Warm the pub cache and run [engine] pub get --offline
  puby gen [options]      [engine] pub run build_runner build --delete-conflicting-outputs [options]
  puby test [options]     [engine] test [options]
  puby clean [options]    flutter clean [options]
  puby mup [options]      [engine] pub upgrade --major-versions [options]
  puby reset              puby clean && puby get
  puby exec [command]     command

Options:
  --no-fvm                Disable FVM support''';

void main(List<String> arguments) async {
  final stopwatch = Stopwatch()..start();

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
    print(magentaPen(help));
    exit(1);
  }

  print('Finding projects...');
  final projects = findProjects();
  if (projects.isEmpty) {
    print(redPen('No projects found in the current directory'));
    exit(1);
  }

  final firstArg = arguments.first;

  final commands = <Command>[];
  if (firstArg == 'exec') {
    commands.add(Command((engineArgs) => arguments.sublist(1)));
  } else if (firstArg == 'link') {
    await linkDependencies(projects);
    commands.add(link);
  } else if (convenienceCommands.containsKey(firstArg)) {
    for (final command in convenienceCommands[firstArg]!) {
      command.add(arguments.sublist(1));
      commands.add(command);
    }
  } else {
    commands.add(Command((engineArgs) => [...engineArgs, 'pub', ...arguments]));
  }

  var exitCode = 0;
  for (final command in commands) {
    exitCode |= await runInAllProjects(projects, command);
  }

  stopwatch.stop();
  final time = stopwatch.prettyPrint();

  if (exitCode == 0) {
    print(greenPen('\nAll commands succeeded ($time)'));
  } else {
    print(redPen('\nOne or more commands failed ($time)'));
  }

  exit(exitCode);
}

Future<int> runInAllProjects(List<Project> projects, Command command) async {
  var exitCode = 0;
  final failures = <String>[];

  Future<void> run(Project project) async {
    final processExitCode = await runInProject(
      project: project,
      projectCount: projects.length,
      command: command,
    );

    if (processExitCode != 0) {
      failures.add(project.path);
    }

    // Combine exit codes
    exitCode |= processExitCode;
  }

  if (command.parallel) {
    final queue = TaskQueue();
    for (final project in projects) {
      unawaited(queue.add(() => run(project)));
    }
    await queue.tasksComplete;
  } else {
    for (final project in projects) {
      await run(project);
    }
  }

  if (exitCode != 0) {
    print(redPen('\nFailures:'));
    for (final failure in failures) {
      print(redPen('  $failure'));
    }
  }

  return exitCode;
}

Future<int> runInProject({
  required Project project,
  required int projectCount,
  required Command command,
}) async {
  final stopwatch = Stopwatch()..start();

  // Fvm is a layer on top of flutter, so don't add the prefix args for these checks
  if (explicitExclude(project, command) ||
      defaultExclude(project, projectCount, command)) {
    return 0;
  }

  final engine = resolveEngine(project, command);
  final finalArgs = command.build(engine);

  final argString = finalArgs.join(' ');
  final pathString = project.path == '.' ? 'current directory' : project.path;
  if (!command.silent) {
    print(greenPen('\nRunning "$argString" in $pathString...'));
  }

  final process = await Process.start(
    finalArgs.first,
    finalArgs.sublist(1),
    workingDirectory: project.path,
    runInShell: true,
  );

  // Piping directly to stdout and stderr can cause unexpected behavior
  var killed = false;
  final err = <String>[];
  final stdoutFuture = process.stdout
      .takeWhile((_) => !killed)
      .map(decoder.convert)
      .listen((line) {
    if (!command.silent) {
      stdout.write(line);
    }
    if (shouldKill(project, line)) {
      killed = process.kill();
    }
  }).asFuture();
  final stderrFuture = process.stderr
      .takeWhile((_) => !killed)
      .map(decoder.convert)
      .listen((line) {
    if (!command.silent) {
      stderr.write(redPen(line));
    }
    err.add(line);
  }).asFuture();

  final processExitCode = await process.exitCode;

  // If we do not wait for these streams to finish, output could end up
  // out of order
  await Future.wait([stdoutFuture, stderrFuture]);

  stopwatch.stop();
  // Skip error handling if the command was successful
  if (processExitCode == 0) {
    print(
      greenPen(
        'Ran "$argString" in $pathString (${stopwatch.prettyPrint()})',
      ),
    );

    return processExitCode;
  }

  if (err.any(
    (e) => e.contains(
      'Flutter users should run `flutter pub get` instead of `dart pub get`.',
    ),
  )) {
    // If a project doesn't explicitly depend on flutter, it is not possible
    // to know if it's dependencies require flutter. So retry if that's the
    // reason for failure.
    print(yellowPen('\nRetrying with "flutter" engine'));
    return runInProject(
      project: project.copyWith(engine: Engine.flutter),
      projectCount: projectCount,
      command: command,
    );
  }

  final unknownSubcommandMatch =
      RegExp(r'Could not find a subcommand named "(.+?)" for ".+? pub"\.')
          .firstMatch(err.join('\n'));
  if (unknownSubcommandMatch != null) {
    // Do not attempt to run in other projects if the command is unknown
    print(redPen('\nUnknown command: ${unknownSubcommandMatch[1]}'));
    exit(1);
  }

  return processExitCode;
}

/// Check if we should continue after this line is received
bool shouldKill(Project project, String line) {
  if (project.engine == Engine.fvm) {
    final flutterVersionNotInstalledMatch =
        RegExp(r'Flutter "(.+?)" is not installed\.').firstMatch(line);
    if (flutterVersionNotInstalledMatch != null) {
      // FVM will ask for input from the user, kill the process to avoid
      // hanging
      print(
        redPen(
          '\nRun `fvm install ${flutterVersionNotInstalledMatch[1]}` first',
        ),
      );
      return true;
    }
  }
  return false;
}

Engine resolveEngine(Project project, Command command) {
  final args = command.build(Engine.none);

  final Engine? engine;
  final String? message;
  if (args[0] == 'clean') {
    engine = Engine.flutter;
    message = 'Overriding engine to "flutter" for "clean" command';
  } else if (args.length >= 2 && args[0] == 'test' && args[1] == '--coverage') {
    engine = Engine.flutter;
    message = 'Overriding engine to "flutter" for "test --coverage" command';
  } else if (project.engine == Engine.fvm && command.noFvm) {
    engine = Engine.flutter;
    message = 'Project uses FVM, but FVM support is disabled: ${project.path}';
  } else {
    engine = project.engine;
    message = null;
  }

  if (message != null && !command.silent) {
    print(yellowPen(message));
  }
  return engine;
}

bool defaultExclude(Project project, int projectCount, Command command) {
  final args = command.build(Engine.none);

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

  if (message != null && !command.silent) {
    print(yellowPen('\n$message'));
  }
  return skip;
}

bool explicitExclude(Project project, Command command) {
  final argString = command.build(Engine.none).join(' ');

  final skip = project.config.excludes.any(argString.startsWith);
  if (skip && !command.silent) {
    print(yellowPen('\nSkipping project with exclusion: ${project.path}'));
  }

  return skip;
}

List<Project> findProjects() {
  final entities =
      Directory.current.listSync(recursive: true, followLinks: false);

  final pubspecEntities =
      entities.whereType<File>().where((e) => e.path.endsWith('pubspec.yaml'));
  final fvmPaths = entities
      .whereType<Directory>()
      .where((e) => e.path.endsWith('.fvm'))
      .map((e) => e.parent.path)
      .toList();

  final projects = <Project>[];
  for (final pubspecEntity in pubspecEntities) {
    final project = Project.fromPubspec(
      pubspecFile: pubspecEntity,
      fvmPaths: fvmPaths,
    );
    projects.add(project);
  }
  return projects;
}
