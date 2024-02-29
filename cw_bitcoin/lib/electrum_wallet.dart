import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:collection/collection.dart';
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
import 'package:cw_bitcoin/litecoin_network.dart';
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
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:rxdart/subjects.dart';
import 'package:http/http.dart' as http;

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
        this.network = networkType == bitcoin.bitcoin
            ? BitcoinNetwork.mainnet
            : networkType == litecoinNetwork
                ? LitecoinNetwork.mainnet
                : BitcoinNetwork.testnet,
        this.isTestnet = networkType == bitcoin.testnet,
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

  List<String> get scriptHashes => walletAddresses.allAddresses
      .map((addr) => scriptHash(addr.address, network: network))
      .toList();

  List<String> get publicScriptHashes => walletAddresses.allAddresses
      .where((addr) => !addr.isHidden)
      .map((addr) => scriptHash(addr.address, network: network))
      .toList();

  String get xpub => hd.base58!;

  @override
  String get seed => mnemonic;

  bitcoin.NetworkType networkType;
  BasedUtxoNetwork network;

  @override
  bool? isTestnet;

  @observable
  bool hasSilentPaymentsScanning = false;
  @observable
  bool nodeSupportsSilentPayments = true;

  @observable
  int? currentChainTip;

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
    print(["AttemptingSyncStatus"]);
    syncStatus = AttemptingSyncStatus();

    if (_isolate != null) {
      final runningIsolate = await _isolate!;
      runningIsolate.kill(priority: Isolate.immediate);
    }

    final receivePort = ReceivePort();
    print(["_isolate"]);
    _isolate = Isolate.spawn(
        startRefresh,
        ScanData(
          sendPort: receivePort.sendPort,
          silentAddress: walletAddresses.silentAddress!,
          network: network,
          height: height,
          chainTip: currentChainTip,
          electrumClient: ElectrumClient(),
          transactionHistoryIds: transactionHistory.transactions.keys.toList(),
          node: electrumClient.uri.toString(),
          labels: walletAddresses.labels,
        ));

    await for (var message in receivePort) {
      if (message is bool) {
        nodeSupportsSilentPayments = message;
        syncStatus = UnsupportedSyncStatus();
      }

      if (message is Map<String, ElectrumTransactionInfo>) {
        for (final map in message.entries) {
          final txid = map.key;
          final tx = map.value;

          if (tx.unspents != null) {
            tx.unspents!.forEach((unspent) => walletAddresses.addSilentAddresses(
                [unspent.bitcoinAddressRecord as BitcoinSilentPaymentAddressRecord]));

            final existingTxInfo = transactionHistory.transactions[txid];
            if (existingTxInfo != null) {
              final newUnspents = tx.unspents!
                  .where((unspent) => !existingTxInfo.unspents!.any((element) =>
                      element.hash.contains(unspent.hash) && element.vout == unspent.vout))
                  .toList();

              if (newUnspents.isNotEmpty) {
                existingTxInfo.unspents ??= [];
                existingTxInfo.unspents!.addAll(newUnspents);
                existingTxInfo.amount += newUnspents.length > 1
                    ? newUnspents.map((e) => e.value).reduce((value, unspent) => value + unspent)
                    : newUnspents[0].value;
              }
            } else {
              transactionHistory.addMany(message);
              transactionHistory.save();
            }
          }
        }

        updateUnspent();
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
      print(["attempting"]);
      syncStatus = AttemptingSyncStatus();

      if (hasSilentPaymentsScanning) {
        print(["_setInitialHeight"]);
        try {
          await _setInitialHeight();
        } catch (e) {
          print(["_setInitialHeight e ", e]);
        }

        print(["_setListeners", walletInfo.restoreHeight, currentChainTip]);
        if ((currentChainTip ?? 0) > walletInfo.restoreHeight) {
          _setListeners(walletInfo.restoreHeight, chainTip: currentChainTip);
        }
      }

      print(["updateTransactions"]);
      await updateTransactions();
      print(["_subscribeForUpdates"]);
      _subscribeForUpdates();
      print(["updateUnspent"]);
      await updateUnspent();
      print(["updateBalance"]);
      try {
        await updateBalance();
      } catch (_) {}
      print(["_feeRates"]);
      _feeRates = await electrumClient.feeRates(network: network);

      print(["Timer.periodic"]);
      Timer.periodic(
          const Duration(minutes: 1), (timer) async => _feeRates = await electrumClient.feeRates());

      if (!hasSilentPaymentsScanning || walletInfo.restoreHeight == currentChainTip) {
        syncStatus = SyncedSyncStatus();
      }
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e.toString());
      syncStatus = FailedSyncStatus();
    }
  }

  @action
  Future<void> _electrumConnect(Node node, {bool? attemptedReconnect}) async {
    try {
      syncStatus = ConnectingSyncStatus();
      await electrumClient.connectToUri(node.uri);
      electrumClient.onConnectionStatusChange = (bool isConnected) async {
        print(["onConnectionStatusChange", isConnected]);
        if (!isConnected) {
          syncStatus = LostConnectionSyncStatus();
          await electrumClient.close();
          if (attemptedReconnect == false) {
            await _electrumConnect(node, attemptedReconnect: true);
          }
        }
      };
      syncStatus = ConnectedSyncStatus();
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e.toString());
      syncStatus = FailedSyncStatus();
    }
  }

  @action
  @override
  Future<void> connectToNode({required Node node}) => _electrumConnect(node);

  Future<EstimatedTxResult> _estimateTxFeeAndInputsToUse(
      int credentialsAmount,
      bool sendAll,
      List<BitcoinBaseAddress> outputAddresses,
      List<BitcoinOutput> outputs,
      BitcoinTransactionCredentials transactionCredentials,
      {int? inputsCount,
      bool? hasSilentPayment}) async {
    final utxos = <UtxoWithAddress>[];
    List<ECPrivate> privateKeys = [];

    var leftAmount = credentialsAmount;
    var allInputsAmount = 0;

    List<Outpoint> vinOutpoints = [];
    List<ECPrivateInfo> inputPrivKeyInfos = [];
    List<ECPublic> inputPubKeys = [];

    for (int i = 0; i < unspentCoins.length; i++) {
      final utx = unspentCoins[i];

      if (utx.isSending) {
        allInputsAmount += utx.value;
        leftAmount = leftAmount - utx.value;

        final address = _addressTypeFromStr(utx.address, network);

        ECPrivate? privkey;
        if (utx.bitcoinAddressRecord is BitcoinSilentPaymentAddressRecord) {
          privkey = walletAddresses.silentAddress!.b_spend.clone().tweakAdd(
                BigintUtils.fromBytes(BytesUtils.fromHexString(
                    (utx.bitcoinAddressRecord as BitcoinSilentPaymentAddressRecord)
                        .silentPaymentTweak!)),
              );
        } else {
          privkey = generateECPrivate(
              hd: utx.bitcoinAddressRecord.isHidden
                  ? walletAddresses.sideHd
                  : walletAddresses.mainHd,
              index: utx.bitcoinAddressRecord.index,
              network: network);
        }

        privateKeys.add(privkey);
        inputPrivKeyInfos.add(ECPrivateInfo(privkey, address.type == SegwitAddresType.p2tr));
        inputPubKeys.add(privkey.getPublic());
        vinOutpoints.add(Outpoint(txid: utx.hash, index: utx.vout));

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

    if (utxos.isEmpty) {
      throw BitcoinTransactionNoInputsException();
    }

    var changeValue = allInputsAmount - credentialsAmount;

    if (!sendAll) {
      if (changeValue > 0) {
        final changeAddress = await walletAddresses.getChangeAddress();
        final address = _addressTypeFromStr(changeAddress, network);
        outputAddresses.add(address);
        outputs.add(BitcoinOutput(address: address, value: BigInt.from(changeValue)));
      }
    }

    if (hasSilentPayment == true) {
      List<SilentPaymentDestination> silentPaymentDestinations = [];

      for (final out in outputs) {
        final address = out.address;
        final amount = out.value;

        if (address is SilentPaymentAddress) {
          final silentPaymentDestination =
              SilentPaymentDestination.fromAddress(address.toAddress(network), amount.toInt());
          silentPaymentDestinations.add(silentPaymentDestination);
        }
      }

      final spb = SilentPaymentBuilder(pubkeys: inputPubKeys, outpoints: vinOutpoints);
      final sendingOutputs = spb.createOutputs(inputPrivKeyInfos, silentPaymentDestinations);

      var outputsAdded = [];

      for (var i = 0; i < outputs.length; i++) {
        final out = outputs[i];

        final silentOutputs = sendingOutputs[out.address.toAddress(network)];
        if (silentOutputs != null) {
          final silentOutput =
              silentOutputs.firstWhereOrNull((element) => !outputsAdded.contains(element));

          if (silentOutput != null) {
            outputs[i] = BitcoinOutput(
              address: silentOutput.address,
              value: BigInt.from(silentOutput.amount),
            );

            outputsAdded.add(silentOutput);
          }
        }
      }
    }

    final estimatedSize = BitcoinTransactionBuilder.estimateTransactionSize(
        utxos: utxos, outputs: outputs, network: network);

    final fee = transactionCredentials.feeRate != null
        ? feeAmountWithFeeRate(transactionCredentials.feeRate!, 0, 0, size: estimatedSize)
        : feeAmountForPriority(transactionCredentials.priority!, 0, 0, size: estimatedSize);

    if (fee == 0) {
      throw BitcoinTransactionWrongBalanceException(currency);
    }

    var amount = credentialsAmount;

    final lastOutput = outputs.last;
    if (!sendAll) {
      if (changeValue > fee) {
        // Here, lastOutput is change, deduct the fee from it
        outputs[outputs.length - 1] =
            BitcoinOutput(address: lastOutput.address, value: lastOutput.value - BigInt.from(fee));
      }
    } else {
      // Here, if sendAll, the output amount equals to the input value - fee to fully spend every input on the transaction and have no amount for change
      amount = allInputsAmount - fee;
      outputs[outputs.length - 1] =
          BitcoinOutput(address: lastOutput.address, value: BigInt.from(amount));
    }

    final totalAmount = amount + fee;

    if (totalAmount > balance[currency]!.confirmed) {
      throw BitcoinTransactionWrongBalanceException(currency);
    }

    if (totalAmount > allInputsAmount) {
      if (unspentCoins.where((utx) => utx.isSending).length == utxos.length) {
        throw BitcoinTransactionWrongBalanceException(currency);
      } else {
        if (changeValue > fee) {
          outputAddresses.removeLast();
          outputs.removeLast();
        }

        return _estimateTxFeeAndInputsToUse(
            credentialsAmount, sendAll, outputAddresses, outputs, transactionCredentials,
            inputsCount: utxos.length + 1, hasSilentPayment: hasSilentPayment);
      }
    }

    return EstimatedTxResult(utxos: utxos, privateKeys: privateKeys, fee: fee, amount: amount);
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    try {
      final outputs = <BitcoinOutput>[];
      final outputAddresses = <BitcoinBaseAddress>[];
      final transactionCredentials = credentials as BitcoinTransactionCredentials;
      final hasMultiDestination = transactionCredentials.outputs.length > 1;
      final sendAll = !hasMultiDestination && transactionCredentials.outputs.first.sendAll;

      var credentialsAmount = 0;
      bool hasSilentPayment = false;

      for (final out in transactionCredentials.outputs) {
        final outputAddress = out.isParsedAddress ? out.extractedAddress! : out.address;
        final address = _addressTypeFromStr(outputAddress, network);

        if (address is SilentPaymentAddress) {
          hasSilentPayment = true;
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
          credentialsAmount, sendAll, outputAddresses, outputs, transactionCredentials,
          hasSilentPayment: hasSilentPayment);

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

      return PendingBitcoinTransaction(transaction, type,
          electrumClient: electrumClient,
          amount: estimatedTx.amount,
          fee: estimatedTx.fee,
          network: network)
        ..addListener((transaction) async {
          transactionHistory.addOne(transaction);
          await updateBalance();
        });
    } catch (e) {
      throw e;
    }
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

  int feeAmountForPriority(BitcoinTransactionPriority priority, int inputsCount, int outputsCount,
          {int? size}) =>
      feeRate(priority) * (size ?? estimatedTransactionSize(inputsCount, outputsCount));

  int feeAmountWithFeeRate(int feeRate, int inputsCount, int outputsCount, {int? size}) =>
      feeRate * (size ?? estimatedTransactionSize(inputsCount, outputsCount));

  @override
  int calculateEstimatedFee(TransactionPriority? priority, int? amount,
      {int? outputsCount, int? size}) {
    if (priority is BitcoinTransactionPriority) {
      return calculateEstimatedFeeWithFeeRate(feeRate(priority), amount,
          outputsCount: outputsCount, size: size);
    }

    return 0;
  }

  int calculateEstimatedFeeWithFeeRate(int feeRate, int? amount, {int? outputsCount, int? size}) {
    if (size != null) {
      return feeAmountWithFeeRate(feeRate, 0, 0, size: size);
    }

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
    List<BitcoinUnspent> updatedUnspentCoins = [];

    // Update unspents stored from scanned silent payment transactions
    transactionHistory.transactions.values.forEach((tx) {
      if (tx.unspents != null) {
        if (!unspentCoins.any((utx) =>
            tx.unspents!.any((element) => utx.hash.contains(element.hash)) &&
            tx.unspents!.any((element) => utx.vout == element.vout))) {
          updatedUnspentCoins.addAll(tx.unspents!);
        }
      }
    });

    final addressesSet = walletAddresses.allAddresses.map((addr) => addr.address).toSet();

    await Future.wait(walletAddresses.allAddresses.map((address) => electrumClient
        .getListUnspentWithAddress(address.address, network)
        .then((unspent) => Future.forEach<Map<String, dynamic>>(unspent, (unspent) async {
              try {
                final coin = BitcoinUnspent.fromJSON(address, unspent);
                final tx = await fetchTransactionInfo(
                    hash: coin.hash, height: 0, myAddresses: addressesSet);
                coin.isChange = tx?.direction == TransactionDirection.outgoing;
                updatedUnspentCoins.add(coin);
              } catch (_) {}
            }))));

    unspentCoins = updatedUnspentCoins;

    if (unspentCoinsInfo.isEmpty) {
      unspentCoins.forEach((coin) => _addCoinInfo(coin));
      return;
    }

    if (unspentCoins.isNotEmpty) {
      unspentCoins.forEach((coin) {
        final coinInfoList = unspentCoinsInfo.values.where((element) =>
            element.walletId.contains(id) &&
            element.hash.contains(coin.hash) &&
            element.vout == coin.vout);

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
          final existUnspentCoins = unspentCoins
              .where((coin) => element.hash.contains(coin.hash) && element.vout == coin.vout);

          if (existUnspentCoins.isEmpty) {
            keys.add(element.key);
          }
        });
      }

      if (keys.isNotEmpty) {
        await unspentCoinsInfo.deleteAll(keys);
      }
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e.toString());
    }
  }

  Future<ElectrumTransactionBundle> getTransactionExpanded(
      {required String hash, required int height}) async {
    String transactionHex;
    int? time;
    int confirmations = 0;
    if (network == BitcoinNetwork.testnet) {
      // Testnet public electrum server does not support verbose transaction fetching
      transactionHex = await electrumClient.getTransactionHex(hash: hash);

      final status = json.decode(
          (await http.get(Uri.parse("https://blockstream.info/testnet/api/tx/$hash/status"))).body);

      time = status["block_time"] as int?;
      confirmations = currentChainTip! - (status["block_height"] as int? ?? 0);
    } else {
      final verboseTransaction = await electrumClient.getTransactionRaw(hash: hash);

      transactionHex = verboseTransaction['hex'] as String;
      time = verboseTransaction['time'] as int?;
      confirmations = verboseTransaction['confirmations'] as int? ?? 0;
    }

    final original = BtcTransaction.fromRaw(transactionHex);
    final ins = <BtcTransaction>[];

    for (final vin in original.inputs) {
      ins.add(BtcTransaction.fromRaw(await electrumClient.getTransactionHex(hash: vin.txId)));
    }

    return ElectrumTransactionBundle(original,
        ins: ins, time: time, confirmations: confirmations, height: height);
  }

  Future<ElectrumTransactionInfo?> fetchTransactionInfo(
      {required String hash,
      required int height,
      required Set<String> myAddresses,
      bool? retryOnFailure}) async {
    try {
      return ElectrumTransactionInfo.fromElectrumBundle(
          await getTransactionExpanded(hash: hash, height: height), walletInfo.type, network,
          addresses: myAddresses, height: height);
    } catch (e) {
      if (e is FormatException && retryOnFailure == true) {
        await Future.delayed(const Duration(seconds: 2));
        return fetchTransactionInfo(hash: hash, height: height, myAddresses: myAddresses);
      }
      return null;
    }
  }

  @override
  Future<Map<String, ElectrumTransactionInfo>> fetchTransactions() async {
    try {
      final Map<String, ElectrumTransactionInfo> historiesWithDetails = {};
      final addressesSet = walletAddresses.allAddresses.map((addr) => addr.address).toSet();
      currentChainTip ??= await electrumClient.getCurrentBlockChainTip() ?? 0;

      await Future.wait(ADDRESS_TYPES.map((type) {
        final addressesByType = walletAddresses.allAddresses.where((addr) => addr.type == type);

        return Future.wait(addressesByType.map((addressRecord) async {
          final history = await _fetchAddressHistory(addressRecord, addressesSet, currentChainTip!);

          if (history.isNotEmpty) {
            addressRecord.txCount = history.length;
            historiesWithDetails.addAll(history);

            final matchedAddresses =
                addressesByType.where((addr) => addr.isHidden == addressRecord.isHidden);

            final isLastUsedAddress =
                history.isNotEmpty && addressRecord.address == matchedAddresses.last.address;

            if (isLastUsedAddress) {
              await walletAddresses.discoverAddresses(
                  matchedAddresses.toList(),
                  addressRecord.isHidden,
                  (address, addressesSet) =>
                      _fetchAddressHistory(address, addressesSet, currentChainTip!)
                          .then((history) => history.isNotEmpty ? address.address : null),
                  type: type);
            }
          }
        }));
      }));

      return historiesWithDetails;
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e.toString());
      return {};
    }
  }

  Future<Map<String, ElectrumTransactionInfo>> _fetchAddressHistory(
      BitcoinAddressRecord addressRecord, Set<String> addressesSet, int currentHeight) async {
    try {
      final Map<String, ElectrumTransactionInfo> historiesWithDetails = {};

      final history = await electrumClient
          .getHistory(addressRecord.scriptHash ?? addressRecord.updateScriptHash(network));

      if (history.isNotEmpty) {
        addressRecord.setAsUsed();

        await Future.wait(history.map((transaction) async {
          final txid = transaction['tx_hash'] as String;
          final height = transaction['height'] as int;
          final storedTx = transactionHistory.transactions[txid];

          if (storedTx != null) {
            if (height > 0) {
              storedTx.height = height;
              // the tx's block itself is the first confirmation so add 1
              storedTx.confirmations = currentHeight - height + 1;
              storedTx.isPending = storedTx.confirmations == 0;
            }

            historiesWithDetails[txid] = storedTx;
          } else {
            final tx = await fetchTransactionInfo(
                hash: txid, height: height, myAddresses: addressesSet, retryOnFailure: true);

            if (tx != null) {
              historiesWithDetails[txid] = tx;

              // Got a new transaction fetched, add it to the transaction history
              // instead of waiting all to finish, and next time it will be faster
              transactionHistory.addOne(tx);
              await transactionHistory.save();
            }
          }

          return Future.value(null);
        }));
      }

      return historiesWithDetails;
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e.toString());
      return {};
    }
  }

  Future<void> updateTransactions() async {
    try {
      print(["_isTransactionUpdating"]);
      if (_isTransactionUpdating) {
        return;
      }

      _isTransactionUpdating = true;
      print(["fetchTransactions"]);
      await fetchTransactions();
      print(["end fetchTransactions"]);
      walletAddresses.updateReceiveAddresses();
      print(["walletAddresses.updateReceiveAddresses() end"]);
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
        } catch (e, stacktrace) {
          print(stacktrace);
          print(e.toString());
          _onError?.call(FlutterErrorDetails(
            exception: e,
            stack: stacktrace,
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
      } catch (e, stacktrace) {
        print(stacktrace);
        print(e.toString());
        _onError?.call(FlutterErrorDetails(
          exception: e,
          stack: stacktrace,
          library: this.runtimeType.toString(),
        ));
      }
    });
  }

  Future<ElectrumBalance> _fetchBalances() async {
    final addresses = walletAddresses.allAddresses.toList();
    final balanceFutures = <Future<Map<String, dynamic>>>[];
    for (var i = 0; i < addresses.length; i++) {
      final addressRecord = addresses[i];
      final sh = scriptHash(addressRecord.address, network: network);
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
          if (element.bitcoinAddressRecord is BitcoinSilentPaymentAddressRecord) {
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
    var addresses = walletAddresses.allAddresses.where((addr) => addr.isHidden).toList();

    if (addresses.length < minCountOfHiddenAddresses) {
      addresses = walletAddresses.allAddresses.toList();
    }

    return addresses[random.nextInt(addresses.length)].address;
  }

  @override
  void setExceptionHandler(void Function(FlutterErrorDetails) onError) => _onError = onError;

  @override
  String signMessage(String message, {String? address = null}) {
    final index = address != null
        ? walletAddresses.allAddresses.firstWhere((element) => element.address == address).index
        : null;
    final HD = index == null ? hd : hd.derive(index);
    return base64Encode(HD.signMessage(message));
  }

  Future<void> _setInitialHeight() async {
    print(["walletInfo.restoreHeight", walletInfo.restoreHeight]);
    // if (walletInfo.restoreHeight == 0) {
    currentChainTip = await electrumClient.getCurrentBlockChainTip();
    print(["did _setInitialHeight", walletInfo.restoreHeight, currentChainTip]);
    if (currentChainTip != null) walletInfo.restoreHeight = currentChainTip!;
    // }
  }
}

class ScanData {
  final SendPort sendPort;
  final SilentPaymentOwner silentAddress;
  final int height;
  final String node;
  final BasedUtxoNetwork network;
  final int chainTip;
  final ElectrumClient electrumClient;
  final List<String> transactionHistoryIds;
  final Map<String, String> labels;

  ScanData({
    required this.sendPort,
    required this.silentAddress,
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
      silentAddress: scanData.silentAddress,
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
  print(["startRefresh"]);
  var cachedBlockchainHeight = scanData.chainTip;

  Future<ElectrumClient> connect() async {
    final electrumClient = scanData.electrumClient;
    if (!electrumClient.isConnected) {
      final node = scanData.node;
      await electrumClient.connectToUri(Uri.parse(node));
    }
    return electrumClient;
  }

  Future<int> getNodeHeightOrUpdate(int baseHeight) async {
    if (cachedBlockchainHeight < baseHeight || cachedBlockchainHeight == 0) {
      final electrumClient = await connect();

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

  print(["lastKnownBlockHeight == syncHeight", lastKnownBlockHeight, syncHeight]);
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

    try {
      final electrumClient = await connect();

      List<dynamic>? tweaks;
      try {
        tweaks = await electrumClient.getTweaks(height: syncHeight);
      } catch (e) {
        if (e is RequestFailedTimeoutException) {
          return scanData.sendPort.send(false);
        }
      }

      if (tweaks == null) {
        scanData.sendPort.send(SyncResponse(syncHeight,
            SyncingSyncStatus.fromHeightValues(currentChainTip, initialSyncHeight, syncHeight)));
      }

      for (var i = 0; i < tweaks!.length; i++) {
        try {
          final details = tweaks[i] as Map<String, dynamic>;
          final output_pubkeys = (details["output_pubkeys"] as List<dynamic>);
          final tweak = details["tweak"].toString();

          // TODO: if tx already scanned & stored skip
          // if (scanData.transactionHistoryIds.contains(txid)) {
          //   // already scanned tx, continue to next tx
          //   pos++;
          //   continue;
          // }

          final spb = SilentPaymentBuilder(receiverTweak: tweak);
          final result = spb.scanOutputs(
            scanData.silentAddress.b_scan,
            scanData.silentAddress.B_spend,
            output_pubkeys.map((output) => output.toString()).toList(),
            precomputedLabels: scanData.labels,
          );
          print(result);

          if (result.isEmpty) {
            // no results tx, continue to next tx
            continue;
          }

          result.forEach((key, value) async {
            final t_k = value[0];
            final address = ECPublic.fromHex(key).toTaprootAddress().toAddress(scanData.network);

            final listUnspent =
                await electrumClient.getListUnspentWithAddress(address, scanData.network);

            BitcoinUnspent? info;
            await Future.forEach<Map<String, dynamic>>(listUnspent, (unspent) async {
              try {
                final addressRecord = BitcoinSilentPaymentAddressRecord(address,
                    index: 0,
                    isHidden: true,
                    isUsed: true,
                    network: scanData.network,
                    silentPaymentTweak: t_k);
                info = BitcoinUnspent.fromJSON(addressRecord, unspent);
              } catch (_) {}
            });

            if (info == null) {
              return;
            }

            // final tweak = value[0];
            // String? label;
            // if (value.length > 1) label = value[1];

            final tx = info!;
            final txInfo = ElectrumTransactionInfo(
              WalletType.bitcoin,
              id: tx.hash,
              height: syncHeight,
              amount: 0, // will be added later via unspent
              fee: 0,
              direction: TransactionDirection.incoming,
              isPending: false,
              date: DateTime.now(),
              confirmations: currentChainTip - syncHeight - 1,
              to: scanData.silentAddress.toString(),
              unspents: [tx],
            );

            // bool spent = false;
            // for (final s in status) {
            //   if ((s["spent"] as bool) == true) {
            //     spent = true;

            //     scanData.sendPort.send({txid: txInfo});

            //     final sentTxId = s["txid"] as String;
            //     final sentTx = json.decode(
            //         (await http.get(Uri.parse("https://blockstream.info/testnet/api/tx/$sentTxId")))
            //             .body);

            //     int amount = 0;
            //     for (final out in (sentTx["vout"] as List<dynamic>)) {
            //       amount += out["value"] as int;
            //     }

            //     final height = s["status"]["block_height"] as int;

            //     scanData.sendPort.send({
            //       sentTxId: ElectrumTransactionInfo(
            //         WalletType.bitcoin,
            //         id: sentTxId,
            //         height: height,
            //         amount: amount,
            //         fee: 0,
            //         direction: TransactionDirection.outgoing,
            //         isPending: false,
            //         date: DateTime.fromMillisecondsSinceEpoch(
            //             (s["status"]["block_time"] as int) * 1000),
            //         confirmations: currentChainTip - height,
            //       )
            //     });
            //   }
            // }

            // if (spent) {
            //   return;
            // }

            // found utxo for tx, send unspent coin to main isolate
            // scanData.sendPort.send(txInfo);

            // also send tx data for tx history
            scanData.sendPort.send({txInfo.id: txInfo});
          });
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
  } else if (SilentPaymentAddress.regex.hasMatch(address)) {
    return SilentPaymentAddress.fromAddress(address);
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
  } else if (type is SilentPaymentsAddresType) {
    return SilentPaymentsAddresType.p2sp;
  } else {
    return SegwitAddresType.p2wpkh;
  }
}
