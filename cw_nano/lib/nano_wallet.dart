import 'dart:convert';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_nano/file.dart';
import 'package:cw_nano/nano_balance.dart';
import 'package:cw_nano/nano_transaction_history.dart';
import 'package:cw_nano/nano_transaction_info.dart';
import 'package:cw_nano/nano_util.dart';
import 'package:mobx/mobx.dart';
import 'dart:async';
import 'package:cw_nano/nano_wallet_addresses.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:web3dart/web3dart.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;

part 'nano_wallet.g.dart';

class NanoWallet = NanoWalletBase with _$NanoWallet;

enum DerivationType { bip39, nano }

abstract class NanoWalletBase
    extends WalletBase<NanoBalance, NanoTransactionHistory, NanoTransactionInfo> with Store {
  NanoWalletBase({
    required WalletInfo walletInfo,
    required String mnemonic,
    required String password,
    required DerivationType derivationType,
    NanoBalance? initialBalance,
  })  : syncStatus = NotConnectedSyncStatus(),
        _password = password,
        _mnemonic = mnemonic,
        _derivationType = derivationType,
        _isTransactionUpdating = false,
        _priorityFees = [],
        walletAddresses = NanoWalletAddresses(walletInfo),
        balance = ObservableMap<CryptoCurrency, NanoBalance>.of({
          CryptoCurrency.nano: initialBalance ??
              NanoBalance(currentBalance: BigInt.zero, receivableBalance: BigInt.zero)
        }),
        super(walletInfo) {
    this.walletInfo = walletInfo;
    transactionHistory = NanoTransactionHistory();
  }

  final String _mnemonic;
  final String _password;
  final DerivationType _derivationType;

  late final String _privateKey;
  late final String _publicAddress;
  late final String _seed;

  List<int> _priorityFees;
  int? _gasPrice;
  bool _isTransactionUpdating;

  @override
  WalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  late ObservableMap<CryptoCurrency, NanoBalance> balance;


  // initialize the different forms of private / public key we'll need:
  Future<void> init() async {
    final String type = (_derivationType == DerivationType.nano) ? "standard" : "hd";

    _seed = bip39.mnemonicToEntropy(_mnemonic).toUpperCase();
    _privateKey = await NanoUtil.uniSeedToPrivate(_mnemonic, 0, type);
    _publicAddress = await NanoUtil.uniSeedToAddress(_mnemonic, 0, type);

    await walletAddresses.init();
    // await transactionHistory.init();

    // walletAddresses.address = _privateKey.address.toString();
    await save();
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    return 0; // always 0 :)
  }

  @override
  Future<void> changePassword(String password) {
    print("e");
    throw UnimplementedError("changePassword");
  }

  @override
  void close() {
    // _client.stop();
  }

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    print("f");
    throw UnimplementedError();
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    print("g");
    throw UnimplementedError();
  }

  Future<void> updateTransactions() async {
    print("h");
    throw UnimplementedError();
  }

  @override
  Future<Map<String, NanoTransactionInfo>> fetchTransactions() async {
    print("i");
    throw UnimplementedError();
  }

  @override
  Object get keys {
    print("j");
    throw UnimplementedError("keys");
  }

  @override
  Future<void> rescan({required int height}) {
    print("k");
    throw UnimplementedError("rescan");
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

  @action
  @override
  Future<void> startSync() async {
    throw UnimplementedError();
  }

  int feeRate(TransactionPriority priority) {
    throw UnimplementedError();
  }

  Future<String> makePath() async => pathForWallet(name: walletInfo.name, type: walletInfo.type);

  String toJSON() => json.encode({
        'mnemonic': _mnemonic,
        // 'balance': balance[currency]!.toJSON(),
      });

  static Future<NanoWallet> open({
    required String name,
    required String password,
    required WalletInfo walletInfo,
  }) async {
    throw UnimplementedError();
  }

  Future<void> _updateBalance() async {
    await save();
  }

  Future<EthPrivateKey> getPrivateKey(String mnemonic, String password) async {
    print("o");
    throw UnimplementedError();
  }

  Future<void>? updateBalance() async => await _updateBalance();

  void _onNewTransaction(FilterEvent event) {
    throw UnimplementedError();
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    print("rename");
    throw UnimplementedError();
  }
}
