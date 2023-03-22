import 'package:equatable/equatable.dart';

/// Represents a locked pub dependency in a pubspec.lock file
class LockedDependency extends Equatable {
  /// The name of the dependency
  final String name;

  /// The version of the dependency
  final String version;

  /// The url of the dependency
  final String url;

  /// Constructor
  LockedDependency({
    required this.name,
    required this.version,
    required this.url,
  });

  /// From json
  static LockedDependency? fromJson(Map<String, dynamic> json) {
    final source = json['source'] as String;

    if (source == 'hosted') {
      final description = json['description'];
      if (description is! Map) return null;
      final name = description['name'] as String?;
      if (name == null) return null;
      final version = json['version'] as String;
      final url = (description['url'] as String).replaceAll('https://', '');

      return LockedDependency(name: name, version: version, url: url);
    } else {
      return null;
    }
  }

  @override
  List<Object?> get props => [name, version, url];
}
