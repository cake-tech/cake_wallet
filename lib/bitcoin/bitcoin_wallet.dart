import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cake_wallet/bitcoin/bitcoin_amount_format.dart';
import 'package:cake_wallet/bitcoin/bitcoin_balance.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitcoin_flutter/src/payments/index.dart' show PaymentData;
import 'package:cake_wallet/bitcoin/file.dart';
import 'package:cake_wallet/bitcoin/electrum.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_history.dart';
import 'package:cake_wallet/src/domain/common/pathForWallet.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/common/pending_transaction.dart';
import 'package:cake_wallet/src/domain/common/transaction_creation_credentials.dart';
import 'package:cake_wallet/src/domain/common/transaction_history.dart';
import 'package:cake_wallet/src/domain/common/wallet.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';

class BitcoinWallet extends Wallet {
  BitcoinWallet(
      {@required this.hdwallet,
      @required this.eclient,
      @required this.path,
      @required String password,
      int accountIndex = 0,
      this.mnemonic})
      : _accountIndex = accountIndex,
        _password = password,
        _syncStatus = BehaviorSubject<SyncStatus>(),
        _onBalanceChange = BehaviorSubject<BitcoinBalance>(),
        _onAddressChange = BehaviorSubject<String>(),
        _onNameChange = BehaviorSubject<String>();

  @override
  Observable<BitcoinBalance> get onBalanceChange => _onBalanceChange.stream;

  @override
  Observable<SyncStatus> get syncStatus => _syncStatus.stream;

  @override
  String get name => path.split('/').last ?? '';
  @override
  String get address => hdwallet.address;
  String get xpub => hdwallet.base58;

  final String path;
  final bitcoin.HDWallet hdwallet;
  final ElectrumClient eclient;
  final String mnemonic;
  BitcoinTransactionHistory history;

  final BehaviorSubject<SyncStatus> _syncStatus;
  final BehaviorSubject<BitcoinBalance> _onBalanceChange;
  final BehaviorSubject<String> _onAddressChange;
  final BehaviorSubject<String> _onNameChange;
  BehaviorSubject<Object> _addressUpdatesSubject;
  StreamSubscription<Object> _addressUpdatesSubscription;
  final String _password;
  int _accountIndex;

  static Future<BitcoinWallet> load(
      {@required String name, @required String password}) async {
    final walletDirPath =
        await pathForWalletDir(name: name, type: WalletType.bitcoin);
    final walletPath = '$walletDirPath/$name';
    final walletJSONRaw = await read(path: walletPath, password: password);
    final jsoned = json.decode(walletJSONRaw) as Map<String, Object>;
    final mnemonic = jsoned['mnemonic'] as String;
    final accountIndex =
        (jsoned['account_index'] == "null" || jsoned['account_index'] == null)
            ? 0
            : int.parse(jsoned['account_index'] as String);

    return await build(
        mnemonic: mnemonic,
        password: password,
        name: name,
        accountIndex: accountIndex);
  }

  static Future<BitcoinWallet> build(
      {@required String mnemonic,
      @required String password,
      @required String name,
      int accountIndex = 0}) async {
    final hd = bitcoin.HDWallet.fromSeed(bip39.mnemonicToSeed(mnemonic),
        network: bitcoin.bitcoin);
    final walletDirPath =
        await pathForWalletDir(name: name, type: WalletType.bitcoin);
    final walletPath = '$walletDirPath/$name';
    final historyPath = '$walletDirPath/transactions.json';
    final eclient = ElectrumClient();
    final wallet = BitcoinWallet(
        hdwallet: hd,
        eclient: eclient,
        path: walletPath,
        mnemonic: mnemonic,
        password: password,
        accountIndex: accountIndex);
    final history = BitcoinTransactionHistory(
        eclient: eclient,
        path: historyPath,
        password: password,
        wallet: wallet);
    wallet.history = history;
    await history.init();

    // await wallet.connectToNode(
    //     node: Node(uri: 'https://electrum2.hodlister.co:50002'));

    // final transactions = await history.fetchTransactions();

    // final balance = await wallet.fetchBalance();

    // print('balance\n$balance');

    // transactions.forEach((tx) => print(tx.id));

    await wallet.updateInfo();

    return wallet;
  }

