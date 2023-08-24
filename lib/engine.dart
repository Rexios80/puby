/// The engine the code uses
enum Engine {
  /// No engine
  none,

  /// Dart
  dart,

  /// Flutter
  flutter,

  /// FVM
  fvm;

  /// If the engine uses flutter directly or transitively
  bool get isFlutter => this == Engine.flutter || this == Engine.fvm;

  /// The arguments used to call the engine
  List<String> get args {
    switch (this) {
      case Engine.none:
        return [];
      case Engine.dart:
      case Engine.flutter:
        return [name];
      case Engine.fvm:
        return [name, 'flutter'];
    }
  }
}
