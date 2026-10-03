import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:cake_backup/backup.dart" as cwb;
import "package:cw_core/db/sqlite.dart";
import "package:sqflite/sqflite.dart";

class DeprecatedWalletSeeds {
  DeprecatedWalletSeeds({required this.walletInfoId, required this.seed, this.passphrase});

  Future<void> save(String password) async => db!.insert(
        tableName,
        {
          "walletInfoId": walletInfoId,
          "seed": await _encrypt(seed, password),
          "passphrase": await _encrypt(passphrase ?? "", password),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  static const tableName = "DeprecatedWalletSeeds";

  final int walletInfoId;
  final String seed;
  final String? passphrase;

  static Future<DeprecatedWalletSeeds?> get(int walletInfoId, String password) async {
    final row = (await db!.query(
      tableName,
      where: "walletInfoId = ?",
      whereArgs: [walletInfoId],
    ))
        .firstOrNull;
    if (row == null) {
      return null;
    }

    final passphrase = await _decrypt(row["passphrase"] as String, password);
    return DeprecatedWalletSeeds(
      walletInfoId: walletInfoId,
      seed: await _decrypt(row["seed"] as String, password),
      passphrase: passphrase.isEmpty ? null : passphrase,
    );
  }

  static Future<void> delete(int walletInfoId) =>
      db!.delete(tableName, where: "walletInfoId = ?", whereArgs: [walletInfoId]);

  static Future<String> _encrypt(String data, String password) async => base64.encode(
        await cwb.encrypt(
          password,
          Uint8List.fromList(utf8.encode(data)),
          highEntropyPassphrase: !Platform.isLinux,
        ),
      );

  static Future<String> _decrypt(String data, String password) async =>
      utf8.decode(await cwb.decrypt(password, base64.decode(data)));
}
