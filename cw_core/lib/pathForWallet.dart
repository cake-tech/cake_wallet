import 'dart:io';
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:path/path.dart' as p;

Future<String> pathForWalletTypeDir({required WalletType type}) async {
  final root = await getAppDir();
  final prefix = walletTypeToString(type).toLowerCase();
  final walletsDir = Directory('${root.path}/wallets');
  final walletDir = Directory('${walletsDir.path}/$prefix');

  if (!walletDir.existsSync()) {
    walletDir.createSync(recursive: true);
  }

  return walletDir.path;
}

Future<String> pathForWalletDir({required String name, required WalletType type}) async {
  final typeRoot = await pathForWalletTypeDir(type: type);
  final walletDire = Directory('${typeRoot}/$name');

  if (!walletDire.existsSync()) {
    walletDire.createSync(recursive: true);
  }

  return walletDire.path;
}

Future<String> pathForWallet({required String name, required WalletType type}) async =>
    await pathForWalletDir(name: name, type: type).then((path) => path + '/$name');

Future<String> outdatedAndroidPathForWalletDir({required String name}) async {
  final directory = await getAppDir();
  final pathDir = directory.path + '/$name';

  return pathDir;
}

Future<void> copyWalletFilesTo({
  required String fromName,
  required String toName,
  required WalletType type,
}) async {
  if (fromName == toName) return;

  final typeRoot = await pathForWalletTypeDir(type: type);
  final sourceDir = Directory(p.join(typeRoot, fromName));
  if (!sourceDir.existsSync()) {
    throw "Source wallet not found: $fromName $type";
  }

  if (Directory(p.join(typeRoot, toName)).existsSync()) {
    throw Exception('Cannot rename wallet: "$toName" already exists');
  }

  final destinationDir = Directory(p.join(typeRoot, toName));
  await _copyDirectory(sourceDir, destinationDir);

  for (final suffix in const ['', '.keys', '.keys.backup']) {
    final file = File(p.join(destinationDir.path, '$fromName$suffix'));
    if (file.existsSync()) {
      await file.rename(p.join(destinationDir.path, '$toName$suffix'));
    }
  }
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(followLinks: false)) {
    final name = p.basename(entity.path);
    if (entity is File) {
      await entity.copy(p.join(destination.path, name));
    } else if (entity is Directory) {
      await _copyDirectory(entity, Directory(p.join(destination.path, name)));
    }
  }
}
