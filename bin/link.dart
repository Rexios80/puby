import 'dart:async';

import 'package:flutter_tools_task_queue/flutter_tools_task_queue.dart';
import 'package:puby/command.dart';
import 'package:puby/pens.dart';
import 'package:puby/project.dart';
import 'package:puby/pub.dart';
import 'package:puby/time.dart';

import 'commands.dart';
import 'projects.dart';

final _pubCache = SystemCache();

Future<int> linkDependencies({
  required GlobalCommand command,
  required List<Project> projects,
}) async {
  final resolutionStopwatch = Stopwatch()..start();
  print('Resolving all dependencies...');
  final dependencies = <PackageId>{};
  final resolutionQueue = TaskQueue();
  for (final project in projects) {
    unawaited(
      resolutionQueue.add(() async {
        final resolved = project.resolveWithCommand(Commands.pubGetOffline);
        if (resolved.exclude) return;

        final flutterVersionOverride =
            await resolved.getFlutterVersionOverride(Commands.pubGetOffline);

        final entry = Entrypoint(resolved.path, _pubCache);
        try {
          final result = await resolveVersions(
            SolveType.get,
            _pubCache,
            entry.workspaceRoot,
            sdkOverrides: {
              if (flutterVersionOverride != null)
                'flutter': flutterVersionOverride,
            },
          );
          dependencies.addAll(result.packages);
          print('Resolved dependencies for ${resolved.path}');
        } catch (e) {
          print(redPen('Failed to resolve dependencies for ${resolved.path}'));
          print(redPen(e));
        }
      }),
    );
  }
  await resolutionQueue.tasksComplete;
  print(
    greenPen(
      'Resolved all dependencies in ${resolutionStopwatch.prettyPrint()}',
    ),
  );

  final downloadStopwatch = Stopwatch()..start();
  print('\nDownloading packages...');
  final downloadQueue = TaskQueue();
  for (final package in dependencies) {
    if (package.description.description.source is! CachedSource) continue;
    unawaited(
      downloadQueue.add(() async {
        try {
          final result = await _pubCache.downloadPackage(package);
          if (result.didUpdate) {
            print('Downloaded ${package.name} ${package.version}');
          }
        } catch (e) {
          print(
            redPen('Failed to download ${package.name} ${package.version}'),
          );
          print(redPen(e));
        }
      }),
    );
  }
  await downloadQueue.tasksComplete;
  print(
    greenPen('Downloaded all packages in ${downloadStopwatch.prettyPrint()}\n'),
  );

  // Stop all stopwatches
  resolutionStopwatch.stop();
  downloadStopwatch.stop();

  return 0;
}
