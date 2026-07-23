import 'dart:math';

import 'package:cw_core/get_height_by_date_zec.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_zcash/cw_zcash.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

class ZkoolSeed {
  ZkoolSeed({required this.seed, required this.passphrase});

  factory ZkoolSeed.fromYwalletSeed({required final String ywalletSeed}) {
    final splSeed = ywalletSeed.split(" ");
    String seed = "";
    ;
    String passphrase = "";
    if ([13, 25].contains(splSeed.length)) {
      seed = splSeed.take(splSeed.length - 1).join(" ");
      passphrase = ywalletSeed.replaceFirst("${seed} ", "");
    } else {
      seed = ywalletSeed;
    }
    return ZkoolSeed(seed: seed, passphrase: passphrase);
  }

  String seed;
  String passphrase;
}

class YwalletAccountInfo {
  YwalletAccountInfo({
    required this.idAccount,
    required this.name,
    required this.seed,
    required this.aindex,
    required this.sk,
    required this.ivk,
    required this.address,
  });
  final int idAccount;
  final String name;
  final String seed;
  late final zkoolSeed = ZkoolSeed.fromYwalletSeed(ywalletSeed: seed);
  final int aindex;
  final String sk;
  final String ivk;
  final String address;
  static YwalletAccountInfo fromJson(final Map<String, dynamic> j) => YwalletAccountInfo(
    idAccount: j['id_account'],
    name: j['name'],
    seed: j['seed'],
    aindex: j['aindex'],
    sk: j['sk'],
    ivk: j['ivk'],
    address: j['address'],
  );
}

Future<void> migrateOldSqliteToZkool2({required final String walletName}) async {
  final dbFile = p.join(await pathForWalletTypeDir(type: WalletType.zcash), "zec.db");
  final migrateDb = await openDatabase(dbFile);
  final outputRaw = await migrateDb.rawQuery(
    "SELECT `id_account`, `name`, `seed`, `aindex`, `sk`, `ivk`, `address` FROM `accounts`",
  );
  final output = outputRaw.map(YwalletAccountInfo.fromJson);

  final walletId = await ZcashWalletBase.getLegacyZcashAccountIdForName(walletName);
  for (final ya in output) {
    if (ya.idAccount != walletId) {
      continue;
    }
    printV("migrating account: ${ya.name} - ${walletName}");
    int birthHeight = await ZcashHeight.getBlockHeightByTime(DateTime(2026, 1, 1));

    final accTxs = await migrateDb.rawQuery(
      "SELECT height FROM transactions WHERE account = ${ya.idAccount}",
    );
    for (final tx in accTxs) {
      final txHeight = int.tryParse(tx['height'].toString()) ?? birthHeight;
      birthHeight = min(birthHeight, txHeight);
    }

    final accountId = await ZcashWalletBase.restoreZcashWalletFromSeed(
      name: walletName,
      seed: ya.zkoolSeed.seed,
      passphrase: ya.zkoolSeed.passphrase,
      birthHeight: birthHeight,
    );
    await ZcashWalletBase.saveAccountId(walletName, accountId);
    return;
  }

  throw Exception("migration not finished (wallet name: $walletName not found)");
}
