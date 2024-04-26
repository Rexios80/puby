import 'package:puby/command.dart';

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
}
