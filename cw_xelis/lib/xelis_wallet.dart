import 'dart:async';
import 'dart:convert';

import 'package:mobx/mobx.dart';

import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/node.dart';

import 'package:cw_xelis/xelis_asset_balance.dart';
import 'package:cw_xelis/src/api/wallet.dart' as x_wallet;
import 'package:cw_xelis/src/api/utils.dart';
import 'package:cw_xelis/xelis_transaction_info.dart';
import 'package:cw_xelis/xelis_transaction_history.dart';
import 'package:cw_xelis/xelis_wallet_addresses.dart';
import 'package:cw_xelis/xelis_events.dart';
// import 'package:cw_xelis/transaction_priority.dart';

import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as xelis_sdk;

part 'xelis_wallet.g.dart';

class XelisWallet = XelisWalletBase with _$XelisWallet;

class Recipient {
  final String address;
  final BigInt amount;
  final bool isChange;

  Recipient({
    required this.address,
    required this.amount,
    required this.isChange,
  });
}

abstract class XelisWalletBase 
  extends WalletBase<XelisAssetBalance,
    XelisTransactionHistory, XelisTransactionInfo
> with Store {
  final x_wallet.XelisWallet _libWallet;

  XelisWalletBase({
    required WalletInfo walletInfo,
    required x_wallet.XelisWallet libWallet,
    required String password,
  })
  : 
    _password = password,
    _libWallet = libWallet,
    _isTransactionUpdating = false,
    this.syncStatus = NotConnectedSyncStatus(),
    this.balance = ObservableMap.of({CryptoCurrency.xel: XelisAssetBalance.zero()}),
    super(walletInfo)
  {
    walletAddresses = XelisWalletAddresses(walletInfo, _libWallet);
    transactionHistory = XelisTransactionHistory();
    _init();
  }

  String _password;

  bool synced = false;
  bool connecting = false;
  String persistantPeer = "us-node.xelis.io";
  Timer? syncTimer;
  int pruningHeight = 0;
  var _seed = "";

  @override
  late ObservableMap<CryptoCurrency, XelisAssetBalance> balance;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  late XelisWalletAddresses walletAddresses;

  @override
  bool get hasRescan => true;

  @override
  String get password => _password;

  @override
  String get seed => _seed;
  void updateSeed(String? language) async {
    _seed = await _libWallet.getSeed(languageIndex: getLanguageIndexFromStr(input: language ?? "english"));
  }

  @override
  Object get keys => {};

  @override
  late final XelisTransactionHistory transactionHistory;

  bool _isTransactionUpdating;
  StreamSubscription? _eventSub;

  void _subscribeToWalletEvents() {
    _eventSub = _convertRawEvents().listen(_handleEvent);
  }

  Future<void> _unsubscribeFromWalletEvents() async {
    await _eventSub?.cancel();
    _eventSub = null;
  }

  Stream<Event> _convertRawEvents() async* {
    final stream =_libWallet.eventsStream();

    await for (final raw in stream) {
      try {
        final data = jsonDecode(raw);
        final event = xelis_sdk.WalletEvent.fromStr(data['event'] as String);

        switch (event) {
          case xelis_sdk.WalletEvent.newTransaction:
            yield NewTransaction(xelis_sdk.TransactionEntry.fromJson(data['data']));
          case xelis_sdk.WalletEvent.balanceChanged:
            yield BalanceChanged(data['data']['asset'] as String, data['data']['balance'] as int);
          case xelis_sdk.WalletEvent.newTopoHeight:
            yield NewTopoheight(data['data']['topoheight'] as int);
          case xelis_sdk.WalletEvent.rescan:
            yield Rescan(data['data']['start_topoheight'] as int);
          case xelis_sdk.WalletEvent.online:
            yield const Online();
          case xelis_sdk.WalletEvent.offline:
            yield const Offline();
          case xelis_sdk.WalletEvent.historySynced:
            yield HistorySynced(data['data']['topoheight'] as int);
          default:
            continue;
        }
      } catch (e) {
        // print('Failed to parse wallet event: $e');
      }
    }
  }

  @override
  Future<void> save() async {}

  @action
  @override
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();
      await updateBalance();
      await _updateTransactions();
      syncStatus = SyncedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
    }
  }

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    if (connecting) {
      return;
    }
    connecting = true;
    String addr = "us-node.xelis.io";
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
      await _libWallet.offlineMode();
      await _libWallet.onlineMode(daemonAddress: addr);
    }
    await this.startSync();
    connecting = false;
  }

  @override
  Future<void> rescan({required int height}) async {
    walletInfo.restoreHeight = height;
    walletInfo.isRecovery = true;
   _libWallet.rescan(topoheight: BigInt.from(pruningHeight));
    await startSync();
    await updateBalance();
    await _updateTransactions(isRescan: true);
    await walletInfo.save();
  }

  Future<void> _handleEvent(Event event) async {
    switch (event) {
      case NewTransaction():
        transactionHistory.addOne(
          XelisTransactionInfo.fromTransactionEntry(event.tx),
        );
        await updateBalance();
        break;

      case BalanceChanged():
        if (event.asset == xelis_sdk.xelisAsset) {
          balance[CryptoCurrency.xel] = XelisAssetBalance(
            balance: event.balance,
            decimals: 8
          );
        }
        break;

      case NewTopoheight():
        // maybe track height
        break;

      case Online():
        syncStatus = ConnectedSyncStatus();
        break;

      case Offline():
        syncStatus = NotConnectedSyncStatus();
        break;

      case HistorySynced():
        // optional
        break;

      case Rescan():
        // optional
        break;
    }
  }

  @action
  Future<void> _init() async {
    try {
      walletAddresses.init();
      _subscribeToWalletEvents();
      _seed = await _libWallet.getSeed();
    } catch (e) {
      // print("Failed to init wallet: $e");
    }
  }

  @override
  Future<void> changePassword(String password) async {
    return () async {
      await _libWallet.changePassword(oldPassword: _password, newPassword: password);
      _password = password;
    }();
  }

  @override
  Future<void> updateBalance() async {
    balance[CryptoCurrency.xel] = XelisAssetBalance(
      balance: (await _libWallet.getXelisBalanceRaw()).toInt(),
      decimals: 8
    );
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    final asset = xelis_sdk.xelisAsset;

    // Default values
    final defaultDecimals = 8;
    final defaultFee = 25000;

    final effectiveRecipients = [
      Recipient(
        address: 'xel:xz9574c80c4xegnvurazpmxhw5dlg2n0g9qm60uwgt75uqyx3pcsqzzra9m',
        amount: BigInt.from(amount ?? 0),
        isChange: false,
      ),
    ];

    // FIXME: hardcoded
    return defaultFee;
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    throw UnimplementedError();
    // final creds = credentials as XelisTransactionCredentials;
    // var totalAmt = 0;
    // var sendAll = false;
    // final outputs = [];
    // for (final out in creds.outputs) {
    //   var amt = 0;
    //   if (out.sendAll) {
    //     if (creds.outputs.length != 1) {
    //       throw "can only send all to one output";
    //     }
    //     sendAll = true;
    //     totalAmt = totalIn;
    //   } else if (out.cryptoAmount != null) {
    //     final coins = double.parse(out.cryptoAmount!);
    //     amt = (coins * 1e8).round();
    //   }
    //   totalAmt += amt;
    //   final o = {
    //     "address": out.isParsedAddress ? out.extractedAddress! : out.address,
    //     "amount": amt
    //   };
    //   outputs.add(o);
    // }

    // // throw exception if no selected coins under coin control
    // // or if the total coins selected, is less than the amount the user wants to spend
    // if (ignoreInputs.length == unspentCoinsInfo.values.length || totalIn < totalAmt) {
    //   throw TransactionNoInputsException();
    // }

    // // The inputs are always used. Currently we don't have use for this
    // // argument. sendall ingores output value and sends everything.
    // final signReq = {
    //   // "inputs": inputs,
    //   "ignoreInputs": ignoreInputs,
    //   "outputs": outputs,
    //   "feerate": creds.feeRate ?? defaultFeeRate,
    //   "password": _password,
    //   "sendall": sendAll,
    // };
    // final res = await _libWallet.createSignedTransaction(walletInfo.name, jsonEncode(signReq));
    // final decoded = json.decode(res);
    // final signedHex = decoded["signedhex"];
    // final send = () async {
    //   await _libWallet.sendRawTransaction(walletInfo.name, signedHex);
    //   await updateBalance();
    // };
    // final fee = decoded["fee"] ?? 0;
    // if (sendAll) {
    //   totalAmt = (totalAmt - fee).round();
    // }
    // return DecredPendingTransaction(
    //     txid: decoded["txid"] ?? "", amount: totalAmt, fee: fee, rawHex: signedHex, send: send);
  }

  // TODO
  @override
  Future<String> signMessage(String message, {String? address}) async {
    throw UnimplementedError();
  }

  // TODO
  @override
  Future<bool> verifyMessage(String message, String signature, {String? address}) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, XelisTransactionInfo>> fetchTransactions() async {
    final txList = (await _libWallet.allHistory())
        .map((jsonStr) => xelis_sdk.TransactionEntry.fromJson(
            json.decode(jsonStr),
          ) as xelis_sdk.TransactionEntry)
        .toList();

    final Map<String, XelisTransactionInfo> result = {};

    for (var entry in txList) {
      result[entry.hash] = XelisTransactionInfo.fromTransactionEntry(entry);
    }

    return result;
  }

  Future<void> _updateTransactions({bool? isRescan}) async {
    try {
      if (_isTransactionUpdating) {
        return;
      }

      if (!await _libWallet.isOnline()) {
        return;
      }

      _isTransactionUpdating = true;

      final transactions = await fetchTransactions();

      if (isRescan == true) {
        transactionHistory.clear();
        transactionHistory.addMany(transactions);
      } else {
        transactionHistory.update(transactions);
      }
      _isTransactionUpdating = false;
    } catch (_) {
      _isTransactionUpdating = false;
    }
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    throw UnimplementedError();
  }

  @action
  Future<void> goOnline(String daemon) async {
    await _libWallet.onlineMode(daemonAddress: daemon);
  }

  @action
  Future<void> goOffline() async {
    await _libWallet.offlineMode();
  }

  @override
  Future<void> close({bool shouldCleanup = false}) async {
    await _unsubscribeFromWalletEvents();
    await _libWallet.close();
  }
}