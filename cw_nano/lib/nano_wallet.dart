import 'dart:convert';
import 'dart:io';

import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/nano_account_info_response.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_nano/file.dart';
import 'package:cw_core/nano_account.dart';
import 'package:cw_nano/nano_balance.dart';
import 'package:cw_nano/nano_client.dart';
import 'package:cw_nano/nano_transaction_credentials.dart';
import 'package:cw_nano/nano_transaction_history.dart';
import 'package:cw_nano/nano_transaction_info.dart';
import 'package:cw_nano/nano_util.dart';
import 'package:cw_nano/nano_wallet_keys.dart';
import 'package:cw_nano/pending_nano_transaction.dart';
import 'package:mobx/mobx.dart';
import 'dart:async';
import 'package:cw_nano/nano_wallet_addresses.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:nanodart/nanodart.dart';
import 'package:bip39/bip39.dart' as bip39;

part 'nano_wallet.g.dart';

class NanoWallet = NanoWalletBase with _$NanoWallet;

abstract class NanoWalletBase
    extends WalletBase<NanoBalance, NanoTransactionHistory, NanoTransactionInfo> with Store {
  NanoWalletBase({
    required WalletInfo walletInfo,
    required String mnemonic,
    required String password,
    NanoBalance? initialBalance,
  })  : syncStatus = NotConnectedSyncStatus(),
        _password = password,
        _mnemonic = mnemonic,
        _derivationType = walletInfo.derivationType!,
        _isTransactionUpdating = false,
        _client = NanoClient(),
        walletAddresses = NanoWalletAddresses(walletInfo),
        balance = ObservableMap<CryptoCurrency, NanoBalance>.of({
          CryptoCurrency.nano: initialBalance ??
              NanoBalance(currentBalance: BigInt.zero, receivableBalance: BigInt.zero)
        }),
        super(walletInfo) {
    this.walletInfo = walletInfo;
    transactionHistory = NanoTransactionHistory(walletInfo: walletInfo, password: password);
    if (!CakeHive.isAdapterRegistered(NanoAccount.typeId)) {
      CakeHive.registerAdapter(NanoAccountAdapter());
    }
  }

  final String _mnemonic;
  final String _password;
  final DerivationType _derivationType;

  String? _privateKey;
  String? _publicAddress;
  String? _seedKey;

  String? _representativeAddress;
  Timer? _receiveTimer;

  late final NanoClient _client;
  bool _isTransactionUpdating;

  @override
  NanoWalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  late ObservableMap<CryptoCurrency, NanoBalance> balance;

  // initialize the different forms of private / public key we'll need:
  Future<void> init() async {
    final String type = (_derivationType == DerivationType.nano) ? "standard" : "hd";

    // our "mnemonic" is actually a seedkey:
    if (!_mnemonic.contains(' ')) {
      _seedKey = _mnemonic;
    }

    if (_seedKey == null) {
      if (_derivationType == DerivationType.nano) {
        _seedKey = bip39.mnemonicToEntropy(_mnemonic).toUpperCase();
      } else {
        _seedKey = await NanoUtil.hdMnemonicListToSeed(_mnemonic.split(' '));
      }
    }
    _privateKey = await NanoUtil.uniSeedToPrivate(_seedKey!, 0, type);
    _publicAddress = await NanoUtil.uniSeedToAddress(_seedKey!, 0, type);
    this.walletInfo.address = _publicAddress!;

    await walletAddresses.init();
    await transactionHistory.init();
    await save();
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    return 0; // always 0 :)
  }

  @override
  Future<void> changePassword(String password) {
    throw UnimplementedError("changePassword");
  }

  @override
  void close() {
    _client.stop();
  }

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();
      final isConnected = _client.connect(node);
      if (!isConnected) {
        throw Exception("Nano Node connection failed");
      }

      try {
        await _updateBalance();
        await _updateRep();
        await _receiveAll();
      } catch (e) {
        print(e);
      }

      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      print(e);
      syncStatus = FailedSyncStatus();
    }
  }

  @override
  Future<void> connectToPowNode({required Node node}) async {
    _client.connectPow(node);
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    credentials = credentials as NanoTransactionCredentials;

    BigInt runningAmount = BigInt.zero;
    await _updateBalance();
    BigInt runningBalance = balance[currency]?.currentBalance ?? BigInt.zero;

    final List<Map<String, String>> blocks = [];
    String? previousHash;

    for (var txOut in credentials.outputs) {
      late BigInt amt;
      if (txOut.sendAll) {
        amt = balance[currency]?.currentBalance ?? BigInt.zero;
      } else {
        amt = BigInt.tryParse(
                NanoUtil.getAmountAsRaw(txOut.cryptoAmount ?? "0", NanoUtil.rawPerNano)) ??
            BigInt.zero;
      }

      if (balance[currency]?.currentBalance != null && amt > balance[currency]!.currentBalance) {
        throw Exception("Trying to send more than entire balance!");
      }

      runningBalance = runningBalance - amt;

      final block = await _client.constructSendBlock(
        amountRaw: amt.toString(),
        destinationAddress: txOut.extractedAddress ?? txOut.address,
        privateKey: _privateKey!,
        balanceAfterTx: runningBalance,
        previousHash: previousHash,
      );
      previousHash = NanoBlocks.computeStateHash(
        NanoAccountType.NANO,
        block["account"]!,
        block["previous"]!,
        block["representative"]!,
        BigInt.parse(block["balance"]!),
        block["link"]!,
      );

      blocks.add(block);
      runningAmount += amt;
    }

    try {
      if (runningAmount > balance[currency]!.currentBalance || runningBalance < BigInt.zero) {
        throw Exception(("Trying to send more than entire balance!"));
      }
    } catch (e) {
      rethrow;
    }

    return PendingNanoTransaction(
      amount: runningAmount,
      id: "",
      nanoClient: _client,
      blocks: blocks,
    );
  }

  Future<void> _receiveAll() async {
    await _updateBalance();
    int blocksReceived = await this._client.confirmAllReceivable(
          destinationAddress: _publicAddress!,
          privateKey: _privateKey!,
        );

    if (blocksReceived > 0) {
      await Future<void>.delayed(Duration(seconds: 3));
      _updateBalance();
      updateTransactions();
    }
  }

  Future<void> updateTransactions() async {
    try {
      if (_isTransactionUpdating) {
        return;
      }

      _isTransactionUpdating = true;
      final transactions = await fetchTransactions();
      transactionHistory.addMany(transactions);
      await transactionHistory.save();
      _isTransactionUpdating = false;
    } catch (_) {
      _isTransactionUpdating = false;
    }
  }

  @override
  Future<Map<String, NanoTransactionInfo>> fetchTransactions() async {
    String address = _publicAddress!;

    final transactions = await _client.fetchTransactions(address);

    final Map<String, NanoTransactionInfo> result = {};

    for (var transactionModel in transactions) {
      result[transactionModel.hash] = NanoTransactionInfo(
        id: transactionModel.hash,
        amountRaw: transactionModel.amount,
        height: transactionModel.height,
        direction: transactionModel.type == "send"
            ? TransactionDirection.outgoing
            : TransactionDirection.incoming,
        confirmed: transactionModel.confirmed,
        date: transactionModel.date ?? DateTime.now(),
        confirmations: transactionModel.confirmed ? 1 : 0,
      );
    }

    return result;
  }

  @override
  NanoWalletKeys get keys {
    return NanoWalletKeys(seedKey: _seedKey!);
  }

  @override
  String? get privateKey => _seedKey!;

  @override
  Future<void> rescan({required int height}) async {
    updateTransactions();
    _updateBalance();
    return;
  }

  @override
  Future<void> save() async {
    await walletAddresses.updateAddressesInBox();
    final path = await makePath();
    await write(path: path, password: _password, data: toJSON());
    await transactionHistory.save();
  }

  @override
  String get seed => _mnemonic;

  String get representative => _representativeAddress ?? "";

  @action
  @override
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();
      await _updateBalance();
      await updateTransactions();

      _receiveTimer?.cancel();
      _receiveTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
        // get our balance:
        await _updateBalance();
        // if we have anything to receive, process it:
        if (balance[currency]!.receivableBalance > BigInt.zero) {
          await _receiveAll();
        }
      });

      syncStatus = SyncedSyncStatus();
    } catch (e) {
      print(e);
      syncStatus = FailedSyncStatus();
      rethrow;
    }
  }

  Future<String> makePath() async => pathForWallet(name: walletInfo.name, type: walletInfo.type);

  String toJSON() => json.encode({
        'seedKey': _seedKey,
        'mnemonic': _mnemonic,
        'currentBalance': balance[currency]?.currentBalance.toString() ?? "0",
        'receivableBalance': balance[currency]?.receivableBalance.toString() ?? "0",
        'derivationType': _derivationType.toString()
      });

  static Future<NanoWallet> open({
    required String name,
    required String password,
    required WalletInfo walletInfo,
  }) async {
    final path = await pathForWallet(name: name, type: walletInfo.type);
    final jsonSource = await read(path: path, password: password);

    final data = json.decode(jsonSource) as Map;
    final mnemonic = data['mnemonic'] as String;
    final balance = NanoBalance.fromString(
        formattedCurrentBalance: data['currentBalance'] as String? ?? "0",
        formattedReceivableBalance: data['receivableBalance'] as String? ?? "0");

    DerivationType derivationType = DerivationType.bip39;
    if (data['derivationType'] == "DerivationType.nano") {
      derivationType = DerivationType.nano;
    }

    walletInfo.derivationType = derivationType;

    return NanoWallet(
      walletInfo: walletInfo,
      password: password,
      mnemonic: mnemonic,
      initialBalance: balance,
    );
    // init() should always be run after this!
  }

  Future<void> _updateBalance() async {
    try {
      balance[currency] = await _client.getBalance(_publicAddress!);
    } catch (e) {
      print("Failed to get balance $e");
    }
    await save();
  }

  Future<void> _updateRep() async {
    try {
      AccountInfoResponse accountInfo = (await _client.getAccountInfo(_publicAddress!))!;
      _representativeAddress = accountInfo.representative;
    } catch (e) {
      // account not found:
      _representativeAddress = NanoClient.DEFAULT_REPRESENTATIVE;
      throw Exception("Failed to get representative address $e");
    }
  }

  Future<void> regenerateAddress() async {
    final String type = (_derivationType == DerivationType.nano) ? "standard" : "hd";
    _privateKey =
        await NanoUtil.uniSeedToPrivate(_seedKey!, this.walletAddresses.account!.id, type);
    _publicAddress =
        await NanoUtil.uniSeedToAddress(_seedKey!, this.walletAddresses.account!.id, type);

    this.walletInfo.address = _publicAddress!;
    this.walletAddresses.address = _publicAddress!;
  }

  Future<void> changeRep(String address) async {
    try {
      final String hash = await _client.changeRep(
        privateKey: _privateKey!,
        repAddress: address,
        ourAddress: _publicAddress!,
      );
      if (hash.isNotEmpty) {
        _representativeAddress = address;
      }
    } catch (e) {
      throw Exception("Failed to change representative address $e");
    }
  }

  Future<void>? updateBalance() async => await _updateBalance();

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    final currentWalletPath = await pathForWallet(name: walletInfo.name, type: type);
    final currentWalletFile = File(currentWalletPath);

    final currentDirPath = await pathForWalletDir(name: walletInfo.name, type: type);
    final currentTransactionsFile = File('$currentDirPath/$transactionsHistoryFileName');

    // Copies current wallet files into new wallet name's dir and files
    if (currentWalletFile.existsSync()) {
      final newWalletPath = await pathForWallet(name: newWalletName, type: type);
      await currentWalletFile.copy(newWalletPath);
    }
    if (currentTransactionsFile.existsSync()) {
      final newDirPath = await pathForWalletDir(name: newWalletName, type: type);
      await currentTransactionsFile.copy('$newDirPath/$transactionsHistoryFileName');
    }

    // Delete old name's dir and files
    await Directory(currentDirPath).delete(recursive: true);
  }
}
