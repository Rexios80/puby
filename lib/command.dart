/// A command and it's properties
class Command {
  final _args = <String>[];

  /// The command to run
  List<String> get args => List.unmodifiable(_args);

  /// Whether to run the command as is
  final bool raw;

  /// Whether to run the command in parallel
  final bool parallel;

  /// Whether to run the command silently
  final bool silent;

  bool _noFvm = false;

  /// If fvm support should be disabled
  bool get noFvm => _noFvm;

  /// Constructor
  Command(
    List<String> args, {
    this.raw = false,
    this.parallel = false,
    this.silent = false,
  }) {
    addArgs(args);
  }

  /// Add arguments to the command
  ///
  /// Processes the arguments and sets the relevant fields
  /// - [--no-fvm]: disables fvm support
  void addArgs(List<String> args) {
    _noFvm = _noFvm || args.remove('--no-fvm');
    _args.addAll(args);
  }
}
