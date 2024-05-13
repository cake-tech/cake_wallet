import 'dart:io';
import 'package:path_provider/path_provider.dart';

String? _rootDirPath;

void setRootDirFromEnv() => _rootDirPath = Platform.environment['CAKE_WALLET_DIR'];

Future<Directory> getAppDir({String appName = 'cake_wallet'}) async {
  Directory dir;

  if (_rootDirPath != null && _rootDirPath!.isNotEmpty) {
    dir = Directory.fromUri(Uri.file(_rootDirPath!));
    dir.create(recursive: true);
  } else {
    dir = await getApplicationDocumentsDirectory();

    if (Platform.isWindows) {
      dir = await getApplicationSupportDirectory();
    } else if (Platform.isLinux) {
      final appDirPath = '${dir.path}/$appName';
      dir = Directory.fromUri(Uri.file(appDirPath));
      await dir.create(recursive: true);
    }
  }

  return dir;
}
