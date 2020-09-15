import 'dart:async';
import 'dart:convert';
import 'package:mobx/mobx.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cake_wallet/bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_no_inputs_exception.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_wrong_balance_exception.dart';
import 'package:cake_wallet/bitcoin/bitcoin_unspent.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet_keys.dart';
import 'package:cake_wallet/bitcoin/electrum.dart';
import 'package:cake_wallet/bitcoin/pending_bitcoin_transaction.dart';
import 'package:cake_wallet/bitcoin/script_hash.dart';
import 'package:cake_wallet/bitcoin/utils.dart';
import 'package:cake_wallet/src/domain/bitcoin/bitcoin_amount_format.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/domain/common/transaction_priority.dart';
import 'package:cake_wallet/src/domain/common/wallet_info.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_history.dart';
import 'package:cake_wallet/bitcoin/bitcoin_address_record.dart';
import 'package:cake_wallet/bitcoin/file.dart';
import 'package:cake_wallet/bitcoin/bitcoin_balance.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/core/wallet_base.dart';

part 'bitcoin_wallet.g.dart';

class BitcoinWallet = BitcoinWalletBase with _$BitcoinWallet;

abstract class BitcoinWalletBase extends WalletBase<BitcoinBalance> with Store {
  BitcoinWalletBase._internal(
      {@required this.eclient,
      @required this.path,
      @required String password,
      @required WalletInfo walletInfo,
      @required List<BitcoinAddressRecord> initialAddresses,
      int accountIndex = 0,
      this.transactionHistory,
      this.mnemonic,
      BitcoinBalance initialBalance})
      : balance =
            initialBalance ?? BitcoinBalance(confirmed: 0, unconfirmed: 0),
        hd = bitcoin.HDWallet.fromSeed(bip39.mnemonicToSeed(mnemonic),
            network: bitcoin.bitcoin),
        addresses = initialAddresses != null
            ? ObservableList<BitcoinAddressRecord>.of(initialAddresses)
            : ObservableList<BitcoinAddressRecord>(),
        syncStatus = NotConnectedSyncStatus(),
        _password = password,
        _accountIndex = accountIndex,
        super(walletInfo) {
    _scripthashesUpdateSubject = {};
  }

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
    final _addresses = data['addresses'] as List ?? <Object>[];
    final addresses = <BitcoinAddressRecord>[];
    final balance = BitcoinBalance.fromJSON(data['balance'] as String) ??
        BitcoinBalance(confirmed: 0, unconfirmed: 0);

    _addresses.forEach((Object el) {
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
        mnemonic: mnemonic,
        password: password,
        accountIndex: accountIndex,
        initialAddresses: initialAddresses,
        initialBalance: initialBalance,
        transactionHistory: history);
  }

  @override
  final BitcoinTransactionHistory transactionHistory;
  final String path;
  final bitcoin.HDWallet hd;
  final ElectrumClient eclient;
  final String mnemonic;

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

  List<String> get scriptHashes =>
      addresses.map((addr) => scriptHash(addr.address)).toList();

  String get xpub => hd.base58;

  @override
  String get seed => mnemonic;

  @override
  BitcoinWalletKeys get keys => BitcoinWalletKeys(
      wif: hd.wif, privateKey: hd.privKey, publicKey: hd.pubKey);

  final String _password;
  int _accountIndex;
  Map<String, BehaviorSubject<Object>> _scripthashesUpdateSubject;

  Future<void> init() async {
    if (addresses.isEmpty) {
      final index = 0;
      addresses
          .add(BitcoinAddressRecord(_getAddress(index: index), index: index));
    }

    address = addresses.first.address;
    transactionHistory.wallet = this;
    await transactionHistory.init();
  }

