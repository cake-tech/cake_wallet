import 'dart:convert';
import 'dart:io';

import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/utils/file.dart';
import 'package:cw_core/wallet_type.dart';

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

  static Future<void> createKeysFile(
      String name, WalletType type, String password, WalletKeysData walletKeysData) async {
    final rootPath = await pathForWallet(name: name, type: type);
    final path = "$rootPath.keys";

    print("Saving .keys file '$path'");
    await write(path: path, password: password, data: walletKeysData.toJSON());

    print("Saving .keys.backup file '$path.backup'");
    await write(path: "$path.backup", password: password, data: walletKeysData.toJSON());
  }

  static Future<bool> hasKeysFile(String name, WalletType type) async {
    final path = await pathForWallet(name: name, type: type);
    return File("$path.keys").existsSync();
  }

  static Future<WalletKeysData> readKeysFile(String name, WalletType type, String password) async {
    final path = await pathForWallet(name: name, type: type);

    if (!File("$path.keys").existsSync()) throw Exception("No .keys file found for $name $type");

    final jsonSource = await read(path: "$path.keys", password: password);
    final data = json.decode(jsonSource) as Map<String, dynamic>;
    return WalletKeysData.fromJSON(data);
  }
}

class WalletKeysData {
  final String? privateKey;
  final String? mnemonic;
  final String? altMnemonic;
  final String? passphrase;
  final String? xPub;

  WalletKeysData({this.privateKey, this.mnemonic, this.altMnemonic, this.passphrase, this.xPub});

  String toJSON() => jsonEncode({
        "privateKey": privateKey,
        "mnemonic": mnemonic,
        if (altMnemonic != null) "altMnemonic": altMnemonic,
        if (passphrase != null) "passphrase": passphrase,
        if (xPub != null) "xPub": xPub
      });

  static WalletKeysData fromJSON(Map<String, dynamic> json) => WalletKeysData(
        privateKey: json["privateKey"] as String?,
        mnemonic: json["mnemonic"] as String?,
        altMnemonic: json["altMnemonic"] as String?,
        passphrase: json["passphrase"] as String?,
        xPub: json["xPub"] as String?,
      );
}
