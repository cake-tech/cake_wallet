import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:collection/collection.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_transaction_history.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/exceptions.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_bitcoin/script_hash.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/file.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:mobx/mobx.dart';
import 'package:rxdart/subjects.dart';

part 'electrum_wallet.g.dart';

class PublicKeyWithDerivationPath {
  const PublicKeyWithDerivationPath(this.publicKey, this.derivationPath);

  final String derivationPath;
  final String publicKey;
}

class UtxoDetails {
  final List<BitcoinUnspent> availableInputs;
  final List<BitcoinUnspent> unconfirmedCoins;
  final List<UtxoWithAddress> utxos;
  final List<ECPrivateInfo> inputPrivKeyInfos;
  final Map<String, PublicKeyWithDerivationPath> publicKeys;
  final int allInputsAmount;
  final bool spendsUnconfirmedTX;
  final bool spendsSilentPayment;

  UtxoDetails({
    required this.availableInputs,
    required this.unconfirmedCoins,
    required this.utxos,
    required this.inputPrivKeyInfos,
    required this.publicKeys,
    required this.allInputsAmount,
    required this.spendsUnconfirmedTX,
    this.spendsSilentPayment = false,
  });
}

class EstimatedTxResult {
  final List<UtxoWithAddress> utxos;
  final List<ECPrivateInfo> inputPrivKeyInfos;
  final Map<String, PublicKeyWithDerivationPath> publicKeys;
  final int fee;
  final int amount;
  final bool hasChange;
  final bool isSendAll;
  final String? memo;
  final bool spendsUnconfirmedTX;
  final bool spendsSilentPayment;

  EstimatedTxResult({
    required this.utxos,
    required this.inputPrivKeyInfos,
    required this.publicKeys,
    required this.fee,
    required this.amount,
    required this.hasChange,
    required this.isSendAll,
    required this.spendsUnconfirmedTX,
    this.memo,
    this.spendsSilentPayment = false,
  });
}

class ElectrumWallet = ElectrumWalletBase with _$ElectrumWallet;

