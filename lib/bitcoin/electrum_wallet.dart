import 'dart:async';
import 'dart:convert';
import 'package:mobx/mobx.dart';
import 'package:rxdart/subjects.dart';
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cake_wallet/bitcoin/electrum_transaction_info.dart';
import 'package:cake_wallet/entities/pathForWallet.dart';
import 'package:cake_wallet/bitcoin/address_to_output_script.dart';
import 'package:cake_wallet/bitcoin/bitcoin_address_record.dart';
import 'package:cake_wallet/bitcoin/bitcoin_amount_format.dart';
import 'package:cake_wallet/bitcoin/electrum_balance.dart';
import 'package:cake_wallet/bitcoin/bitcoin_mnemonic.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cake_wallet/bitcoin/electrum_transaction_history.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_no_inputs_exception.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_priority.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_wrong_balance_exception.dart';
import 'package:cake_wallet/bitcoin/bitcoin_unspent.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet_keys.dart';
import 'package:cake_wallet/bitcoin/file.dart';
import 'package:cake_wallet/bitcoin/pending_bitcoin_transaction.dart';
import 'package:cake_wallet/bitcoin/script_hash.dart';
import 'package:cake_wallet/bitcoin/utils.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/node.dart';
import 'package:cake_wallet/entities/sync_status.dart';
import 'package:cake_wallet/entities/transaction_priority.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/bitcoin/electrum.dart';

part 'electrum_wallet.g.dart';

class ElectrumWallet = ElectrumWalletBase with _$ElectrumWallet;

