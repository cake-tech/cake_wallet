import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:collection/collection.dart';
import 'package:cw_bitcoin/address_from_output.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/bitcoin_wallet_keys.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_derivations.dart';
import 'package:cw_bitcoin/electrum_transaction_history.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/exceptions.dart';
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
import 'package:cw_core/get_height_by_date.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:mobx/mobx.dart';
import 'package:rxdart/subjects.dart';
import 'package:sp_scanner/sp_scanner.dart';

part 'electrum_wallet.g.dart';

class ElectrumWallet = ElectrumWalletBase with _$ElectrumWallet;

const int TWEAKS_COUNT = 25;

abstract class ElectrumWalletBase
    extends WalletBase<ElectrumBalance, ElectrumTransactionHistory, ElectrumTransactionInfo>
    with Store {
  ElectrumWalletBase({
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required this.networkType,
    String? xpub,
    String? mnemonic,
    Uint8List? seedBytes,
    this.passphrase,
    List<BitcoinAddressRecord>? initialAddresses,
    ElectrumClient? electrumClient,
    ElectrumBalance? initialBalance,
    CryptoCurrency? currency,
    this.alwaysScan,
  })  : accountHD =
            getAccountHDWallet(currency, networkType, seedBytes, xpub, walletInfo.derivationInfo),
        syncStatus = NotConnectedSyncStatus(),
        _password = password,
        _feeRates = <int>[],
        _isTransactionUpdating = false,
        isEnabledAutoGenerateSubaddress = true,
        unspentCoins = [],
        _scripthashesUpdateSubject = {},
        balance = ObservableMap<CryptoCurrency, ElectrumBalance>.of(currency != null
            ? {
                currency: initialBalance ??
                    ElectrumBalance(
                      confirmed: 0,
                      unconfirmed: 0,
                      frozen: 0,
                    )
              }
            : {}),
        this.unspentCoinsInfo = unspentCoinsInfo,
        this.network = _getNetwork(networkType, currency),
        this.isTestnet = networkType == bitcoin.testnet,
        this._mnemonic = mnemonic,
        super(walletInfo) {
    this.electrumClient = electrumClient ?? ElectrumClient();
    this.walletInfo = walletInfo;
    transactionHistory = ElectrumTransactionHistory(walletInfo: walletInfo, password: password);

    reaction((_) => syncStatus, _syncStatusReaction);
  }

  static bitcoin.HDWallet getAccountHDWallet(
      CryptoCurrency? currency,
      bitcoin.NetworkType networkType,
      Uint8List? seedBytes,
      String? xpub,
      DerivationInfo? derivationInfo) {
    if (seedBytes == null && xpub == null) {
      throw Exception(
          "To create a Wallet you need either a seed or an xpub. This should not happen");
    }

    if (seedBytes != null) {
      return currency == CryptoCurrency.bch
          ? bitcoinCashHDWallet(seedBytes)
          : bitcoin.HDWallet.fromSeed(seedBytes, network: networkType)
              .derivePath(_hardenedDerivationPath(derivationInfo?.derivationPath ?? electrum_path));
    }

    return bitcoin.HDWallet.fromBase58(xpub!);
  }

  static bitcoin.HDWallet bitcoinCashHDWallet(Uint8List seedBytes) =>
      bitcoin.HDWallet.fromSeed(seedBytes).derivePath("m/44'/145'/0'");

  static int estimatedTransactionSize(int inputsCount, int outputsCounts) =>
      inputsCount * 68 + outputsCounts * 34 + 10;

  bool? alwaysScan;

  final bitcoin.HDWallet accountHD;
  final String? _mnemonic;

  bitcoin.HDWallet get hd => accountHD.derive(0);
  final String? passphrase;

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

  Set<String> get addressesSet => walletAddresses.allAddresses.map((addr) => addr.address).toSet();

  List<String> get scriptHashes => walletAddresses.addressesByReceiveType
      .map((addr) => scriptHash(addr.address, network: network))
      .toList();

  List<String> get publicScriptHashes => walletAddresses.allAddresses
      .where((addr) => !addr.isHidden)
      .map((addr) => scriptHash(addr.address, network: network))
      .toList();

  String get xpub => accountHD.base58!;

  @override
  String? get seed => _mnemonic;

  bitcoin.NetworkType networkType;
  BasedUtxoNetwork network;

  @override
  bool? isTestnet;

  bool get hasSilentPaymentsScanning => type == WalletType.bitcoin;

  @observable
  bool nodeSupportsSilentPayments = true;
  @observable
  bool silentPaymentsScanningActive = false;

  bool _isTryingToConnect = false;

  @action
  Future<void> setSilentPaymentsScanning(bool active, bool usingElectrs) async {
    silentPaymentsScanningActive = active;

    if (active) {
      syncStatus = AttemptingSyncStatus();

      final tip = await getUpdatedChainTip();

      if (tip == walletInfo.restoreHeight) {
        syncStatus = SyncedTipSyncStatus(tip);
      }

      if (tip > walletInfo.restoreHeight) {
        _setListeners(
          walletInfo.restoreHeight,
          chainTipParam: _currentChainTip,
          usingElectrs: usingElectrs,
        );
      }
    } else {
      alwaysScan = false;

      _isolate?.then((value) => value.kill(priority: Isolate.immediate));

      if (electrumClient.isConnected) {
        syncStatus = SyncedSyncStatus();
      } else {
        if (electrumClient.uri != null) {
          await electrumClient.connectToUri(electrumClient.uri!, useSSL: electrumClient.useSSL);
          startSync();
        }
      }
    }
  }

  int? _currentChainTip;

  Future<int> getCurrentChainTip() async {
    if (_currentChainTip != null) {
      return _currentChainTip!;
    }
    _currentChainTip = await electrumClient.getCurrentBlockChainTip() ?? 0;

    return _currentChainTip!;
  }

  Future<int> getUpdatedChainTip() async {
    final newTip = await electrumClient.getCurrentBlockChainTip();
    if (newTip != null && newTip > (_currentChainTip ?? 0)) {
      _currentChainTip = newTip;
    }
    return _currentChainTip ?? 0;
  }

  @override
  BitcoinWalletKeys get keys =>
      BitcoinWalletKeys(wif: hd.wif!, privateKey: hd.privKey!, publicKey: hd.pubKey!);

  String _password;
  List<BitcoinUnspent> unspentCoins;
  List<int> _feeRates;

  // ignore: prefer_final_fields
  Map<String, BehaviorSubject<Object>?> _scripthashesUpdateSubject;

  // ignore: prefer_final_fields
  BehaviorSubject<Object>? _chainTipUpdateSubject;
  bool _isTransactionUpdating;
  Future<Isolate>? _isolate;

  void Function(FlutterErrorDetails)? _onError;
  Timer? _autoSaveTimer;
  static const int _autoSaveInterval = 30;

  Future<void> init() async {
    await walletAddresses.init();
    await transactionHistory.init();
    await save();

    _autoSaveTimer =
        Timer.periodic(Duration(seconds: _autoSaveInterval), (_) async => await save());
  }

  @action
  Future<void> _setListeners(
    int height, {
    int? chainTipParam,
    bool? doSingleScan,
    bool? usingElectrs,
  }) async {
    final chainTip = chainTipParam ?? await getUpdatedChainTip();

    if (chainTip == height) {
      syncStatus = SyncedSyncStatus();
      return;
    }

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
          silentAddress: walletAddresses.silentAddress!,
          network: network,
          height: height,
          chainTip: chainTip,
          electrumClient: ElectrumClient(),
          transactionHistoryIds: transactionHistory.transactions.keys.toList(),
          node: usingElectrs == true ? ScanNode(node!.uri, node!.useSSL) : null,
          labels: walletAddresses.labels,
          labelIndexes: walletAddresses.silentAddresses
              .where((addr) => addr.type == SilentPaymentsAddresType.p2sp && addr.index >= 1)
              .map((addr) => addr.index)
              .toList(),
          isSingleScan: doSingleScan ?? false,
        ));

    await for (var message in receivePort) {
      if (message is Map<String, ElectrumTransactionInfo>) {
        for (final map in message.entries) {
          final txid = map.key;
          final tx = map.value;

          if (tx.unspents != null) {
            final existingTxInfo = transactionHistory.transactions[txid];
            final txAlreadyExisted = existingTxInfo != null;

            // Updating tx after re-scanned
            if (txAlreadyExisted) {
              existingTxInfo.amount = tx.amount;
              existingTxInfo.confirmations = tx.confirmations;
              existingTxInfo.height = tx.height;

              final newUnspents = tx.unspents!
                  .where((unspent) => !(existingTxInfo.unspents?.any((element) =>
                          element.hash.contains(unspent.hash) &&
                          element.vout == unspent.vout &&
                          element.value == unspent.value) ??
                      false))
                  .toList();

              if (newUnspents.isNotEmpty) {
                newUnspents.forEach(_updateSilentAddressRecord);

                existingTxInfo.unspents ??= [];
                existingTxInfo.unspents!.addAll(newUnspents);

                final newAmount = newUnspents.length > 1
                    ? newUnspents.map((e) => e.value).reduce((value, unspent) => value + unspent)
                    : newUnspents[0].value;

                if (existingTxInfo.direction == TransactionDirection.incoming) {
                  existingTxInfo.amount += newAmount;
                }

                // Updates existing TX
                transactionHistory.addOne(existingTxInfo);
                // Update balance record
                balance[currency]!.confirmed += newAmount;
              }
            } else {
              // else: First time seeing this TX after scanning
              tx.unspents!.forEach(_updateSilentAddressRecord);

              // Add new TX record
              transactionHistory.addMany(message);
              // Update balance record
              balance[currency]!.confirmed += tx.amount;
            }

            await updateAllUnspents();
          }
        }
      }

      if (message is SyncResponse) {
        if (message.syncStatus is UnsupportedSyncStatus) {
          nodeSupportsSilentPayments = false;
        }

        syncStatus = message.syncStatus;
        await walletInfo.updateRestoreHeight(message.height);
      }
    }
  }

  void _updateSilentAddressRecord(BitcoinSilentPaymentsUnspent unspent) {
    final silentAddress = walletAddresses.silentAddress!;
    final silentPaymentAddress = SilentPaymentAddress(
      version: silentAddress.version,
      B_scan: silentAddress.B_scan,
      B_spend: unspent.silentPaymentLabel != null
          ? silentAddress.B_spend.tweakAdd(
              BigintUtils.fromBytes(BytesUtils.fromHexString(unspent.silentPaymentLabel!)),
            )
          : silentAddress.B_spend,
      hrp: silentAddress.hrp,
    );

    final addressRecord = walletAddresses.silentAddresses
        .firstWhereOrNull((address) => address.address == silentPaymentAddress.toString());
    addressRecord?.txCount += 1;
    addressRecord?.balance += unspent.value;

    walletAddresses.addSilentAddresses(
      [unspent.bitcoinAddressRecord as BitcoinSilentPaymentAddressRecord],
    );
  }

  @action
  @override
  Future<void> startSync() async {
    try {
      syncStatus = SyncronizingSyncStatus();

      if (hasSilentPaymentsScanning) {
        await _setInitialHeight();
      }

      await _subscribeForUpdates();

      await updateTransactions();
      await updateAllUnspents();
      await updateBalance();

      Timer.periodic(const Duration(minutes: 1), (timer) async => await updateFeeRates());

      if (alwaysScan == true) {
        _setListeners(walletInfo.restoreHeight);
      } else {
        syncStatus = SyncedSyncStatus();
      }
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e.toString());
      syncStatus = FailedSyncStatus();
    }
  }

  @action
  Future<void> updateFeeRates() async {
    final feeRates = await electrumClient.feeRates(network: network);
    if (feeRates != [0, 0, 0]) {
      _feeRates = feeRates;
    }
  }

  Node? node;

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    this.node = node;

    try {
      syncStatus = ConnectingSyncStatus();

      await electrumClient.close();

      electrumClient.onConnectionStatusChange = _onConnectionStatusChange;

      await electrumClient.connectToUri(node.uri, useSSL: node.useSSL);
    } catch (e) {
      print(e.toString());
      syncStatus = FailedSyncStatus();
    }
  }

  int get _dustAmount => 546;

  bool _isBelowDust(int amount) => amount <= _dustAmount && network != BitcoinNetwork.testnet;

  UtxoDetails _createUTXOS({
    required bool sendAll,
    required int credentialsAmount,
    required bool paysToSilentPayment,
    int? inputsCount,
  }) {
    List<UtxoWithAddress> utxos = [];
    List<Outpoint> vinOutpoints = [];
    List<ECPrivateInfo> inputPrivKeyInfos = [];
    final publicKeys = <String, PublicKeyWithDerivationPath>{};
    int allInputsAmount = 0;
    bool spendsSilentPayment = false;
    bool spendsUnconfirmedTX = false;

    int leftAmount = credentialsAmount;
    final availableInputs = unspentCoins.where((utx) => utx.isSending && !utx.isFrozen).toList();
    final unconfirmedCoins = availableInputs.where((utx) => utx.confirmations == 0).toList();

    for (int i = 0; i < availableInputs.length; i++) {
      final utx = availableInputs[i];
      if (!spendsUnconfirmedTX) spendsUnconfirmedTX = utx.confirmations == 0;

      if (paysToSilentPayment) {
        // Check inputs for shared secret derivation
        if (utx.bitcoinAddressRecord.type == SegwitAddresType.p2wsh) {
          throw BitcoinTransactionSilentPaymentsNotSupported();
        }
      }

      allInputsAmount += utx.value;
      leftAmount = leftAmount - utx.value;

      final address = addressTypeFromStr(utx.address, network);
      ECPrivate? privkey;
      bool? isSilentPayment = false;

      final hd =
          utx.bitcoinAddressRecord.isHidden ? walletAddresses.sideHd : walletAddresses.mainHd;
      final derivationPath =
          "${_hardenedDerivationPath(walletInfo.derivationInfo?.derivationPath ?? "m/0'")}"
          "/${utx.bitcoinAddressRecord.isHidden ? "1" : "0"}"
          "/${utx.bitcoinAddressRecord.index}";
      final pubKeyHex = hd.derive(utx.bitcoinAddressRecord.index).pubKey!;

      publicKeys[address.pubKeyHash()] = PublicKeyWithDerivationPath(pubKeyHex, derivationPath);

      if (utx.bitcoinAddressRecord is BitcoinSilentPaymentAddressRecord) {
        final unspentAddress = utx.bitcoinAddressRecord as BitcoinSilentPaymentAddressRecord;
        privkey = walletAddresses.silentAddress!.b_spend.tweakAdd(
          BigintUtils.fromBytes(
            BytesUtils.fromHexString(unspentAddress.silentPaymentTweak!),
          ),
        );
        spendsSilentPayment = true;
        isSilentPayment = true;
      } else {
        privkey =
            generateECPrivate(hd: hd, index: utx.bitcoinAddressRecord.index, network: network);
      }

      vinOutpoints.add(Outpoint(txid: utx.hash, index: utx.vout));
      inputPrivKeyInfos.add(ECPrivateInfo(
        privkey,
        address.type == SegwitAddresType.p2tr,
        tweak: !isSilentPayment,
      ));

      utxos.add(
        UtxoWithAddress(
          utxo: BitcoinUtxo(
            txHash: utx.hash,
            value: BigInt.from(utx.value),
            vout: utx.vout,
            scriptType: _getScriptType(address),
            isSilentPayment: isSilentPayment,
          ),
          ownerDetails: UtxoAddressDetails(
            publicKey: privkey.getPublic().toHex(),
            address: address,
          ),
        ),
      );

      // sendAll continues for all inputs
      if (!sendAll) {
        bool amountIsAcquired = leftAmount <= 0;
        if ((inputsCount == null && amountIsAcquired) || inputsCount == i + 1) {
          break;
        }
      }
    }

    if (utxos.isEmpty) {
      throw BitcoinTransactionNoInputsException();
    }

    return UtxoDetails(
      availableInputs: availableInputs,
      unconfirmedCoins: unconfirmedCoins,
      utxos: utxos,
      vinOutpoints: vinOutpoints,
      inputPrivKeyInfos: inputPrivKeyInfos,
      publicKeys: publicKeys,
      allInputsAmount: allInputsAmount,
      spendsSilentPayment: spendsSilentPayment,
      spendsUnconfirmedTX: spendsUnconfirmedTX,
    );
  }

  Future<EstimatedTxResult> estimateSendAllTx(
    List<BitcoinOutput> outputs,
    int feeRate, {
    String? memo,
    int credentialsAmount = 0,
    bool hasSilentPayment = false,
  }) async {
    final utxoDetails = _createUTXOS(
      sendAll: true,
      credentialsAmount: credentialsAmount,
      paysToSilentPayment: hasSilentPayment,
    );

    int estimatedSize;
    if (network is BitcoinCashNetwork) {
      estimatedSize = ForkedTransactionBuilder.estimateTransactionSize(
        utxos: utxoDetails.utxos,
        outputs: outputs,
        network: network as BitcoinCashNetwork,
        memo: memo,
      );
    } else {
      estimatedSize = BitcoinTransactionBuilder.estimateTransactionSize(
        utxos: utxoDetails.utxos,
        outputs: outputs,
        network: network,
        memo: memo,
        inputPrivKeyInfos: utxoDetails.inputPrivKeyInfos,
        vinOutpoints: utxoDetails.vinOutpoints,
      );
    }

    int fee = feeAmountWithFeeRate(feeRate, 0, 0, size: estimatedSize);

    if (fee == 0) {
      throw BitcoinTransactionNoFeeException();
    }

    // Here, when sending all, the output amount equals to the input value - fee to fully spend every input on the transaction and have no amount left for change
    int amount = utxoDetails.allInputsAmount - fee;

    if (amount <= 0) {
      throw BitcoinTransactionWrongBalanceException(amount: utxoDetails.allInputsAmount + fee);
    }

    if (amount <= 0) {
      throw BitcoinTransactionWrongBalanceException();
    }

    // Attempting to send less than the dust limit
    if (_isBelowDust(amount)) {
      throw BitcoinTransactionNoDustException();
    }

    if (credentialsAmount > 0) {
      final amountLeftForFee = amount - credentialsAmount;
      if (amountLeftForFee > 0 && _isBelowDust(amountLeftForFee)) {
        amount -= amountLeftForFee;
        fee += amountLeftForFee;
      }
    }

    if (outputs.length == 1) {
      outputs[0] = BitcoinOutput(address: outputs.last.address, value: BigInt.from(amount));
    }

    return EstimatedTxResult(
      utxos: utxoDetails.utxos,
      inputPrivKeyInfos: utxoDetails.inputPrivKeyInfos,
      publicKeys: utxoDetails.publicKeys,
      fee: fee,
      amount: amount,
      isSendAll: true,
      hasChange: false,
      memo: memo,
      spendsUnconfirmedTX: utxoDetails.spendsUnconfirmedTX,
      spendsSilentPayment: utxoDetails.spendsSilentPayment,
    );
  }

  Future<EstimatedTxResult> estimateTxForAmount(
    int credentialsAmount,
    List<BitcoinOutput> outputs,
    int feeRate, {
    int? inputsCount,
    String? memo,
    bool? useUnconfirmed,
    bool hasSilentPayment = false,
  }) async {
    final utxoDetails = _createUTXOS(
      sendAll: false,
      credentialsAmount: credentialsAmount,
      inputsCount: inputsCount,
      paysToSilentPayment: hasSilentPayment,
    );

    final spendingAllCoins = utxoDetails.availableInputs.length == utxoDetails.utxos.length;
    final spendingAllConfirmedCoins = !utxoDetails.spendsUnconfirmedTX &&
        utxoDetails.utxos.length ==
            utxoDetails.availableInputs.length - utxoDetails.unconfirmedCoins.length;

    // How much is being spent - how much is being sent
    int amountLeftForChangeAndFee = utxoDetails.allInputsAmount - credentialsAmount;

    if (amountLeftForChangeAndFee <= 0) {
      if (!spendingAllCoins) {
        return estimateTxForAmount(
          credentialsAmount,
          outputs,
          feeRate,
          inputsCount: utxoDetails.utxos.length + 1,
          memo: memo,
          hasSilentPayment: hasSilentPayment,
        );
      }

      throw BitcoinTransactionWrongBalanceException();
    }

    final changeAddress = await walletAddresses.getChangeAddress();
    final address = addressTypeFromStr(changeAddress, network);
    outputs.add(BitcoinOutput(
      address: address,
      value: BigInt.from(amountLeftForChangeAndFee),
    ));

    int estimatedSize;
    if (network is BitcoinCashNetwork) {
      estimatedSize = ForkedTransactionBuilder.estimateTransactionSize(
        utxos: utxoDetails.utxos,
        outputs: outputs,
        network: network as BitcoinCashNetwork,
        memo: memo,
      );
    } else {
      estimatedSize = BitcoinTransactionBuilder.estimateTransactionSize(
        utxos: utxoDetails.utxos,
        outputs: outputs,
        network: network,
        memo: memo,
        inputPrivKeyInfos: utxoDetails.inputPrivKeyInfos,
        vinOutpoints: utxoDetails.vinOutpoints,
      );
    }

    int fee = feeAmountWithFeeRate(feeRate, 0, 0, size: estimatedSize);

    if (fee == 0) {
      throw BitcoinTransactionNoFeeException();
    }

    int amount = credentialsAmount;
    final lastOutput = outputs.last;
    final amountLeftForChange = amountLeftForChangeAndFee - fee;

    if (!_isBelowDust(amountLeftForChange)) {
      // Here, lastOutput already is change, return the amount left without the fee to the user's address.
      outputs[outputs.length - 1] =
          BitcoinOutput(address: lastOutput.address, value: BigInt.from(amountLeftForChange));
    } else {
      // If has change that is lower than dust, will end up with tx rejected by network rules, so estimate again without the added change
      outputs.removeLast();

      // Still has inputs to spend before failing
      if (!spendingAllCoins) {
        return estimateTxForAmount(
          credentialsAmount,
          outputs,
          feeRate,
          inputsCount: utxoDetails.utxos.length + 1,
          memo: memo,
          useUnconfirmed: useUnconfirmed ?? spendingAllConfirmedCoins,
        );
      }

      final estimatedSendAll = await estimateSendAllTx(
        outputs,
        feeRate,
        memo: memo,
      );

      if (estimatedSendAll.amount == credentialsAmount) {
        return estimatedSendAll;
      }

      // Estimate to user how much is needed to send to cover the fee
      final maxAmountWithReturningChange = utxoDetails.allInputsAmount - _dustAmount - fee - 1;
      throw BitcoinTransactionNoDustOnChangeException(
        bitcoinAmountToString(amount: maxAmountWithReturningChange),
        bitcoinAmountToString(amount: estimatedSendAll.amount),
      );
    }

    // Attempting to send less than the dust limit
    if (_isBelowDust(amount)) {
      throw BitcoinTransactionNoDustException();
    }

    final totalAmount = amount + fee;

    if (totalAmount > balance[currency]!.confirmed) {
      throw BitcoinTransactionWrongBalanceException();
    }

    if (totalAmount > utxoDetails.allInputsAmount) {
      if (spendingAllCoins) {
        throw BitcoinTransactionWrongBalanceException();
      } else {
        outputs.removeLast();
        return estimateTxForAmount(
          credentialsAmount,
          outputs,
          feeRate,
          inputsCount: utxoDetails.utxos.length + 1,
          memo: memo,
          useUnconfirmed: useUnconfirmed ?? spendingAllConfirmedCoins,
          hasSilentPayment: hasSilentPayment,
        );
      }
    }

    return EstimatedTxResult(
      utxos: utxoDetails.utxos,
      inputPrivKeyInfos: utxoDetails.inputPrivKeyInfos,
      publicKeys: utxoDetails.publicKeys,
      fee: fee,
      amount: amount,
      hasChange: true,
      isSendAll: false,
      memo: memo,
      spendsUnconfirmedTX: utxoDetails.spendsUnconfirmedTX,
      spendsSilentPayment: utxoDetails.spendsSilentPayment,
    );
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    try {
      final outputs = <BitcoinOutput>[];
      final transactionCredentials = credentials as BitcoinTransactionCredentials;
      final hasMultiDestination = transactionCredentials.outputs.length > 1;
      final sendAll = !hasMultiDestination && transactionCredentials.outputs.first.sendAll;
      final memo = transactionCredentials.outputs.first.memo;

      int credentialsAmount = 0;
      bool hasSilentPayment = false;

      for (final out in transactionCredentials.outputs) {
        final outputAmount = out.formattedCryptoAmount!;

        if (!sendAll && _isBelowDust(outputAmount)) {
          throw BitcoinTransactionNoDustException();
        }

        if (hasMultiDestination) {
          if (out.sendAll) {
            throw BitcoinTransactionWrongBalanceException();
          }
        }

        credentialsAmount += outputAmount;

        final address =
            addressTypeFromStr(out.isParsedAddress ? out.extractedAddress! : out.address, network);

        if (address is SilentPaymentAddress) {
          hasSilentPayment = true;
        }

        if (sendAll) {
          // The value will be changed after estimating the Tx size and deducting the fee from the total to be sent
          outputs.add(BitcoinOutput(address: address, value: BigInt.from(0)));
        } else {
          outputs.add(BitcoinOutput(address: address, value: BigInt.from(outputAmount)));
        }
      }

      final feeRateInt = transactionCredentials.feeRate != null
          ? transactionCredentials.feeRate!
          : feeRate(transactionCredentials.priority!);

      EstimatedTxResult estimatedTx;
      if (sendAll) {
        estimatedTx = await estimateSendAllTx(
          outputs,
          feeRateInt,
          memo: memo,
          credentialsAmount: credentialsAmount,
          hasSilentPayment: hasSilentPayment,
        );
      } else {
        estimatedTx = await estimateTxForAmount(
          credentialsAmount,
          outputs,
          feeRateInt,
          memo: memo,
          hasSilentPayment: hasSilentPayment,
        );
      }

      if (walletInfo.isHardwareWallet) {
        final transaction = await buildHardwareWalletTransaction(
          utxos: estimatedTx.utxos,
          outputs: outputs,
          publicKeys: estimatedTx.publicKeys,
          fee: BigInt.from(estimatedTx.fee),
          network: network,
          memo: estimatedTx.memo,
          outputOrdering: BitcoinOrdering.none,
          enableRBF: true,
        );

        return PendingBitcoinTransaction(
          transaction,
          type,
          electrumClient: electrumClient,
          amount: estimatedTx.amount,
          fee: estimatedTx.fee,
          feeRate: feeRateInt.toString(),
          network: network,
          hasChange: estimatedTx.hasChange,
          isSendAll: estimatedTx.isSendAll,
          hasTaprootInputs: false, // ToDo: (Konsti) Support Taproot
        )..addListener((transaction) async {
            transactionHistory.addOne(transaction);
            await updateBalance();
          });
      }

      BasedBitcoinTransacationBuilder txb;
      if (network is BitcoinCashNetwork) {
        txb = ForkedTransactionBuilder(
          utxos: estimatedTx.utxos,
          outputs: outputs,
          fee: BigInt.from(estimatedTx.fee),
          network: network,
          memo: estimatedTx.memo,
          outputOrdering: BitcoinOrdering.none,
          enableRBF: !estimatedTx.spendsUnconfirmedTX,
        );
      } else {
        txb = BitcoinTransactionBuilder(
          utxos: estimatedTx.utxos,
          outputs: outputs,
          fee: BigInt.from(estimatedTx.fee),
          network: network,
          memo: estimatedTx.memo,
          outputOrdering: BitcoinOrdering.none,
          enableRBF: !estimatedTx.spendsUnconfirmedTX,
        );
      }

      bool hasTaprootInputs = false;

      final transaction = txb.buildTransaction((txDigest, utxo, publicKey, sighash) {
        final key = estimatedTx.inputPrivKeyInfos
            .firstWhereOrNull((element) => element.privkey.getPublic().toHex() == publicKey);

        if (key == null) {
          throw Exception("Cannot find private key");
        }

        if (utxo.utxo.isP2tr()) {
          hasTaprootInputs = true;
          return key.privkey.signTapRoot(
            txDigest,
            sighash: sighash,
            tweak: utxo.utxo.isSilentPayment != true,
          );
        } else {
          return key.privkey.signInput(txDigest, sigHash: sighash);
        }
      });

      return PendingBitcoinTransaction(
        transaction,
        type,
        electrumClient: electrumClient,
        amount: estimatedTx.amount,
        fee: estimatedTx.fee,
        feeRate: feeRateInt.toString(),
        network: network,
        hasChange: estimatedTx.hasChange,
        isSendAll: estimatedTx.isSendAll,
        hasTaprootInputs: hasTaprootInputs,
      )..addListener((transaction) async {
          transactionHistory.addOne(transaction);
          if (estimatedTx.spendsSilentPayment) {
            transactionHistory.transactions.values.forEach((tx) {
              tx.unspents?.removeWhere(
                  (unspent) => estimatedTx.utxos.any((e) => e.utxo.txHash == unspent.hash));
              transactionHistory.addOne(tx);
            });
          }

          await updateBalance();
        });
    } catch (e) {
      throw e;
    }
  }

  Future<BtcTransaction> buildHardwareWalletTransaction({
    required List<BitcoinBaseOutput> outputs,
    required BigInt fee,
    required BasedUtxoNetwork network,
    required List<UtxoWithAddress> utxos,
    required Map<String, PublicKeyWithDerivationPath> publicKeys,
    String? memo,
    bool enableRBF = false,
    BitcoinOrdering inputOrdering = BitcoinOrdering.bip69,
    BitcoinOrdering outputOrdering = BitcoinOrdering.bip69,
  }) async =>
      throw UnimplementedError();

  String toJSON() => json.encode({
        'mnemonic': _mnemonic,
        'xpub': xpub,
        'passphrase': passphrase ?? '',
        'account_index': walletAddresses.currentReceiveAddressIndexByType,
        'change_address_index': walletAddresses.currentChangeAddressIndexByType,
        'addresses': walletAddresses.allAddresses.map((addr) => addr.toJSON()).toList(),
        'address_page_type': walletInfo.addressPageType == null
            ? SegwitAddresType.p2wpkh.toString()
            : walletInfo.addressPageType.toString(),
        'balance': balance[currency]?.toJSON(),
        'derivationTypeIndex': walletInfo.derivationInfo?.derivationType?.index,
        'derivationPath': walletInfo.derivationInfo?.derivationPath,
        'silent_addresses': walletAddresses.silentAddresses.map((addr) => addr.toJSON()).toList(),
        'silent_address_index': walletAddresses.currentSilentAddressIndex.toString(),
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

  int feeAmountForPriority(TransactionPriority priority, int inputsCount, int outputsCount,
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

  @action
  @override
  Future<void> rescan({
    required int height,
    int? chainTip,
    ScanData? scanData,
    bool? doSingleScan,
    bool? usingElectrs,
  }) async {
    silentPaymentsScanningActive = true;
    _setListeners(height, doSingleScan: doSingleScan, usingElectrs: usingElectrs);
  }

  @override
  Future<void> close() async {
    try {
      await electrumClient.close();
    } catch (_) {}
    _autoSaveTimer?.cancel();
  }

  Future<String> makePath() async => pathForWallet(name: walletInfo.name, type: walletInfo.type);

  @action
  Future<void> updateAllUnspents() async {
    List<BitcoinUnspent> updatedUnspentCoins = [];

    if (hasSilentPaymentsScanning) {
      // Update unspents stored from scanned silent payment transactions
      transactionHistory.transactions.values.forEach((tx) {
        if (tx.unspents != null) {
          updatedUnspentCoins.addAll(tx.unspents!);
        }
      });
    }

    await Future.wait(walletAddresses.allAddresses.map((address) async {
      updatedUnspentCoins.addAll(await fetchUnspent(address));
    }));

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
          if (coin.bitcoinAddressRecord is! BitcoinSilentPaymentAddressRecord)
            coin.bitcoinAddressRecord.balance += coinInfo.value;
        } else {
          _addCoinInfo(coin);
        }
      });
    }

    await _refreshUnspentCoinsInfo();
  }

  @action
  Future<void> updateUnspents(BitcoinAddressRecord address) async {
    final newUnspentCoins = await fetchUnspent(address);

    if (newUnspentCoins.isNotEmpty) {
      unspentCoins.addAll(newUnspentCoins);

      newUnspentCoins.forEach((coin) {
        final coinInfoList = unspentCoinsInfo.values.where(
          (element) =>
              element.walletId.contains(id) &&
              element.hash.contains(coin.hash) &&
              element.vout == coin.vout,
        );

        if (coinInfoList.isNotEmpty) {
          final coinInfo = coinInfoList.first;

          coin.isFrozen = coinInfo.isFrozen;
          coin.isSending = coinInfo.isSending;
          coin.note = coinInfo.note;
          if (coin.bitcoinAddressRecord is! BitcoinSilentPaymentAddressRecord)
            coin.bitcoinAddressRecord.balance += coinInfo.value;
        } else {
          _addCoinInfo(coin);
        }
      });
    }
  }

  @action
  Future<List<BitcoinUnspent>> fetchUnspent(BitcoinAddressRecord address) async {
    final unspents = await electrumClient.getListUnspent(address.getScriptHash(network));

    List<BitcoinUnspent> updatedUnspentCoins = [];

    await Future.wait(unspents.map((unspent) async {
      try {
        final coin = BitcoinUnspent.fromJSON(address, unspent);
        final tx = await fetchTransactionInfo(hash: coin.hash, height: 0);
        coin.isChange = address.isHidden;
        coin.confirmations = tx?.confirmations;

        updatedUnspentCoins.add(coin);
      } catch (_) {}
    }));

    return updatedUnspentCoins;
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
      isSilentPayment: coin is BitcoinSilentPaymentsUnspent,
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
    } catch (e) {
      print(e.toString());
    }
  }

  Future<bool> canReplaceByFee(String hash) async {
    final verboseTransaction = await electrumClient.getTransactionRaw(hash: hash);
    final confirmations = verboseTransaction['confirmations'] as int? ?? 0;
    final transactionHex = verboseTransaction['hex'] as String?;

    if (confirmations > 0) return false;

    if (transactionHex == null) {
      return false;
    }

    final original = bitcoin.Transaction.fromHex(transactionHex);

    return original.ins
        .any((element) => element.sequence != null && element.sequence! < 4294967293);
  }

  Future<bool> isChangeSufficientForFee(String txId, int newFee) async {
    final bundle = await getTransactionExpanded(hash: txId);
    final outputs = bundle.originalTransaction.outputs;

    final changeAddresses = walletAddresses.allAddresses.where((element) => element.isHidden);

    // look for a change address in the outputs
    final changeOutput = outputs.firstWhereOrNull((output) => changeAddresses.any(
        (element) => element.address == addressFromOutputScript(output.scriptPubKey, network)));

    var allInputsAmount = 0;

    for (int i = 0; i < bundle.originalTransaction.inputs.length; i++) {
      final input = bundle.originalTransaction.inputs[i];
      final inputTransaction = bundle.ins[i];
      final vout = input.txIndex;
      final outTransaction = inputTransaction.outputs[vout];
      allInputsAmount += outTransaction.amount.toInt();
    }

    int totalOutAmount = bundle.originalTransaction.outputs
        .fold<int>(0, (previousValue, element) => previousValue + element.amount.toInt());

    var currentFee = allInputsAmount - totalOutAmount;

    int remainingFee = (newFee - currentFee > 0) ? newFee - currentFee : newFee;

    return changeOutput != null && changeOutput.amount.toInt() - remainingFee >= 0;
  }

  Future<PendingBitcoinTransaction> replaceByFee(String hash, int newFee) async {
    try {
      final bundle = await getTransactionExpanded(hash: hash);

      final utxos = <UtxoWithAddress>[];
      List<ECPrivate> privateKeys = [];

      var allInputsAmount = 0;

      // Add inputs
      for (var i = 0; i < bundle.originalTransaction.inputs.length; i++) {
        final input = bundle.originalTransaction.inputs[i];
        final inputTransaction = bundle.ins[i];
        final vout = input.txIndex;
        final outTransaction = inputTransaction.outputs[vout];
        final address = addressFromOutputScript(outTransaction.scriptPubKey, network);
        allInputsAmount += outTransaction.amount.toInt();

        final addressRecord =
            walletAddresses.allAddresses.firstWhere((element) => element.address == address);

        final btcAddress = addressTypeFromStr(addressRecord.address, network);
        final privkey = generateECPrivate(
            hd: addressRecord.isHidden ? walletAddresses.sideHd : walletAddresses.mainHd,
            index: addressRecord.index,
            network: network);

        privateKeys.add(privkey);

        utxos.add(
          UtxoWithAddress(
            utxo: BitcoinUtxo(
              txHash: input.txId,
              value: outTransaction.amount,
              vout: vout,
              scriptType: _getScriptType(btcAddress),
            ),
            ownerDetails:
                UtxoAddressDetails(publicKey: privkey.getPublic().toHex(), address: btcAddress),
          ),
        );
      }

      int totalOutAmount = bundle.originalTransaction.outputs
          .fold<int>(0, (previousValue, element) => previousValue + element.amount.toInt());

      var currentFee = allInputsAmount - totalOutAmount;
      int remainingFee = newFee - currentFee;

      final outputs = <BitcoinOutput>[];

      // Add outputs and deduct the fees from it
      for (int i = bundle.originalTransaction.outputs.length - 1; i >= 0; i--) {
        final out = bundle.originalTransaction.outputs[i];
        final address = addressFromOutputScript(out.scriptPubKey, network);
        final btcAddress = addressTypeFromStr(address, network);

        int newAmount;
        if (out.amount.toInt() >= remainingFee) {
          newAmount = out.amount.toInt() - remainingFee;
          remainingFee = 0;

          // if new amount of output is less than dust amount, then don't add this output as well
          if (newAmount <= _dustAmount) {
            continue;
          }
        } else {
          remainingFee -= out.amount.toInt();
          continue;
        }

        outputs.add(BitcoinOutput(address: btcAddress, value: BigInt.from(newAmount)));
      }

      final changeAddresses = walletAddresses.allAddresses.where((element) => element.isHidden);

      // look for a change address in the outputs
      final changeOutput = outputs.firstWhereOrNull((output) =>
          changeAddresses.any((element) => element.address == output.address.toAddress(network)));

      // deduct the change amount from the output amount
      if (changeOutput != null) {
        totalOutAmount -= changeOutput.value.toInt();
      }

      final txb = BitcoinTransactionBuilder(
        utxos: utxos,
        outputs: outputs,
        fee: BigInt.from(newFee),
        network: network,
        enableRBF: true,
      );

      final transaction = txb.buildTransaction((txDigest, utxo, publicKey, sighash) {
        final key =
            privateKeys.firstWhereOrNull((element) => element.getPublic().toHex() == publicKey);

        if (key == null) {
          throw Exception("Cannot find private key");
        }

        if (utxo.utxo.isP2tr()) {
          return key.signTapRoot(txDigest, sighash: sighash);
        } else {
          return key.signInput(txDigest, sigHash: sighash);
        }
      });

      return PendingBitcoinTransaction(
        transaction,
        type,
        electrumClient: electrumClient,
        amount: totalOutAmount,
        fee: newFee,
        network: network,
        hasChange: changeOutput != null,
        feeRate: newFee.toString(),
      )..addListener((transaction) async {
          transactionHistory.addOne(transaction);
          await updateBalance();
        });
    } catch (e) {
      throw e;
    }
  }

  Future<ElectrumTransactionBundle> getTransactionExpanded({required String hash}) async {
    String transactionHex;
    int? time;
    int confirmations = 0;
    if (network == BitcoinNetwork.testnet) {
      // Testnet public electrum server does not support verbose transaction fetching
      transactionHex = await electrumClient.getTransactionHex(hash: hash);

      final status = json.decode(
          (await http.get(Uri.parse("https://blockstream.info/testnet/api/tx/$hash/status"))).body);

      time = status["block_time"] as int?;
      final height = status["block_height"] as int? ?? 0;
      final tip = await getUpdatedChainTip();
      if (tip > 0) confirmations = height > 0 ? tip - height + 1 : 0;
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

    return ElectrumTransactionBundle(
      original,
      ins: ins,
      time: time,
      confirmations: confirmations,
    );
  }

  Future<ElectrumTransactionInfo?> fetchTransactionInfo(
      {required String hash, required int height, bool? retryOnFailure}) async {
    try {
      return ElectrumTransactionInfo.fromElectrumBundle(
          await getTransactionExpanded(hash: hash), walletInfo.type, network,
          addresses: addressesSet, height: height);
    } catch (e) {
      if (e is FormatException && retryOnFailure == true) {
        await Future.delayed(const Duration(seconds: 2));
        return fetchTransactionInfo(hash: hash, height: height);
      }
      return null;
    }
  }

  @override
  Future<Map<String, ElectrumTransactionInfo>> fetchTransactions() async {
    try {
      final Map<String, ElectrumTransactionInfo> historiesWithDetails = {};

      if (type == WalletType.bitcoin) {
        await Future.wait(ADDRESS_TYPES
            .map((type) => fetchTransactionsForAddressType(historiesWithDetails, type)));
      } else if (type == WalletType.bitcoinCash) {
        await fetchTransactionsForAddressType(historiesWithDetails, P2pkhAddressType.p2pkh);
      } else if (type == WalletType.litecoin) {
        await fetchTransactionsForAddressType(historiesWithDetails, SegwitAddresType.p2wpkh);
      }

      transactionHistory.transactions.values.forEach((tx) async {
        final isPendingSilentPaymentUtxo =
            (tx.isPending || tx.confirmations == 0) && historiesWithDetails[tx.id] == null;

        if (isPendingSilentPaymentUtxo) {
          final info =
              await fetchTransactionInfo(hash: tx.id, height: tx.height, retryOnFailure: true);

          if (info != null) {
            tx.confirmations = info.confirmations;
            tx.isPending = tx.confirmations == 0;
            transactionHistory.addOne(tx);
            await transactionHistory.save();
          }
        }
      });

      return historiesWithDetails;
    } catch (e) {
      print(e.toString());
      return {};
    }
  }

  Future<void> fetchTransactionsForAddressType(
    Map<String, ElectrumTransactionInfo> historiesWithDetails,
    BitcoinAddressType type,
  ) async {
    final addressesByType = walletAddresses.allAddresses.where((addr) => addr.type == type);
    final hiddenAddresses = addressesByType.where((addr) => addr.isHidden == true);
    final receiveAddresses = addressesByType.where((addr) => addr.isHidden == false);

    await Future.wait(addressesByType.map((addressRecord) async {
      final history = await _fetchAddressHistory(addressRecord, await getCurrentChainTip());

      if (history.isNotEmpty) {
        addressRecord.txCount = history.length;
        historiesWithDetails.addAll(history);

        final matchedAddresses = addressRecord.isHidden ? hiddenAddresses : receiveAddresses;
        final isUsedAddressUnderGap = matchedAddresses.toList().indexOf(addressRecord) >=
            matchedAddresses.length -
                (addressRecord.isHidden
                    ? ElectrumWalletAddressesBase.defaultChangeAddressesCount
                    : ElectrumWalletAddressesBase.defaultReceiveAddressesCount);

        if (isUsedAddressUnderGap) {
          final prevLength = walletAddresses.allAddresses.length;

          // Discover new addresses for the same address type until the gap limit is respected
          await walletAddresses.discoverAddresses(
            matchedAddresses.toList(),
            addressRecord.isHidden,
            (address) async {
              await _subscribeForUpdates();
              return _fetchAddressHistory(address, await getCurrentChainTip())
                  .then((history) => history.isNotEmpty ? address.address : null);
            },
            type: type,
          );

          final newLength = walletAddresses.allAddresses.length;

          if (newLength > prevLength) {
            await fetchTransactionsForAddressType(historiesWithDetails, type);
          }
        }
      }
    }));
  }

  Future<Map<String, ElectrumTransactionInfo>> _fetchAddressHistory(
      BitcoinAddressRecord addressRecord, int? currentHeight) async {
    try {
      final Map<String, ElectrumTransactionInfo> historiesWithDetails = {};

      final history = await electrumClient.getHistory(addressRecord.getScriptHash(network));

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
              if (currentHeight != null) storedTx.confirmations = currentHeight - height + 1;
              storedTx.isPending = storedTx.confirmations == 0;
            }

            historiesWithDetails[txid] = storedTx;
          } else {
            final tx = await fetchTransactionInfo(hash: txid, height: height, retryOnFailure: true);

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
      await getCurrentChainTip();

      transactionHistory.transactions.values.forEach((tx) async {
        if (tx.unspents != null && tx.unspents!.isNotEmpty && tx.height > 0) {
          tx.confirmations = await getCurrentChainTip() - tx.height + 1;
        }
      });

      _isTransactionUpdating = true;
      await fetchTransactions();
      walletAddresses.updateReceiveAddresses();
      _isTransactionUpdating = false;
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e);
      _isTransactionUpdating = false;
    }
  }

  Future<void> _subscribeForUpdates() async {
    final unsubscribedScriptHashes = walletAddresses.allAddresses.where(
      (address) => !_scripthashesUpdateSubject.containsKey(address.getScriptHash(network)),
    );

    await Future.wait(unsubscribedScriptHashes.map((address) async {
      final sh = address.getScriptHash(network);
      await _scripthashesUpdateSubject[sh]?.close();
      _scripthashesUpdateSubject[sh] = await electrumClient.scripthashUpdate(sh);
      _scripthashesUpdateSubject[sh]?.listen((event) async {
        try {
          await updateUnspents(address);

          await updateBalance();

          await _fetchAddressHistory(address, await getCurrentChainTip());
        } catch (e, s) {
          print(e.toString());
          _onError?.call(FlutterErrorDetails(
            exception: e,
            stack: s,
            library: this.runtimeType.toString(),
          ));
        }
      });
    }));
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

    if (hasSilentPaymentsScanning) {
      // Add values from unspent coins that are not fetched by the address list
      // i.e. scanned silent payments
      transactionHistory.transactions.values.forEach((tx) {
        if (tx.unspents != null) {
          tx.unspents!.forEach((unspent) {
            if (unspent.bitcoinAddressRecord is BitcoinSilentPaymentAddressRecord) {
              if (unspent.isFrozen) totalFrozen += unspent.value;
              totalConfirmed += unspent.value;
            }
          });
        }
      });
    }

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
  Future<String> signMessage(String message, {String? address = null}) async {
    final index = address != null
        ? walletAddresses.allAddresses.firstWhere((element) => element.address == address).index
        : null;
    final HD = index == null ? hd : hd.derive(index);
    return base64Encode(HD.signMessage(message));
  }

  Future<void> _setInitialHeight() async {
    if (_chainTipUpdateSubject != null) return;

    if ((_currentChainTip == null || _currentChainTip! == 0) && walletInfo.restoreHeight == 0) {
      await getUpdatedChainTip();
      await walletInfo.updateRestoreHeight(_currentChainTip!);
    }

    _chainTipUpdateSubject = electrumClient.chainTipSubscribe();
    _chainTipUpdateSubject?.listen((e) async {
      final event = e as Map<String, dynamic>;
      final height = int.tryParse(event['height'].toString());

      if (height != null) {
        _currentChainTip = height;

        if (alwaysScan == true && syncStatus is SyncedSyncStatus) {
          _setListeners(walletInfo.restoreHeight);
        }
      }
    });
  }

  static BasedUtxoNetwork _getNetwork(bitcoin.NetworkType networkType, CryptoCurrency? currency) {
    if (networkType == bitcoin.bitcoin && currency == CryptoCurrency.bch) {
      return BitcoinCashNetwork.mainnet;
    }

    if (networkType == litecoinNetwork) {
      return LitecoinNetwork.mainnet;
    }

    if (networkType == bitcoin.testnet) {
      return BitcoinNetwork.testnet;
    }

    return BitcoinNetwork.mainnet;
  }

  static String _hardenedDerivationPath(String derivationPath) =>
      derivationPath.substring(0, derivationPath.lastIndexOf("'") + 1);

  @action
  void _onConnectionStatusChange(bool? isConnected) {
    if (syncStatus is SyncingSyncStatus) return;

    if (isConnected == true && syncStatus is! SyncedSyncStatus) {
      syncStatus = ConnectedSyncStatus();
    } else if (isConnected == false) {
      syncStatus = LostConnectionSyncStatus();
    } else if (isConnected != true && syncStatus is! ConnectingSyncStatus) {
      syncStatus = NotConnectedSyncStatus();
    }
  }

  void _syncStatusReaction(SyncStatus syncStatus) async {
    if (syncStatus is! AttemptingSyncStatus && syncStatus is! SyncedTipSyncStatus) {
      silentPaymentsScanningActive = syncStatus is SyncingSyncStatus;
    }

    if (syncStatus is NotConnectedSyncStatus) {
      // Needs to re-subscribe to all scripthashes when reconnected
      _scripthashesUpdateSubject = {};

      if (_isTryingToConnect) return;

      _isTryingToConnect = true;

      Future.delayed(Duration(seconds: 10), () {
        if (this.syncStatus is! SyncedSyncStatus && this.syncStatus is! SyncedTipSyncStatus) {
          this.electrumClient.connectToUri(
                node!.uri,
                useSSL: node!.useSSL ?? false,
              );
        }
        _isTryingToConnect = false;
      });
    }

    // Message is shown on the UI for 3 seconds, revert to synced
    if (syncStatus is SyncedTipSyncStatus) {
      Timer(Duration(seconds: 3), () {
        if (this.syncStatus is SyncedTipSyncStatus) this.syncStatus = SyncedSyncStatus();
      });
    }
  }
}