  List<String> getAddresses() => _accountIndex == 0
      ? [address]
      : List<String>.generate(
          _accountIndex, (i) => _getAddress(hd: hdwallet, index: i));

  Future<String> newAddress() async {
    _accountIndex += 1;
    final address = _getAddress(hd: hdwallet, index: _accountIndex);
    await save();

    return address;
  }

  @override
  Future close() async {
    await _addressUpdatesSubscription?.cancel();
  }

  @override
  Future connectToNode(
      {Node node, bool useSSL = false, bool isLightWallet = false}) async {
    try {
      // FIXME: Hardcoded server address
      // final uri = Uri.parse(node.uri);
      // https://electrum2.hodlister.co:50002
      await eclient.connect(host: 'electrum2.hodlister.co', port: 50002);
      _syncStatus.value = ConnectedSyncStatus();
    } catch (e) {
      print(e.toString());
      _syncStatus.value = FailedSyncStatus();
    }
  }

  @override
  Future<PendingTransaction> createTransaction(
      TransactionCreationCredentials credentials) {
        final txb = TransactionBuilder(network: bitcoin.bitcoin);

    // TODO: implement createTransaction
    return null;
  }

  @override
  Future<String> getAddress() async => address;

  @override
  Future<int> getCurrentHeight() async => 0;

  @override
  Future<String> getFilename() async => path.split('/').last ?? '';

  @override
  Future<String> getFullBalance() async =>
      bitcoinAmountToString(amount: _onBalanceChange.value.total);

  @override
  TransactionHistory getHistory() => history;

  @override
  Future<Map<String, String>> getKeys() async =>
      {'publicKey': hdwallet.pubKey, 'privateKey': hdwallet.privKey};

  @override
  Future<String> getName() async => path.split('/').last ?? '';

  @override
  Future<int> getNodeHeight() async => 0;

  @override
  Future<String> getSeed() async => mnemonic;

  @override
  WalletType getType() => WalletType.bitcoin;

  @override
  Future<String> getUnlockedBalance() async =>
      bitcoinAmountToString(amount: _onBalanceChange.value.total);

  @override
  Future<bool> isConnected() async => eclient.isConnected;

  @override
  Observable<String> get onAddressChange => _onAddressChange.stream;

  @override
  Observable<String> get onNameChange => _onNameChange.stream;

  @override
  Future rescan({int restoreHeight = 0}) {
    // TODO: implement rescan
    return null;
  }

  @override
  Future startSync() async {
    _addressUpdatesSubject = eclient.addressUpdate(address: address);
    _addressUpdatesSubscription =
        _addressUpdatesSubject.listen((obj) => print('new obj: $obj'));
    _onBalanceChange.value = await fetchBalance();
    getHistory().update();
  }

  @override
  Future updateInfo() async {
    _onNameChange.value = await getName();
    // _addressUpdatesSubject = eclient.addressUpdate(address: address);
    // _addressUpdatesSubscription =
    //     _addressUpdatesSubject.listen((obj) => print('new obj: $obj'));
    _onBalanceChange.value = BitcoinBalance(confirmed: 0, unconfirmed: 0);
    print(await getKeys());
  }

  Future<BitcoinBalance> fetchBalance() async {
    final balance = await _fetchBalances();

    return BitcoinBalance(
        confirmed: balance['confirmed'], unconfirmed: balance['unconfirmed']);
  }

  Future<void> save() async => await write(
      path: path,
      password: _password,
      obj: {'mnemonic': mnemonic, 'account_index': _accountIndex.toString()});

  String _getAddress({bitcoin.HDWallet hd, int index}) => bitcoin
      .P2PKH(
          data: PaymentData(
              pubkey: Uint8List.fromList(hd.derive(index).pubKey.codeUnits)))
      .data
      .address;

  Future<Map<String, int>> _fetchBalances() async {
    final balances = await Future.wait(
        getAddresses().map((address) => eclient.getBalance(address: address)));
    final balance =
        balances.fold(Map<String, int>(), (Map<String, int> acc, val) {
      acc['confirmed'] =
          (val['confirmed'] as int ?? 0) + (acc['confirmed'] ?? 0);
      acc['unconfirmed'] =
          (val['unconfirmed'] as int ?? 0) + (acc['unconfirmed'] ?? 0);

      return acc;
    });

    return balance;
  }
}
