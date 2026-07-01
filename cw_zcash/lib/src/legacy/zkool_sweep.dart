import 'dart:io';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:path/path.dart' as p;
import 'package:zkool/src/rust/api/account.dart' as zkool_account;
import 'package:zkool/src/rust/api/coin.dart' as zkool_coin;
import 'package:zkool/src/rust/api/sync.dart' as zkool_sync;
import 'package:zkool/src/rust/api/pay.dart' as zkool_pay;
import 'package:zkool/src/rust/api/key.dart' as zkool_key;
import 'package:zkool/src/rust/api/network.dart' as zkool_network;
import 'package:zkool/src/rust/pay.dart' as zkool_paydart;
import 'package:zkool/src/rust/frb_generated.dart' as zkool_frb;

class ZkoolSweep {
  ZkoolSweep({
    required this.currentBalance,
    required this.cacheDir,
    required this.seed,
    required this.passphrase,
    required this.address,
    required this.url,
    required this.height,
  });
  final int currentBalance;
  final String seed;
  final String cacheDir;
  final String passphrase;
  final String address;
  final String url;
  final int height;
  static SweepUpdate msg = SweepUpdate(message: 'Idling', currentHeight: 0, networkHeight: 0);
  Future<void> start() async {
    try {
      await _init();
      if (!zkool_key.isValidAddress(address: address)) {
        msg.message = "$address is not valid";
        return;
      }

      msg = SweepUpdate(message: 'Starting import', currentHeight: 0, networkHeight: 0);
      await _newAccount();
      msg.message = "Starting sync";
      await warpSync();
      msg.message = "Waiting";
      while (msg.blocksLeft != 0 && msg.networkHeight != 0) {
        await Future.delayed(Duration(seconds: 1));
      }
      await Future.delayed(Duration(seconds: 5));
      final balance = await getBalance();
      if (balance.toInt() == balance) {
        msg.message = "No need to sweep, balance is the same";
        return;
      }
      msg.message = "Sweeping";
      await sweep(balance);
    } catch (e) {
      msg.message = e.toString();
      printV("zkool_sweep: $e");
      rethrow;
    }
  }

  Future<BigInt> getBalance() async {
    final b = await zkool_sync.balance(c: c);
    return b.field0.reduce((final a, final b) => a + b);
  }

  Future<void> sweep(final BigInt amount) async {
    msg.message = "prepare";
    final tx = await zkool_pay.prepare(
      recipients: [zkool_paydart.Recipient(address: address, amount: amount)],
      options: zkool_pay.PaymentOptions(
        srcPools: 7,
        recipientPaysFee: true,
        smartTransparent: false,
      ),
      c: c,
    );
    msg.message = "getLatestHeight";
    final height = await getLatestHeight();
    msg.message = "signTransaction";
    final signTx = await zkool_pay.signTransaction(pczt: tx, c: c);
    msg.message = "extractTransaction";
    final txBytes = await zkool_pay.extractTransaction(package: signTx);
    msg.message = "broadcastTransaction";
    final result = await zkool_pay.broadcastTransaction(height: height, txBytes: txBytes, c: c);
    msg.message = "result";
    if (result.isEmpty) {
      msg.message = "Unknown error";
      throw Exception(result);
    }
  }

  static var c = zkool_coin.Coin();

  static bool _isInit = false;

  File get dbFile => File(p.join(cacheDir, "zkool-tmp-mirror.db"));

  Future<int> warpSync() async {
    final currentHeight = await getLatestHeight();
    msg.networkHeight = currentHeight;
    final sync = zkool_sync.synchronize(
      accounts: [currentAccount],
      currentHeight: currentHeight,
      actionsPerSync: 10000,
      transparentLimit: 100,
      checkpointAge: 200,
      c: c,
    );
    bool success = false;
    await sync.listen(
      (final syncProgress) {
        msg.currentHeight = syncProgress.height;
        msg.message = "Sync ${syncProgress.height} / ${syncProgress.time}";
      },
      onError: (final e) {
        msg.message = e.toString();
      },
      onDone: () {
        msg.message = "Sync done!";
        success = true;
      },
    );

    if (msg.currentHeight != currentHeight && msg.currentHeight != 0) {
      msg.message = "Canceling sync";
      await zkool_sync.cancelSync();
      await Future.delayed(Duration(seconds: 1));
      return warpSync();
    }
    return 0;
  }

  Future<int> getLatestHeight() async {
    try {
      return await zkool_network.getCurrentHeight(c: c);
    } catch (e) {
      printV("getLatestHeight: $e");
    }
    return 0;
  }

  Future<void> _newAccount() async {
    final id = await zkool_account.newAccount(
      na: zkool_account.NewAccount(
        name: 'restoretmp' + DateTime.now().microsecondsSinceEpoch.toString(),
        restore: true,
        passphrase: "",
        key: seed,
        aindex: 0,
        birth: height,
        folder: '',
        useInternal: true,
        internal: false,
        ledger: false,
      ),
      c: c,
    );
    currentAccount = id;
    c = await c.setAccount(account: id);
  }

  int currentAccount = 0;

  Future<void> _init() async {
    if (_isInit) return;
    _isInit = true;
    printV(".init()");
    await zkool_frb.RustLib.init();
    await zkool_network.initDatadir(directory: dbFile.parent.path);
    c = await c.openDatabase(dbFilepath: dbFile.path, password: 'cw_zcash_migration');
    c = c.setLwd(url: url, serverType: 0);
    printV(".init(): Done");
  }
}

class SweepUpdate {
  SweepUpdate({required this.message, required this.currentHeight, required this.networkHeight});
  String message;
  int currentHeight;
  int networkHeight;
  double get progress {
    if (networkHeight == 0) return 0.01;
    return currentHeight / networkHeight;
  }

  int get blocksLeft => networkHeight - currentHeight;

  Map<String, dynamic> toJson() => {
    "message": message,
    "currentHeight": currentHeight,
    "networkHeight": networkHeight,
    "progress": progress,
  };
}