abstract class ElectrumWalletBase
    extends WalletBase<ElectrumBalance, ElectrumTransactionHistory, ElectrumTransactionInfo>
    with Store {
  ElectrumWalletBase({
    required super.walletInfo,
    required String password,
    required this.unspentCoinsInfo,
    required this.network,
    required String mnemonic,
    required this.passphrase,
    required CryptoCurrency currency,
    ElectrumBalance? initialBalance,
  })  : _password = password,
        _mnemonic = mnemonic,
        balance = ObservableMap<CryptoCurrency, ElectrumBalance>.of(
          {currency: initialBalance ?? ElectrumBalance(confirmed: 0, unconfirmed: 0, frozen: 0)},
        ),
        super() {
    isTestnet = !network.isMainnet;
    transactionHistory = ElectrumTransactionHistory(walletInfo: walletInfo, password: password);

    reaction((_) => syncStatus, syncStatusReaction);
  }

  late Bip32Slip10Secp256k1 accountHD;

  final String passphrase;
  final String? _mnemonic;

  @override
  @observable
  bool isEnabledAutoGenerateSubaddress = true;

  ElectrumClient electrumClient = ElectrumClient();
  Box<UnspentCoinsInfo> unspentCoinsInfo;

  @override
  late ElectrumWalletAddresses walletAddresses;

  @override
  @observable
  ObservableMap<CryptoCurrency, ElectrumBalance> balance;

  @override
  @observable
  SyncStatus syncStatus = NotConnectedSyncStatus();

  String get xpub => accountHD.publicKey.toExtended;

  @override
  String? get seed => _mnemonic;

  BasedUtxoNetwork network;

  bool _isTryingToConnect = false;

  @observable
  int? _currentChainTip;

  @computed
  Future<int> get currentChainTip async {
    if (_currentChainTip != null) {
      return _currentChainTip!;
    }
    _currentChainTip = await electrumClient.getCurrentBlockChainTip() ?? 0;

    return _currentChainTip!;
  }

  @computed
  Future<int> get latestChainTip async {
    final newTip = await electrumClient.getCurrentBlockChainTip();
    if (newTip != null && newTip > (_currentChainTip ?? 0)) {
      _currentChainTip = newTip;
    }
    return _currentChainTip ?? 0;
  }

  String _password;
  List<BitcoinUnspent> unspentCoins = [];
  List<int> _feeRates = <int>[];

  // ignore: prefer_final_fields
  Map<String, BehaviorSubject<Object>?> _scripthashesUpdateSubject = {};

  bool _isTransactionUpdating = false;

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
  @override
  Future<void> startSync() async {
    try {
      syncStatus = SyncronizingSyncStatus();

      await subscribeForUpdates();

      await updateTransactions();
      await updateAllUnspents();
      await updateBalance();

      Timer.periodic(const Duration(minutes: 1), (timer) async => await updateFeeRates());

      syncStatus = SyncedSyncStatus();
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

  // TODO: depends on address type
  int get _dustAmount => 546;

  bool _isBelowDust(int amount) =>
      amount <= _dustAmount &&
      // Testnet has no dust limit
      network.isMainnet;

  UtxoDetails _createUTXOS({bool sendAll = false, int credentialsAmount = 0, int? inputsToUse}) {
    List<UtxoWithAddress> utxos = [];
    List<ECPrivateInfo> inputPrivKeyInfos = [];
    final publicKeys = <String, PublicKeyWithDerivationPath>{};
    int allSendingInputsAmount = 0;
    bool spendsUnconfirmedTX = false;

    int amountLeftToSend = credentialsAmount;
    final availableInputs = unspentCoins.where((utx) => utx.isSending && !utx.isFrozen).toList();
    final unconfirmedCoins = availableInputs.where((utx) => utx.confirmations == 0).toList();

    for (int i = 0; i < availableInputs.length; i++) {
      final utx = availableInputs[i];
      if (!spendsUnconfirmedTX) spendsUnconfirmedTX = unconfirmedCoins.contains(utx);

      // The Address class from the stored utxos
      final address = BitcoinBaseAddress.fromString(utx.address, network);

      // The generated privkey based on the wallet's loaded HD derivation path and utxo index
      final hd =
          utx.bitcoinAddressRecord.isHidden ? walletAddresses.sideHd : walletAddresses.mainHd;
      final derivationKey = hd.childKey(Bip32KeyIndex(utx.bitcoinAddressRecord.index));
      final privkey = ECPrivate(derivationKey.privateKey);

      // The public key from the above generated private key
      final pubkey = privkey.getPublic();

      // Compare that the generated public via the HD derivation returns the same address as the stored utxo
      // If not, the derivation path is wrong and a different private key was generated
      if (!pubkey.compareToAddress(address, network)) {
        throw BitcoinKeysWrongDerivation();
      }

      final pubkeyHex = pubkey.toHex();

      final derivationPath = "${walletInfo.derivationInfo!.derivationPath!}"
          "/${hd.index.toInt()}"
          "/${utx.bitcoinAddressRecord.index}";

      publicKeys[address.pubKeyHash()] = PublicKeyWithDerivationPath(pubkeyHex, derivationPath);
      inputPrivKeyInfos.add(ECPrivateInfo(privkey, address.type == SegwitAddresType.p2tr));

      utxos.add(
        UtxoWithAddress(
          utxo: BitcoinUtxo(
            txHash: utx.hash,
            value: BigInt.from(utx.value),
            vout: utx.vout,
            scriptType: BitcoinAddressType.fromAddress(address),
          ),
          ownerDetails: UtxoAddressDetails(publicKey: pubkeyHex, address: address),
        ),
      );

      allSendingInputsAmount += utx.value;

      // sendAll continues for all available inputs
      if (!sendAll) {
        amountLeftToSend -= utx.value;

        bool amountIsAcquired = amountLeftToSend <= 0;
        final sendWithExtraInputs = inputsToUse != null;
        final extraInputsNeededSelected = inputsToUse == i + 1;
        final amountNeededReached = !sendWithExtraInputs && amountIsAcquired;

        if (amountNeededReached || extraInputsNeededSelected) {
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
      inputPrivKeyInfos: inputPrivKeyInfos,
      publicKeys: publicKeys,
      allInputsAmount: allSendingInputsAmount,
      spendsUnconfirmedTX: spendsUnconfirmedTX,
    );
  }

  Future<EstimatedTxResult> estimateSendAllTx(
    List<BitcoinOutput> outputs,
    int feeRate, {
    String? memo,
  }) async {
    final utxoDetails = _createUTXOS(sendAll: true);

    final estimatedSize = BitcoinTransactionBuilder.estimateTransactionSize(
      utxos: utxoDetails.utxos,
      outputs: outputs,
      network: network,
      memo: memo,
      inputPrivKeyInfos: utxoDetails.inputPrivKeyInfos,
    );

    int fee = feeRate * estimatedSize;

    if (fee == 0) {
      throw BitcoinTransactionNoFeeException();
    }

    // Here, when sending all, the output amount equals to the input value - fee to fully spend every input on the transaction and have no amount left for change
    int outputAmount = utxoDetails.allInputsAmount - fee;

    if (outputAmount <= 0) {
      throw BitcoinTransactionWrongBalanceException(amount: utxoDetails.allInputsAmount + fee);
    }

    // Attempting to send less than the dust limit
    if (_isBelowDust(outputAmount)) {
      throw BitcoinTransactionNoDustException();
    }

    if (outputs.length == 1) {
      outputs[0] = BitcoinOutput(address: outputs.last.address, value: BigInt.from(outputAmount));
    }

    return EstimatedTxResult(
      utxos: utxoDetails.utxos,
      inputPrivKeyInfos: utxoDetails.inputPrivKeyInfos,
      publicKeys: utxoDetails.publicKeys,
      fee: fee,
      amount: outputAmount,
      isSendAll: true,
      hasChange: false,
      memo: memo,
      spendsUnconfirmedTX: utxoDetails.spendsUnconfirmedTX,
    );
  }

  Future<EstimatedTxResult> estimateTxForAmount(
    int credentialsAmount,
    List<BitcoinOutput> outputs,
    int feeRate, {
    int? inputsToUse,
    String? memo,
    bool? useUnconfirmed,
  }) async {
    final utxoDetails = _createUTXOS(
      credentialsAmount: credentialsAmount,
      inputsToUse: inputsToUse,
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
        );
      } else {
        throw BitcoinTransactionWrongBalanceException();
      }
    }

    final changeAddress = BitcoinBaseAddress.fromString(
      await walletAddresses.getChangeAddress(),
      network,
    );
    outputs.add(BitcoinOutput(
      address: changeAddress,
      value: BigInt.from(amountLeftForChangeAndFee),
    ));

    final estimatedSize = BitcoinTransactionBuilder.estimateTransactionSize(
      utxos: utxoDetails.utxos,
      outputs: outputs,
      network: network,
      memo: memo,
      inputPrivKeyInfos: utxoDetails.inputPrivKeyInfos,
    );

    int fee = feeRate * estimatedSize;

    if (fee == 0) {
      throw BitcoinTransactionNoFeeException();
    }

    int amount = credentialsAmount;
    final changeOutput = outputs.last;
    final amountLeftForChange = amountLeftForChangeAndFee - fee;
    final canHaveChange = !_isBelowDust(amountLeftForChange);

    if (canHaveChange) {
      // Here, lastOutput already is change, return the amount left without the fee to the user's address.
      outputs.last = BitcoinOutput(
        address: changeOutput.address,
        value: BigInt.from(amountLeftForChange),
      );
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

      final estimatedSendAll = await estimateSendAllTx(outputs, feeRate, memo: memo);

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
        estimatedTx = await estimateSendAllTx(outputs, feeRateInt, memo: memo);
      } else {
        estimatedTx = await estimateTxForAmount(
          credentialsAmount,
          outputs,
          feeRateInt,
          memo: memo,
        );
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
          return key.privkey.signTapRoot(txDigest, sighash: sighash);
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
          await updateBalance();
        });
    } catch (e) {
      throw e;
    }
  }

  String toJSON() => json.encode({
        'mnemonic': _mnemonic,
        'passphrase': passphrase,
        'account_index': walletAddresses.currentReceiveAddressIndexByType,
        'change_address_index': walletAddresses.currentChangeAddressIndexByType,
        'addresses': walletAddresses.allAddresses.map((addr) => addr.toJSON()).toList(),
        'address_page_type': walletInfo.addressPageType == null
            ? SegwitAddresType.p2wpkh.toString()
            : walletInfo.addressPageType.toString(),
        'balance': balance[currency]?.toJSON(),
        'derivationTypeIndex': walletInfo.derivationInfo!.derivationType!.index,
        'derivationPath': walletInfo.derivationInfo!.derivationPath!,
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

  @override
  Future<void> save() async {
    final path = await pathForWallet(name: walletInfo.name, type: walletInfo.type);
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
  Future<void> close() async {
    try {
      await electrumClient.close();
    } catch (_) {}
    _autoSaveTimer?.cancel();
  }

  @action
  Future<void> updateAllUnspents() async {
    List<BitcoinUnspent> updatedUnspentCoins = [];

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

  Future<ElectrumTransactionBundle> getTransactionExpanded({required String hash}) async {
    String transactionHex;
    int? time;
    int confirmations = 0;
    if (isTestnet) {
      // Testnet public electrum server does not support verbose transaction fetching
      transactionHex = await electrumClient.getTransactionHex(hash: hash);

      final status = json.decode(
          (await http.get(Uri.parse("https://blockstream.info/testnet/api/tx/$hash/status"))).body);

      time = status["block_time"] as int?;
      final height = status["block_height"] as int? ?? 0;
      final tip = await latestChainTip;
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
        await getTransactionExpanded(hash: hash),
        walletInfo.type,
        network,
        addresses: walletAddresses.addressesSet,
        height: height,
      );
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
      final history = await _fetchAddressHistory(addressRecord, await currentChainTip);

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
              return _fetchAddressHistory(address, await currentChainTip)
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

      await currentChainTip;

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

  Future<void> subscribeForUpdates() async {
    final unsubscribedScriptHashes = Map.of(walletAddresses.scriptHashesMap);
    unsubscribedScriptHashes.removeWhere(
      (sh, _) => _scripthashesUpdateSubject.containsKey(sh),
    );

    await Future.wait(unsubscribedScriptHashes.entries.map((entry) async {
      final sh = entry.key;
      final address = entry.value;

      _scripthashesUpdateSubject[sh] = await electrumClient.scripthashUpdate(sh);
      _scripthashesUpdateSubject[sh]?.listen((event) async {
        try {
          await updateUnspents(address);

          await updateBalance();

          await _fetchAddressHistory(address, await currentChainTip);
        } catch (e, s) {
          print(e.toString());
          onError?.call(FlutterErrorDetails(
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
      confirmed: totalConfirmed,
      unconfirmed: totalUnconfirmed,
      frozen: totalFrozen,
    );
  }

  Future<void> updateBalance() async {
    balance[currency] = await _fetchBalances();
    await save();
  }

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

  void syncStatusReaction(SyncStatus syncStatus) async {
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
  }
}

String hardenedDerivationPath(String derivationPath) =>
    derivationPath.substring(0, derivationPath.lastIndexOf("'") + 1);
