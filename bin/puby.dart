import 'dart:async';
import 'dart:io';

import 'package:flutter_tools_task_queue/flutter_tools_task_queue.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pub_update_checker/pub_update_checker.dart';
import 'package:puby/command.dart';
import 'package:puby/pens.dart';
import 'package:puby/project.dart';
import 'package:puby/time.dart';

import 'commands.dart';
import 'projects.dart';

const help = '''
Commands:
  puby [args]            [engine] pub [args]
  puby link              Warm the pub cache and run [engine] pub get --offline
  puby gen               [engine] pub run build_runner build --delete-conflicting-outputs
  puby test              [engine] test
  puby clean             flutter clean
  puby mup               [engine] pub upgrade --major-versions
  puby reset             puby clean && puby get
  puby relink            puby clean && puby link
  puby exec [command]    command

Options:
  --no-fvm                Disable FVM support''';

final minFvmVersion = Version.parse('3.2.0');

void main(List<String> arguments) async {
  final newVersion = await PubUpdateChecker.check();
  if (newVersion != null) {
    print(
      yellowPen(
        'There is an update available: $newVersion. Run `dart pub global activate puby` to update.',
      ),
    );
  }

  final fvmVersionResult = await Process.run('fvm', ['--version']);
  final fvmInstalled = fvmVersionResult.exitCode == 0;
  if (!fvmInstalled) {
    print(
      yellowPen(
        '''
FVM is not installed
Commands in projects configured with FVM will fail''',
      ),
    );
  } else {
    final fvmVersion = Version.parse(fvmVersionResult.stdout.toString().trim());
    if (fvmVersion < minFvmVersion) {
      print(
        yellowPen(
          '''
This version of puby expects FVM version $minFvmVersion or higher
FVM version $fvmVersion is installed
Commands in projects configured with FVM may fail''',
        ),
      );
    }
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
    print('Running "${command.args.join(' ')}" in parallel...');

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
