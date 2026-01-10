import 'dart:io';
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/wallet_type.dart';

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
    await pathForWalletDir(name: name, type: type)
        .then((path) => path + '/$name');

Future<String> outdatedAndroidPathForWalletDir({required String name}) async {
  final directory = await getAppDir();
  final pathDir = directory.path + '/$name';

  return pathDir;
}
