import 'dart:typed_data';
import 'dart:convert';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet_keys.dart';
import 'package:cake_wallet/src/domain/bitcoin/bitcoin_amount_format.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobx/mobx.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitcoin_flutter/src/payments/index.dart' show PaymentData;
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_history.dart';
import 'package:cake_wallet/bitcoin/bitcoin_address_record.dart';
import 'package:cake_wallet/bitcoin/file.dart';
import 'package:cake_wallet/bitcoin/electrum.dart';
import 'package:cake_wallet/bitcoin/bitcoin_balance.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:rxdart/rxdart.dart';

part 'bitcoin_wallet.g.dart';

class BitcoinWallet = BitcoinWalletBase with _$BitcoinWallet;

abstract class BitcoinWalletBase extends WalletBase<BitcoinBalance> with Store {
  static BitcoinWallet fromJSON(
      {@required String password,
      @required String name,
      @required String dirPath,
      String jsonSource}) {
    final data = json.decode(jsonSource) as Map;
    final mnemonic = data['mnemonic'] as String;
    final accountIndex =
        (data['account_index'] == 'null' || data['account_index'] == null)
            ? 0
            : int.parse(data['account_index'] as String);
    final _addresses = data['addresses'] as List;
    final addresses = <BitcoinAddressRecord>[];
    final balance = BitcoinBalance.fromJSON(data['balance'] as String) ??
        BitcoinBalance(confirmed: 0, unconfirmed: 0);

    _addresses?.forEach((Object el) {
      if (el is String) {
        addresses.add(BitcoinAddressRecord.fromJSON(el));
      }
    });

    return BitcoinWalletBase.build(
        dirPath: dirPath,
        mnemonic: mnemonic,
        password: password,
        name: name,
        accountIndex: accountIndex,
        initialAddresses: addresses,
        initialBalance: balance);
  }

  static BitcoinWallet build(
      {@required String mnemonic,
      @required String password,
      @required String name,
      @required String dirPath,
      List<BitcoinAddressRecord> initialAddresses,
      BitcoinBalance initialBalance,
      int accountIndex = 0}) {
    final walletPath = '$dirPath/$name';
    final eclient = ElectrumClient();
    final history = BitcoinTransactionHistory(
        eclient: eclient, dirPath: dirPath, password: password);

    return BitcoinWallet._internal(
        eclient: eclient,
        path: walletPath,
        name: name,
        mnemonic: mnemonic,
        password: password,
        accountIndex: accountIndex,
        initialAddresses: initialAddresses,
        initialBalance: initialBalance,
        transactionHistory: history);
  }

  BitcoinWalletBase._internal(
      {@required this.eclient,
      @required this.path,
      @required String password,
      @required this.name,
      List<BitcoinAddressRecord> initialAddresses,
      int accountIndex = 0,
      this.transactionHistory,
      this.mnemonic,
      BitcoinBalance initialBalance}) {
    type = WalletType.bitcoin;
    currency = CryptoCurrency.btc;
    balance = initialBalance ?? BitcoinBalance(confirmed: 0, unconfirmed: 0);
    hd = bitcoin.HDWallet.fromSeed(bip39.mnemonicToSeed(mnemonic),
        network: bitcoin.bitcoin);
    addresses = initialAddresses != null
        ? ObservableList<BitcoinAddressRecord>.of(initialAddresses)
        : ObservableList<BitcoinAddressRecord>();
    syncStatus = NotConnectedSyncStatus();

    _password = password;
    _accountIndex = accountIndex;
  }

  @override
  final BitcoinTransactionHistory transactionHistory;
  final String path;
  bitcoin.HDWallet hd;
  final ElectrumClient eclient;
  final String mnemonic;

  @override
  String name;

  @override
  @observable
  String address;

  @override
  @observable
  BitcoinBalance balance;

  @override
  @observable
  SyncStatus syncStatus;

  ObservableList<BitcoinAddressRecord> addresses;