class ScanNode {
  final Uri uri;
  final bool? useSSL;

  ScanNode(this.uri, this.useSSL);
}

class ScanData {
  final SendPort sendPort;
  final SilentPaymentOwner silentAddress;
  final int height;
  final ScanNode? node;
  final BasedUtxoNetwork network;
  final int chainTip;
  final ElectrumClient electrumClient;
  final List<String> transactionHistoryIds;
  final Map<String, String> labels;
  final List<int> labelIndexes;
  final bool isSingleScan;

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
    required this.labelIndexes,
    required this.isSingleScan,
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
      labelIndexes: scanData.labelIndexes,
      isSingleScan: scanData.isSingleScan,
    );
  }
}

class SyncResponse {
  final int height;
  final SyncStatus syncStatus;

  SyncResponse(this.height, this.syncStatus);
}

Future<void> startRefresh(ScanData scanData) async {
  int syncHeight = scanData.height;
  int initialSyncHeight = syncHeight;

  BehaviorSubject<Object>? tweaksSubscription = null;

  final syncingStatus = scanData.isSingleScan
      ? SyncingSyncStatus(1, 0)
      : SyncingSyncStatus.fromHeightValues(scanData.chainTip, initialSyncHeight, syncHeight);

  // Initial status UI update, send how many blocks left to scan
  scanData.sendPort.send(SyncResponse(syncHeight, syncingStatus));

  final electrumClient = scanData.electrumClient;
  await electrumClient.connectToUri(
    scanData.node?.uri ?? Uri.parse("tcp://electrs.cakewallet.com:50001"),
    useSSL: scanData.node?.useSSL ?? false,
  );

  if (tweaksSubscription == null) {
    final count = scanData.isSingleScan ? 1 : TWEAKS_COUNT;
    final receiver = Receiver(
      scanData.silentAddress.b_scan.toHex(),
      scanData.silentAddress.B_spend.toHex(),
      scanData.network == BitcoinNetwork.testnet,
      scanData.labelIndexes,
      scanData.labelIndexes.length,
    );

    tweaksSubscription = await electrumClient.tweaksSubscribe(height: syncHeight, count: count);
    tweaksSubscription?.listen((t) async {
      final tweaks = t as Map<String, dynamic>;

      if (tweaks["message"] != null) {
        // re-subscribe to continue receiving messages
        electrumClient.tweaksSubscribe(height: syncHeight, count: count);
        return;
      }

      final blockHeight = tweaks.keys.first;
      final tweakHeight = int.parse(blockHeight);

      try {
        final blockTweaks = tweaks[blockHeight] as Map<String, dynamic>;

        for (var j = 0; j < blockTweaks.keys.length; j++) {
          final txid = blockTweaks.keys.elementAt(j);
          final details = blockTweaks[txid] as Map<String, dynamic>;
          final outputPubkeys = (details["output_pubkeys"] as Map<dynamic, dynamic>);
          final tweak = details["tweak"].toString();

          try {
            // scanOutputs called from rust here
            final addToWallet = scanOutputs(
              outputPubkeys.values.toList(),
              tweak,
              receiver,
            );

            if (addToWallet.isEmpty) {
              // no results tx, continue to next tx
              continue;
            }

            // placeholder ElectrumTransactionInfo object to update values based on new scanned unspent(s)
            final txInfo = ElectrumTransactionInfo(
              WalletType.bitcoin,
              id: txid,
              height: tweakHeight,
              amount: 0,
              fee: 0,
              direction: TransactionDirection.incoming,
              isPending: false,
              date: scanData.network == BitcoinNetwork.mainnet
                  ? getDateByBitcoinHeight(tweakHeight)
                  : DateTime.now(),
              confirmations: scanData.chainTip - tweakHeight + 1,
              unspents: [],
            );

            addToWallet.forEach((label, value) {
              (value as Map<String, dynamic>).forEach((output, tweak) {
                final t_k = tweak.toString();

                final receivingOutputAddress = ECPublic.fromHex(output)
                    .toTaprootAddress(tweak: false)
                    .toAddress(scanData.network);

                int? amount;
                int? pos;
                outputPubkeys.entries.firstWhere((k) {
                  final isMatchingOutput = k.value[0] == output;
                  if (isMatchingOutput) {
                    amount = int.parse(k.value[1].toString());
                    pos = int.parse(k.key.toString());
                    return true;
                  }
                  return false;
                });

                final receivedAddressRecord = BitcoinSilentPaymentAddressRecord(
                  receivingOutputAddress,
                  index: 0,
                  isHidden: false,
                  isUsed: true,
                  network: scanData.network,
                  silentPaymentTweak: t_k,
                  type: SegwitAddresType.p2tr,
                  txCount: 1,
                  balance: amount!,
                );

                final unspent = BitcoinSilentPaymentsUnspent(
                  receivedAddressRecord,
                  txid,
                  amount!,
                  pos!,
                  silentPaymentTweak: t_k,
                  silentPaymentLabel: label == "None" ? null : label,
                );

                txInfo.unspents!.add(unspent);
                txInfo.amount += unspent.value;
              });
            });

            scanData.sendPort.send({txInfo.id: txInfo});
          } catch (_) {}
        }
      } catch (_) {}

      syncHeight = tweakHeight;
      scanData.sendPort.send(
        SyncResponse(
          syncHeight,
          SyncingSyncStatus.fromHeightValues(
            scanData.chainTip,
            initialSyncHeight,
            syncHeight,
          ),
        ),
      );

      if (tweakHeight >= scanData.chainTip || scanData.isSingleScan) {
        if (tweakHeight >= scanData.chainTip)
          scanData.sendPort.send(SyncResponse(
            syncHeight,
            SyncedTipSyncStatus(scanData.chainTip),
          ));

        if (scanData.isSingleScan) {
          scanData.sendPort.send(SyncResponse(syncHeight, SyncedSyncStatus()));
        }

        await tweaksSubscription!.close();
        await electrumClient.close();
      }
    });
  }

  if (tweaksSubscription == null) {
    return scanData.sendPort.send(
      SyncResponse(syncHeight, UnsupportedSyncStatus()),
    );
  }
}

