import 'dart:async';
import 'dart:io';

import 'package:flutter_tools_task_queue/flutter_tools_task_queue.dart';
import 'package:pub_update_checker/pub_update_checker.dart';
import 'package:puby/command.dart';
import 'package:puby/pens.dart';
import 'package:puby/project.dart';
import 'package:puby/time.dart';

import 'commands.dart';
import 'projects.dart';

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

  print(greenPen('Found ${projects.length} projects\n'));

  final firstArg = arguments.first;
  final convenienceCommand = Commands.convenience[firstArg];

  final commands = <Command>[];
  if (firstArg == 'exec') {
    commands.add(ProjectCommand(arguments.sublist(1), raw: true));
  } else if (convenienceCommand != null) {
    for (final command in convenienceCommand) {
      command.addArgs(arguments.sublist(1));
      commands.add(command);
    }
  } else {
    commands.add(ProjectCommand(['pub', ...arguments]));
  }

  var exitCode = 0;
  for (final command in commands) {
    if (command is ProjectCommand) {
      exitCode |= await runInAllProjects(projects, command);
    } else if (command is GlobalCommand) {
      exitCode |= await command.run(projects: projects);
    }
  }

  exit(exitCode);
}

Future<int> runInAllProjects(
  List<Project> projects,
  ProjectCommand command,
) async {
  final stopwatch = Stopwatch()..start();

  if (command.parallel) {
    print('Running "${command.args.join(' ')}" in parallel...');
  }

  var exitCode = 0;
  final failures = <String>[];

  Future<void> run(Project project) async {
    final processExitCode = await command.runInProject(project);

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
    print('');
  } else {
    for (final project in projects) {
      await run(project);
      print('');
    }
  }

  stopwatch.stop();
  final time = stopwatch.prettyPrint();

  if (exitCode != 0) {
    print(redPen('One or more commands failed ($time)'));
    print(redPen('Failures:'));
    for (final failure in failures) {
      print(redPen('  $failure'));
    }
  } else {
    print(greenPen('All commands succeeded ($time)'));
  }

  print('');

  return exitCode;
}
