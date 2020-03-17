import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<String> pathForWallet({String name}) async {
  final directory = await getApplicationDocumentsDirectory();
  final pathDir = directory.path + '/$name';
  final dir = Directory(pathDir);

  if (!await dir.exists()) {
    await dir.create();
  }

  return pathDir + '/$name';
}