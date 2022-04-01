import 'dart:io';

import 'package:yaml/yaml.dart';

class PubyConfig {
  final List<String> excludes;

  PubyConfig._({
    required this.excludes,
  });

  PubyConfig.empty() : this._(excludes: []);

  factory PubyConfig.fromProjectPath(String path) {
    final file = File('$path/puby.yaml');
    if (!file.existsSync()) {
      return PubyConfig.empty();
    }

    final yaml = loadYaml(file.readAsStringSync());
    final excludes = (yaml['exclude'] as List?)?.cast<String>() ?? [];

    return PubyConfig._(excludes: excludes);
  }
}
