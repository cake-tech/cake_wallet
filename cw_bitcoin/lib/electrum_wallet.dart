import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:blockchain_utils/blockchain_utils.dart';
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
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_bitcoin/script_hash.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/file.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:rxdart/subjects.dart';

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
        isEnabledAutoGenerateSubaddress = true,
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
    transactionHistory = ElectrumTransactionHistory(walletInfo: walletInfo, password: password);
  }

  static bitcoin.HDWallet bitcoinCashHDWallet(Uint8List seedBytes) =>
      bitcoin.HDWallet.fromSeed(seedBytes).derivePath("m/44'/145'/0'/0");

  static int estimatedTransactionSize(int inputsCount, int outputsCounts) =>
      inputsCount * 68 + outputsCounts * 34 + 10;

  final bitcoin.HDWallet hd;
  final String mnemonic;

  @override
  @observable
  bool isEnabledAutoGenerateSubaddress;

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
          primarySilentAddress: walletAddresses.primarySilentAddress!,
          network: network,
          height: height,
          chainTip: currentChainTip,
          electrumClient: ElectrumClient(),
          transactionHistoryIds: transactionHistory.transactions.keys.toList(),
          node: electrumClient.uri.toString(),
          labels: walletAddresses.labels,
        ));

    await for (var message in receivePort) {
      if (message is BitcoinUnspent) {
        if (!unspentCoins.any((utx) =>
            utx.hash.contains(message.hash) &&
            utx.vout == message.vout &&
            utx.address.contains(message.address))) {
          unspentCoins.add(message);

          if (unspentCoinsInfo.values.any((element) =>
              element.walletId.contains(id) &&
              element.hash.contains(message.hash) &&
              element.address.contains(message.address))) {
            _addCoinInfo(message);

            await walletInfo.save();
            await save();
          }

          balance[currency] = await _fetchBalances();
        }
      }

      if (message is Map<String, ElectrumTransactionInfo>) {
        transactionHistory.addMany(message);
        await transactionHistory.save();
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

      await updateTransactions();
      _subscribeForUpdates();
      await updateUnspent();
      await updateBalance();
      _feeRates = await electrumClient.feeRates();

      Timer.periodic(
          const Duration(minutes: 1), (timer) async => _feeRates = await electrumClient.feeRates());

      syncStatus = SyncedSyncStatus();
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
        leftAmount = leftAmount - utx.value;

        if (utx.bitcoinAddressRecord.silentPaymentTweak != null) {
          // final d = ECPrivate.fromHex(walletAddresses.primarySilentAddress!.spendPrivkey.toHex())
          //     .tweakAdd(utx.bitcoinAddressRecord.silentPaymentTweak!)!;

          // inputPrivKeys.add(bitcoin.PrivateKeyInfo(d, true));
          // address = bitcoin.P2trAddress(address: utx.address, networkType: networkType);
          // keyPairs.add(bitcoin.ECPair.fromPrivateKey(d.toCompressedHex().fromHex,
          //     compressed: true, network: networkType));
          // scriptType = bitcoin.AddressType.p2tr;
          // script = bitcoin.P2trAddress(pubkey: d.publicKey.toHex(), networkType: networkType)
          //     .scriptPubkey
          //     .toBytes();
        }

        final address = _addressTypeFromStr(utx.address, network);
        final privkey = generateECPrivate(
            hd: utx.bitcoinAddressRecord.isHidden ? walletAddresses.sideHd : walletAddresses.mainHd,
            index: utx.bitcoinAddressRecord.index,
            network: network);

        privateKeys.add(privkey);

        utxos.add(
          UtxoWithAddress(
            utxo: BitcoinUtxo(
              txHash: utx.hash,
              value: BigInt.from(utx.value),
              vout: utx.vout,
              scriptType: _getScriptType(address),
            ),
            ownerDetails:
                UtxoAddressDetails(publicKey: privkey.getPublic().toHex(), address: address),
          ),
        );

        bool amountIsAcquired = !sendAll && leftAmount <= 0;
        if ((inputsCount == null && amountIsAcquired) || inputsCount == i + 1) {
          break;
        }
      }
    }

    if (inputs.isEmpty) {
      throw BitcoinTransactionNoInputsException();
    }

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

    if (fee == 0) {
      throw BitcoinTransactionWrongBalanceException(currency);
    }

    final totalAmount = amount + fee;

    if (totalAmount > balance[currency]!.confirmed || totalAmount > allInputsAmount) {
      throw BitcoinTransactionWrongBalanceException(currency);
    }

    final txb = bitcoin.TransactionBuilder(network: networkType);
    final changeAddress = await walletAddresses.getChangeAddress();
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
                data: generatePaymentData(
                    hd: input.bitcoinAddressRecord.isHidden
                        ? walletAddresses.sideHd
                        : walletAddresses.mainHd,
                    index: input.bitcoinAddressRecord.index),
                network: networkType)
            .data;

        txb.addInput(input.hash, input.vout, null, p2wpkh.output);
      } else {
        txb.addInput(input.hash, input.vout);
      }
    });

    outputs.forEach((item) {
      final outputAmount = hasMultiDestination ? item.formattedCryptoAmount : amount;
      final outputAddress = item.isParsedAddress ? item.extractedAddress! : item.address;
      txb.addOutput(addressToOutputScript(outputAddress, networkType), outputAmount!);
    });

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
      final input = inputs[i];
      final keyPair = generateKeyPair(
          hd: input.bitcoinAddressRecord.isHidden ? walletAddresses.sideHd : walletAddresses.mainHd,
          index: input.bitcoinAddressRecord.index,
          network: networkType);
      final witnessValue = input.isP2wpkh ? input.value : null;

      txb.sign(vin: i, keyPair: keyPair, witnessValue: witnessValue);
    }

        if (SilentPaymentAddress.regex.hasMatch(outputAddress)) {
          // final outpointsHash = SilentPayment.hashOutpoints(outpoints);
          // final generatedOutputs = SilentPayment.generateMultipleRecipientPubkeys(inputPrivKeys,
          //     outpointsHash, SilentPaymentDestination.fromAddress(outputAddress, outputAmount!));

          // generatedOutputs.forEach((recipientSilentAddress, generatedOutput) {
          //   generatedOutput.forEach((output) {
          //     outputs.add(BitcoinOutputDetails(
          //       address: P2trAddress(
          //           program: ECPublic.fromHex(output.$1.toHex()).toTapPoint(),
          //           networkType: networkType),
          //       value: BigInt.from(output.$2),
          //     ));
          //   });
          // });
        }

        outputAddresses.add(address);

        if (hasMultiDestination) {
          if (out.sendAll || out.formattedCryptoAmount! <= 0) {
            throw BitcoinTransactionWrongBalanceException(currency);
          }

          final outputAmount = out.formattedCryptoAmount!;
          credentialsAmount += outputAmount;

          outputs.add(BitcoinOutput(address: address, value: BigInt.from(outputAmount)));
        } else {
          if (!sendAll) {
            final outputAmount = out.formattedCryptoAmount!;
            credentialsAmount += outputAmount;
            outputs.add(BitcoinOutput(address: address, value: BigInt.from(outputAmount)));
          } else {
            // The value will be changed after estimating the Tx size and deducting the fee from the total
            outputs.add(BitcoinOutput(address: address, value: BigInt.from(0)));
          }
        }
      }

      final estimatedTx = await _estimateTxFeeAndInputsToUse(
          credentialsAmount, sendAll, outputAddresses, outputs, transactionCredentials);

      final txb = BitcoinTransactionBuilder(
          utxos: estimatedTx.utxos,
          outputs: outputs,
          fee: BigInt.from(estimatedTx.fee),
          network: network);

      final transaction = txb.buildTransaction((txDigest, utxo, publicKey, sighash) {
        final key = estimatedTx.privateKeys
            .firstWhereOrNull((element) => element.getPublic().toHex() == publicKey);

        if (key == null) {
          throw Exception("Cannot find private key");
        }

        if (utxo.utxo.isP2tr()) {
          return key.signTapRoot(txDigest, sighash: sighash);
        } else {
          return key.signInput(txDigest, sigHash: sighash);
        }
      });
  }

  String toJSON() => json.encode({
        'mnemonic': mnemonic,
        'account_index': walletAddresses.currentReceiveAddressIndexByType,
        'change_address_index': walletAddresses.currentChangeAddressIndexByType,
        'addresses': walletAddresses.allAddresses.map((addr) => addr.toJSON()).toList(),
        'address_page_type': walletInfo.addressPageType == null
            ? SegwitAddresType.p2wpkh.toString()
            : walletInfo.addressPageType.toString(),
        'balance': balance[currency]?.toJSON(),
        'silent_addresses': walletAddresses.silentAddresses.map((addr) => addr.toJSON()).toList(),
        'silent_address_index': walletAddresses.currentSilentAddressIndex.toString(),
        'network_type': network == BitcoinNetwork.testnet ? 'testnet' : 'mainnet',
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
    // Update unspents stored from scanned silent payment transactions
    transactionHistory.transactions.values.forEach((tx) {
      if (tx.unspent != null) {
        if (!unspentCoins
            .any((utx) => utx.hash.contains(tx.unspent!.hash) && utx.vout == tx.unspent!.vout)) {
          unspentCoins.add(tx.unspent!);
        }
      }
    });

    List<BitcoinUnspent> updatedUnspentCoins = [];

    final addressesSet = walletAddresses.allAddresses.map((addr) => addr.address).toSet();

    await Future.wait(walletAddresses.allAddresses.map((address) => electrumClient
        .getListUnspentWithAddress(address.address, network)
        .then((unspent) => Future.forEach<Map<String, dynamic>>(unspent, (unspent) async {
              try {
                return BitcoinUnspent.fromJSON(address, unspent);
              } catch (_) {
                return null;
              }
            }).whereNotNull())));
    unspentCoins = unspent.expand((e) => e).toList();
    unspentCoins.forEach((coin) async {
      final tx = await fetchTransactionInfo(hash: coin.hash, height: 0);
      coin.isChange = tx?.direction == TransactionDirection.outgoing;
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

  Future<ElectrumTransactionBundle> getTransactionExpanded(
      {required String hash, required int height}) async {
    final verboseTransaction = await electrumClient.getTransactionRaw(hash: hash);
    final transactionHex = verboseTransaction['hex'] as String;
    final original = bitcoin.Transaction.fromHex(transactionHex);
    final ins = <bitcoin.Transaction>[];
    final time = verboseTransaction['time'] as int?;
    final confirmations = verboseTransaction['confirmations'] as int? ?? 0;

    for (final vin in original.ins) {
      final id = HEX.encode(vin.hash!.reversed.toList());
      final txHex = await electrumClient.getTransactionHex(hash: id);
      final tx = bitcoin.Transaction.fromHex(txHex);
      ins.add(tx);
    }

    final original = BtcTransaction.fromRaw(transactionHex);
    final ins = <BtcTransaction>[];

    for (final vin in original.inputs) {
      try {
        final id = HEX.encode(HEX.decode(vin.txId).reversed.toList());
        final txHex = await electrumClient.getTransactionHex(hash: id);
        final tx = BtcTransaction.fromRaw(txHex);
        ins.add(tx);
      } catch (_) {
        ins.add(BtcTransaction.fromRaw(await electrumClient.getTransactionHex(hash: vin.txId)));
      }
    }

    return ElectrumTransactionBundle(original,
        ins: ins, time: time, confirmations: confirmations, height: height);
  }

  Future<ElectrumTransactionInfo?> fetchTransactionInfo(
      {required String hash, required int height}) async {
    try {
      final tx = await getTransactionExpanded(hash: hash, height: height);
      final addresses = walletAddresses.addresses.map((addr) => addr.address).toSet();
      return ElectrumTransactionInfo.fromElectrumBundle(tx, walletInfo.type, networkType,
          addresses: addresses, height: height);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, ElectrumTransactionInfo>> fetchTransactions() async {
    final addressHashes = <String, BitcoinAddressRecord>{};
    final normalizedHistories = <Map<String, dynamic>>[];
    final newTxCounts = <String, int>{};

    walletAddresses.addresses.forEach((addressRecord) {
      final sh = scriptHash(addressRecord.address, networkType: networkType);
      addressHashes[sh] = addressRecord;
      newTxCounts[sh] = 0;
    });

    try {
      final histories = addressHashes.keys.map((scriptHash) =>
          electrumClient.getHistory(scriptHash).then((history) => {scriptHash: history}));
      final historyResults = await Future.wait(histories);

      historyResults.forEach((history) {
        history.entries.forEach((historyItem) {
          if (historyItem.value.isNotEmpty) {
            final address = addressHashes[historyItem.key];
            address?.setAsUsed();
            newTxCounts[historyItem.key] = historyItem.value.length;
            normalizedHistories.addAll(historyItem.value);
          }
        });
      });

      for (var sh in addressHashes.keys) {
        var balanceData = await electrumClient.getBalance(sh);
        var addressRecord = addressHashes[sh];
        if (addressRecord != null) {
          addressRecord.balance = balanceData['confirmed'] as int? ?? 0;
        }
      }

      addressHashes.forEach((sh, addressRecord) {
        addressRecord.txCount = newTxCounts[sh] ?? 0;
      });

      final historiesWithDetails = await Future.wait(normalizedHistories.map((transaction) {
        try {
          return fetchTransactionInfo(
              hash: transaction['tx_hash'] as String, height: transaction['height'] as int);
        } catch (_) {
          return Future.value(null);
        }
      }));

      return historiesWithDetails.fold<Map<String, ElectrumTransactionInfo>>(
          <String, ElectrumTransactionInfo>{}, (acc, tx) {
        if (tx == null) {
          return acc;
        }
        acc[tx.id] = acc[tx.id]?.updated(tx) ?? tx;
        return acc;
      });
    } catch (e) {
      print(e.toString());
      return {};
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
    _chainTipUpdateSubject?.listen((_) async {
      try {
        final currentHeight = await electrumClient.getCurrentBlockChainTip();
        if (currentHeight != null) walletInfo.restoreHeight = currentHeight;
        _setListeners(walletInfo.restoreHeight, chainTip: currentHeight);
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
    var totalConfirmed = 0;
    var totalUnconfirmed = 0;

    // Add values from unspent coins that are not fetched by the address list
    // i.e. scanned silent payments
    unspentCoinsInfo.values.forEach((info) {
      unspentCoins.forEach((element) {
        if (element.hash == info.hash &&
            element.bitcoinAddressRecord.address == info.address &&
            element.value == info.value) {
          if (info.isFrozen) totalFrozen += element.value;
          if (element.bitcoinAddressRecord.silentPaymentTweak != null) {
            totalConfirmed += element.value;
          }
        }
      });
    });

    final balances = await Future.wait(balanceFutures);

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
    final HD = index == null ? hd : hd.derive(index);
    return base64Encode(HD.signMessage(message));
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

class ScanData {
  final SendPort sendPort;
  final SilentPaymentOwner primarySilentAddress;
  final int height;
  final String node;
  final BasedUtxoNetwork network;
  final int chainTip;
  final ElectrumClient electrumClient;
  final List<String> transactionHistoryIds;
  final Map<String, String> labels;

  ScanData({
    required this.sendPort,
    required this.primarySilentAddress,
    required this.height,
    required this.node,
    required this.network,
    required this.chainTip,
    required this.electrumClient,
    required this.transactionHistoryIds,
    required this.labels,
  });

  factory ScanData.fromHeight(ScanData scanData, int newHeight) {
    return ScanData(
      sendPort: scanData.sendPort,
      primarySilentAddress: scanData.primarySilentAddress,
      height: newHeight,
      node: scanData.node,
      network: scanData.network,
      chainTip: scanData.chainTip,
      transactionHistoryIds: scanData.transactionHistoryIds,
      electrumClient: scanData.electrumClient,
      labels: scanData.labels,
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
      // Get all the tweaks from the block
      final electrumClient = scanData.electrumClient;
      if (!electrumClient.isConnected) {
        final node = scanData.node;
        await electrumClient.connectToUri(Uri.parse(node));
      }
      final tweaks = await electrumClient.getTweaks(height: syncHeight);

      for (var i = 0; i < tweaks.length; i++) {
        try {
          // final txid = tweaks.keys.toList()[i];
          final details = tweaks.values.toList()[i];
          print(["details", details]);
          final output_pubkeys = (details["output_pubkeys"] as List<String>);

          // print(["Scanning tx:", txid]);

          // TODO: if tx already scanned & stored skip
          // if (scanData.transactionHistoryIds.contains(txid)) {
          //   // already scanned tx, continue to next tx
          //   pos++;
          //   continue;
          // }

          final result = SilentPayment.scanTweak(
            scanData.primarySilentAddress.b_scan,
            scanData.primarySilentAddress.B_spend,
            details["tweak"] as String,
            output_pubkeys.map((e) => BytesUtils.fromHexString(e)).toList(),
            labels: scanData.labels,
          );

          if (result.isEmpty) {
            // no results tx, continue to next tx
            continue;
          }

          if (result.length > 1) {
            print("MULTIPLE UNSPENT COINS FOUND!");
          } else {
            print("UNSPENT COIN FOUND!");
          }

          // result.forEach((key, value) async {
          //   final outpoint = output_pubkeys[key];

          //   if (outpoint == null) {
          //     return;
          //   }

          //   final tweak = value[0];
          //   String? label;
          //   if (value.length > 1) label = value[1];

          //   final txInfo = ElectrumTransactionInfo(
          //     WalletType.bitcoin,
          //     id: txid,
          //     height: syncHeight,
          //     amount: outpoint.value!,
          //     fee: 0,
          //     direction: TransactionDirection.incoming,
          //     isPending: false,
          //     date: DateTime.fromMillisecondsSinceEpoch((blockJson["timestamp"] as int) * 1000),
          //     confirmations: currentChainTip - syncHeight,
          //     to: bitcoin.SilentPaymentAddress.createLabeledSilentPaymentAddress(
          //             scanData.primarySilentAddress.scanPubkey,
          //             scanData.primarySilentAddress.spendPubkey,
          //             label != null ? label.fromHex : "0".fromHex,
          //             hrp: scanData.primarySilentAddress.hrp,
          //             version: scanData.primarySilentAddress.version)
          //         .toString(),
          //     unspent: null,
          //   );

          //   final status = json.decode((await http
          //           .get(Uri.parse("https://blockstream.info/testnet/api/tx/$txid/outspends")))
          //       .body) as List<dynamic>;

          //   bool spent = false;
          //   for (final s in status) {
          //     if ((s["spent"] as bool) == true) {
          //       spent = true;

          //       scanData.sendPort.send({txid: txInfo});

          //       final sentTxId = s["txid"] as String;
          //       final sentTx = json.decode(
          //           (await http.get(Uri.parse("https://blockstream.info/testnet/api/tx/$sentTxId")))
          //               .body);

          //       int amount = 0;
          //       for (final out in (sentTx["vout"] as List<dynamic>)) {
          //         amount += out["value"] as int;
          //       }

          //       final height = s["status"]["block_height"] as int;

          //       scanData.sendPort.send({
          //         sentTxId: ElectrumTransactionInfo(
          //           WalletType.bitcoin,
          //           id: sentTxId,
          //           height: height,
          //           amount: amount,
          //           fee: 0,
          //           direction: TransactionDirection.outgoing,
          //           isPending: false,
          //           date: DateTime.fromMillisecondsSinceEpoch(
          //               (s["status"]["block_time"] as int) * 1000),
          //           confirmations: currentChainTip - height,
          //         )
          //       });
          //     }
          //   }

          //   if (spent) {
          //     return;
          //   }

          //   final unspent = BitcoinUnspent(
          //     BitcoinAddressRecord(
          //       bitcoin.P2trAddress(program: key, networkType: scanData.network).address,
          //       index: 0,
          //       isHidden: true,
          //       isUsed: true,
          //       silentAddressLabel: null,
          //       silentPaymentTweak: tweak,
          //       type: bitcoin.AddressType.p2tr,
          //     ),
          //     txid,
          //     outpoint.value!,
          //     outpoint.index,
          //     silentPaymentTweak: tweak,
          //     type: bitcoin.AddressType.p2tr,
          //   );

          //   // found utxo for tx, send unspent coin to main isolate
          //   scanData.sendPort.send(unspent);

          //   // also send tx data for tx history
          //   txInfo.unspent = unspent;
          //   scanData.sendPort.send({txid: txInfo});
          // });
        } catch (_) {}
      }

      // Finished scanning block, add 1 to height and continue to next block in loop
      syncHeight += 1;
      currentChainTip = await getNodeHeightOrUpdate(syncHeight);
      scanData.sendPort.send(SyncResponse(syncHeight,
          SyncingSyncStatus.fromHeightValues(currentChainTip, initialSyncHeight, syncHeight)));
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e.toString());

      scanData.sendPort.send(SyncResponse(syncHeight, NotConnectedSyncStatus()));
      break;
    }
  }
}

class EstimatedTxResult {
  EstimatedTxResult(
      {required this.utxos, required this.privateKeys, required this.fee, required this.amount});

  final List<UtxoWithAddress> utxos;
  final List<ECPrivate> privateKeys;
  final int fee;
  final int amount;
}

BitcoinBaseAddress _addressTypeFromStr(String address, BasedUtxoNetwork network) {
  if (P2pkhAddress.regex.hasMatch(address)) {
    return P2pkhAddress.fromAddress(address: address, network: network);
  } else if (P2shAddress.regex.hasMatch(address)) {
    return P2shAddress.fromAddress(address: address, network: network);
  } else if (P2wshAddress.regex.hasMatch(address)) {
    return P2wshAddress.fromAddress(address: address, network: network);
  } else if (P2trAddress.regex.hasMatch(address)) {
    return P2trAddress.fromAddress(address: address, network: network);
  } else {
    return P2wpkhAddress.fromAddress(address: address, network: network);
  }
}

BitcoinAddressType _getScriptType(BitcoinBaseAddress type) {
  if (type is P2pkhAddress) {
    return P2pkhAddressType.p2pkh;
  } else if (type is P2shAddress) {
    return P2shAddressType.p2wpkhInP2sh;
  } else if (type is P2wshAddress) {
    return SegwitAddresType.p2wsh;
  } else if (type is P2trAddress) {
    return SegwitAddresType.p2tr;
  } else {
    return SegwitAddresType.p2wpkh;
  }
}
