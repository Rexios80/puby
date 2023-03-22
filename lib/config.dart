import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// A puby configuration file
class PubyConfig {
  /// Specified command exclusions
  final List<String> excludes;

  PubyConfig._({
    required this.excludes,
  });

  /// Create an empty puby config
  PubyConfig.empty() : this._(excludes: []);

  /// Create a puby config from a project path
  factory PubyConfig.fromProjectPath(String path) {
    final file = File(p.join(path, 'puby.yaml'));
    if (!file.existsSync()) {
      return PubyConfig.empty();
    }

    final yaml = loadYaml(file.readAsStringSync());
    final excludes = (yaml['exclude'] as List?)?.cast<String>() ?? [];

    return PubyConfig._(excludes: excludes);
  }
}
