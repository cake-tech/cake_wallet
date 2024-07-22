import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:collection/collection.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/exceptions.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_bitcoin/script_hash.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/get_height_by_date.dart';
import 'package:mobx/mobx.dart';
import 'package:rxdart/subjects.dart';
import 'package:sp_scanner/sp_scanner.dart';

part 'silent_payments_wallet.g.dart';

class SilentPaymentWalletUtxoDetails extends UtxoDetails {
  SilentPaymentWalletUtxoDetails({
    required super.availableInputs,
    required super.unconfirmedCoins,
    required super.utxos,
    required super.inputPrivKeyInfos,
    required super.publicKeys,
    required super.allInputsAmount,
    required super.spendsUnconfirmedTX,
    required super.spendsSilentPayment,
  }) : super();
}

class SilentPaymentWalletEstimatedTxResult extends EstimatedTxResult {
  SilentPaymentWalletEstimatedTxResult({
    required super.utxos,
    required super.inputPrivKeyInfos,
    required super.publicKeys,
    required super.fee,
    required super.amount,
    required super.hasChange,
    required super.isSendAll,
    required super.spendsUnconfirmedTX,
    super.memo,
    required super.spendsSilentPayment,
  });
}

class SilentPaymentsWallet = SilentPaymentsWalletBase with _$SilentPaymentsWallet;

abstract class SilentPaymentsWalletBase extends ElectrumWallet {
  SilentPaymentsWalletBase({
    required super.password,
    required super.walletInfo,
    required super.unspentCoinsInfo,
    required super.network,
    required super.mnemonic,
    required super.passphrase,
    super.initialBalance,
    required super.currency,
    this.silentPaymentsAlwaysScanning = false,
  }) : super();

  @observable
  bool silentPaymentsAlwaysScanning;
  bool get hasSilentPaymentsScanning => type == WalletType.bitcoin;
  @observable
  bool nodeSupportsSilentPayments = true;
  @observable
  bool silentPaymentsScanningActive = false;

  @observable
  int? _currentChainTip;

  BehaviorSubject<Object>? _chainTipUpdateSubject;

  @observable
  Future<Isolate>? _isolate;

