import 'dart:convert';

import 'package:cw_core/utils/file.dart';

mixin WalletKeysFile {
  // this needs to be overridden
  Future<String> makePath() => throw UnimplementedError();

  // this needs to be overridden
  WalletKeysData get walletKeysData => throw UnimplementedError();

  Future<String> makeKeysFilePath() async => "${await makePath()}.keys";

  Future<void> saveKeysFile(String password, [bool isBackup = false]) async {
    final rootPath = await makeKeysFilePath();
    final path = "$rootPath${isBackup ? ".backup" : ""}";
    print("Saving .keys file '$path'");
    await write(path: path, password: password, data: walletKeysData.toJSON());
  }
}

class WalletKeysData {
  final String? privateKey;
  final String? mnemonic;
  final String? altMnemonic;
  final String? xPub;

  WalletKeysData({this.privateKey, this.mnemonic, this.altMnemonic, this.xPub});

  String toJSON() => jsonEncode({
        "privateKey": privateKey,
        "mnemonic": mnemonic,
        if (altMnemonic != null) "altMnemonic": altMnemonic,
        if (xPub != null) "xPub": xPub
      });
}
