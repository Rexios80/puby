import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter_tools_task_queue/flutter_tools_task_queue.dart';
import 'package:path/path.dart' as p;
import 'package:puby/dependency.dart';
import 'package:puby/pens.dart';
import 'package:puby/project.dart';
import 'package:puby/time.dart';
import 'package:yaml/yaml.dart';

final homeDirectory =
    Platform.environment['HOME'] ?? Platform.environment['USERPROFILE']!;

final pubCacheDirectory = Platform.environment['PUB_CACHE'] ??
    (Platform.isWindows
        ? r'%LOCALAPPDATA%\Pub\Cache'
        : '$homeDirectory/.pub-cache');

Future<void> linkDependencies(List<Project> projects) async {
  final stopwatch = Stopwatch()..start();
  print('Warming cache...');

  final lockFiles = projects.map((e) => File(p.join(e.path, 'pubspec.lock')));
  final locked = <String, Set<LockedDependency>>{};
  for (final lockFile in lockFiles) {
    if (!lockFile.existsSync()) {
      print(
        redPen(
          'No pubspec.lock found in ${lockFile.path}. Unable to link dependencies',
        ),
      );
      continue;
    }
    final lockContent = lockFile.readAsStringSync();
    final yaml = loadYaml(lockContent);
    final packages = yaml['packages'] as YamlMap;
    for (final package in packages.keys) {
      final lock = LockedDependency.fromJson(Map.from(packages[package]));
      if (lock == null) continue;
      locked.update(
        package,
        (value) => value..add(lock),
        ifAbsent: () => {lock},
      );
    }
  }

  final hostedCache = _readHostedCache();

  final missing = <LockedDependency>{};
  for (final package in locked.keys) {
    final locks = locked[package]!;
    for (final lock in locks) {
      final name = '$package-${lock.version}';
      if (!(hostedCache[lock.url]?.contains(name) ?? false)) {
        missing.add(lock);
      }
    }
  }

  if (missing.isEmpty) {
    print('No missing dependencies');
  } else {
    print('Caching ${missing.length} missing dependencies...');
  }

  final queue = TaskQueue();
  for (final lock in missing) {
    unawaited(
      queue.add(() async {
        final result = await Process.run(
          'dart',
          ['pub', 'cache', 'add', lock.name, '--version', lock.version],
        );

        if (result.exitCode != 0) {
          print(redPen(result.stderr));
        }
      }),
    );
  }
  await queue.tasksComplete;

  stopwatch.stop();
  print(greenPen('Cache warmed in ${stopwatch.prettyPrint()}\n'));
}

Map<String, HashSet<String>> _readHostedCache() {
  final hosted = Directory(p.join(pubCacheDirectory, 'hosted'));
  if (!hosted.existsSync()) return {};

  final packages = <String, HashSet<String>>{};

  final urls = hosted.listSync().whereType<Directory>();
  for (final url in urls) {
    packages[p.basename(url.path)] = HashSet.from(
      Directory(url.path)
          .listSync()
          .whereType<Directory>()
          .map((e) => p.basename(e.path)),
    );
  }

  return packages;
}
