import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:cw_core/balance.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';

mixin WalletKeysFile<BalanceType extends Balance, HistoryType extends TransactionHistoryBase,
        TransactionType extends TransactionInfo>
    on WalletBase<BalanceType, HistoryType, TransactionType> {
  Future<String> makePath() => pathForWallet(name: walletInfo.name, type: walletInfo.type);

  // this needs to be overridden
  WalletKeysData get walletKeysData;

  Future<String> makeKeysFilePath() async => "${await makePath()}.keys";

  Future<void> saveKeysFile(String password, EncryptionFileUtils encryptionFileUtils,
      [bool isBackup = false]) async {
    try {
      final rootPath = await makeKeysFilePath();
      final path = "$rootPath${isBackup ? ".backup" : ""}";
      dev.log("Saving .keys file '$path'");
      await encryptionFileUtils.write(
          path: path, password: password, data: walletKeysData.toJSON());
    } catch (_) {}
  }

  static Future<void> createKeysFile(String name, WalletType type, String password,
      WalletKeysData walletKeysData, EncryptionFileUtils encryptionFileUtils,
      [bool withBackup = true]) async {
    try {
      final rootPath = await pathForWallet(name: name, type: type);
      final path = "$rootPath.keys";

      dev.log("Saving .keys file '$path'");
      await encryptionFileUtils.write(
          path: path, password: password, data: walletKeysData.toJSON());

      if (withBackup) {
        dev.log("Saving .keys.backup file '$path.backup'");
        await encryptionFileUtils.write(
            path: "$path.backup", password: password, data: walletKeysData.toJSON());
      }
    } catch (_) {}
  }

  static Future<bool> hasKeysFile(String name, WalletType type) async {
    try {
      final path = await pathForWallet(name: name, type: type);
      return File("$path.keys").existsSync() || File("$path.keys.backup").existsSync();
    } catch (_) {
      return false;
    }
  }

  static Future<WalletKeysData> readKeysFile(
    String name,
    WalletType type,
    String password,
    EncryptionFileUtils encryptionFileUtils,
  ) async {
    final path = await pathForWallet(name: name, type: type);

    var readPath = "$path.keys";
    try {
      if (!File(readPath).existsSync()) throw Exception("No .keys file found for $name $type");

      final jsonSource = await encryptionFileUtils.read(path: readPath, password: password);
      final data = json.decode(jsonSource) as Map<String, dynamic>;
      return WalletKeysData.fromJSON(data);
    } catch (e) {
      dev.log("Failed to read .keys file. Trying .keys.backup file...");

      readPath = "$readPath.backup";
      if (!File(readPath).existsSync())
        throw Exception("No .keys nor a .keys.backup file found for $name $type");

      final jsonSource = await encryptionFileUtils.read(path: readPath, password: password);
      final data = json.decode(jsonSource) as Map<String, dynamic>;
      final keysData = WalletKeysData.fromJSON(data);

      dev.log("Restoring .keys from .keys.backup");
      createKeysFile(name, type, password, keysData, encryptionFileUtils, false);
      return keysData;
    }
  }
}

class WalletKeysData {
  final String? privateKey;
  final String? mnemonic;
  final String? altMnemonic;
  final String? passphrase;
  final String? xPub;
  final String? scanSecret;
  final String? spendPubkey;

  WalletKeysData({this.privateKey, this.mnemonic, this.altMnemonic, this.passphrase, this.xPub, this.scanSecret, this.spendPubkey});

  String toJSON() => jsonEncode({
        "privateKey": privateKey,
        "mnemonic": mnemonic,
        if (altMnemonic != null) "altMnemonic": altMnemonic,
        if (passphrase != null) "passphrase": passphrase,
        if (xPub != null) "xPub": xPub,
        if (scanSecret != null) "scanSecret": scanSecret,
        if (spendPubkey != null) "spendPubkey": spendPubkey,
      });

  static WalletKeysData fromJSON(Map<String, dynamic> json) => WalletKeysData(
        privateKey: json["privateKey"] as String?,
        mnemonic: json["mnemonic"] as String?,
        altMnemonic: json["altMnemonic"] as String?,
        passphrase: json["passphrase"] as String?,
        xPub: json["xPub"] as String?,
        scanSecret: json["scanSecret"] as String?,
        spendPubkey: json["spendPubkey"] as String?,
      );
}