  String get xpub => hd.base58;

  @override
  String get seed => mnemonic;

  @override
  BitcoinWalletKeys get keys => BitcoinWalletKeys(
      wif: hd.wif, privateKey: hd.privKey, publicKey: hd.pubKey);

  int _accountIndex;
  String _password;
  BehaviorSubject<Object> _addressUpdateSubject;

  Future<void> init() async {
    if (addresses.isEmpty) {
      addresses.add(BitcoinAddressRecord(_getAddress(hd: hd, index: 0)));
    }

    address = addresses.first.address;
    transactionHistory.wallet = this;
    await transactionHistory.init();
  }

  Future<BitcoinAddressRecord> generateNewAddress({String label}) async {
    _accountIndex += 1;
    final address = BitcoinAddressRecord(
        _getAddress(hd: hd, index: _accountIndex),
        label: label);
    addresses.add(address);

    await save();

    return address;
  }

  Future<void> updateAddress(String address, {String label}) async {
    for (final addr in addresses) {
      if (addr.address == address) {
        addr.label = label;
        await save();
        break;
      }
    }
  }

  @action
  @override
  Future<void> startSync() async {
    try {
      syncStatus = StartingSyncStatus();
      await _addressUpdateSubject?.close();
      _addressUpdateSubject = eclient.addressUpdate(address: address);
      await transactionHistory.update();
      await _updateBalance();
      syncStatus = SyncedSyncStatus();
    } catch (e) {
      print(e.toString());
      syncStatus = FailedSyncStatus();
    }
  }

  @action
  @override
  Future<void> connectToNode({@required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();
      await eclient.connect(host: 'electrum2.hodlister.co', port: 50002);
      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      print(e.toString);
      syncStatus = FailedSyncStatus();
    }
  }

  @override
  Future<void> createTransaction(Object credentials) async {
    final transactionCredentials = credentials as BitcoinTransactionCredentials;

    final txb = bitcoin.TransactionBuilder(network: bitcoin.bitcoin);
    final keyPair = bitcoin.ECPair.fromWIF(hd.wif);
    final transactions = transactionHistory.transactions;
    transactions.sort((q, w) => q.height.compareTo(w.height));
    final prevTx = transactions.first;

    txb.setVersion(1);
    txb.addInput(prevTx, 0);
    txb.addOutput(transactionCredentials.address,
        doubleToBitcoinAmount(transactionCredentials.amount));
    txb.sign(vin: 0, keyPair: keyPair);
    final encoded = txb.build().toHex();

    print('Enoded transaction $encoded');
    await eclient.broadcastTransaction(transactionRaw: encoded);
  }

  @override
  Future<void> save() async =>
      await write(path: path, password: _password, data: toJSON());

  String toJSON() => json.encode({
        'mnemonic': mnemonic,
        'account_index': _accountIndex.toString(),
        'addresses': addresses.map((addr) => addr.toJSON()).toList(),
        'balance': balance?.toJSON()
      });

  String _getAddress({bitcoin.HDWallet hd, int index}) => bitcoin
      .P2WPKH(
          data: PaymentData(
              pubkey: Uint8List.fromList(hd.derive(index).pubKey.codeUnits)))
      .data
      .address;

  Future<BitcoinBalance> _fetchBalances() async {
    final balances = await Future.wait(
        addresses.map((record) => eclient.getBalance(address: record.address)));
    final balance = balances.fold(
        BitcoinBalance(confirmed: 0, unconfirmed: 0),
        (BitcoinBalance acc, val) => BitcoinBalance(
            confirmed: (val['confirmed'] as int ?? 0) + (acc.confirmed ?? 0),
            unconfirmed:
                (val['unconfirmed'] as int ?? 0) + (acc.unconfirmed ?? 0)));

    return balance;
  }

  Future<void> _updateBalance() async {
    balance = await _fetchBalances();
    await save();
  }
}
