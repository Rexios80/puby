import 'dart:io';

Future<bool> fvmInstalled() async {
  try {
    await Process.run('fvm', []);
    return true;
  } catch (e) {
    return false;
  }
}
