import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:puby/pens.dart';

final minFvmVersion = Version.parse('3.2.0');

Future<void> fvmCheck() async {
  try {
    final fvmVersionResult = await Process.run('fvm', ['--version']);
    final fvmVersion = Version.parse(fvmVersionResult.stdout.toString().trim());
    if (fvmVersion < minFvmVersion) {
      print(
        yellowPen(
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
      redPen(
        '''
FVM is not installed
Commands in projects configured with FVM will fail
''',
      ),
    );
  }
}