class EstimatedTxResult {
  EstimatedTxResult({
    required this.utxos,
    required this.inputPrivKeyInfos,
    required this.publicKeys,
    required this.fee,
    required this.amount,
    required this.hasChange,
    required this.isSendAll,
    this.memo,
    required this.spendsSilentPayment,
    required this.spendsUnconfirmedTX,
  });

  final List<UtxoWithAddress> utxos;
  final List<ECPrivateInfo> inputPrivKeyInfos;
  final Map<String, PublicKeyWithDerivationPath> publicKeys; // PubKey to derivationPath
  final int fee;
  final int amount;
  final bool spendsSilentPayment;
  final bool hasChange;
  final bool isSendAll;
  final String? memo;
  final bool spendsUnconfirmedTX;
}

class PublicKeyWithDerivationPath {
  const PublicKeyWithDerivationPath(this.publicKey, this.derivationPath);

  final String derivationPath;
  final String publicKey;
}

BitcoinBaseAddress addressTypeFromStr(String address, BasedUtxoNetwork network) {
  if (network is BitcoinCashNetwork) {
    if (!address.startsWith("bitcoincash:") &&
        (address.startsWith("q") || address.startsWith("p"))) {
      address = "bitcoincash:$address";
    }

    return BitcoinCashAddress(address).baseAddress;
  }

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

class UtxoDetails {
  final List<BitcoinUnspent> availableInputs;
  final List<BitcoinUnspent> unconfirmedCoins;
  final List<UtxoWithAddress> utxos;
  final List<Outpoint> vinOutpoints;
  final List<ECPrivateInfo> inputPrivKeyInfos;
  final Map<String, PublicKeyWithDerivationPath> publicKeys; // PubKey to derivationPath
  final int allInputsAmount;
  final bool spendsSilentPayment;
  final bool spendsUnconfirmedTX;

  UtxoDetails({
    required this.availableInputs,
    required this.unconfirmedCoins,
    required this.utxos,
    required this.vinOutpoints,
    required this.inputPrivKeyInfos,
    required this.publicKeys,
    required this.allInputsAmount,
    required this.spendsSilentPayment,
    required this.spendsUnconfirmedTX,
  });
}