  @action
  Future<void> setSilentPaymentsScanning(bool active, bool usingElectrs) async {
    silentPaymentsScanningActive = active;

    if (active) {
      syncStatus = AttemptingSyncStatus();

      final tip = await latestChainTip;

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
      silentPaymentsAlwaysScanning = false;

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

  @action
  Future<void> _setListeners(
    int height, {
    int? chainTipParam,
    bool? doSingleScan,
    bool? usingElectrs,
  }) async {
    final chainTip = chainTipParam ?? await latestChainTip;

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
        _startElectrumScan,
        _ScanData(
          sendPort: receivePort.sendPort,
          silentAddress: walletAddresses.silentAddress!,
          network: network,
          height: height,
          chainTip: chainTip,
          electrumClient: ElectrumClient(),
          transactionHistoryIds: transactionHistory.transactions.keys.toList(),
          node: usingElectrs == true ? _ScanNode(node!.uri, node!.useSSL) : null,
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

      if (message is _SyncResponse) {
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

      await subscribeForUpdates;

      await updateTransactions();
      await updateAllUnspents();
      await updateBalance();

      Timer.periodic(const Duration(minutes: 1), (timer) async => await updateFeeRates());

      if (silentPaymentsAlwaysScanning == true) {
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

  SilentPaymentWalletUtxoDetails _createUTXOS({
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

      final address = BitcoinBaseAddress.fromString(utx.address, network);
      ECPrivate? privkey;
      bool? isSilentPayment = false;

      final hd =
          utx.bitcoinAddressRecord.isHidden ? walletAddresses.sideHd : walletAddresses.mainHd;
      final derivationPath =
          "${ElectrumWalletBase.hardenedDerivationPath(Bip32PathParser.parse(walletInfo.derivationInfo?.derivationPath ?? "m/0'"))}"
          "/${utx.bitcoinAddressRecord.isHidden ? "1" : "0"}"
          "/${utx.bitcoinAddressRecord.index}";
      final pubKeyHex =
          hd.childKey(Bip32KeyIndex(utx.bitcoinAddressRecord.index)).publicKey.toHex();

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
        privkey = generateECPrivate(hd, utx.bitcoinAddressRecord.index);
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
            scriptType: BitcoinAddressType.fromAddress(address),
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

    return SilentPaymentWalletUtxoDetails(
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

  Future<SilentPaymentWalletEstimatedTxResult> estimateSendAllTx(
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

    int fee = feeRate * estimatedSize;

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

    return SilentPaymentWalletEstimatedTxResult(
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

  Future<SilentPaymentWalletEstimatedTxResult> estimateTxForAmount(
    int credentialsAmount,
    List<BitcoinOutput> outputs,
    int feeRate, {
    int? inputsToUse,
    String? memo,
    bool? useUnconfirmed,
    bool hasSilentPayment = false,
  }) async {
    final utxoDetails = _createUTXOS(
      sendAll: false,
      credentialsAmount: credentialsAmount,
      inputsCount: inputsToUse,
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
          inputsToUse: utxoDetails.utxos.length + 1,
          memo: memo,
          hasSilentPayment: hasSilentPayment,
        );
      }

      throw BitcoinTransactionWrongBalanceException();
    }

    final changeAddress = await walletAddresses.getChangeAddress();
    final address = BitcoinBaseAddress.fromString(changeAddress, network);
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

    int fee = feeRate * estimatedSize;

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
          inputsToUse: utxoDetails.utxos.length + 1,
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
          inputsToUse: utxoDetails.utxos.length + 1,
          memo: memo,
          useUnconfirmed: useUnconfirmed ?? spendingAllConfirmedCoins,
          hasSilentPayment: hasSilentPayment,
        );
      }
    }

    return SilentPaymentWalletEstimatedTxResult(
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

        final address = BitcoinBaseAddress.fromString(
            out.isParsedAddress ? out.extractedAddress! : out.address, network);

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

      SilentPaymentWalletEstimatedTxResult estimatedTx;
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

  String toJSON() => json.encode({
        'mnemonic': seed,
        'passphrase': passphrase,
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

  @action
  @override
  Future<void> rescan({
    required int height,
    int? chainTip,
    _ScanData? scanData,
    bool? doSingleScan,
    bool? usingElectrs,
  }) async {
    silentPaymentsScanningActive = true;
    _setListeners(height, doSingleScan: doSingleScan, usingElectrs: usingElectrs);
  }

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
              await subscribeForUpdates();
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

  Future<void> _setInitialHeight() async {
    if (_chainTipUpdateSubject != null) return;

    if ((_currentChainTip == null || _currentChainTip! == 0) && walletInfo.restoreHeight == 0) {
      await latestChainTip;
      await walletInfo.updateRestoreHeight(_currentChainTip!);
    }

    _chainTipUpdateSubject = electrumClient.chainTipSubscribe();
    _chainTipUpdateSubject?.listen((e) async {
      final event = e as Map<String, dynamic>;
      final height = int.tryParse(event['height'].toString());

      if (height != null) {
        _currentChainTip = height;

        if (silentPaymentsAlwaysScanning == true && syncStatus is SyncedSyncStatus) {
          _setListeners(walletInfo.restoreHeight);
        }
      }
    });
  }

  @override
  void syncStatusReaction(SyncStatus syncStatus) async {
    if (syncStatus is! AttemptingSyncStatus && syncStatus is! SyncedTipSyncStatus) {
      silentPaymentsScanningActive = syncStatus is SyncingSyncStatus;
    }

    super.syncStatusReaction(syncStatus);

    // Message is shown on the UI for 3 seconds after scan complete to the tip of the blockchain,
    // then revert to synced status
    if (syncStatus is SyncedTipSyncStatus) {
      Timer(Duration(seconds: 3), () {
        if (this.syncStatus is SyncedTipSyncStatus) this.syncStatus = SyncedSyncStatus();
      });
    }
  }
}

class _ScanNode {
  final Uri uri;
  final bool? useSSL;

  _ScanNode(this.uri, this.useSSL);
}

class _ScanData {
  final SendPort sendPort;
  final SilentPaymentOwner silentAddress;
  final int height;
  final _ScanNode? node;
  final BasedUtxoNetwork network;
  final int chainTip;
  final ElectrumClient electrumClient;
  final List<String> transactionHistoryIds;
  final Map<String, String> labels;
  final List<int> labelIndexes;
  final bool isSingleScan;

  _ScanData({
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
}

class _SyncResponse {
  final int height;
  final SyncStatus syncStatus;

  _SyncResponse(this.height, this.syncStatus);
}

const int _TWEAKS_COUNT = 25;

Future<void> _startElectrumScan(_ScanData scanData) async {
  int syncHeight = scanData.height;
  int initialSyncHeight = syncHeight;

  BehaviorSubject<Object>? tweaksSubscription = null;

  final syncingStatus = scanData.isSingleScan
      ? SyncingSyncStatus(1, 0)
      : SyncingSyncStatus.fromHeightValues(scanData.chainTip, initialSyncHeight, syncHeight);

  // Initial status UI update, send how many blocks left to scan
  scanData.sendPort.send(_SyncResponse(syncHeight, syncingStatus));

  final electrumClient = scanData.electrumClient;
  await electrumClient.connectToUri(
    scanData.node?.uri ?? Uri.parse("tcp://electrs.cakewallet.com:50001"),
    useSSL: scanData.node?.useSSL ?? false,
  );

  if (tweaksSubscription == null) {
    final count = scanData.isSingleScan ? 1 : _TWEAKS_COUNT;
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
        _SyncResponse(
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
          scanData.sendPort.send(_SyncResponse(
            syncHeight,
            SyncedTipSyncStatus(scanData.chainTip),
          ));

        if (scanData.isSingleScan) {
          scanData.sendPort.send(_SyncResponse(syncHeight, SyncedSyncStatus()));
        }

        await tweaksSubscription!.close();
        await electrumClient.close();
      }
    });
  }

  if (tweaksSubscription == null) {
    return scanData.sendPort.send(
      _SyncResponse(syncHeight, UnsupportedSyncStatus()),
    );
  }
}
