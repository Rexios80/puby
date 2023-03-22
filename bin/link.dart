import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:puby/dependency.dart';
import 'package:puby/pens.dart';
import 'package:puby/project.dart';
import 'package:yaml/yaml.dart';

final homeDirectory =
    Platform.environment['HOME'] ?? Platform.environment['USERPROFILE']!;

final pubCacheDirectory = Platform.environment['PUB_CACHE'] ??
    (Platform.isWindows
        ? r'%LOCALAPPDATA%\Pub\Cache'
        : '$homeDirectory/.pub-cache');

void linkDependencies(List<Project> projects) {
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
  final gitCache = _readGitCache();

  print(hostedCache);

  final missing = <LockedDependency>{};
  for (final package in locked.keys) {
    final locks = locked[package]!;
    for (final lock in locks) {
      if (lock is LockedGitDependency) {
        final name = '$package-${lock.resolvedRef}';
        if (!gitCache.contains(name)) {
          missing.add(lock);
        }
      } else {
        final name = '$package-${lock.version}';
        print(lock.url);
        print(hostedCache[lock.url]);
        if (!(hostedCache[lock.url]?.contains(name) ?? false)) {
          missing.add(lock);
        }
      }
    }
  }

  print(missing);

  for (final lock in missing) {
    final String constraint;
    if (lock is LockedGitDependency) {
      constraint =
          '${lock.name}:{"git":{"url":"${lock.url}","path":"${lock.path}","ref":"${lock.resolvedRef}"}}';
    } else {
      constraint = lock.version;
    }

    print('Caching ${lock.name}:$constraint...');
    final result = Process.runSync(
      'dart',
      ['pub', 'cache', 'add', lock.name, '--version', constraint],
    );

    if (result.exitCode != 0) {
      print(redPen(result.stderr));
    }
  }
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

HashSet<String> _readGitCache() {
  final git = Directory(p.join(pubCacheDirectory, 'git'));
  if (!git.existsSync()) return HashSet();

  return HashSet.from(
    git.listSync().whereType<Directory>().map((e) => p.basename(e.path)),
  );
}
