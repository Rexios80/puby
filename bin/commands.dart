import 'package:puby/command.dart';
import 'package:puby/engine.dart';
import 'package:puby/pens.dart';
import 'package:puby/project.dart';

abstract class Commands {
  static final clean = Command(['clean'], parallel: true);
  static final convenience = <String, List<Command>>{
    'gen': [
      Command([
        'pub',
        'run',
        'build_runner',
        'build',
        '--delete-conflicting-outputs',
      ]),
    ],
    'test': [
      Command(['test']),
    ],
    'clean': [
      clean,
    ],
    'mup': [
      Command(['pub', 'upgrade', '--major-versions']),
    ],
    'reset': [
      clean,
      Command(['pub', 'get']),
    ],
  };

  /// Check if we should continue after this line is received
  static bool shouldKill(Project project, Command command, String line) {
    if (project.engine == Engine.fvm) {
      final flutterVersionNotInstalledMatch =
          RegExp(r'Flutter SDK: SDK Version : (.+?) is not installed\.')
              .firstMatch(line);
      if (flutterVersionNotInstalledMatch != null) {
        // FVM will ask for input from the user, kill the process to avoid
        // hanging
        if (!command.silent) {
          print(
            redPen(
              'Run `fvm install ${flutterVersionNotInstalledMatch[1]}` first',
            ),
          );
        }
        return true;
      }
    }
    return false;
  }
}