abstract class ElectrumWalletBase extends WalletBase<ElectrumBalance,
    ElectrumTransactionHistory, ElectrumTransactionInfo> with Store {
  ElectrumWalletBase(
      {@required String password,
      @required WalletInfo walletInfo,
      @required List<BitcoinAddressRecord> initialAddresses,
      @required this.networkType,
      @required this.mnemonic,
      ElectrumClient electrumClient,
      int accountIndex = 0,
      ElectrumBalance initialBalance})
      : balance = initialBalance ??
            const ElectrumBalance(confirmed: 0, unconfirmed: 0),
        hd = bitcoin.HDWallet.fromSeed(mnemonicToSeedBytes(mnemonic),
                network: networkType)
            .derivePath("m/0'/0"),
        addresses = ObservableList<BitcoinAddressRecord>.of(
            (initialAddresses ?? []).toSet()),
        syncStatus = NotConnectedSyncStatus(),
        _password = password,
        _accountIndex = accountIndex,
        _feeRates = <int>[],
        _isTransactionUpdating = false,
        super(walletInfo) {
    this.electrumClient = electrumClient ?? ElectrumClient();
    this.walletInfo = walletInfo;
    transactionHistory =
        ElectrumTransactionHistory(walletInfo: walletInfo, password: password);
    _unspent = [];
    _scripthashesUpdateSubject = {};
  }

  static int estimatedTransactionSize(int inputsCount, int outputsCounts) =>
      inputsCount * 146 + outputsCounts * 33 + 8;

  final bitcoin.HDWallet hd;
  final String mnemonic;

  ElectrumClient electrumClient;

  @override
  @observable
  String address;

  @override
  @observable
  ElectrumBalance balance;

  @override
  @observable
  SyncStatus syncStatus;

  ObservableList<BitcoinAddressRecord> addresses;

  List<String> get scriptHashes => addresses
      .map((addr) => scriptHash(addr.address, networkType: networkType))
      .toList();

  String get xpub => hd.base58;

  @override
  String get seed => mnemonic;

  bitcoin.NetworkType networkType;

  @override
  BitcoinWalletKeys get keys => BitcoinWalletKeys(
      wif: hd.wif, privateKey: hd.privKey, publicKey: hd.pubKey);

  final String _password;
  List<BitcoinUnspent> _unspent;
  List<int> _feeRates;
  int _accountIndex;
  Map<String, BehaviorSubject<Object>> _scripthashesUpdateSubject;
  bool _isTransactionUpdating;

  Future<void> init() async {
    await generateAddresses();
    address = addresses[_accountIndex].address;
    await transactionHistory.init();
  }

  @action
  Future<void> nextAddress() async {
    _accountIndex += 1;

    if (_accountIndex >= addresses.length) {
      _accountIndex = 0;
    }

    address = addresses[_accountIndex].address;

    await updateAddressesInfo();

    await save();
  }

  Future<void> generateAddresses() async {
    if (addresses.length < 33) {
      final addressesCount = 33 - addresses.length;
      await generateNewAddresses(addressesCount,
          startIndex: addresses.length, hd: hd);
    }
  }

  Future<BitcoinAddressRecord> generateNewAddress(
      {bool isHidden = false, bitcoin.HDWallet hd}) async {
    _accountIndex += 1;
    final _hd = hd ?? this.hd;
    final address = BitcoinAddressRecord(
        getAddress(index: _accountIndex, hd: _hd),
        index: _accountIndex,
        isHidden: isHidden);
    addresses.add(address);
    await save();
    return address;
  }

  Future<List<BitcoinAddressRecord>> generateNewAddresses(int count,
      {int startIndex = 0, bitcoin.HDWallet hd, bool isHidden = false}) async {
    final list = <BitcoinAddressRecord>[];

    for (var i = startIndex; i < count + startIndex; i++) {
      final address = BitcoinAddressRecord(getAddress(index: i, hd: hd),
          index: i, isHidden: isHidden);
      list.add(address);
    }

    addresses.addAll(list);
    await save();
    return list;
  }

  Future<void> updateAddress(String address) async {
    for (final addr in addresses) {
      if (addr.address == address) {
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
      updateTransactions();
      _subscribeForUpdates();
      await _updateBalance();
      await _updateUnspent();
      _feeRates = await electrumClient.feeRates();

      Timer.periodic(const Duration(minutes: 1),
          (timer) async => _feeRates = await electrumClient.feeRates());

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
      await electrumClient.connectToUri(node.uri);
      electrumClient.onConnectionStatusChange = (bool isConnected) {
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
    const minAmount = 546;
    final transactionCredentials = credentials as BitcoinTransactionCredentials;
    final inputs = <BitcoinUnspent>[];
    final allAmountFee =
        calculateEstimatedFee(transactionCredentials.priority, null);
    final allAmount = balance.confirmed - allAmountFee;
    var fee = 0;
    final credentialsAmount = transactionCredentials.amount != null
        ? stringDoubleToBitcoinAmount(transactionCredentials.amount)
        : 0;
    final amount = transactionCredentials.amount == null ||
            allAmount - credentialsAmount < minAmount
        ? allAmount
        : credentialsAmount;
    final txb = bitcoin.TransactionBuilder(network: networkType);
    final changeAddress = address;
    var leftAmount = amount;
    var totalInputAmount = 0;

    if (_unspent.isEmpty) {
      await _updateUnspent();
    }

    for (final utx in _unspent) {
      leftAmount = leftAmount - utx.value;
      totalInputAmount += utx.value;
      inputs.add(utx);

      if (leftAmount <= 0) {
        break;
      }
    }

    if (inputs.isEmpty) {
      throw BitcoinTransactionNoInputsException();
    }

    final totalAmount = amount + fee;
    fee = transactionCredentials.amount != null
        ? feeAmountForPriority(transactionCredentials.priority, inputs.length,
            amount == allAmount ? 1 : 2)
        : allAmountFee;

    if (totalAmount > balance.confirmed) {
      throw BitcoinTransactionWrongBalanceException();
    }

    if (amount <= 0 || totalInputAmount < amount) {
      throw BitcoinTransactionWrongBalanceException();
    }

    txb.setVersion(1);

    inputs.forEach((input) {
      if (input.isP2wpkh) {
        final p2wpkh = bitcoin
            .P2WPKH(
                data: generatePaymentData(hd: hd, index: input.address.index),
                network: networkType)
            .data;

        txb.addInput(input.hash, input.vout, null, p2wpkh.output);
      } else {
        txb.addInput(input.hash, input.vout);
      }
    });

    txb.addOutput(
        addressToOutputScript(transactionCredentials.address, networkType),
        amount);

    final estimatedSize = estimatedTransactionSize(inputs.length, 2);
    final feeAmount = feeRate(transactionCredentials.priority) * estimatedSize;
    final changeValue = totalInputAmount - amount - feeAmount;

    if (changeValue > minAmount) {
      txb.addOutput(changeAddress, changeValue);
    }

    for (var i = 0; i < inputs.length; i++) {
      final input = inputs[i];
      final keyPair = generateKeyPair(
          hd: hd, index: input.address.index, network: networkType);
      final witnessValue = input.isP2wpkh ? input.value : null;

      txb.sign(vin: i, keyPair: keyPair, witnessValue: witnessValue);
    }

    return PendingBitcoinTransaction(txb.build(), type,
        electrumClient: electrumClient, amount: amount, fee: fee)
      ..addListener((transaction) async {
        transactionHistory.addOne(transaction);
        await _updateBalance();
      });
  }

  String toJSON() => json.encode({
        'mnemonic': mnemonic,
        'account_index': _accountIndex.toString(),
        'addresses': addresses.map((addr) => addr.toJSON()).toList(),
        'balance': balance?.toJSON()
      });

  int feeRate(TransactionPriority priority) {
    if (priority is BitcoinTransactionPriority) {
      return _feeRates[priority.raw];
    }

    return 0;
  }

  int feeAmountForPriority(BitcoinTransactionPriority priority, int inputsCount,
          int outputsCount) =>
      feeRate(priority) * estimatedTransactionSize(inputsCount, outputsCount);

  @override
  int calculateEstimatedFee(TransactionPriority priority, int amount) {
    if (priority is BitcoinTransactionPriority) {
      int inputsCount = 0;

      if (amount != null) {
        int totalValue = 0;

        for (final input in _unspent) {
          if (totalValue >= amount) {
            break;
          }

          totalValue += input.value;
          inputsCount += 1;
        }
      } else {
        inputsCount = _unspent.length;
      }
      // If send all, then we have no change value
      return feeAmountForPriority(
          priority, inputsCount, amount != null ? 2 : 1);
    }

    return 0;
  }

  @override
  Future<void> save() async {
    final path = await makePath();
    await write(path: path, password: _password, data: toJSON());
    await transactionHistory.save();
  }

  bitcoin.ECPair keyPairFor({@required int index}) =>
      generateKeyPair(hd: hd, index: index, network: networkType);

  @override
  Future<void> rescan({int height}) async => throw UnimplementedError();

  @override
  Future<void> close() async {
    try {
      await electrumClient?.close();
    } catch (_) {}
  }

  String getAddress({@required int index, @required bitcoin.HDWallet hd}) => '';

  Future<String> makePath() async =>
      pathForWallet(name: walletInfo.name, type: walletInfo.type);

  Future<void> _updateUnspent() async {
    final unspent = await Future.wait(addresses.map((address) => electrumClient
        .getListUnspentWithAddress(address.address, networkType)
        .then((unspent) => unspent
            .map((unspent) => BitcoinUnspent.fromJSON(address, unspent)))));
    _unspent = unspent.expand((e) => e).toList();
  }

  Future<ElectrumTransactionInfo> fetchTransactionInfo(
      {@required String hash, @required int height}) async {
    final tx = await electrumClient.getTransactionExpanded(hash: hash);
    return ElectrumTransactionInfo.fromElectrumVerbose(tx, walletInfo.type,
        height: height, addresses: addresses);
  }

  @override
  Future<Map<String, ElectrumTransactionInfo>> fetchTransactions() async {
    final histories =
        scriptHashes.map((scriptHash) => electrumClient.getHistory(scriptHash));
    final _historiesWithDetails = await Future.wait(histories)
        .then((histories) => histories.expand((i) => i).toList())
        .then((histories) => histories.map((tx) => fetchTransactionInfo(
            hash: tx['tx_hash'] as String, height: tx['height'] as int)));
    final historiesWithDetails = await Future.wait(_historiesWithDetails);

    return historiesWithDetails.fold<Map<String, ElectrumTransactionInfo>>(
        <String, ElectrumTransactionInfo>{}, (acc, tx) {
      acc[tx.id] = acc[tx.id]?.updated(tx) ?? tx;
      return acc;
    });
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
    } catch (e) {
      print(e);
      _isTransactionUpdating = false;
    }
  }

  void _subscribeForUpdates() {
    scriptHashes.forEach((sh) async {
      await _scripthashesUpdateSubject[sh]?.close();
      _scripthashesUpdateSubject[sh] = electrumClient.scripthashUpdate(sh);
      _scripthashesUpdateSubject[sh].listen((event) async {
        try {
          await _updateBalance();
          await _updateUnspent();
          await updateTransactions();
        } catch (e) {
          print(e.toString());
        }
      });
    });
  }

  Future<ElectrumBalance> _fetchBalances() async {
    final balances = await Future.wait(
        scriptHashes.map((sh) => electrumClient.getBalance(sh)));
    final balance = balances.fold(
        ElectrumBalance(confirmed: 0, unconfirmed: 0),
        (ElectrumBalance acc, val) => ElectrumBalance(
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