  Future<BitcoinAddressRecord> generateNewAddress({String label}) async {
    _accountIndex += 1;
    final address = BitcoinAddressRecord(_getAddress(index: _accountIndex),
        index: _accountIndex, label: label);
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
      transactionHistory.updateAsync(
          onFinished: () => print('transactionHistory update finished!'));
      _subscribeForUpdates();
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
      await eclient.connectToUri(node.uri);
      eclient.onConnectionStatusChange = (bool isConnected) {
        if (!isConnected) {
          syncStatus = LostConnectionSyncStatus();
        }
      };
      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      print(e.toString());
      syncStatus = FailedSyncStatus();
    }
  }

  @override
  Future<PendingBitcoinTransaction> createTransaction(
      Object credentials) async {
    final transactionCredentials = credentials as BitcoinTransactionCredentials;
    final inputs = <BitcoinUnspent>[];
    final fee = _feeMultiplier(transactionCredentials.priority);
    final amount = transactionCredentials.amount != null
        ? doubleToBitcoinAmount(transactionCredentials.amount)
        : balance.total - fee;
    final totalAmount = amount + fee;
    final txb = bitcoin.TransactionBuilder(network: bitcoin.bitcoin);
    var leftAmount = totalAmount;
    final changeAddress = address;
    var totalInputAmount = 0;

    final unspent = addresses.map((address) => eclient
        .getListUnspentWithAddress(address.address)
        .then((unspent) => unspent
            .map((unspent) => BitcoinUnspent.fromJSON(address, unspent))));

    for (final unptsFutures in unspent) {
      final utxs = await unptsFutures;

      for (final utx in utxs) {
        final inAmount = utx.value > totalAmount ? totalAmount : utx.value;
        leftAmount = leftAmount - inAmount;
        totalInputAmount += inAmount;
        inputs.add(utx);

        if (leftAmount <= 0) {
          break;
        }
      }

      if (leftAmount <= 0) {
        break;
      }
    }

    if (inputs.isEmpty) {
      throw BitcoinTransactionNoInputsException();
    }

    if (amount <= 0 || totalInputAmount < amount) {
      throw BitcoinTransactionWrongBalanceException();
    }

    final changeValue = totalInputAmount - amount - fee;

    txb.setVersion(1);

    inputs.forEach((input) {
      if (input.isP2wpkh) {
        final p2wpkh = bitcoin
            .P2WPKH(
                data: generatePaymentData(hd: hd, index: input.address.index),
                network: bitcoin.bitcoin)
            .data;

        txb.addInput(input.hash, input.vout, null, p2wpkh.output);
      } else {
        txb.addInput(input.hash, input.vout);
      }
    });

    txb.addOutput(transactionCredentials.address, amount);

    if (changeValue > 0) {
      txb.addOutput(changeAddress, changeValue);
    }

    for (var i = 0; i < inputs.length; i++) {
      final input = inputs[i];
      final keyPair = generateKeyPair(hd: hd, index: input.address.index);
      final witnessValue = input.isP2wpkh ? input.value : null;

      txb.sign(vin: i, keyPair: keyPair, witnessValue: witnessValue);
    }

    return PendingBitcoinTransaction(txb.build(),
        eclient: eclient, amount: amount, fee: fee)
      ..addListener((transaction) => transactionHistory.addOne(transaction));
  }

  String toJSON() => json.encode({
        'mnemonic': mnemonic,
        'account_index': _accountIndex.toString(),
        'addresses': addresses.map((addr) => addr.toJSON()).toList(),
        'balance': balance?.toJSON()
      });

  @override
  double calculateEstimatedFee(TransactionPriority priority) =>
      bitcoinAmountToDouble(amount: _feeMultiplier(priority));

  @override
  Future<void> save() async =>
      await write(path: path, password: _password, data: toJSON());

  bitcoin.ECPair keyPairFor({@required int index}) =>
      generateKeyPair(hd: hd, index: index);

  void _subscribeForUpdates() {
    scriptHashes.forEach((sh) async {
      await _scripthashesUpdateSubject[sh]?.close();
      _scripthashesUpdateSubject[sh] = eclient.scripthashUpdate(sh);
      _scripthashesUpdateSubject[sh].listen((event) async {
        transactionHistory.updateAsync();
        await _updateBalance();
      });
    });
  }

  Future<BitcoinBalance> _fetchBalances() async {
    final balances = await Future.wait(
        scriptHashes.map((sHash) => eclient.getBalance(sHash)));
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

  String _getAddress({@required int index}) =>
      generateAddress(hd: hd, index: index);

  int _feeMultiplier(TransactionPriority priority) {
    switch (priority) {
      case TransactionPriority.slow:
        return 6000;
      case TransactionPriority.regular:
        return 9000;
      case TransactionPriority.fast:
        return 15000;
      default:
        return 0;
    }
  }
}
