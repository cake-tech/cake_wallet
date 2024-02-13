import 'dart:developer';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_decred/pending_transaction.dart';
import 'package:cw_decred/transaction_credentials.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:hive/hive.dart';

import 'package:cw_decred/api/libdcrwallet.dart' as libdcrwallet;
import 'package:cw_decred/transaction_history.dart';
import 'package:cw_decred/wallet_addresses.dart';
import 'package:cw_decred/transaction_priority.dart';
import 'package:cw_decred/balance.dart';
import 'package:cw_decred/transaction_info.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/unspent_transaction_output.dart';

part 'wallet.g.dart';

class DecredWallet = DecredWalletBase with _$DecredWallet;

abstract class DecredWalletBase extends WalletBase<DecredBalance,
    DecredTransactionHistory, DecredTransactionInfo> with Store {
  DecredWalletBase(WalletInfo walletInfo, String password,
      Box<UnspentCoinsInfo> unspentCoinsInfo)
      : _password = password,
        this.syncStatus = NotConnectedSyncStatus(),
        this.unspentCoinsInfo = unspentCoinsInfo,
        this.balance =
            ObservableMap.of({CryptoCurrency.dcr: DecredBalance.zero()}),
        super(walletInfo) {
    walletAddresses = DecredWalletAddresses(walletInfo);
    transactionHistory = DecredTransactionHistory();
  }

  // NOTE: Hitting this max fee would be unexpected with current on chain use
  // but this may need to be updated in the future.
  final maxFeeRate = 100000;
  static final defaultFeeRate = 10000;
  final String _password;
  final idPrefix = "decred_";
  bool connecting = false;
  int bestHeight = 0;
  String bestHash = "";
  String persistantPeer = "";
  FeeCache feeRateFast = FeeCache(defaultFeeRate);
  FeeCache feeRateMedium = FeeCache(defaultFeeRate);
  FeeCache feeRateSlow = FeeCache(defaultFeeRate);
  Timer? syncTimer;
  Box<UnspentCoinsInfo> unspentCoinsInfo;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  late ObservableMap<CryptoCurrency, DecredBalance> balance;

  @override
  late DecredWalletAddresses walletAddresses;

  @override
  String? get seed {
    return libdcrwallet.walletSeed(walletInfo.name, _password);
  }

  @override
  Object get keys {
    // throw UnimplementedError();
    return {};
  }

  Future<void> init() async {
    updateBalance();
  }

  void performBackgroundTasks() async {
    if (!checkSync()) {
      return;
    }
    final res = libdcrwallet.bestBlock(walletInfo.name);
    final decoded = json.decode(res);
    final hash = decoded["hash"] ?? "";
    if (this.bestHash != hash) {
      this.bestHash = hash;
      this.bestHeight = decoded["height"] ?? "";
    }
    updateBalance();
    var from = 0;
    while (true) {
      // Transactions are returned from newest to oldest. Loop fetching 5 txn
      // at a time until we find a batch with txn that no longer need to be
      // updated.
      final txs = await this.fetchFiveTransactions(from);
      if (txs.length == 0) {
        return;
      }
      if (this.transactionHistory.update(txs)) {
        return;
      }
      from += 5;
    }
  }

  bool checkSync() {
    final syncStatusJSON = libdcrwallet.syncStatus(walletInfo.name);
    final decoded = json.decode(syncStatusJSON);

    final syncStatusCode = decoded["syncstatuscode"] ?? 0;
    final syncStatusStr = decoded["syncstatus"] ?? "";
    final targetHeight = decoded["targetheight"] ?? 1;
    final numPeers = decoded["numpeers"] ?? 0;
    // final cFiltersHeight = decoded["cfiltersheight"] ?? 0;
    final headersHeight = decoded["headersheight"] ?? 0;
    final rescanHeight = decoded["rescanheight"] ?? 0;

    if (numPeers == 0) {
      syncStatus = NotConnectedSyncStatus();
      return false;
    }

    // Sync codes:
    // NotStarted = 0
    // FetchingCFilters = 1
    // FetchingHeaders = 2
    // DiscoveringAddrs = 3
    // Rescanning = 4
    // Complete = 5

    if (syncStatusCode > 4) {
      syncStatus = SyncedSyncStatus();
      return true;
    }

    if (syncStatusCode == 0) {
      syncStatus = ConnectedSyncStatus();
      return false;
    }

    if (syncStatusCode == 1) {
      syncStatus = SyncingSyncStatus(targetHeight, 0.0);
      return false;
    }

    if (syncStatusCode == 2) {
      final headersProg = headersHeight / targetHeight;
      // Only allow headers progress to go up half way.
      syncStatus =
          SyncingSyncStatus(targetHeight - headersHeight, headersProg / 2);
      return false;
    }

    // TODO: This step takes a while so should really get more info to the UI
    // that we are discovering addresses.
    if (syncStatusCode == 3) {
      // Hover at half.
      syncStatus = SyncingSyncStatus(0, .5);
      return false;
    }

    if (syncStatusCode == 4) {
      // Start at 75%.
      final rescanProg = rescanHeight / targetHeight / 4;
      syncStatus =
          SyncingSyncStatus(targetHeight - rescanHeight, .75 + rescanProg);
      return false;
    }
    return false;
  }

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    if (connecting) {
      throw "decred already connecting";
    }
    connecting = true;
    String addr = "";
    if (node.uri.host != "") {
      addr = node.uri.host;
      if (node.uri.port != "") {
        addr += ":" + node.uri.port.toString();
      }
    }
    if (addr != persistantPeer) {
      if (syncTimer != null) {
        syncTimer!.cancel();
        syncTimer = null;
      }
      persistantPeer = addr;
      libdcrwallet.closeWallet(walletInfo.name);
      libdcrwallet.loadWalletSync({
        "name": walletInfo.name,
        "dataDir": walletInfo.dirPath,
      });
    }
    await this._startSync();
    connecting = false;
  }

  @action
  @override
  Future<void> startSync() async {
    if (connecting) {
      throw "decred already connecting";
    }
    connecting = true;
    await this._startSync();
    connecting = false;
  }

  Future<void> _startSync() async {
    if (syncTimer != null) {
      return;
    }
    try {
      syncStatus = ConnectingSyncStatus();
      libdcrwallet.startSyncAsync(
        name: walletInfo.name,
        peers: persistantPeer,
      );
      syncTimer = Timer.periodic(
          Duration(seconds: 5), (Timer t) => performBackgroundTasks());
    } catch (e) {
      print(e.toString());
      syncStatus = FailedSyncStatus();
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final inputs = [];
    this.unspentCoinsInfo.values.forEach((unspent) {
      if (unspent.isSending) {
        final input = {"txid": unspent.hash, "vout": unspent.vout};
        inputs.add(input);
      }
    });
    final ignoreInputs = [];
    this.unspentCoinsInfo.values.forEach((unspent) {
      if (unspent.isFrozen) {
        final input = {"txid": unspent.hash, "vout": unspent.vout};
        ignoreInputs.add(input);
      }
    });
    final creds = credentials as DecredTransactionCredentials;
    var totalAmt = 0;
    final outputs = [];
    for (final out in creds.outputs) {
      var amt = 0;
      if (out.cryptoAmount != null) {
        final coins = double.parse(out.cryptoAmount!);
        amt = (coins * 1e8).toInt();
      }
      totalAmt += amt;
      final o = {"address": out.address, "amount": amt};
      outputs.add(o);
    }
    ;
    final signReq = {
      "inputs": inputs,
      "ignoreInputs": ignoreInputs,
      "outputs": outputs,
      "feerate": creds.feeRate ?? defaultFeeRate,
      "password": _password,
    };
    final res = libdcrwallet.createSignedTransaction(
        walletInfo.name, jsonEncode(signReq));
    final decoded = json.decode(res);
    final signedHex = decoded["signedhex"];
    final send = () async {
      libdcrwallet.sendRawTransaction(walletInfo.name, signedHex);
    };
    return DecredPendingTransaction(
        txid: decoded["txid"] ?? "",
        amount: totalAmt,
        fee: decoded["fee"] ?? 0,
        rawHex: signedHex,
        send: send);
  }

  int feeRate(TransactionPriority priority) {
    if (!(priority is DecredTransactionPriority)) {
      return defaultFeeRate;
    }
    int Function(int nb) feeForNb = (int nb) {
      try {
        final feeStr = libdcrwallet.estimateFee(walletInfo.name, nb);
        var fee = int.parse(feeStr);
        if (fee > maxFeeRate) {
          throw "dcr fee returned from estimate fee was over max";
        } else if (fee <= 0) {
          throw "dcr fee returned from estimate fee was zero";
        }
        return fee;
      } catch (e) {
        print(e);
        return defaultFeeRate;
      }
    };
    final p = priority as DecredTransactionPriority;
    switch (p) {
      case DecredTransactionPriority.slow:
        if (feeRateSlow.isOld()) {
          feeRateSlow.update(feeForNb(4));
        }
        return feeRateSlow.feeRate();
      case DecredTransactionPriority.medium:
        if (feeRateMedium.isOld()) {
          feeRateMedium.update(feeForNb(2));
        }
        return feeRateMedium.feeRate();
      case DecredTransactionPriority.fast:
        if (feeRateFast.isOld()) {
          feeRateFast.update(feeForNb(1));
        }
        return feeRateFast.feeRate();
    }
    return defaultFeeRate;
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    if (priority is DecredTransactionPriority) {
      final P2PKHOutputSize =
          36; // 8 bytes value + 2 bytes version + at least 1 byte varint script size + P2PKHPkScriptSize
      // MsgTxOverhead is 4 bytes version (lower 2 bytes for the real transaction
      // version and upper 2 bytes for the serialization type) + 4 bytes locktime
      // + 4 bytes expiry + 3 bytes of varints for the number of transaction
      // inputs (x2 for witness and prefix) and outputs
      final MsgTxOverhead = 15;
      // TxInOverhead is the overhead for a wire.TxIn with a scriptSig length <
      // 254. prefix (41 bytes) + ValueIn (8 bytes) + BlockHeight (4 bytes) +
      // BlockIndex (4 bytes) + sig script var int (at least 1 byte)
      final TxInOverhead = 57;
      final P2PKHInputSize = TxInOverhead +
          109; // TxInOverhead (57) + var int (1) + P2PKHSigScriptSize (108)

      // Estimate using a transaction consuming three inputs and paying to one
      // address with change.
      return this.feeRate(priority) *
          (MsgTxOverhead + P2PKHInputSize * 3 + P2PKHOutputSize * 2);
    }
    return 0;
  }

  @override
  Future<Map<String, DecredTransactionInfo>> fetchTransactions() async {
    return this.fetchFiveTransactions(0);
  }

  @override
  Future<Map<String, DecredTransactionInfo>> fetchFiveTransactions(
      int from) async {
    final res =
        libdcrwallet.listTransactions(walletInfo.name, from.toString(), "5");
    final decoded = json.decode(res);
    var txs = <String, DecredTransactionInfo>{};
    for (final d in decoded) {
      final txid = d["txid"] ?? "";
      var direction = TransactionDirection.outgoing;
      if (d["category"] == "receive") {
        direction = TransactionDirection.incoming;
      }
      final amountDouble = d["amount"] ?? 0.0;
      final amount = (amountDouble * 1e8).toInt().abs();
      final feeDouble = d["fee"] ?? 0.0;
      final fee = (feeDouble * 1e8).toInt().abs();
      final confs = d["confirmations"] ?? 0;
      final sendTime = d["time"] ?? 0;
      final txInfo = DecredTransactionInfo(
        id: txid,
        amount: amount,
        fee: fee,
        direction: direction,
        isPending: confs == 0,
        date: DateTime.fromMillisecondsSinceEpoch(sendTime * 1000, isUtc: true),
        height: 0,
        confirmations: confs,
        to: d["address"] ?? "",
      );
      txs[txid] = txInfo;
    }
    return txs;
  }

  @override
  Future<void> save() async {}

  @override
  Future<void> rescan({required int height}) async {
    // TODO.
  }

  @override
  void close() {
    if (syncTimer != null) {
      syncTimer!.cancel();
      syncTimer = null;
    }
    libdcrwallet.closeWallet(walletInfo.name);
  }

  @override
  Future<void> changePassword(String password) async {
    await libdcrwallet.changeWalletPassword(
        walletInfo.name, _password, password);
  }

  @override
  Future<void>? updateBalance() async {
    final balanceMap = libdcrwallet.balance(walletInfo.name);
    balance[CryptoCurrency.dcr] = DecredBalance(
      confirmed: balanceMap["confirmed"] ?? 0,
      unconfirmed: balanceMap["unconfirmed"] ?? 0,
    );
  }

  @override
  void setExceptionHandler(void Function(FlutterErrorDetails) onError) =>
      onError;

  Future<void> renameWalletFiles(String newWalletName) async {
    final currentDirPath =
        await pathForWalletDir(name: walletInfo.name, type: type);

    final newDirPath = await pathForWalletDir(name: newWalletName, type: type);

    if (File(newDirPath).existsSync()) {
      throw "wallet already exists at $newDirPath";
    }
    ;

    await Directory(currentDirPath).rename(newDirPath);
  }

  @override
  String signMessage(String message, {String? address = null}) {
    return ""; // TODO
  }

  List<Unspent> unspents() {
    final res = libdcrwallet.listUnspents(walletInfo.name);
    final decoded = json.decode(res);
    var unspents = <Unspent>[];
    for (final d in decoded) {
      final spendable = d["spendable"] ?? false;
      if (!spendable) {
        continue;
      }
      final amountDouble = d["amount"] ?? 0.0;
      final amount = (amountDouble * 1e8).toInt().abs();
      final utxo = Unspent(
          d["address"] ?? "", d["txid"] ?? "", amount, d["vout"] ?? 0, null);
      utxo.isChange = d["ischange"] ?? false;
      unspents.add(utxo);
    }
    this.updateUnspents(unspents);
    return unspents;
  }

  void updateUnspents(List<Unspent> unspentCoins) {
    if (this.unspentCoinsInfo.isEmpty) {
      unspentCoins.forEach((coin) => this.addCoinInfo(coin));
      return;
    }

    if (unspentCoins.isEmpty) {
      this.unspentCoinsInfo.clear();
      return;
    }

    final walletID = idPrefix + walletInfo.name;
    if (unspentCoins.isNotEmpty) {
      unspentCoins.forEach((coin) {
        final coinInfoList = this.unspentCoinsInfo.values.where((element) =>
            element.walletId == walletID &&
            element.hash == coin.hash &&
            element.vout == coin.vout);

        if (coinInfoList.isEmpty) {
          this.addCoinInfo(coin);
        }
      });
    }

    final List<dynamic> keys = <dynamic>[];
    this.unspentCoinsInfo.values.forEach((element) {
      final existUnspentCoins =
          unspentCoins.where((coin) => element.hash.contains(coin.hash));

      if (existUnspentCoins.isEmpty) {
        keys.add(element.key);
      }
    });

    if (keys.isNotEmpty) {
      unspentCoinsInfo.deleteAll(keys);
    }
  }

  void addCoinInfo(Unspent coin) {
    final newInfo = UnspentCoinsInfo(
      walletId: idPrefix + walletInfo.name,
      hash: coin.hash,
      isFrozen: false,
      isSending: false,
      noteRaw: "",
      address: coin.address,
      value: coin.value,
      vout: coin.vout,
      isChange: coin.isChange,
      keyImage: coin.keyImage,
    );

    unspentCoinsInfo.add(newInfo);
  }
}
