import 'dart:io';

import 'package:io/io.dart';
import 'package:puby/command.dart';
import 'package:io/ansi.dart';
import 'package:puby/project.dart';
import 'package:puby/time.dart';

import 'link.dart';
import 'projects.dart';

abstract class Commands {
  static final clean = ProjectCommand(['clean'], parallel: true);
  static final link = GlobalCommand(
    ['link'],
    (command, projects) =>
        linkDependencies(command: command, projects: projects),
  );
  static final pubGetOffline =
      ProjectCommand(['pub', 'get', '--offline'], parallel: true);

  static final convenience = <String, List<Command>>{
    'gen': [
      ProjectCommand([
        'pub',
        'run',
        'build_runner',
        'build',
        '--delete-conflicting-outputs',
      ]),
    ],
    'test': [
      ProjectCommand(['test']),
    ],
    'clean': [
      clean,
    ],
    'mup': [
      ProjectCommand(['pub', 'upgrade', '--major-versions']),
    ],
    'reset': [
      clean,
      ProjectCommand(['pub', 'get']),
    ],
    'link': [
      link,
      pubGetOffline,
    ],
    'relink': [
      clean,
      link,
      pubGetOffline,
    ],
  };
}

extension ProjectCommandExtension on ProjectCommand {
  Future<int> runInProject(Project project) async {
    final stopwatch = Stopwatch()..start();

    final resolved = project.resolveWithCommand(this);
    if (resolved.exclude) return 0;

    final finalArgs = [
      if (!raw) ...resolved.engine.prefixArgs,
      ...args,
      if (!raw) ...resolved.engine.suffixArgs,
    ];

    final argString = finalArgs.join(' ');
    final pathString =
        resolved.path == '.' ? 'current directory' : resolved.path;
    if (!silent) {
      print(green.wrap('Running "$argString" in $pathString...'));
    }

    final process = await Process.start(
      finalArgs.first,
      finalArgs.sublist(1),
      workingDirectory: resolved.path,
      runInShell: true,
      mode: silent ? ProcessStartMode.detached : ProcessStartMode.inheritStdio,
    );

    final exitCode = await process.exitCode;

    stopwatch.stop();

    // Skip error handling if the command was successful or this is a raw command
    if (raw || exitCode == 0) {
      print(
        green.wrap(
          'Ran "$argString" in $pathString (${stopwatch.prettyPrint()})',
        ),
      );
    } else if (exitCode == ExitCode.usage.code) {
      // Do not attempt to run in other projects if the command is unknown
      print(red.wrap('Unknown command. Exiting...'));
      exit(exitCode);
    }

    return exitCode;
  }
}
