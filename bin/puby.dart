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

import 'commands.dart';
import 'link.dart';
import 'projects.dart';

const decoder = Utf8Decoder();

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
  final newVersion = await PubUpdateChecker.check();
  if (newVersion != null) {
    print(
      yellowPen(
        'There is an update available: $newVersion. Run `dart pub global activate puby` to update.',
      ),
    );
  }

  final showHelp = arguments.isEmpty ||
      arguments.first == '-h' ||
      arguments.first == '--help';

  if (showHelp) {
    print(magentaPen(help));
    exit(1);
  }

  print('Finding projects...');
  final projects = findProjects();
  if (projects.isEmpty) {
    print(redPen('No projects found in the current directory'));
    exit(1);
  }

  print(greenPen('Found ${projects.length} projects'));

  final firstArg = arguments.first;

  final commands = <Command>[];
  if (firstArg == 'exec') {
    commands.add(Command(arguments.sublist(1), raw: true));
  } else if (firstArg == 'link') {
    await linkDependencies(projects);
    commands.add(
      Command(
        ['pub', 'get', '--offline', ...arguments.skip(1)],
        parallel: true,
      ),
    );
  } else if (Commands.convenience.containsKey(firstArg)) {
    for (final command in Commands.convenience[firstArg]!) {
      command.addArgs(arguments.sublist(1));
      commands.add(command);
    }
  } else {
    commands.add(Command(['pub', ...arguments]));
  }

  var exitCode = 0;
  for (final command in commands) {
    if (command.parallel) {
      print('Running "${command.args.join(' ')}" in parallel...');
    }
    exitCode |= await runInAllProjects(projects, command);
  }

  exit(exitCode);
}

Future<int> runInAllProjects(List<Project> projects, Command command) async {
  final stopwatch = Stopwatch()..start();

  var exitCode = 0;
  final failures = <String>[];

  Future<void> run(Project project) async {
    final processExitCode =
        await runInProject(project: project, command: command);

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

  stopwatch.stop();
  final time = stopwatch.prettyPrint();

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

Future<int> runInProject({
  required Project project,
  required Command command,
}) async {
  final stopwatch = Stopwatch()..start();

  final resolved = project.resolveWithCommand(command);
  if (resolved.exclude) return 0;

  final finalArgs = [
    if (!command.raw) ...resolved.engine.args,
    ...command.args,
  ];

  final argString = finalArgs.join(' ');
  final pathString = resolved.path == '.' ? 'current directory' : resolved.path;
  if (!command.silent) {
    print(greenPen('\nRunning "$argString" in $pathString...'));
  }

  final process = await Process.start(
    finalArgs.first,
    finalArgs.sublist(1),
    workingDirectory: resolved.path,
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
    if (!command.raw && shouldKill(resolved, line)) {
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
  // Skip error handling if the command was successful or this is a raw command
  if (command.raw || processExitCode == 0) {
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
      project: resolved.copyWith(engine: Engine.flutter),
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
        RegExp(r'Flutter SDK: SDK Version : (.+?) is not installed\.')
            .firstMatch(line);
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
