import 'dart:async';
import 'dart:convert';
import 'package:cake_wallet/bitcoin/unspent_coins_info.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/bitcoin/electrum_wallet_addresses.dart';
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
      @required Box<UnspentCoinsInfo> unspentCoinsInfo,
      @required List<BitcoinAddressRecord> initialAddresses,
      @required this.networkType,
      @required this.mnemonic,
      ElectrumClient electrumClient,
      ElectrumBalance initialBalance})
      : balance = initialBalance ??
            const ElectrumBalance(confirmed: 0, unconfirmed: 0),
        hd = bitcoin.HDWallet.fromSeed(mnemonicToSeedBytes(mnemonic),
                network: networkType)
            .derivePath("m/0'/0"),
        syncStatus = NotConnectedSyncStatus(),
        _password = password,
        _feeRates = <int>[],
        _isTransactionUpdating = false,
        super(walletInfo) {
    this.electrumClient = electrumClient ?? ElectrumClient();
    this.walletInfo = walletInfo;
    this.unspentCoinsInfo = unspentCoinsInfo;
    transactionHistory =
        ElectrumTransactionHistory(walletInfo: walletInfo, password: password);
    unspentCoins = [];
    _scripthashesUpdateSubject = {};
  }

  static int estimatedTransactionSize(int inputsCount, int outputsCounts) =>
      inputsCount * 146 + outputsCounts * 33 + 8;

  final bitcoin.HDWallet hd;
  final String mnemonic;

  ElectrumClient electrumClient;
  Box<UnspentCoinsInfo> unspentCoinsInfo;

  @override
  ElectrumWalletAddresses walletAddresses;

  @override
  @observable
  ElectrumBalance balance;

  @override
  @observable
  SyncStatus syncStatus;

  List<String> get scriptHashes => walletAddresses.addresses
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
  List<BitcoinUnspent> unspentCoins;
  List<int> _feeRates;
  Map<String, BehaviorSubject<Object>> _scripthashesUpdateSubject;
  bool _isTransactionUpdating;

  Future<void> init() async {
    await walletAddresses.init();
    await transactionHistory.init();
    await save();
  }

  @action
  @override
  Future<void> startSync() async {
    try {
      syncStatus = StartingSyncStatus();
      await updateTransactions();
      _subscribeForUpdates();
      await _updateBalance();
      await updateUnspent();
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
    final outputs = transactionCredentials.outputs;
    final hasMultiDestination = outputs.length > 1;
    var allInputsAmount = 0;

    if (unspentCoins.isEmpty) {
      await updateUnspent();
    }

    for (final utx in unspentCoins) {
      if (utx.isSending) {
        allInputsAmount += utx.value;
        inputs.add(utx);
      }
    }

    if (inputs.isEmpty) {
      throw BitcoinTransactionNoInputsException();
    }

    final allAmountFee = feeAmountForPriority(
        transactionCredentials.priority, inputs.length, outputs.length);
    final allAmount = allInputsAmount - allAmountFee;

    var credentialsAmount = 0;
    var amount = 0;
    var fee = 0;

    if (hasMultiDestination) {
      if (outputs.any((item) => item.sendAll
          || item.formattedCryptoAmount <= 0)) {
        throw BitcoinTransactionWrongBalanceException(currency);
      }

      credentialsAmount = outputs.fold(0, (acc, value) =>
          acc + value.formattedCryptoAmount);

      if (allAmount - credentialsAmount < minAmount) {
        throw BitcoinTransactionWrongBalanceException(currency);
      }

      amount = credentialsAmount;

      fee = calculateEstimatedFee(transactionCredentials.priority, amount,
          outputsCount: outputs.length + 1);
    } else {
      final output = outputs.first;

      credentialsAmount = !output.sendAll
          ? output.formattedCryptoAmount
          : 0;

      if (credentialsAmount > allAmount) {
        throw BitcoinTransactionWrongBalanceException(currency);
      }

      amount = output.sendAll || allAmount - credentialsAmount < minAmount
          ? allAmount
          : credentialsAmount;

      fee = output.sendAll || amount == allAmount
          ? allAmountFee
          : calculateEstimatedFee(transactionCredentials.priority, amount);
    }

    if (fee == 0) {
      throw BitcoinTransactionWrongBalanceException(currency);
    }

    final totalAmount = amount + fee;

    if (totalAmount > balance.confirmed || totalAmount > allInputsAmount) {
      throw BitcoinTransactionWrongBalanceException(currency);
    }

    final txb = bitcoin.TransactionBuilder(network: networkType);
    final changeAddress = walletAddresses.address;
    var leftAmount = totalAmount;
    var totalInputAmount = 0;

    inputs.clear();

    for (final utx in unspentCoins) {
      if (utx.isSending) {
        leftAmount = leftAmount - utx.value;
        totalInputAmount += utx.value;
        inputs.add(utx);

        if (leftAmount <= 0) {
          break;
        }
      }
    }

    if (inputs.isEmpty) {
      throw BitcoinTransactionNoInputsException();
    }

    if (amount <= 0 || totalInputAmount < totalAmount) {
      throw BitcoinTransactionWrongBalanceException(currency);
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

    outputs.forEach((item) {
      final outputAmount = hasMultiDestination
          ? item.formattedCryptoAmount
          : amount;

      txb.addOutput(
          addressToOutputScript(item.address, networkType),
          outputAmount);
    });

    final estimatedSize =
      estimatedTransactionSize(inputs.length, outputs.length + 1);
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
        'account_index': walletAddresses.accountIndex.toString(),
        'addresses': walletAddresses.addresses.map((addr) => addr.toJSON()).toList(),
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
  int calculateEstimatedFee(TransactionPriority priority, int amount,
  {int outputsCount}) {
    if (priority is BitcoinTransactionPriority) {
      int inputsCount = 0;

      if (amount != null) {
        int totalValue = 0;

        for (final input in unspentCoins) {
          if (totalValue >= amount) {
            break;
          }

          if (input.isSending) {
            totalValue += input.value;
            inputsCount += 1;
          }
        }

        if (totalValue < amount) return 0;
      } else {
        for (final input in unspentCoins) {
          if (input.isSending) {
            inputsCount += 1;
          }
        }
      }

      // If send all, then we have no change value
      final _outputsCount = outputsCount ?? (amount != null ? 2 : 1);

      return feeAmountForPriority(
          priority, inputsCount, _outputsCount);
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

  Future<String> makePath() async =>
      pathForWallet(name: walletInfo.name, type: walletInfo.type);

  Future<void> updateUnspent() async {
    final unspent = await Future.wait(walletAddresses
        .addresses.map((address) => electrumClient
        .getListUnspentWithAddress(address.address, networkType)
        .then((unspent) => unspent
            .map((unspent) => BitcoinUnspent.fromJSON(address, unspent)))));
    unspentCoins = unspent.expand((e) => e).toList();

    if (unspentCoinsInfo.isEmpty) {
      unspentCoins.forEach((coin) => _addCoinInfo(coin));
      return;
    }

    if (unspentCoins.isNotEmpty) {
      unspentCoins.forEach((coin) {
        final coinInfoList = unspentCoinsInfo.values.where((element) =>
          element.walletId.contains(id) && element.hash.contains(coin.hash));

        if (coinInfoList.isNotEmpty) {
          final coinInfo = coinInfoList.first;

          coin.isFrozen = coinInfo.isFrozen;
          coin.isSending = coinInfo.isSending;
          coin.note = coinInfo.note;
        } else {
          _addCoinInfo(coin);
        }
      });
    }

    await _refreshUnspentCoinsInfo();
  }

  Future<void> _addCoinInfo(BitcoinUnspent coin) async {
    final newInfo = UnspentCoinsInfo(
        walletId: id,
        hash: coin.hash,
        isFrozen: coin.isFrozen,
        isSending: coin.isSending,
        note: coin.note
    );

    await unspentCoinsInfo.add(newInfo);
  }

  Future<void> _refreshUnspentCoinsInfo() async {
    try {
      final List<dynamic> keys = <dynamic>[];
      final currentWalletUnspentCoins = unspentCoinsInfo.values
          .where((element) => element.walletId.contains(id));

      if (currentWalletUnspentCoins.isNotEmpty) {
        currentWalletUnspentCoins.forEach((element) {
          final existUnspentCoins = unspentCoins
              ?.where((coin) => element.hash.contains(coin?.hash));

          if (existUnspentCoins?.isEmpty ?? true) {
            keys.add(element.key);
          }
        });
      }

      if (keys.isNotEmpty) {
        await unspentCoinsInfo.deleteAll(keys);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<ElectrumTransactionInfo> fetchTransactionInfo(
      {@required String hash, @required int height}) async {
    final tx = await electrumClient.getTransactionExpanded(hash: hash);
    return ElectrumTransactionInfo.fromElectrumVerbose(tx, walletInfo.type,
        height: height, addresses: walletAddresses.addresses);
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
          await updateUnspent();
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
