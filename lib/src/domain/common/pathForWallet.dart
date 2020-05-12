import 'dart:io';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<String> pathForWalletDir({@required String name, @required  WalletType type}) async {
  final root = await getApplicationDocumentsDirectory();
  final prefix = walletTypeToString(type).toLowerCase();
  final walletsDir = Directory('${root.path}/wallets');
  final walletDire = Directory('${walletsDir.path}/$prefix/$name');

  if (!walletDire.existsSync()) {
    walletDire.createSync(recursive: true);
  }

  return walletDire.path;
}

Future<String> pathForWallet({@required String name, @required WalletType type}) async =>
    await pathForWalletDir(name: name, type: type)
        .then((path) => path + '/$name');
