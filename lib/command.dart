/// A command and it's properties
class Command {
  final _args = <String>[];

  /// The command to run
  List<String> get args => List.unmodifiable(_args);

  /// Whether to run the command as is
  final bool raw;

  /// Whether to run the command in all projects in parallel
  final bool parallel;

  /// Whether to run the command silently
  ///
  /// Right now this is the same as [parallel]
  bool get silent => parallel;

  bool _noFvm = false;

  /// If fvm support should be disabled
  bool get noFvm => _noFvm;

  /// If this command should be run only in the current working directory
  final bool global;

  /// Constructor
  Command(
    List<String> args, {
    this.raw = false,
    this.parallel = false,
    this.global = false,
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
