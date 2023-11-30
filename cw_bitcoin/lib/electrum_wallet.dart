import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:cw_core/unspent_coins_info.dart';
import 'package:hive/hive.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:mobx/mobx.dart';
import 'package:rxdart/subjects.dart';
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:collection/collection.dart';
import 'package:cw_bitcoin/address_to_output_script.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/bitcoin_transaction_no_inputs_exception.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_transaction_wrong_balance_exception.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/bitcoin_wallet_keys.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_transaction_history.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/file.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_bitcoin/script_hash.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:hex/hex.dart';

part 'electrum_wallet.g.dart';

class ElectrumWallet = ElectrumWalletBase with _$ElectrumWallet;

abstract class ElectrumWalletBase
    extends WalletBase<ElectrumBalance, ElectrumTransactionHistory, ElectrumTransactionInfo>
    with Store {
  ElectrumWalletBase(
      {required String password,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      required this.networkType,
      required this.mnemonic,
      required Uint8List seedBytes,
      required ElectrumTransactionHistory transactionHistory,
      List<BitcoinAddressRecord>? initialAddresses,
      ElectrumClient? electrumClient,
      ElectrumBalance? initialBalance,
      CryptoCurrency? currency})
      : hd = currency == CryptoCurrency.bch
            ? bitcoinCashHDWallet(seedBytes)
            : bitcoin.HDWallet.fromSeed(seedBytes, network: networkType).derivePath("m/0'/0"),
        syncStatus = NotConnectedSyncStatus(),
        _password = password,
        _feeRates = <int>[],
        _isTransactionUpdating = false,
        unspentCoins = [],
        _scripthashesUpdateSubject = {},
        balance = ObservableMap<CryptoCurrency, ElectrumBalance>.of(currency != null
            ? {
                currency:
                    initialBalance ?? const ElectrumBalance(confirmed: 0, unconfirmed: 0, frozen: 0)
              }
            : {}),
        this.unspentCoinsInfo = unspentCoinsInfo,
        super(walletInfo) {
    this.electrumClient = electrumClient ?? ElectrumClient();
    this.walletInfo = walletInfo;
    this.transactionHistory = transactionHistory;
  }

  static bitcoin.HDWallet bitcoinCashHDWallet(Uint8List seedBytes) =>
      bitcoin.HDWallet.fromSeed(seedBytes).derivePath("m/44'/145'/0'/0");

  static int estimatedTransactionSize(int inputsCount, int outputsCounts) =>
      inputsCount * 146 + outputsCounts * 33 + 8;

  final bitcoin.HDWallet hd;
  final String mnemonic;

  late ElectrumClient electrumClient;
  Box<UnspentCoinsInfo> unspentCoinsInfo;

  @override
  late ElectrumWalletAddresses walletAddresses;

  @override
  @observable
  late ObservableMap<CryptoCurrency, ElectrumBalance> balance;

  @override
  @observable
  SyncStatus syncStatus;

  List<String> get scriptHashes => walletAddresses.addresses
      .map((addr) => scriptHash(addr.address, networkType: networkType))
      .toList();

  List<String> get publicScriptHashes => walletAddresses.addresses
      .where((addr) => !addr.isHidden)
      .map((addr) => scriptHash(addr.address, networkType: networkType))
      .toList();

  String get xpub => hd.base58!;

  @override
  String get seed => mnemonic;

  @override
  String get password => _password;

  bitcoin.NetworkType networkType;

  @override
  BitcoinWalletKeys get keys =>
      BitcoinWalletKeys(wif: hd.wif!, privateKey: hd.privKey!, publicKey: hd.pubKey!);

  String _password;
  List<BitcoinUnspent> unspentCoins;
  List<int> _feeRates;
  Map<String, BehaviorSubject<Object>?> _scripthashesUpdateSubject;
  BehaviorSubject<Object>? _chainTipUpdateSubject;
  bool _isTransactionUpdating;
  Future<Isolate>? _isolate;

  void Function(FlutterErrorDetails)? _onError;
  Timer? _autoSaveTimer;
  static const int _autoSaveInterval = 30;

  Future<void> init() async {
    await walletAddresses.init();
    await transactionHistory.init();

    _autoSaveTimer =
        Timer.periodic(Duration(seconds: _autoSaveInterval), (_) async => await save());
  }

  @action
  Future<void> _setListeners(int height, {int? chainTip}) async {
    final currentChainTip = chainTip ?? await electrumClient.getCurrentBlockChainTip() ?? 0;
    syncStatus = AttemptingSyncStatus();

    if (_isolate != null) {
      final runningIsolate = await _isolate!;
      runningIsolate.kill(priority: Isolate.immediate);
    }

    final receivePort = ReceivePort();
    _isolate = Isolate.spawn(
        startRefresh,
        ScanData(
          sendPort: receivePort.sendPort,
          silentAddress: walletAddresses.silentAddress!.toString(),
          scanPrivkeyCompressed:
              walletAddresses.silentAddress!.scanPrivkey.toCompressedHex().fromHex,
          spendPubkeyCompressed:
              walletAddresses.silentAddress!.spendPubkey.toCompressedHex().fromHex,
          networkType: networkType,
          height: height,
          chainTip: currentChainTip,
          electrumClient: ElectrumClient(),
          transactionHistoryIds: transactionHistory.transactions.keys.toList(),
          node: electrumClient.uri.toString(),
        ));

    await for (var message in receivePort) {
      if (message is BitcoinUnspent) {
        unspentCoins.add(message);
        _addCoinInfo(message);
        await walletInfo.save();
        await save();

        _subscribeForUpdates();
      }

      // check if is a SyncStatus type since "is SyncStatus" doesn't work here
      if (message is SyncResponse) {
        syncStatus = message.syncStatus;
        walletInfo.restoreHeight = message.height;
        await walletInfo.save();
      }
    }
  }

  @action
  @override
  Future<void> startSync() async {
    try {
      await _setInitialHeight();
    } catch (_) {}

    try {
      rescan(height: walletInfo.restoreHeight);

      await walletAddresses.discoverAddresses();
      await updateTransactions();
      _subscribeForUpdates();
      await updateUnspent();
      await updateBalance();
      _feeRates = await electrumClient.feeRates();

      Timer.periodic(
          const Duration(minutes: 1), (timer) async => _feeRates = await electrumClient.feeRates());
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e.toString());
      syncStatus = FailedSyncStatus();
    }
  }

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();
      await electrumClient.connectToUri(node.uri);
      electrumClient.onConnectionStatusChange = (bool isConnected) {
        if (!isConnected) {
          syncStatus = LostConnectionSyncStatus();
        }
      };
      syncStatus = ConnectedSyncStatus();

      final currentChainTip = await electrumClient.getCurrentBlockChainTip();

      if ((currentChainTip ?? 0) > walletInfo.restoreHeight) {
        _setListeners(walletInfo.restoreHeight, chainTip: currentChainTip);
      }
    } catch (e) {
      print(e.toString());
      syncStatus = FailedSyncStatus();
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    try {
      if (unspentCoins.isEmpty) {
        await updateUnspent();
      }

      final inputs = <BitcoinUnspent>[];
      var allInputsAmount = 0;

      for (int i = 0; i < unspentCoins.length; i++) {
        final utx = unspentCoins[i];
        if (utx.isSending) {
          allInputsAmount += utx.value;
          inputs.add(utx);
        }
      }

      if (inputs.isEmpty) {
        throw BitcoinTransactionNoInputsException();
      }

      final minAmount = networkType == bitcoin.testnet ? 0 : 546;
      final transactionCredentials = credentials as BitcoinTransactionCredentials;
      final outputs = transactionCredentials.outputs;
      final hasMultiDestination = outputs.length > 1;

      final allAmountFee = transactionCredentials.feeRate != null
          ? feeAmountWithFeeRate(transactionCredentials.feeRate!, inputs.length, outputs.length)
          : feeAmountForPriority(transactionCredentials.priority!, inputs.length, outputs.length);

      final allAmount = allInputsAmount - allAmountFee;

      var credentialsAmount = 0;
      var amount = 0;
      var fee = 0;

      if (hasMultiDestination) {
        if (outputs.any((item) => item.sendAll || item.formattedCryptoAmount! <= 0)) {
          throw BitcoinTransactionWrongBalanceException(currency);
        }

        credentialsAmount = outputs.fold(0, (acc, value) => acc + value.formattedCryptoAmount!);

        if (allAmount - credentialsAmount < minAmount) {
          throw BitcoinTransactionWrongBalanceException(currency);
        }

        amount = credentialsAmount;

        if (transactionCredentials.feeRate != null) {
          fee = calculateEstimatedFeeWithFeeRate(transactionCredentials.feeRate!, amount,
              outputsCount: outputs.length + 1);
        } else {
          fee = calculateEstimatedFee(transactionCredentials.priority, amount,
              outputsCount: outputs.length + 1);
        }
      } else {
        final output = outputs.first;
        credentialsAmount = !output.sendAll ? output.formattedCryptoAmount! : 0;

        if (credentialsAmount > allAmount) {
          throw BitcoinTransactionWrongBalanceException(currency);
        }

        amount = output.sendAll || allAmount - credentialsAmount < minAmount
            ? allAmount
            : credentialsAmount;

        if (output.sendAll || amount == allAmount) {
          fee = allAmountFee;
        } else if (transactionCredentials.feeRate != null) {
          fee = calculateEstimatedFeeWithFeeRate(transactionCredentials.feeRate!, amount);
        } else {
          fee = calculateEstimatedFee(transactionCredentials.priority, amount);
        }
      }

      if (fee == 0 && networkType == bitcoin.bitcoin) {
        throw BitcoinTransactionWrongBalanceException(currency);
      }

      if (networkType == bitcoin.testnet) {
        fee += 50;
        amount -= 50;
      }

      final totalAmount = amount + fee;

      if ((totalAmount > balance[currency]!.confirmed || totalAmount > allInputsAmount) &&
          networkType == bitcoin.bitcoin) {
        throw BitcoinTransactionWrongBalanceException(currency);
      }

      final changeAddress = await walletAddresses.getChangeAddress();
      var leftAmount = totalAmount;
      var totalInputAmount = 0;

      final txb = bitcoin.TransactionBuilder(network: networkType, version: 1);

      List<bitcoin.PrivateKeyInfo> inputPrivKeys = [];
      List<bitcoin.Outpoint> outpoints = [];

      List<int>? amounts;
      List<Uint8List>? scriptPubKeys;

      final curve = bitcoin.getSecp256k1();

      for (int i = 0; i < inputs.length; i++) {
        final utx = inputs[i];
        leftAmount = leftAmount - utx.value;
        totalInputAmount += utx.value;

        if (amounts == null) {
          amounts = [];
        }
        amounts.add(utx.value);

        outpoints.add(bitcoin.Outpoint(txid: utx.hash, index: utx.vout));

        if (utx.bitcoinAddressRecord.silentPaymentTweak != null) {
          // https://github.com/bitcoin/bips/blob/c55f80c53c98642357712c1839cfdc0551d531c4/bip-0352.mediawiki#user-content-Spending
          final d = bitcoin.PrivateKey.fromHex(
                  curve, walletAddresses.silentAddress!.spendPrivkey.toCompressedHex())
              .tweakAdd(utx.bitcoinAddressRecord.silentPaymentTweak!.fromHex.bigint)!;

          inputPrivKeys.add(bitcoin.PrivateKeyInfo(d, utx.type == bitcoin.AddressType.p2tr));

          final p2tr = bitcoin.P2trAddress(pubkey: d.publicKey.toHex(), network: networkType);

          bitcoin.ECPair keyPair = bitcoin.ECPair.fromPrivateKey(d.toCompressedHex().fromHex,
              compressed: true, network: networkType);

          final script = p2tr.toScriptPubKey().toBytes();

          txb.addInput(utx.hash, utx.vout, null, script, keyPair, utx.value);

          if (scriptPubKeys == null) {
            scriptPubKeys = [];
          }
          scriptPubKeys.add(script);

          continue;
        }

        if ((utx.type == bitcoin.AddressType.p2tr) ||
            bitcoin.P2trAddress.REGEX.hasMatch(utx.address)) {
          bitcoin.ECPair keyPair = generateKeyPair(
              hd: utx.bitcoinAddressRecord.isHidden
                  ? walletAddresses.sideHd
                  : walletAddresses.mainHd,
              index: utx.bitcoinAddressRecord.index,
              network: networkType);

          inputPrivKeys.add(bitcoin.PrivateKeyInfo(
              bitcoin.PrivateKey.fromHex(curve, keyPair.privateKey!.hex),
              utx.type == bitcoin.AddressType.p2tr));

          final p2tr = bitcoin.P2trAddress(pubkey: keyPair.publicKey.hex, network: networkType);
          final script = p2tr.toScriptPubKey().toBytes();

          txb.addInput(utx.hash, utx.vout, null, script, keyPair, utx.value);

          if (scriptPubKeys == null) {
            scriptPubKeys = [];
          }
          scriptPubKeys.add(script);

          continue;
        }

        bitcoin.ECPair keyPair = generateKeyPair(
            hd: utx.bitcoinAddressRecord.isHidden ? walletAddresses.sideHd : walletAddresses.mainHd,
            index: utx.bitcoinAddressRecord.index,
            network: networkType);

        inputPrivKeys.add(bitcoin.PrivateKeyInfo(
            bitcoin.PrivateKey.fromHex(curve, keyPair.privateKey!.hex),
            utx.type == bitcoin.AddressType.p2tr));

        if (utx.isP2wpkh) {
          final p2wpkh = bitcoin
              .P2WPKH(
                  data: generatePaymentData(
                      hd: utx.bitcoinAddressRecord.isHidden
                          ? walletAddresses.sideHd
                          : walletAddresses.mainHd,
                      index: utx.bitcoinAddressRecord.index),
                  network: networkType)
              .data;

          final script = p2wpkh.output;
          txb.addInput(utx.hash, utx.vout, null, script, keyPair, utx.value);

          if (scriptPubKeys == null) {
            scriptPubKeys = [];
          }
          if (script != null) scriptPubKeys.add(script);

          continue;
        }

        txb.addInput(utx.hash, utx.vout, null, null, keyPair, utx.value);

        if (leftAmount <= 0) {
          break;
        }
      }

      if (txb.inputs.isEmpty) {
        throw BitcoinTransactionNoInputsException();
      }

      if ((amount <= 0 || totalInputAmount < totalAmount) && networkType == bitcoin.bitcoin) {
        throw BitcoinTransactionWrongBalanceException(currency);
      }

      List<bitcoin.SilentPaymentDestination> silentPaymentDestinations = [];
      outputs.forEach((item) {
        final outputAmount = hasMultiDestination ? item.formattedCryptoAmount : amount;
        final outputAddress = item.isParsedAddress ? item.extractedAddress! : item.address;

        if (bitcoin.SilentPaymentAddress.REGEX.hasMatch(outputAddress)) {
          // Add all silent payment destinations to a list and generate outputs later
          silentPaymentDestinations
              .add(bitcoin.SilentPaymentDestination.fromAddress(outputAddress, outputAmount!));
        } else {
          // Add all non-silent payment destinations to the transaction
          txb.addOutput(addressToOutputScript(outputAddress, networkType), outputAmount!);
        }
      });

      if (silentPaymentDestinations.isNotEmpty) {
        final outpointsHash = bitcoin.SilentPayment.hashOutpoints(outpoints);
        final generatedOutputs = bitcoin.SilentPayment.generateMultipleRecipientPubkeys(
            inputPrivKeys, outpointsHash, silentPaymentDestinations);

        generatedOutputs.forEach((recipientSilentAddress, generatedOutput) {
          generatedOutput.forEach((output) {
            txb.addOutput(
                bitcoin.P2trAddress(
                        program: bitcoin.ECPublic.fromHex(output.$1.toHex()).toTapPoint(),
                        network: networkType)
                    .toScriptPubKey()
                    .toBytes(),
                output.$2);
          });
        });
      }

      final estimatedSize = estimatedTransactionSize(inputs.length, outputs.length + 1);
      var feeAmount = 0;

      if (transactionCredentials.feeRate != null) {
        feeAmount = transactionCredentials.feeRate! * estimatedSize;
      } else {
        feeAmount = feeRate(transactionCredentials.priority!) * estimatedSize;
      }

      final changeValue = totalInputAmount - amount - feeAmount;

      if (changeValue > minAmount) {
        txb.addOutput(changeAddress, changeValue);
      }

      for (var i = 0; i < inputs.length; i++) {
        txb.sign(vin: i, amounts: amounts, scriptPubKeys: scriptPubKeys, inputs: inputs);
      }

      return PendingBitcoinTransaction(txb.build(), type,
          electrumClient: electrumClient, amount: amount, fee: fee, networkType: networkType)
        ..addListener((transaction) async {
          transactionHistory.addOne(transaction);
          await updateBalance();
        });
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e.toString());
      rethrow;
    }
  }

  String toJSON() => json.encode({
        'mnemonic': mnemonic,
        'account_index': walletAddresses.currentReceiveAddressIndex.toString(),
        'change_address_index': walletAddresses.currentChangeAddressIndex.toString(),
        'addresses': walletAddresses.addresses.map((addr) => addr.toJSON()).toList(),
        'balance': balance[currency]?.toJSON(),
        'network_type': networkType == bitcoin.bitcoin ? 'mainnet' : 'testnet',
      });

  int feeRate(TransactionPriority priority) {
    try {
      if (priority is BitcoinTransactionPriority) {
        return _feeRates[priority.raw];
      }

      return 0;
    } catch (_) {
      return 0;
    }
  }

  int feeAmountForPriority(
          BitcoinTransactionPriority priority, int inputsCount, int outputsCount) =>
      feeRate(priority) * estimatedTransactionSize(inputsCount, outputsCount);

  int feeAmountWithFeeRate(int feeRate, int inputsCount, int outputsCount) =>
      feeRate * estimatedTransactionSize(inputsCount, outputsCount);

  @override
  int calculateEstimatedFee(TransactionPriority? priority, int? amount, {int? outputsCount}) {
    if (priority is BitcoinTransactionPriority) {
      return calculateEstimatedFeeWithFeeRate(feeRate(priority), amount,
          outputsCount: outputsCount);
    }

    return 0;
  }

  int calculateEstimatedFeeWithFeeRate(int feeRate, int? amount, {int? outputsCount}) {
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

    return feeAmountWithFeeRate(feeRate, inputsCount, _outputsCount);
  }

  @override
  Future<void> save() async {
    final path = await makePath();
    await write(path: path, password: _password, data: toJSON());
    await transactionHistory.save();
  }

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

  @override
  Future<void> changePassword(String password) async {
    _password = password;
    await save();
    await transactionHistory.changePassword(password);
  }

  bitcoin.ECPair keyPairFor({required int index}) =>
      generateKeyPair(hd: hd, index: index, network: networkType);

  @action
  @override
  Future<void> rescan({required int height, int? chainTip, ScanData? scanData}) async {
    _setListeners(height);
  }

  @override
  Future<void> close() async {
    try {
      await electrumClient.close();
    } catch (_) {}
    _autoSaveTimer?.cancel();
  }

  Future<String> makePath() async => pathForWallet(name: walletInfo.name, type: walletInfo.type);

  Future<void> updateUnspent() async {
    final unspent = await Future.wait(walletAddresses.addresses.map((address) => electrumClient
        .getListUnspentWithAddress(address.address, networkType)
        .then((unspent) => unspent.map((unspent) {
              try {
                return BitcoinUnspent.fromJSON(address, unspent);
              } catch (_) {
                return null;
              }
            }).whereNotNull())));
    unspent.expand((e) => e).forEach((newUnspent) {
      try {
        if (!unspentCoins.any((currentUnspent) =>
            currentUnspent.address.contains(newUnspent.address) &&
            currentUnspent.hash.contains(newUnspent.hash))) {
          unspentCoins.add(newUnspent);
        }
      } catch (_) {}
    });

    if (unspentCoinsInfo.isEmpty) {
      unspentCoins.forEach((coin) => _addCoinInfo(coin));
      return;
    }

    if (unspentCoins.isNotEmpty) {
      unspentCoins.forEach((coin) {
        final coinInfoList = unspentCoinsInfo.values.where((element) =>
            element.walletId.contains(id) &&
            element.hash.contains(coin.hash) &&
            element.address.contains(coin.address));

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

  @action
  Future<void> _addCoinInfo(BitcoinUnspent coin) async {
    final newInfo = UnspentCoinsInfo(
      walletId: id,
      hash: coin.hash,
      isFrozen: coin.isFrozen,
      isSending: coin.isSending,
      noteRaw: coin.note,
      address: coin.bitcoinAddressRecord.address,
      value: coin.value,
      vout: coin.vout,
      isChange: coin.isChange,
    );

    await unspentCoinsInfo.add(newInfo);
  }

  Future<void> _refreshUnspentCoinsInfo() async {
    try {
      final List<dynamic> keys = <dynamic>[];
      final currentWalletUnspentCoins =
          unspentCoinsInfo.values.where((element) => element.walletId.contains(id));

      if (currentWalletUnspentCoins.isNotEmpty) {
        currentWalletUnspentCoins.forEach((element) {
          final existUnspentCoins = unspentCoins.where((coin) => element.hash.contains(coin.hash));

          if (existUnspentCoins.isEmpty) {
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

  @override
  Future<Map<String, ElectrumTransactionInfo>> fetchTransactions() async {
    final addressHashes = <String, BitcoinAddressRecord>{};
    final normalizedHistories = <Map<String, dynamic>>[];
    walletAddresses.addresses.forEach((addressRecord) {
      final sh = scriptHash(addressRecord.address, networkType: networkType);
      addressHashes[sh] = addressRecord;
    });
    final histories = addressHashes.keys.map((scriptHash) =>
        electrumClient.getHistory(scriptHash).then((history) => {scriptHash: history}));
    final historyResults = await Future.wait(histories);
    historyResults.forEach((history) {
      history.entries.forEach((historyItem) {
        if (historyItem.value.isNotEmpty) {
          final address = addressHashes[historyItem.key];
          address?.setAsUsed();
          normalizedHistories.addAll(historyItem.value);
        }
      });
    });
    final historiesWithDetails = await Future.wait(normalizedHistories.map((transaction) {
      try {
        return fetchTransactionInfo(
            hash: transaction['tx_hash'] as String,
            height: transaction['height'] as int,
            electrumClient: electrumClient,
            addressRecords: walletAddresses.addresses,
            walletInfo: walletInfo,
            networkType: networkType);
      } catch (_) {
        return Future.value(null);
      }
    }));
    return historiesWithDetails
        .fold<Map<String, ElectrumTransactionInfo>>(<String, ElectrumTransactionInfo>{}, (acc, tx) {
      if (tx == null) {
        return acc;
      }
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
      walletAddresses.updateReceiveAddresses();
      await transactionHistory.save();
      _isTransactionUpdating = false;
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e);
      _isTransactionUpdating = false;
    }
  }

  void _subscribeForUpdates() async {
    scriptHashes.forEach((sh) async {
      await _scripthashesUpdateSubject[sh]?.close();
      _scripthashesUpdateSubject[sh] = electrumClient.scripthashUpdate(sh);
      _scripthashesUpdateSubject[sh]?.listen((event) async {
        try {
          await updateUnspent();
          await updateBalance();
          await updateTransactions();
          final currentHeight = await electrumClient.getCurrentBlockChainTip();
          if (currentHeight != null) walletInfo.restoreHeight = currentHeight;
          rescan(height: walletInfo.restoreHeight);
        } catch (e, s) {
          print(e.toString());
          _onError?.call(FlutterErrorDetails(
            exception: e,
            stack: s,
            library: this.runtimeType.toString(),
          ));
        }
      });
    });
    await _chainTipUpdateSubject?.close();
    _chainTipUpdateSubject = electrumClient.chainTipUpdate();
    _chainTipUpdateSubject!.listen((event) async {
      try {
        print(["NEW HEIGHT!", event]);
        // _setListeners(walletInfo.restoreHeight, chainTip_setListeners: event);
      } catch (e, s) {
        print(e.toString());
        _onError?.call(FlutterErrorDetails(
          exception: e,
          stack: s,
          library: this.runtimeType.toString(),
        ));
      }
    });
  }

  Future<ElectrumBalance> _fetchBalances() async {
    final addresses = walletAddresses.addresses.toList();
    final balanceFutures = <Future<Map<String, dynamic>>>[];
    for (var i = 0; i < addresses.length; i++) {
      final addressRecord = addresses[i];
      final sh = scriptHash(addressRecord.address, networkType: networkType);
      final balanceFuture = electrumClient.getBalance(sh);
      balanceFutures.add(balanceFuture);
    }

    var totalFrozen = 0;
    unspentCoinsInfo.values.forEach((info) {
      unspentCoins.forEach((element) {
        if (element.hash == info.hash &&
            info.isFrozen &&
            element.bitcoinAddressRecord.address == info.address &&
            element.value == info.value) {
          totalFrozen += element.value;
        }
      });
    });

    final balances = await Future.wait(balanceFutures);
    var totalConfirmed = 0;
    var totalUnconfirmed = 0;

    for (var i = 0; i < balances.length; i++) {
      final addressRecord = addresses[i];
      final balance = balances[i];
      final confirmed = balance['confirmed'] as int? ?? 0;
      final unconfirmed = balance['unconfirmed'] as int? ?? 0;
      totalConfirmed += confirmed;
      totalUnconfirmed += unconfirmed;

      if (confirmed > 0 || unconfirmed > 0) {
        addressRecord.setAsUsed();
      }
    }

    return ElectrumBalance(
        confirmed: totalConfirmed, unconfirmed: totalUnconfirmed, frozen: totalFrozen);
  }

  Future<void> updateBalance() async {
    balance[currency] = await _fetchBalances();
    await save();
  }

  String getChangeAddress() {
    const minCountOfHiddenAddresses = 5;
    final random = Random();
    var addresses = walletAddresses.addresses.where((addr) => addr.isHidden).toList();

    if (addresses.length < minCountOfHiddenAddresses) {
      addresses = walletAddresses.addresses.toList();
    }

    return addresses[random.nextInt(addresses.length)].address;
  }

  @override
  void setExceptionHandler(void Function(FlutterErrorDetails) onError) => _onError = onError;

  @override
  String signMessage(String message, {String? address = null}) {
    final index = address != null
        ? walletAddresses.addresses.firstWhere((element) => element.address == address).index
        : null;
    return index == null
        ? base64Encode(hd.sign(message))
        : base64Encode(hd.derive(index).sign(message));
  }

  Future<void> _setInitialHeight() async {
    if (walletInfo.isRecovery) {
      return;
    }

    if (walletInfo.restoreHeight == 0) {
      final currentHeight = await electrumClient.getCurrentBlockChainTip();
      if (currentHeight != null) walletInfo.restoreHeight = currentHeight;
    }
  }
}

Future<ElectrumTransactionInfo?> fetchTransactionInfo(
    {required String hash,
    required int height,
    required ElectrumClient electrumClient,
    required Iterable<BitcoinAddressRecord> addressRecords,
    required WalletInfo walletInfo,
    required bitcoin.NetworkType networkType}) async {
  try {
    final tx = await getTransactionExpanded(
        hash: hash, height: height, electrumClient: electrumClient, networkType: networkType);
    final addresses = addressRecords.map((addr) => addr.address).toSet();
    return ElectrumTransactionInfo.fromElectrumBundle(tx, walletInfo.type, networkType,
        addresses: addresses, height: height);
  } catch (_) {
    return null;
  }
}

Future<ElectrumTransactionBundle> getTransactionExpanded(
    {required String hash,
    required int height,
    required ElectrumClient electrumClient,
    required bitcoin.NetworkType networkType}) async {
  final verboseTransaction =
      await electrumClient.getTransactionRaw(hash: hash, networkType: networkType);

  String transactionHex;
  int? time;
  int confirmations = 0;
  if (networkType.bech32 == bitcoin.testnet.bech32) {
    transactionHex = verboseTransaction as String;
    confirmations = 1;
  } else {
    transactionHex = verboseTransaction['hex'] as String;
    time = verboseTransaction['time'] as int?;
    confirmations = verboseTransaction['confirmations'] as int? ?? 0;
  }

  final original = bitcoin.Transaction.fromHex(transactionHex);
  final ins = <bitcoin.Transaction>[];

  for (final vin in original.ins) {
    final id = HEX.encode(vin.hash!.reversed.toList());
    final txHex = await electrumClient.getTransactionHex(hash: id);
    final tx = bitcoin.Transaction.fromHex(txHex);
    ins.add(tx);
  }

  return ElectrumTransactionBundle(original, ins: ins, time: time, confirmations: confirmations);
}

class ScanData {
  final SendPort sendPort;
  final Uint8List scanPrivkeyCompressed;
  final Uint8List spendPubkeyCompressed;
  final String silentAddress;
  final int height;
  final String node;
  final bitcoin.NetworkType networkType;
  final int chainTip;
  final ElectrumClient electrumClient;
  final List<String> transactionHistoryIds;

  ScanData({
    required this.sendPort,
    required this.scanPrivkeyCompressed,
    required this.spendPubkeyCompressed,
    required this.silentAddress,
    required this.height,
    required this.node,
    required this.networkType,
    required this.chainTip,
    required this.electrumClient,
    required this.transactionHistoryIds,
  });

  factory ScanData.fromHeight(ScanData scanData, int newHeight) {
    return ScanData(
      sendPort: scanData.sendPort,
      scanPrivkeyCompressed: scanData.scanPrivkeyCompressed,
      spendPubkeyCompressed: scanData.spendPubkeyCompressed,
      silentAddress: scanData.silentAddress,
      height: newHeight,
      node: scanData.node,
      networkType: scanData.networkType,
      chainTip: scanData.chainTip,
      transactionHistoryIds: scanData.transactionHistoryIds,
      electrumClient: scanData.electrumClient,
    );
  }
}

class SyncResponse {
  final int height;
  final SyncStatus syncStatus;

  SyncResponse(this.height, this.syncStatus);
}

Future<void> startRefresh(ScanData scanData) async {
  var cachedBlockchainHeight = scanData.chainTip;

  Future<int> getNodeHeightOrUpdate(int baseHeight) async {
    if (cachedBlockchainHeight < baseHeight || cachedBlockchainHeight == 0) {
      final electrumClient = scanData.electrumClient;
      if (!electrumClient.isConnected) {
        final node = scanData.node;
        await electrumClient.connectToUri(Uri.parse(node));
      }

      cachedBlockchainHeight =
          await electrumClient.getCurrentBlockChainTip() ?? cachedBlockchainHeight;
    }

    return cachedBlockchainHeight;
  }

  var lastKnownBlockHeight = 0;
  var initialSyncHeight = 0;

  var syncHeight = scanData.height;
  var currentChainTip = scanData.chainTip;

  if (syncHeight <= 0) {
    syncHeight = currentChainTip;
  }

  if (initialSyncHeight <= 0) {
    initialSyncHeight = syncHeight;
  }

  if (lastKnownBlockHeight == syncHeight) {
    scanData.sendPort.send(SyncResponse(currentChainTip, SyncedSyncStatus()));
    return;
  }

  // Run this until no more blocks left to scan txs. At first this was recursive
  // i.e. re-calling the startRefresh function but this was easier for the above values to retain
  // their initial values
  while (true) {
    lastKnownBlockHeight = syncHeight;

    final syncingStatus =
        SyncingSyncStatus.fromHeightValues(currentChainTip, initialSyncHeight, syncHeight);
    scanData.sendPort.send(SyncResponse(syncHeight, syncingStatus));

    if (syncingStatus.blocksLeft <= 0) {
      scanData.sendPort.send(SyncResponse(currentChainTip, SyncedSyncStatus()));
      return;
    }

    print(["Scanning from height:", syncHeight]);

    try {
      final networkPath =
          scanData.networkType.network == bitcoin.BtcNetwork.mainnet ? "" : "/testnet";

      // This endpoint gets up to 10 latest blocks from the given height
      final tenNewestBlocks =
          (await http.get(Uri.parse("https://blockstream.info$networkPath/api/blocks/$syncHeight")))
              .body;
      var decodedBlocks = json.decode(tenNewestBlocks) as List<dynamic>;

      decodedBlocks.sort((a, b) => (a["height"] as int).compareTo(b["height"] as int));
      decodedBlocks =
          decodedBlocks.where((element) => (element["height"] as int) >= syncHeight).toList();

      // for each block, get up to 25 txs
      for (var i = 0; i < decodedBlocks.length; i++) {
        final blockJson = decodedBlocks[i];
        final blockHash = blockJson["id"];
        final txCount = blockJson["tx_count"] as int;

        // print(["Scanning block index:", i, "with tx count:", txCount]);

        int startIndex = 0;
        // go through each tx in block until no more txs are left
        while (startIndex < txCount) {
          // This endpoint gets up to 25 txs from the given block hash and start index
          final twentyFiveTxs = json.decode((await http.get(Uri.parse(
                  "https://blockstream.info$networkPath/api/block/$blockHash/txs/$startIndex")))
              .body) as List<dynamic>;

          // print(["Scanning txs index:", startIndex]);

          // For each tx, apply silent payment filtering and do shared secret calculation when applied
          for (var i = 0; i < twentyFiveTxs.length; i++) {
            try {
              final tx = twentyFiveTxs[i];
              final txid = tx["txid"] as String;

              // print(["Scanning tx:", txid]);

              // TODO: if tx already scanned & stored skip
              // if (scanData.transactionHistoryIds.contains(txid)) {
              //   // already scanned tx, continue to next tx
              //   pos++;
              //   continue;
              // }

              List<String> pubkeys = [];
              List<bitcoin.Outpoint> outpoints = [];

              bool skip = false;

              for (var i = 0; i < (tx["vin"] as List<dynamic>).length; i++) {
                final input = tx["vin"][i];
                if (input["witness"] == null) {
                  skip = true;
                  // print("Skipping, no witness");
                  break;
                }

                if (input["witness"].length != 2) {
                  skip = true;
                  // print("Skipping, invalid witness");
                  break;
                }

                final pubkey = input["witness"][1] as String;
                pubkeys.add(pubkey);
                outpoints.add(
                    bitcoin.Outpoint(txid: input["txid"] as String, index: input["vout"] as int));
              }

              if (skip) {
                // skipped tx, continue to next tx
                continue;
              }

              Map<Uint8List, bitcoin.Outpoint> outpointsByP2TRpubkey = {};
              for (var i = 0; i < (tx["vout"] as List<dynamic>).length; i++) {
                final output = tx["vout"][i];
                if (output["scriptpubkey_type"] != "v1_p2tr") {
                  // print("Skipping, not a v1_p2tr output");
                  continue;
                }

                final script = (output["scriptpubkey"] as String).fromHex;

                // final alreadySpentOutput = (await electrumClient.getHistory(
                //             scriptHashFromScript(script, networkType: scanData.networkType)))
                //         .length >
                //     1;

                // if (alreadySpentOutput) {
                // print("Skipping, invalid witness");
                //   break;
                // }

                // final p2tr = bitcoin.P2trAddress(program: script.sublist(2).hex);
                // final address = p2tr.toAddress(scanData.networkType);

                // print(["Verifying taproot address:", address]);

                outpointsByP2TRpubkey[script.sublist(2)] =
                    bitcoin.Outpoint(txid: txid, index: i, value: output["value"] as int);
              }

              if (pubkeys.isEmpty || outpoints.isEmpty || outpointsByP2TRpubkey.isEmpty) {
                // skipped tx, continue to next tx
                continue;
              }

              final outpointHash = bitcoin.SilentPayment.hashOutpoints(outpoints);

              final curve = bitcoin.getSecp256k1();

              final result = bitcoin.scanOutputs(
                  bitcoin.PrivateKey.fromHex(curve, scanData.scanPrivkeyCompressed.hex),
                  bitcoin.PublicKey.fromHex(curve, scanData.spendPubkeyCompressed.hex),
                  bitcoin.getSumInputPubKeys(pubkeys),
                  outpointHash,
                  outpointsByP2TRpubkey.keys.toList());

              if (result.isEmpty) {
                // no results tx, continue to next tx
                continue;
              }

              if (result.length > 1) {
                print("MULTIPLE UNSPENT COINS FOUND!");
              } else {
                print("UNSPENT COIN FOUND!");
              }
              print(result);

              result.forEach((key, value) {
                final outpoint = outpointsByP2TRpubkey[key.fromHex];

                if (outpoint == null) {
                  return;
                }

                // found utxo for tx
                scanData.sendPort.send(BitcoinUnspent(
                  BitcoinAddressRecord(
                    key,
                    index: 0,
                    isHidden: false,
                    isUsed: true,
                    silentAddressLabel: null,
                    silentPaymentTweak: value,
                    type: bitcoin.AddressType.p2tr,
                  ),
                  outpoint.txid,
                  outpoint.value!,
                  outpoint.index,
                  silentPaymentTweak: value,
                  type: bitcoin.AddressType.p2tr,
                ));
              });
            } catch (_) {}
          }

          // Finished scanning batch of txs in block, add 25 to start index and continue to next block in loop
          startIndex += 25;
        }

        // Finished scanning block, add 1 to height and continue to next block in loop
        syncHeight += 1;
        currentChainTip = await getNodeHeightOrUpdate(syncHeight);
        scanData.sendPort.send(SyncResponse(syncHeight,
            SyncingSyncStatus.fromHeightValues(currentChainTip, initialSyncHeight, syncHeight)));
      }
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e.toString());

      break;
    }
  }
}
