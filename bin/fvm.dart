import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:io/ansi.dart';

final minFvmVersion = Version.parse('3.2.1');

Future<void> fvmCheck() async {
  try {
    final fvmVersionResult = await Process.run('fvm', ['--version']);
    final fvmVersion = Version.parse(fvmVersionResult.stdout.toString().trim());
    if (fvmVersion < minFvmVersion) {
      print(
        yellow.wrap(
          '''
This version of puby expects FVM version $minFvmVersion or higher
FVM version $fvmVersion is installed
Commands in projects configured with FVM may fail
''',
        ),
      );
    }
  } catch (e) {
    print(
      red.wrap(
        '''
FVM is not installed
Commands in projects configured with FVM will fail
''',
      ),
    );
  }
}
