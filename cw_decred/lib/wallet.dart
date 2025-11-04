import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:cw_core/exceptions.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_decred/amount_format.dart';
import 'package:cw_decred/pending_transaction.dart';
import 'package:cw_decred/transaction_credentials.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:hive/hive.dart';

import 'package:cw_decred/api/libdcrwallet.dart';
import 'package:cw_decred/transaction_history.dart';
import 'package:cw_decred/wallet_addresses.dart';
import 'package:cw_decred/transaction_priority.dart';
import 'package:cw_decred/wallet_service.dart';
import 'package:cw_decred/balance.dart';
import 'package:cw_decred/transaction_info.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/unspent_transaction_output.dart';

part 'wallet.g.dart';

class DecredWallet = DecredWalletBase with _$DecredWallet;

abstract class DecredWalletBase
    extends WalletBase<DecredBalance, DecredTransactionHistory, DecredTransactionInfo> with Store {
  DecredWalletBase(WalletInfo walletInfo, DerivationInfo derivationInfo, String password, Box<UnspentCoinsInfo> unspentCoinsInfo,
      Libwallet libwallet, Function() closeLibwallet)
      : _password = password,
        _libwallet = libwallet,
        _closeLibwallet = closeLibwallet,
        this.syncStatus = NotConnectedSyncStatus(),
        this.unspentCoinsInfo = unspentCoinsInfo,
        this.watchingOnly =
            derivationInfo.derivationPath == DecredWalletService.pubkeyRestorePath ||
                derivationInfo.derivationPath ==
                    DecredWalletService.pubkeyRestorePathTestnet,
        this.balance = ObservableMap.of({CryptoCurrency.dcr: DecredBalance.zero()}),
        this.isTestnet = derivationInfo.derivationPath ==
                DecredWalletService.seedRestorePathTestnet ||
            derivationInfo.derivationPath ==
                DecredWalletService.pubkeyRestorePathTestnet,
        super(walletInfo, derivationInfo) {
    walletAddresses = DecredWalletAddresses(walletInfo, libwallet);
    transactionHistory = DecredTransactionHistory();

    reaction((_) => isEnabledAutoGenerateSubaddress, (bool enabled) {
      this.walletAddresses.isEnabledAutoGenerateSubaddress = enabled;
    });
  }

  // NOTE: Hitting this max fee would be unexpected with current on chain use
  // but this may need to be updated in the future.
  final maxFeeRate = 100000;

  // syncIntervalSyncing is used up until synced, then transactions are checked
  // every syncIntervalSynced.
  final syncIntervalSyncing = 5; // seconds
  final syncIntervalSynced = 30; // seconds
  static final defaultFeeRate = 10000;
  final String _password;
  final Libwallet _libwallet;
  final Function() _closeLibwallet;
  final idPrefix = "decred_";

  // TODO: Encrypt this.
  var _seed = "";
  var _pubkey = "";
  var _unspents = <Unspent>[];

  // synced is used to set the syncTimer interval.
  bool synced = false;
  bool watchingOnly;
  bool connecting = false;
  String persistantPeer = "default-spv-nodes";
  FeeCache feeRateFast = FeeCache(defaultFeeRate);
  FeeCache feeRateMedium = FeeCache(defaultFeeRate);
  FeeCache feeRateSlow = FeeCache(defaultFeeRate);
  Timer? syncTimer;
  Box<UnspentCoinsInfo> unspentCoinsInfo;

  @override
  @observable
  bool isEnabledAutoGenerateSubaddress = true;

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
    if (watchingOnly) {
      return null;
    }
    return _seed;
  }

  @override
  Object get keys => {};

  @override
  bool isTestnet;

  String get pubkey {
    return _pubkey;
  }

  @override
  String formatCryptoAmount(String amount) => decredAmountToString(amount: int.parse(amount));

  Future<void> init() async {
    final getSeed = () async {
      if (!watchingOnly) {
        _seed = await _libwallet.walletSeed(walletInfo.name, _password) ?? "";
      }
      _pubkey = await _libwallet.defaultPubkey(walletInfo.name);
    };
    await Future.wait([
      updateBalance(),
      updateTransactionHistory(),
      walletAddresses.init(),
      fetchTransactions(),
      updateFees(),
      fetchUnspents(),
      getSeed(),
    ]);
  }

  Future<void> performBackgroundTasks() async {
    if (!await checkSync()) {
      if (synced == true) {
        synced = false;
        if (syncTimer != null) {
          syncTimer!.cancel();
        }
        syncTimer = Timer.periodic(
            Duration(seconds: syncIntervalSyncing), (Timer t) => performBackgroundTasks());
      }
      return;
    }
    // Set sync check interval lower since we are synced.
    if (synced == false) {
      synced = true;
      if (syncTimer != null) {
        syncTimer!.cancel();
      }
      syncTimer = Timer.periodic(
          Duration(seconds: syncIntervalSynced), (Timer t) => performBackgroundTasks());
    }
    await Future.wait([
      updateTransactionHistory(),
      updateFees(),
      fetchUnspents(),
      updateBalance(),
      walletAddresses.updateAddressesInBox(),
    ]);
  }

  Future<void> updateFees() async {
    final feeForNb = (int nb) async {
      try {
        final feeStr = await _libwallet.estimateFee(walletInfo.name, nb);
        var fee = int.parse(feeStr);
        if (fee > maxFeeRate) {
          throw "dcr fee returned from estimate fee was over max";
        } else if (fee <= 0) {
          throw "dcr fee returned from estimate fee was zero";
        }
        return fee;
      } catch (e) {
        printV(e);
        return defaultFeeRate;
      }
    };
    if (feeRateSlow.isOld()) {
      feeRateSlow.update(await feeForNb(4));
    }
    if (feeRateMedium.isOld()) {
      feeRateMedium.update(await feeForNb(2));
    }
    if (feeRateFast.isOld()) {
      feeRateFast.update(await feeForNb(1));
    }
  }

  Future<void> updateTransactionHistory() async {
    // from is the number of transactions skipped from most recent, not block
    // height.
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

  Future<bool> checkSync() async {
    final syncStatusJSON = await _libwallet.syncStatus(walletInfo.name);
    final decoded = json.decode(syncStatusJSON.isEmpty ? "{}" : syncStatusJSON);

    final syncStatusCode = decoded["syncstatuscode"] ?? 0;
    // final syncStatusStr = decoded["syncstatus"] ?? "";
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
      syncStatus = SyncingSyncStatus(targetHeight - headersHeight, headersProg);
      return false;
    }

    // TODO: This step takes a while so should really get more info to the UI
    // that we are discovering addresses.
    if (syncStatusCode == 3) {
      // Hover at half.
      syncStatus = ProcessingSyncStatus();
      return false;
    }

    if (syncStatusCode == 4) {
      // Start at 75%.
      final rescanProg = rescanHeight / targetHeight / 4;
      syncStatus = SyncingSyncStatus(targetHeight - rescanHeight, .75 + rescanProg);
      return false;
    }
    return false;
  }

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    if (connecting) {
      return;
    }
    connecting = true;
    String addr = "default-spv-nodes";
    if (node.uri.host != addr) {
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
      await _libwallet.closeWallet(walletInfo.name);
      final network = isTestnet ? "testnet" : "mainnet";
      final dirPath = await pathForWalletDir(name: walletInfo.name, type: WalletType.decred);
      final config = {
        "name": walletInfo.name,
        "datadir": dirPath,
        "net": network,
        "unsyncedaddrs": true,
      };
      await _libwallet.loadWallet(jsonEncode(config));
    }
    await this._startSync();
    connecting = false;
  }

  @action
  @override
  Future<void> startSync() async {
    if (connecting) {
      return;
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
      await _libwallet.startSync(
        walletInfo.name,
        persistantPeer == "default-spv-nodes" ? "" : persistantPeer,
      );
      syncTimer = Timer.periodic(
          Duration(seconds: syncIntervalSyncing), (Timer t) => performBackgroundTasks());
    } catch (e) {
      printV(e.toString());
      syncStatus = FailedSyncStatus();
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    if (watchingOnly) {
      return DecredPendingTransaction(
          txid: "",
          amount: 0,
          fee: 0,
          rawHex: "",
          send: () async {
            throw "unable to send with watching only wallet";
          });
    }
    var totalIn = 0;
    final ignoreInputs = [];
    this.unspentCoinsInfo.values.forEach((unspent) {
      if (unspent.isFrozen || !unspent.isSending) {
        final input = {"txid": unspent.hash, "vout": unspent.vout};
        ignoreInputs.add(input);
        return;
      }
      totalIn += unspent.value;
    });

    final creds = credentials as DecredTransactionCredentials;
    var totalAmt = 0;
    var sendAll = false;
    final outputs = [];
    for (final out in creds.outputs) {
      var amt = 0;
      if (out.sendAll) {
        if (creds.outputs.length != 1) {
          throw "can only send all to one output";
        }
        sendAll = true;
        totalAmt = totalIn;
      } else if (out.cryptoAmount != null) {
        final coins = double.parse(out.cryptoAmount!);
        amt = (coins * 1e8).round();
      }
      totalAmt += amt;
      final o = {
        "address": out.isParsedAddress ? out.extractedAddress! : out.address,
        "amount": amt
      };
      outputs.add(o);
    }

    // throw exception if no selected coins under coin control
    // or if the total coins selected, is less than the amount the user wants to spend
    if (ignoreInputs.length == unspentCoinsInfo.values.length || totalIn < totalAmt) {
      throw TransactionNoInputsException();
    }

    // The inputs are always used. Currently we don't have use for this
    // argument. sendall ingores output value and sends everything.
    final signReq = {
      // "inputs": inputs,
      "ignoreInputs": ignoreInputs,
      "outputs": outputs,
      "feerate": creds.feeRate ?? defaultFeeRate,
      "password": _password,
      "sendall": sendAll,
    };
    final res = await _libwallet.createSignedTransaction(walletInfo.name, jsonEncode(signReq));
    final decoded = json.decode(res);
    final signedHex = decoded["signedhex"];
    final send = () async {
      await _libwallet.sendRawTransaction(walletInfo.name, signedHex);
      await updateBalance();
    };
    final fee = decoded["fee"] ?? 0;
    if (sendAll) {
      totalAmt = (totalAmt - fee).round();
    }
    return DecredPendingTransaction(
        txid: decoded["txid"] ?? "", amount: totalAmt, fee: fee, rawHex: signedHex, send: send);
  }

  int feeRate(TransactionPriority priority) {
    if (!(priority is DecredTransactionPriority)) {
      return defaultFeeRate;
    }
    final p = priority;
    switch (p) {
      case DecredTransactionPriority.slow:
        return feeRateSlow.feeRate();
      case DecredTransactionPriority.medium:
        return feeRateMedium.feeRate();
      case DecredTransactionPriority.fast:
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
      final P2PKHInputSize =
          TxInOverhead + 109; // TxInOverhead (57) + var int (1) + P2PKHSigScriptSize (108)

      int inputsCount = 1;
      if (amount != null) {
        inputsCount += _unspents.where((e) {
          amount = (amount!) - e.value;
          return (amount!) > 0;
        }).length;
      }

      // Estimate using a transaction consuming inoutsCount and paying to one address with change.
      return (this.feeRate(priority) / 1000).round() *
          (MsgTxOverhead + P2PKHInputSize * inputsCount + P2PKHOutputSize * 2);
    }
    return 0;
  }

  @override
  Future<Map<String, DecredTransactionInfo>> fetchTransactions() async {
    return this.fetchFiveTransactions(0);
  }

  Future<Map<String, DecredTransactionInfo>> fetchFiveTransactions(int from) async {
    try {
      final res = await _libwallet.listTransactions(walletInfo.name, from.toString(), "5");
      final decoded = json.decode(res);
      var txs = <String, DecredTransactionInfo>{};
      for (final d in decoded) {
        final txid = uniqueTxID(d["txid"] ?? "", d["vout"] ?? 0);
        var direction = TransactionDirection.outgoing;
        if (d["category"] == "receive") {
          direction = TransactionDirection.incoming;
        }
        final amountDouble = d["amount"] ?? 0.0;
        final amount = (amountDouble * 1e8).round().abs();
        final feeDouble = d["fee"] ?? 0.0;
        final fee = (feeDouble * 1e8).round().abs();
        final confs = d["confirmations"] ?? 0;
        final sendTime = d["time"] ?? 0;
        final height = d["height"] ?? 0;
        final txInfo = DecredTransactionInfo(
          id: txid,
          amount: amount,
          fee: fee,
          direction: direction,
          isPending: confs == 0,
          date: DateTime.fromMillisecondsSinceEpoch(sendTime * 1000, isUtc: false),
          height: height,
          confirmations: confs,
          to: d["address"] ?? "",
        );
        txs[txid] = txInfo;
      }
      return txs;
    } catch (e) {
      printV(e);
      return {};
    }
  }

  // uniqueTxID combines the tx id and vout to create a unique id.
  String uniqueTxID(String id, int vout) {
    return id + ":" + vout.toString();
  }

  @override
  Future<void> save() async {}

  @override
  bool get hasRescan => walletBirthdayBlockHeight() != -1;

  @override
  Future<void> rescan({required int height}) async {
    // The required height is not used. A birthday time is recorded in the
    // mnemonic. As long as not private data is imported into the wallet, we
    // can always rescan from there.
    var rescanHeight = 0;
    if (!watchingOnly) {
      rescanHeight = await walletBirthdayBlockHeight();
      // Sync has not yet reached the birthday block.
      if (rescanHeight == -1) {
        return;
      }
    }
    await _libwallet.rescanFromHeight(walletInfo.name, rescanHeight.toString());
  }

  @override
  Future<void> close({bool shouldCleanup = false}) async {
    if (syncTimer != null) {
      syncTimer!.cancel();
      syncTimer = null;
    }
    await _libwallet.closeWallet(walletInfo.name);
    if (shouldCleanup) {
      await _libwallet.shutdown();
      _closeLibwallet();
    }
  }

  @override
  Future<void> changePassword(String password) async {
    if (watchingOnly) {
      return;
    }
    return () async {
      await _libwallet.changeWalletPassword(walletInfo.name, _password, password);
    }();
  }

  @override
  Future<void> updateBalance() async {
    final balanceMap = await _libwallet.balance(walletInfo.name);

    var totalFrozen = 0;

    unspentCoinsInfo.values.forEach((info) {
      _unspents.forEach((element) {
        if (element.hash == info.hash &&
            element.vout == info.vout &&
            info.isFrozen &&
            element.value == info.value) {
          totalFrozen += element.value;
        }
      });
    });

    balance[CryptoCurrency.dcr] = DecredBalance(
      confirmed: balanceMap["confirmed"] ?? 0,
      unconfirmed: balanceMap["unconfirmed"] ?? 0,
      frozen: totalFrozen,
    );
  }

  @override
  Future<bool> checkNodeHealth() async => await checkSync();

  @override
  void setExceptionHandler(void Function(FlutterErrorDetails) onError) => onError;

  Future<void> renameWalletFiles(String newWalletName) async {
    final currentDirPath = await pathForWalletDir(name: walletInfo.name, type: type);

    final newDirPath = await pathForWalletDir(name: newWalletName, type: type);

    if (File(newDirPath).existsSync()) {
      throw "wallet already exists at $newDirPath";
    }

    final sourceDir = Directory(currentDirPath);
    final targetDir = Directory(newDirPath);

    if (!targetDir.existsSync()) {
      await targetDir.create(recursive: true);
    }

    await for (final entity in sourceDir.list(recursive: true)) {
      final relativePath = entity.path.substring(sourceDir.path.length + 1);
      final targetPath = p.join(targetDir.path, relativePath);

      if (entity is File) {
        await entity.rename(targetPath);
      } else if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
      }
    }

    await sourceDir.delete(recursive: true);
  }

  @override
  Future<String> signMessage(String message, {String? address = null}) async {
    if (watchingOnly) {
      throw "a watching only wallet cannot sign";
    }
    var addr = address;
    if (addr == null) {
      addr = walletAddresses.address;
    }
    if (addr == "") {
      throw "unable to get an address from unsynced wallet";
    }
    return await _libwallet.signMessage(walletInfo.name, message, addr, _password);
  }

  Future<void> fetchUnspents() async {
    try {
      final res = await _libwallet.listUnspents(walletInfo.name);
      final decoded = json.decode(res);
      var unspents = <Unspent>[];
      for (final d in decoded) {
        final spendable = d["spendable"] ?? false;
        if (!spendable) {
          continue;
        }
        final amountDouble = d["amount"] ?? 0.0;
        final amount = (amountDouble * 1e8).round().abs();
        final utxo = Unspent(d["address"] ?? "", d["txid"] ?? "", amount, d["vout"] ?? 0, null);
        utxo.isChange = d["ischange"] ?? false;
        unspents.add(utxo);
      }
      _unspents = unspents;
    } catch (e) {
      printV(e);
    }
  }

  List<Unspent> unspents() {
    this.updateUnspents(_unspents);
    return _unspents;
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
            element.walletId == walletID && element.hash == coin.hash && element.vout == coin.vout);

        if (coinInfoList.isEmpty) {
          this.addCoinInfo(coin);
        } else {
          final coinInfo = coinInfoList.first;

          coin.isFrozen = coinInfo.isFrozen;
          coin.isSending = coinInfo.isSending;
          coin.note = coinInfo.note;
        }
      });
    }

    final List<dynamic> keys = <dynamic>[];
    this.unspentCoinsInfo.values.forEach((element) {
      final existUnspentCoins = unspentCoins.where((coin) => element.hash.contains(coin.hash));

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
      isSending: coin.isSending,
      noteRaw: "",
      address: coin.address,
      value: coin.value,
      vout: coin.vout,
      isChange: coin.isChange,
      keyImage: coin.keyImage,
    );

    unspentCoinsInfo.add(newInfo);
  }

  // walletBirthdayBlockHeight checks if the wallet birthday is set and returns
  // it. Returns -1 if not.
  Future<int> walletBirthdayBlockHeight() async {
    try {
      final res = await _libwallet.birthState(walletInfo.name);
      final decoded = json.decode(res);
      // Having these values set indicates that sync has not reached the birthday
      // yet, so no birthday is set.
      if (decoded["setfromheight"] == true || decoded["setfromtime"] == true) {
        return -1;
      }
      return decoded["height"] ?? 0;
    } on FormatException catch (_) {
      return 0;
    }
  }

  Future<bool> verifyMessage(String message, String signature, {String? address = null}) async {
    var addr = address;
    if (addr == null) {
      throw "an address is required to verify message";
    }
    return () async {
      final verified = await _libwallet.verifyMessage(walletInfo.name, message, addr, signature);
      if (verified == "true") {
        return true;
      }
      return false;
    }();
  }

  @override
  String get password => _password;

  @override
  bool canSend() => seed != null;
}
