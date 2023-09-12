import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Checkpoints {
  static const String _baseDirSuffix = '/checkpoints';

  static void createCheckpoint(String checkpointId) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final file = File('${appDocDir.path}$_baseDirSuffix/${checkpointId}_${DateTime.now()}');

    file.create(recursive: true);
  }

  static Future<Iterable<String>> getCheckpoints() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final checkpointsDir = Directory('${appDocDir.path}$_baseDirSuffix');

    if (!checkpointsDir.existsSync()) return ["No checkpoints available"];

    return checkpointsDir.listSync().map((e) => e.path.split('/').last);
  }
}
