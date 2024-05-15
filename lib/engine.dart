/// The engine the code uses
enum Engine {
  /// Dart
  dart,

  /// Flutter
  flutter,

  /// FVM
  fvm;

  /// If the engine uses flutter directly or transitively
  bool get isFlutter => {flutter, fvm}.contains(this);

  /// The arguments required to call the engine
  List<String> get prefixArgs {
    switch (this) {
      case Engine.dart:
      case Engine.flutter:
        return [name];
      case Engine.fvm:
        return ['fvm', 'flutter'];
    }
  }

  /// The arguments that should be appended to the command
  List<String> get suffixArgs {
    switch (this) {
      case Engine.dart:
      case Engine.flutter:
        return [];
      case Engine.fvm:
        return ['--fvm-skip-input'];
    }
  }
}
