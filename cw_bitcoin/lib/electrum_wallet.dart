import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:collection/collection.dart';
import 'package:cw_bitcoin/address_from_output.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/bitcoin_wallet_keys.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_transaction_history.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/exceptions.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart' as ledger;
import 'package:mobx/mobx.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart' as http;

part 'electrum_wallet.g.dart';

class ElectrumWallet = ElectrumWalletBase with _$ElectrumWallet;

abstract class ElectrumWalletBase
    extends WalletBase<ElectrumBalance, ElectrumTransactionHistory, ElectrumTransactionInfo>
    with Store, WalletKeysFile {
  ElectrumWalletBase({
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required this.network,
    required this.encryptionFileUtils,
    String? xpub,
    String? mnemonic,
    List<int>? seedBytes,
    this.passphrase,
    List<BitcoinAddressRecord>? initialAddresses,
    ElectrumClient? electrumClient,
    ElectrumBalance? initialBalance,
    CryptoCurrency? currency,
    this.alwaysScan,
    required this.mempoolAPIEnabled,
  })  : bip32 = getAccountHDWallet(currency, network, seedBytes, xpub, walletInfo.derivationInfo),
        syncStatus = NotConnectedSyncStatus(),
        _password = password,
        _isTransactionUpdating = false,
        isEnabledAutoGenerateSubaddress = true,
        unspentCoins = {},
        scripthashesListening = {},
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
        this.isTestnet = !network.isMainnet,
        this._mnemonic = mnemonic,
        super(walletInfo) {
    this.electrumClient = electrumClient ?? ElectrumClient();
    this.walletInfo = walletInfo;
    transactionHistory = ElectrumTransactionHistory(
      walletInfo: walletInfo,
      password: password,
      encryptionFileUtils: encryptionFileUtils,
    );

    reaction((_) => syncStatus, syncStatusReaction);

    sharedPrefs.complete(SharedPreferences.getInstance());
  }

  static Bip32Slip10Secp256k1 getAccountHDWallet(CryptoCurrency? currency, BasedUtxoNetwork network,
      List<int>? seedBytes, String? xpub, DerivationInfo? derivationInfo) {
    if (seedBytes == null && xpub == null) {
      throw Exception(
          "To create a Wallet you need either a seed or an xpub. This should not happen");
    }

    if (seedBytes != null) {
      switch (currency) {
        case CryptoCurrency.btc:
        case CryptoCurrency.ltc:
        case CryptoCurrency.tbtc:
          return Bip32Slip10Secp256k1.fromSeed(seedBytes);
        case CryptoCurrency.bch:
          return bitcoinCashHDWallet(seedBytes);
        default:
          throw Exception("Unsupported currency");
      }
    }

    return Bip32Slip10Secp256k1.fromExtendedKey(xpub!, getKeyNetVersion(network));
  }

  static Bip32Slip10Secp256k1 bitcoinCashHDWallet(List<int> seedBytes) =>
      Bip32Slip10Secp256k1.fromSeed(seedBytes).derivePath("m/44'/145'/0'") as Bip32Slip10Secp256k1;

  int estimatedTransactionSize(int inputsCount, int outputsCounts) =>
      inputsCount * 68 + outputsCounts * 34 + 10;

  static Bip32KeyNetVersions? getKeyNetVersion(BasedUtxoNetwork network) {
    switch (network) {
      case LitecoinNetwork.mainnet:
        return Bip44Conf.litecoinMainNet.altKeyNetVer;
      default:
        return null;
    }
  }

  bool? alwaysScan;
  bool mempoolAPIEnabled;

  final Bip32Slip10Secp256k1 bip32;
  final String? _mnemonic;

  final EncryptionFileUtils encryptionFileUtils;

  @override
  final String? passphrase;

  @override
  @observable
  bool isEnabledAutoGenerateSubaddress;

  late ElectrumClient electrumClient;
  ElectrumApiProvider? electrumClient2;
  BitcoinBaseElectrumRPCService? get rpc => electrumClient2?.rpc;
  ApiProvider? apiProvider;
  Box<UnspentCoinsInfo> unspentCoinsInfo;

  @override
  late ElectrumWalletAddresses walletAddresses;

  @override
  @observable
  late ObservableMap<CryptoCurrency, ElectrumBalance> balance;

  @override
  @observable
  SyncStatus syncStatus;

  Set<String> get addressesSet => walletAddresses.allAddresses
      .where((element) => element.type != SegwitAddresType.mweb)
      .map((addr) => addr.address)
      .toSet();

  List<String> get scriptHashes => walletAddresses.addressesByReceiveType
      .where((addr) => RegexUtils.addressTypeFromStr(addr.address, network) is! MwebAddress)
      .map((addr) => (addr as BitcoinAddressRecord).scriptHash)
      .toList();

  List<String> get publicScriptHashes => walletAddresses.allAddresses
      .where((addr) => !addr.isChange)
      .where((addr) => RegexUtils.addressTypeFromStr(addr.address, network) is! MwebAddress)
      .map((addr) => addr.scriptHash)
      .toList();

  String get xpub => bip32.publicKey.toExtended;

  @override
  String? get seed => _mnemonic;

  @override
  WalletKeysData get walletKeysData =>
      WalletKeysData(mnemonic: _mnemonic, xPub: xpub, passphrase: passphrase);

  @override
  String get password => _password;

  BasedUtxoNetwork network;

  @override
  bool isTestnet;

  @observable
  bool nodeSupportsSilentPayments = true;
  @observable
  bool silentPaymentsScanningActive = false;

  bool _isTryingToConnect = false;

  Completer<SharedPreferences> sharedPrefs = Completer();

  @observable
  int? currentChainTip;

  @override
  BitcoinWalletKeys get keys => BitcoinWalletKeys(
        wif: WifEncoder.encode(bip32.privateKey.raw, netVer: network.wifNetVer),
        privateKey: bip32.privateKey.toHex(),
        publicKey: bip32.publicKey.toHex(),
      );

  String _password;
  @observable
  Set<BitcoinUnspent> unspentCoins;

  @observable
  TransactionPriorities? feeRates;
  int feeRate(TransactionPriority priority) => feeRates![priority];

  @observable
  Set<String> scripthashesListening;

  bool _chainTipListenerOn = false;
  bool _isTransactionUpdating;

  void Function(FlutterErrorDetails)? _onError;
  Timer? _autoSaveTimer;
  StreamSubscription<dynamic>? _receiveStream;
  Timer? _updateFeeRateTimer;
  static const int _autoSaveInterval = 1;

  Future<void> init() async {
    await walletAddresses.init();
    await transactionHistory.init();

    _autoSaveTimer =
        Timer.periodic(Duration(minutes: _autoSaveInterval), (_) async => await save());
  }

  @action
  @override
  Future<void> startSync() async {
    try {
      if (syncStatus is SynchronizingSyncStatus) {
        return;
      }

      syncStatus = SynchronizingSyncStatus();

      await subscribeForHeaders();
      await subscribeForUpdates();

      // await updateTransactions();
      // await updateAllUnspents();
      await updateBalance();
      await updateFeeRates();

      _updateFeeRateTimer ??=
          Timer.periodic(const Duration(seconds: 5), (timer) async => await updateFeeRates());

      syncStatus = SyncedSyncStatus();

      await save();
    } catch (e, stacktrace) {
      print(stacktrace);
      print("startSync $e");
      syncStatus = FailedSyncStatus();
    }
  }

  @action
  Future<void> registerSilentPaymentsKey() async {
    final registered = await electrumClient.tweaksRegister(
      secViewKey: walletAddresses.silentAddress!.b_scan.toHex(),
      pubSpendKey: walletAddresses.silentAddress!.B_spend.toHex(),
      labels: walletAddresses.silentAddresses
          .where((addr) => addr.type == SilentPaymentsAddresType.p2sp && addr.labelIndex >= 1)
          .map((addr) => addr.labelIndex)
          .toList(),
    );

    print("registered: $registered");
  }

  @action
  void callError(FlutterErrorDetails error) {
    _onError?.call(error);
  }

  @action
  Future<void> updateFeeRates() async {
    try {
      feeRates = BitcoinElectrumTransactionPriorities.fromList(
        await electrumClient2!.getFeeRates(),
      );
    } catch (e, stacktrace) {
      // _onError?.call(FlutterErrorDetails(
      //   exception: e,
      //   stack: stacktrace,
      //   library: this.runtimeType.toString(),
      // ));
    }
  }

  Node? node;

  Future<bool> getNodeIsElectrs() async {
    return true;
    if (node == null) {
      return false;
    }

    final version = await electrumClient.version();

    if (version.isNotEmpty) {
      final server = version[0];

      if (server.toLowerCase().contains('electrs')) {
        node!.isElectrs = true;
        node!.save();
        return node!.isElectrs!;
      }
    }

    node!.isElectrs = false;
    node!.save();
    return node!.isElectrs!;
  }

  Future<bool> getNodeSupportsSilentPayments() async {
    return true;
    // As of today (august 2024), only ElectrumRS supports silent payments
    if (!(await getNodeIsElectrs())) {
      return false;
    }

    if (node == null) {
      return false;
    }

    try {
      final tweaksResponse = await electrumClient.getTweaks(height: 0);

      if (tweaksResponse != null) {
        node!.supportsSilentPayments = true;
        node!.save();
        return node!.supportsSilentPayments!;
      }
    } on RequestFailedTimeoutException catch (_) {
      node!.supportsSilentPayments = false;
      node!.save();
      return node!.supportsSilentPayments!;
    } catch (_) {}

    node!.supportsSilentPayments = false;
    node!.save();
    return node!.supportsSilentPayments!;
  }

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    scripthashesListening = {};
    _isTransactionUpdating = false;
    _chainTipListenerOn = false;
    this.node = node;

    try {
      syncStatus = ConnectingSyncStatus();

      await _receiveStream?.cancel();
      rpc?.disconnect();

      // electrumClient.onConnectionStatusChange = _onConnectionStatusChange;

      this.electrumClient2 = ElectrumApiProvider(
        await ElectrumTCPService.connect(
          node.uri,
          onConnectionStatusChange: _onConnectionStatusChange,
          defaultRequestTimeOut: const Duration(seconds: 5),
          connectionTimeOut: const Duration(seconds: 5),
        ),
      );
      // await electrumClient.connectToUri(node.uri, useSSL: node.useSSL);
    } catch (e, stacktrace) {
      print(stacktrace);
      print("connectToNode $e");
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
    UnspentCoinType coinTypeToSpendFrom = UnspentCoinType.any,
  }) {
    List<UtxoWithAddress> utxos = [];
    List<Outpoint> vinOutpoints = [];
    List<ECPrivateInfo> inputPrivKeyInfos = [];
    final publicKeys = <String, PublicKeyWithDerivationPath>{};
    int allInputsAmount = 0;
    bool spendsSilentPayment = false;
    bool spendsUnconfirmedTX = false;

    int leftAmount = credentialsAmount;
    final availableInputs = unspentCoins.where((utx) {
      if (!utx.isSending || utx.isFrozen) {
        return false;
      }

      switch (coinTypeToSpendFrom) {
        case UnspentCoinType.mweb:
          return utx.bitcoinAddressRecord.type == SegwitAddresType.mweb;
        case UnspentCoinType.nonMweb:
          return utx.bitcoinAddressRecord.type != SegwitAddresType.mweb;
        case UnspentCoinType.any:
          return true;
      }
    }).toList();
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

      final address = RegexUtils.addressTypeFromStr(utx.address, network);
      ECPrivate? privkey;
      bool? isSilentPayment = false;

      if (utx.bitcoinAddressRecord is BitcoinReceivedSPAddressRecord) {
        privkey = (utx.bitcoinAddressRecord as BitcoinReceivedSPAddressRecord).spendKey;
        spendsSilentPayment = true;
        isSilentPayment = true;
      } else if (!isHardwareWallet) {
        privkey = ECPrivate.fromBip32(
          bip32: walletAddresses.bip32,
          account: BitcoinAddressUtils.getAccountFromChange(utx.bitcoinAddressRecord.isChange),
          index: utx.bitcoinAddressRecord.index,
        );
      }

      vinOutpoints.add(Outpoint(txid: utx.hash, index: utx.vout));
      String pubKeyHex;

      if (privkey != null) {
        inputPrivKeyInfos.add(ECPrivateInfo(
          privkey,
          address.type == SegwitAddresType.p2tr,
          tweak: !isSilentPayment,
        ));

        pubKeyHex = privkey.getPublic().toHex();
      } else {
        pubKeyHex = walletAddresses.bip32
            .childKey(Bip32KeyIndex(utx.bitcoinAddressRecord.index))
            .publicKey
            .toHex();
      }

      // TODO: isElectrum
      final derivationPath = BitcoinAddressUtils.getDerivationPath(
        type: utx.bitcoinAddressRecord.type,
        account: utx.bitcoinAddressRecord.isChange ? 1 : 0,
        index: utx.bitcoinAddressRecord.index,
      );
      publicKeys[address.pubKeyHash()] = PublicKeyWithDerivationPath(pubKeyHex, derivationPath);

      utxos.add(
        UtxoWithAddress(
          utxo: BitcoinUtxo(
            txHash: utx.hash,
            value: BigInt.from(utx.value),
            vout: utx.vout,
            scriptType: BitcoinAddressUtils.getScriptType(address),
            isSilentPayment: isSilentPayment,
          ),
          ownerDetails: UtxoAddressDetails(
            publicKey: pubKeyHex,
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
    UnspentCoinType coinTypeToSpendFrom = UnspentCoinType.any,
  }) async {
    final utxoDetails = _createUTXOS(
      sendAll: true,
      credentialsAmount: credentialsAmount,
      paysToSilentPayment: hasSilentPayment,
      coinTypeToSpendFrom: coinTypeToSpendFrom,
    );

    int fee = await calcFee(
      utxos: utxoDetails.utxos,
      outputs: outputs,
      memo: memo,
      feeRate: feeRate,
    );

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
    List<BitcoinOutput> updatedOutputs,
    int feeRate, {
    int? inputsCount,
    String? memo,
    bool? useUnconfirmed,
    bool hasSilentPayment = false,
    UnspentCoinType coinTypeToSpendFrom = UnspentCoinType.any,
  }) async {
    final utxoDetails = _createUTXOS(
      sendAll: false,
      credentialsAmount: credentialsAmount,
      inputsCount: inputsCount,
      paysToSilentPayment: hasSilentPayment,
      coinTypeToSpendFrom: coinTypeToSpendFrom,
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
          updatedOutputs,
          feeRate,
          inputsCount: utxoDetails.utxos.length + 1,
          memo: memo,
          hasSilentPayment: hasSilentPayment,
          coinTypeToSpendFrom: coinTypeToSpendFrom,
        );
      }

      throw BitcoinTransactionWrongBalanceException();
    }

    final changeAddress = await walletAddresses.getChangeAddress(
      inputs: utxoDetails.availableInputs,
      outputs: updatedOutputs,
    );
    final address = RegexUtils.addressTypeFromStr(changeAddress.address, network);
    updatedOutputs.add(BitcoinOutput(
      address: address,
      value: BigInt.from(amountLeftForChangeAndFee),
      isChange: true,
    ));
    outputs.add(BitcoinOutput(
      address: address,
      value: BigInt.from(amountLeftForChangeAndFee),
      isChange: true,
    ));

    final changeDerivationPath = BitcoinAddressUtils.getDerivationPath(
      type: changeAddress.type,
      account: changeAddress.isChange ? 1 : 0,
      index: changeAddress.index,
    );
    utxoDetails.publicKeys[address.pubKeyHash()] =
        PublicKeyWithDerivationPath('', changeDerivationPath);

    // calcFee updates the silent payment outputs to calculate the tx size accounting
    // for taproot addresses, but if more inputs are needed to make up for fees,
    // the silent payment outputs need to be recalculated for the new inputs
    var temp = outputs.map((output) => output).toList();
    int fee = await calcFee(
      utxos: utxoDetails.utxos,
      // Always take only not updated bitcoin outputs here so for every estimation
      // the SP outputs are re-generated to the proper taproot addresses
      outputs: temp,
      memo: memo,
      feeRate: feeRate,
    );

    updatedOutputs.clear();
    updatedOutputs.addAll(temp);

    if (fee == 0) {
      throw BitcoinTransactionNoFeeException();
    }

    int amount = credentialsAmount;
    final lastOutput = updatedOutputs.last;
    final amountLeftForChange = amountLeftForChangeAndFee - fee;

    if (!_isBelowDust(amountLeftForChange)) {
      // Here, lastOutput already is change, return the amount left without the fee to the user's address.
      updatedOutputs[updatedOutputs.length - 1] = BitcoinOutput(
        address: lastOutput.address,
        value: BigInt.from(amountLeftForChange),
        isSilentPayment: lastOutput.isSilentPayment,
        isChange: true,
      );
      outputs[outputs.length - 1] = BitcoinOutput(
        address: lastOutput.address,
        value: BigInt.from(amountLeftForChange),
        isSilentPayment: lastOutput.isSilentPayment,
        isChange: true,
      );
    } else {
      // If has change that is lower than dust, will end up with tx rejected by network rules, so estimate again without the added change
      updatedOutputs.removeLast();
      outputs.removeLast();

      // Still has inputs to spend before failing
      if (!spendingAllCoins) {
        return estimateTxForAmount(
          credentialsAmount,
          outputs,
          updatedOutputs,
          feeRate,
          inputsCount: utxoDetails.utxos.length + 1,
          memo: memo,
          hasSilentPayment: hasSilentPayment,
          useUnconfirmed: useUnconfirmed ?? spendingAllConfirmedCoins,
          coinTypeToSpendFrom: coinTypeToSpendFrom,
        );
      }

      final estimatedSendAll = await estimateSendAllTx(
        updatedOutputs,
        feeRate,
        memo: memo,
        coinTypeToSpendFrom: coinTypeToSpendFrom,
      );

      if (estimatedSendAll.amount == credentialsAmount) {
        return estimatedSendAll;
      }

      // Estimate to user how much is needed to send to cover the fee
      final maxAmountWithReturningChange = utxoDetails.allInputsAmount - _dustAmount - fee - 1;
      throw BitcoinTransactionNoDustOnChangeException(
        BitcoinAmountUtils.bitcoinAmountToString(amount: maxAmountWithReturningChange),
        BitcoinAmountUtils.bitcoinAmountToString(amount: estimatedSendAll.amount),
      );
    }

    // Attempting to send less than the dust limit
    if (_isBelowDust(amount)) {
      throw BitcoinTransactionNoDustException();
    }

    final totalAmount = amount + fee;

    if (totalAmount > (balance[currency]!.confirmed + balance[currency]!.secondConfirmed)) {
      throw BitcoinTransactionWrongBalanceException();
    }

    if (totalAmount > utxoDetails.allInputsAmount) {
      if (spendingAllCoins) {
        throw BitcoinTransactionWrongBalanceException();
      } else {
        updatedOutputs.removeLast();
        outputs.removeLast();
        return estimateTxForAmount(
          credentialsAmount,
          outputs,
          updatedOutputs,
          feeRate,
          inputsCount: utxoDetails.utxos.length + 1,
          memo: memo,
          useUnconfirmed: useUnconfirmed ?? spendingAllConfirmedCoins,
          hasSilentPayment: hasSilentPayment,
          coinTypeToSpendFrom: coinTypeToSpendFrom,
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

  Future<int> calcFee({
    required List<UtxoWithAddress> utxos,
    required List<BitcoinBaseOutput> outputs,
    String? memo,
    required int feeRate,
  }) async =>
      feeRate *
      BitcoinTransactionBuilder.estimateTransactionSize(
        utxos: utxos,
        outputs: outputs,
        network: network,
        memo: memo,
      );

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    try {
      final outputs = <BitcoinOutput>[];
      final transactionCredentials = credentials as BitcoinTransactionCredentials;
      final hasMultiDestination = transactionCredentials.outputs.length > 1;
      final sendAll = !hasMultiDestination && transactionCredentials.outputs.first.sendAll;
      final memo = transactionCredentials.outputs.first.memo;
      final coinTypeToSpendFrom = transactionCredentials.coinTypeToSpendFrom;

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

        final address = RegexUtils.addressTypeFromStr(
            out.isParsedAddress ? out.extractedAddress! : out.address, network);
        final isSilentPayment = address is SilentPaymentAddress;

        if (isSilentPayment) {
          hasSilentPayment = true;
        }

        if (sendAll) {
          // The value will be changed after estimating the Tx size and deducting the fee from the total to be sent
          outputs.add(BitcoinOutput(
            address: address,
            value: BigInt.from(0),
            isSilentPayment: isSilentPayment,
          ));
        } else {
          outputs.add(BitcoinOutput(
            address: address,
            value: BigInt.from(outputAmount),
            isSilentPayment: isSilentPayment,
          ));
        }
      }

      final feeRateInt = transactionCredentials.feeRate != null
          ? transactionCredentials.feeRate!
          : feeRate(transactionCredentials.priority!);

      EstimatedTxResult estimatedTx;
      final updatedOutputs =
          outputs.map((e) => BitcoinOutput(address: e.address, value: e.value)).toList();

      if (sendAll) {
        estimatedTx = await estimateSendAllTx(
          updatedOutputs,
          feeRateInt,
          memo: memo,
          credentialsAmount: credentialsAmount,
          hasSilentPayment: hasSilentPayment,
          coinTypeToSpendFrom: coinTypeToSpendFrom,
        );
      } else {
        estimatedTx = await estimateTxForAmount(
          credentialsAmount,
          outputs,
          updatedOutputs,
          feeRateInt,
          memo: memo,
          hasSilentPayment: hasSilentPayment,
          coinTypeToSpendFrom: coinTypeToSpendFrom,
        );
      }

      if (walletInfo.isHardwareWallet) {
        final transaction = await buildHardwareWalletTransaction(
          utxos: estimatedTx.utxos,
          outputs: updatedOutputs,
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
          outputs: updatedOutputs,
          fee: BigInt.from(estimatedTx.fee),
          network: network,
          memo: estimatedTx.memo,
          outputOrdering: BitcoinOrdering.none,
          enableRBF: !estimatedTx.spendsUnconfirmedTX,
        );
      } else {
        txb = BitcoinTransactionBuilder(
          utxos: estimatedTx.utxos,
          outputs: updatedOutputs,
          fee: BigInt.from(estimatedTx.fee),
          network: network,
          memo: estimatedTx.memo,
          outputOrdering: BitcoinOrdering.none,
          enableRBF: !estimatedTx.spendsUnconfirmedTX,
        );
      }

      bool hasTaprootInputs = false;

      final transaction = txb.buildTransaction((txDigest, utxo, publicKey, sighash) {
        String error = "Cannot find private key.";

        ECPrivateInfo? key;

        if (estimatedTx.inputPrivKeyInfos.isEmpty) {
          error += "\nNo private keys generated.";
        } else {
          error += "\nAddress: ${utxo.ownerDetails.address.toAddress(network)}";

          key = estimatedTx.inputPrivKeyInfos.firstWhereOrNull((element) {
            final elemPubkey = element.privkey.getPublic().toHex();
            if (elemPubkey == publicKey) {
              return true;
            } else {
              error += "\nExpected: $publicKey";
              error += "\nPubkey: $elemPubkey";
              return false;
            }
          });
        }

        if (key == null) {
          throw Exception(error);
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
        utxos: estimatedTx.utxos,
      )..addListener((transaction) async {
          transactionHistory.addOne(transaction);
          if (estimatedTx.spendsSilentPayment) {
            transactionHistory.transactions.values.forEach((tx) {
              tx.unspents?.removeWhere(
                  (unspent) => estimatedTx.utxos.any((e) => e.utxo.txHash == unspent.hash));
              transactionHistory.addOne(tx);
            });
          }

          unspentCoins
              .removeWhere((utxo) => estimatedTx.utxos.any((e) => e.utxo.txHash == utxo.hash));

          await updateBalance();
        });
    } catch (e) {
      throw e;
    }
  }

  void setLedgerConnection(ledger.LedgerConnection connection) => throw UnimplementedError();

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
        'mweb_addresses': walletAddresses.mwebAddresses.map((addr) => addr.toJSON()).toList(),
        'alwaysScan': alwaysScan,
      });

  int feeAmountForPriority(TransactionPriority priority, int inputsCount, int outputsCount,
          {int? size}) =>
      feeRate(priority) * (size ?? estimatedTransactionSize(inputsCount, outputsCount));

  int feeAmountWithFeeRate(int feeRate, int inputsCount, int outputsCount, {int? size}) =>
      feeRate * (size ?? estimatedTransactionSize(inputsCount, outputsCount));

  @override
  int calculateEstimatedFee(TransactionPriority? priority, int? amount,
      {int? outputsCount, int? size}) {
    if (priority is BitcoinMempoolAPITransactionPriority) {
      return calculateEstimatedFeeWithFeeRate(
        feeRate(priority),
        amount,
        outputsCount: outputsCount,
        size: size,
      );
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
    if (!(await WalletKeysFile.hasKeysFile(walletInfo.name, walletInfo.type))) {
      await saveKeysFile(_password, encryptionFileUtils);
      await saveKeysFile(_password, encryptionFileUtils, true);
    }

    final path = await makePath();
    await encryptionFileUtils.write(path: path, password: _password, data: toJSON());
    // await transactionHistory.save();
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
  Future<void> rescan({required int height}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> close({required bool shouldCleanup}) async {
    try {
      await _receiveStream?.cancel();
      await electrumClient.close();
    } catch (_) {}
    _autoSaveTimer?.cancel();
    _updateFeeRateTimer?.cancel();
  }

  @action
  Future<void> updateAllUnspents() async {
    List<BitcoinUnspent> updatedUnspentCoins = [];

    // Set the balance of all non-silent payment and non-mweb addresses to 0 before updating
    walletAddresses.allAddresses
        .where((element) => element.type != SegwitAddresType.mweb)
        .forEach((addr) {
      if (addr is! BitcoinSilentPaymentAddressRecord) addr.balance = 0;
    });

    await Future.wait(walletAddresses.allAddresses
        .where((element) => element.type != SegwitAddresType.mweb)
        .map((address) async {
      updatedUnspentCoins.addAll(await fetchUnspent(address));
    }));

    unspentCoins = updatedUnspentCoins.toSet();

    if (unspentCoinsInfo.length != updatedUnspentCoins.length) {
      unspentCoins.forEach((coin) => addCoinInfo(coin));
      return;
    }

    await updateCoins(unspentCoins);
    // await refreshUnspentCoinsInfo();
  }

  @action
  void updateCoin(BitcoinUnspent coin) {
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
    } else {
      addCoinInfo(coin);
    }
  }

  @action
  Future<void> updateCoins(Set<BitcoinUnspent> newUnspentCoins) async {
    if (newUnspentCoins.isEmpty) {
      return;
    }
    newUnspentCoins.forEach(updateCoin);
  }

  @action
  Future<void> updateUnspentsForAddress(BitcoinAddressRecord addressRecord) async {
    final newUnspentCoins = (await fetchUnspent(addressRecord)).toSet();
    await updateCoins(newUnspentCoins);

    print([1, unspentCoins.containsAll(newUnspentCoins)]);
    if (!unspentCoins.containsAll(newUnspentCoins)) {
      newUnspentCoins.forEach((coin) {
        print(unspentCoins.contains(coin));
        print([coin.vout, coin.hash]);
        print([unspentCoins.first.vout, unspentCoins.first.hash]);
        if (!unspentCoins.contains(coin)) {
          unspentCoins.add(coin);
        }
      });
    }

    // if (unspentCoinsInfo.length != unspentCoins.length) {
    //   unspentCoins.forEach(addCoinInfo);
    // }

    // await refreshUnspentCoinsInfo();
  }

  @action
  Future<List<BitcoinUnspent>> fetchUnspent(BitcoinAddressRecord address) async {
    List<BitcoinUnspent> updatedUnspentCoins = [];

    final unspents = await electrumClient2!.request(
      ElectrumScriptHashListUnspent(scriptHash: address.scriptHash),
    );

    await Future.wait(unspents.map((unspent) async {
      try {
        final coin = BitcoinUnspent.fromUTXO(address, unspent);
        final tx = await fetchTransactionInfo(hash: coin.hash);
        coin.isChange = address.isChange;
        coin.confirmations = tx?.confirmations;

        updatedUnspentCoins.add(coin);
      } catch (_) {}
    }));

    return updatedUnspentCoins;
  }

  @action
  Future<void> addCoinInfo(BitcoinUnspent coin) async {
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
      isSilentPayment: coin.bitcoinAddressRecord is BitcoinReceivedSPAddressRecord,
    );

    await unspentCoinsInfo.add(newInfo);
  }

  Future<void> refreshUnspentCoinsInfo() async {
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
      print("refreshUnspentCoinsInfo $e");
    }
  }

  Future<String?> canReplaceByFee(ElectrumTransactionInfo tx) async {
    try {
      final bundle = await getTransactionExpanded(hash: tx.txHash);
      _updateInputsAndOutputs(tx, bundle);
      if (bundle.confirmations > 0) return null;
      return bundle.originalTransaction.canReplaceByFee ? bundle.originalTransaction.toHex() : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isChangeSufficientForFee(String txId, int newFee) async {
    final bundle = await getTransactionExpanded(hash: txId);
    final outputs = bundle.originalTransaction.outputs;

    final changeAddresses = walletAddresses.allAddresses.where((element) => element.isChange);

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
      String? memo;

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

        final btcAddress = RegexUtils.addressTypeFromStr(addressRecord.address, network);
        final privkey = ECPrivate.fromBip32(
          bip32: walletAddresses.bip32,
          account: addressRecord.isChange ? 1 : 0,
          index: addressRecord.index,
        );

        privateKeys.add(privkey);

        utxos.add(
          UtxoWithAddress(
            utxo: BitcoinUtxo(
              txHash: input.txId,
              value: outTransaction.amount,
              vout: vout,
              scriptType: BitcoinAddressUtils.getScriptType(btcAddress),
            ),
            ownerDetails:
                UtxoAddressDetails(publicKey: privkey.getPublic().toHex(), address: btcAddress),
          ),
        );
      }

      // Create a list of available outputs
      final outputs = <BitcoinOutput>[];
      for (final out in bundle.originalTransaction.outputs) {
        // Check if the script contains OP_RETURN
        final script = out.scriptPubKey.script;
        if (script.contains('OP_RETURN') && memo == null) {
          final index = script.indexOf('OP_RETURN');
          if (index + 1 <= script.length) {
            try {
              final opReturnData = script[index + 1].toString();
              memo = utf8.decode(HEX.decode(opReturnData));
              continue;
            } catch (_) {
              throw Exception('Cannot decode OP_RETURN data');
            }
          }
        }

        final address = addressFromOutputScript(out.scriptPubKey, network);
        final btcAddress = RegexUtils.addressTypeFromStr(address, network);
        outputs.add(BitcoinOutput(address: btcAddress, value: BigInt.from(out.amount.toInt())));
      }

      // Calculate the total amount and fees
      int totalOutAmount =
          outputs.fold<int>(0, (previousValue, output) => previousValue + output.value.toInt());
      int currentFee = allInputsAmount - totalOutAmount;
      int remainingFee = newFee - currentFee;

      if (remainingFee <= 0) {
        throw Exception("New fee must be higher than the current fee.");
      }

      // Deduct Remaining Fee from Main Outputs
      if (remainingFee > 0) {
        for (int i = outputs.length - 1; i >= 0; i--) {
          int outputAmount = outputs[i].value.toInt();

          if (outputAmount > _dustAmount) {
            int deduction = (outputAmount - _dustAmount >= remainingFee)
                ? remainingFee
                : outputAmount - _dustAmount;
            outputs[i] = BitcoinOutput(
                address: outputs[i].address, value: BigInt.from(outputAmount - deduction));
            remainingFee -= deduction;

            if (remainingFee <= 0) break;
          }
        }
      }

      // Final check if the remaining fee couldn't be deducted
      if (remainingFee > 0) {
        throw Exception("Not enough funds to cover the fee.");
      }

      // Identify all change outputs
      final changeAddresses = walletAddresses.allAddresses.where((element) => element.isChange);
      final List<BitcoinOutput> changeOutputs = outputs
          .where((output) => changeAddresses
              .any((element) => element.address == output.address.toAddress(network)))
          .toList();

      int totalChangeAmount =
          changeOutputs.fold<int>(0, (sum, output) => sum + output.value.toInt());

      // The final amount that the receiver will receive
      int sendingAmount = allInputsAmount - newFee - totalChangeAmount;

      final txb = BitcoinTransactionBuilder(
        utxos: utxos,
        outputs: outputs,
        fee: BigInt.from(newFee),
        network: network,
        memo: memo,
        outputOrdering: BitcoinOrdering.none,
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
        amount: sendingAmount,
        fee: newFee,
        network: network,
        hasChange: changeOutputs.isNotEmpty,
        feeRate: newFee.toString(),
      )..addListener((transaction) async {
          transactionHistory.transactions.values.forEach((tx) {
            if (tx.id == hash) {
              tx.isReplaced = true;
              tx.isPending = false;
              transactionHistory.addOne(tx);
            }
          });
          transactionHistory.addOne(transaction);
          await updateBalance();
        });
    } catch (e) {
      throw e;
    }
  }

  Future<ElectrumTransactionBundle> getTransactionExpanded({required String hash}) async {
    int? time;
    int? height;

    final transactionHex = await electrumClient2!.request(
      ElectrumGetTransactionHex(transactionHash: hash),
    );

    // TODO:
    // if (mempoolAPIEnabled) {
    if (true) {
      try {
        final txVerbose = await http.get(
          Uri.parse(
            "http://mempool.cakewallet.com:8999/api/v1/tx/$hash/status",
          ),
        );

        if (txVerbose.statusCode == 200 &&
            txVerbose.body.isNotEmpty &&
            jsonDecode(txVerbose.body) != null) {
          height = jsonDecode(txVerbose.body)['block_height'] as int;

          final blockHash = await http.get(
            Uri.parse(
              "http://mempool.cakewallet.com:8999/api/v1/block-height/$height",
            ),
          );

          if (blockHash.statusCode == 200 &&
              blockHash.body.isNotEmpty &&
              jsonDecode(blockHash.body) != null) {
            final blockResponse = await http.get(
              Uri.parse(
                "http://mempool.cakewallet.com:8999/api/v1/block/${blockHash.body}",
              ),
            );

            if (blockResponse.statusCode == 200 &&
                blockResponse.body.isNotEmpty &&
                jsonDecode(blockResponse.body)['timestamp'] != null) {
              time = int.parse(jsonDecode(blockResponse.body)['timestamp'].toString());
            }
          }
        }
      } catch (_) {}
    }

    int? confirmations;

    if (height != null) {
      if (time == null && height > 0) {
        time = (getDateByBitcoinHeight(height).millisecondsSinceEpoch / 1000).round();
      }

      final tip = currentChainTip!;
      if (tip > 0 && height > 0) {
        // Add one because the block itself is the first confirmation
        confirmations = tip - height + 1;
      }
    }

    final original = BtcTransaction.fromRaw(transactionHex);
    final ins = <BtcTransaction>[];

    for (final vin in original.inputs) {
      final inputTransactionHex = await electrumClient2!.request(
        ElectrumGetTransactionHex(transactionHash: vin.txId),
      );

      ins.add(BtcTransaction.fromRaw(inputTransactionHex));
    }

    return ElectrumTransactionBundle(
      original,
      ins: ins,
      time: time,
      confirmations: confirmations ?? 0,
    );
  }

  Future<ElectrumTransactionInfo?> fetchTransactionInfo({required String hash, int? height}) async {
    try {
      return ElectrumTransactionInfo.fromElectrumBundle(
        await getTransactionExpanded(hash: hash),
        walletInfo.type,
        network,
        addresses: addressesSet,
        height: height,
      );
    } catch (e, s) {
      print([e, s]);
      return null;
    }
  }

  @override
  @action
  Future<Map<String, ElectrumTransactionInfo>> fetchTransactions() async {
    try {
      final Map<String, ElectrumTransactionInfo> historiesWithDetails = {};

      if (type == WalletType.bitcoinCash) {
        await Future.wait(BITCOIN_CASH_ADDRESS_TYPES
            .map((type) => fetchTransactionsForAddressType(historiesWithDetails, type)));
      } else if (type == WalletType.litecoin) {
        await Future.wait(LITECOIN_ADDRESS_TYPES
            .map((type) => fetchTransactionsForAddressType(historiesWithDetails, type)));
      }

      return historiesWithDetails;
    } catch (e) {
      print("fetchTransactions $e");
      return {};
    }
  }

  Future<void> fetchTransactionsForAddressType(
    Map<String, ElectrumTransactionInfo> historiesWithDetails,
    BitcoinAddressType type,
  ) async {
    final addressesByType = walletAddresses.allAddresses.where((addr) => addr.type == type);
    await Future.wait(addressesByType.map((addressRecord) async {
      final history = await _fetchAddressHistory(addressRecord);

      if (history.isNotEmpty) {
        historiesWithDetails.addAll(history);
      }
    }));
  }

  Future<Map<String, ElectrumTransactionInfo>> _fetchAddressHistory(
    BitcoinAddressRecord addressRecord,
  ) async {
    String txid = "";

    try {
      final Map<String, ElectrumTransactionInfo> historiesWithDetails = {};

      final history = await electrumClient2!.request(ElectrumScriptHashGetHistory(
        scriptHash: addressRecord.scriptHash,
      ));

      if (history.isNotEmpty) {
        addressRecord.setAsUsed();
        addressRecord.txCount = history.length;

        await Future.wait(history.map((transaction) async {
          txid = transaction['tx_hash'] as String;

          final height = transaction['height'] as int;
          final storedTx = transactionHistory.transactions[txid];

          if (storedTx != null) {
            if (height > 0) {
              storedTx.height = height;
              // the tx's block itself is the first confirmation so add 1
              if ((currentChainTip ?? 0) > 0) {
                storedTx.confirmations = currentChainTip! - height + 1;
              }
              storedTx.isPending = storedTx.confirmations == 0;
            }

            historiesWithDetails[txid] = storedTx;
          } else {
            final tx = await fetchTransactionInfo(hash: txid, height: height);

            if (tx != null) {
              historiesWithDetails[txid] = tx;

              // Got a new transaction fetched, add it to the transaction history
              // instead of waiting all to finish, and next time it will be faster
              transactionHistory.addOne(tx);
            }
          }

          return Future.value(null);
        }));

        final totalAddresses = (addressRecord.isChange
            ? walletAddresses.changeAddresses
                .where((addr) => addr.type == addressRecord.type)
                .length
            : walletAddresses.receiveAddresses
                .where((addr) => addr.type == addressRecord.type)
                .length);
        final gapLimit = (addressRecord.isChange
            ? ElectrumWalletAddressesBase.defaultChangeAddressesCount
            : ElectrumWalletAddressesBase.defaultReceiveAddressesCount);

        final isUsedAddressUnderGap = addressRecord.index < totalAddresses &&
            (addressRecord.index >= totalAddresses - gapLimit);

        if (isUsedAddressUnderGap) {
          // Discover new addresses for the same address type until the gap limit is respected
          await walletAddresses.discoverAddresses(
            isChange: addressRecord.isChange,
            gap: gapLimit,
            type: addressRecord.type,
          );
        }
      }

      return historiesWithDetails;
    } catch (e, stacktrace) {
      _onError?.call(FlutterErrorDetails(
        exception: "$txid - $e",
        stack: stacktrace,
        library: this.runtimeType.toString(),
      ));
      return {};
    }
  }

  @action
  Future<void> updateTransactions() async {
    try {
      if (_isTransactionUpdating) {
        return;
      }

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

  @action
  Future<void> subscribeForUpdates([
    Iterable<BitcoinAddressRecord>? unsubscribedScriptHashes,
  ]) async {
    unsubscribedScriptHashes ??= walletAddresses.allAddresses.where(
      (address) => !scripthashesListening.contains(address.scriptHash),
    );

    await Future.wait(unsubscribedScriptHashes.map((addressRecord) async {
      final scripthash = addressRecord.scriptHash;
      final listener = await electrumClient2!.subscribe(
        ElectrumScriptHashSubscribe(scriptHash: scripthash),
      );

      if (listener != null) {
        scripthashesListening.add(scripthash);

        // https://electrumx.readthedocs.io/en/latest/protocol-basics.html#status
        // The status of the script hash is the hash of the tx history, or null if the string is empty because there are no transactions
        listener((status) async {
          print("status: $status");

          await _fetchAddressHistory(addressRecord);
          await updateUnspentsForAddress(addressRecord);
        });
      }
    }));
  }

  @action
  Future<ElectrumBalance> fetchBalances() async {
    var totalFrozen = 0;
    var totalConfirmed = 0;
    var totalUnconfirmed = 0;

    unspentCoins.forEach((element) {
      if (element.isFrozen) {
        totalFrozen += element.value;
      }

      if (element.confirmations == 0) {
        totalUnconfirmed += element.value;
      } else {
        totalConfirmed += element.value;
      }
    });

    return ElectrumBalance(
      confirmed: totalConfirmed,
      unconfirmed: totalUnconfirmed,
      frozen: totalFrozen,
    );
  }

  @action
  Future<void> updateBalance() async {
    balance[currency] = await fetchBalances();
  }

  @override
  void setExceptionHandler(void Function(FlutterErrorDetails) onError) => _onError = onError;

  @override
  Future<String> signMessage(String message, {String? address = null}) async {
    Bip32Slip10Secp256k1 HD = bip32;

    final record = walletAddresses.allAddresses.firstWhere((element) => element.address == address);

    if (record.isChange) {
      HD = HD.childKey(Bip32KeyIndex(1));
    } else {
      HD = HD.childKey(Bip32KeyIndex(0));
    }

    HD = HD.childKey(Bip32KeyIndex(record.index));
    final priv = ECPrivate.fromHex(HD.privateKey.privKey.toHex());

    String messagePrefix = '\x18Bitcoin Signed Message:\n';
    final hexEncoded = priv.signMessage(utf8.encode(message), messagePrefix: messagePrefix);
    final decodedSig = hex.decode(hexEncoded);
    return base64Encode(decodedSig);
  }

  @override
  Future<bool> verifyMessage(String message, String signature, {String? address = null}) async {
    if (address == null) {
      return false;
    }

    List<int> sigDecodedBytes = [];

    if (signature.endsWith('=')) {
      sigDecodedBytes = base64.decode(signature);
    } else {
      sigDecodedBytes = hex.decode(signature);
    }

    if (sigDecodedBytes.length != 64 && sigDecodedBytes.length != 65) {
      throw ArgumentException(
          "signature must be 64 bytes without recover-id or 65 bytes with recover-id");
    }

    String messagePrefix = '\x18Bitcoin Signed Message:\n';
    final messageHash = QuickCrypto.sha256Hash(
        BitcoinSignerUtils.magicMessage(utf8.encode(message), messagePrefix));

    List<int> correctSignature =
        sigDecodedBytes.length == 65 ? sigDecodedBytes.sublist(1) : List.from(sigDecodedBytes);
    List<int> rBytes = correctSignature.sublist(0, 32);
    List<int> sBytes = correctSignature.sublist(32);
    final sig = ECDSASignature(BigintUtils.fromBytes(rBytes), BigintUtils.fromBytes(sBytes));

    List<int> possibleRecoverIds = [0, 1];

    final baseAddress = RegexUtils.addressTypeFromStr(address, network);

    for (int recoveryId in possibleRecoverIds) {
      final pubKey = sig.recoverPublicKey(messageHash, Curves.generatorSecp256k1, recoveryId);

      final recoveredPub = ECPublic.fromBytes(pubKey!.toBytes());

      String? recoveredAddress;

      if (baseAddress is P2pkAddress) {
        recoveredAddress = recoveredPub.toP2pkAddress().toAddress(network);
      } else if (baseAddress is P2pkhAddress) {
        recoveredAddress = recoveredPub.toP2pkhAddress().toAddress(network);
      } else if (baseAddress is P2wshAddress) {
        recoveredAddress = recoveredPub.toP2wshAddress().toAddress(network);
      } else if (baseAddress is P2wpkhAddress) {
        recoveredAddress = recoveredPub.toP2wpkhAddress().toAddress(network);
      }

      if (recoveredAddress == address) {
        return true;
      }
    }

    return false;
  }

  @action
  void onHeadersResponse(ElectrumHeaderResponse response) {
    currentChainTip = response.height;
  }

  @action
  Future<void> subscribeForHeaders() async {
    if (_chainTipListenerOn) return;

    final listener = electrumClient2!.subscribe(ElectrumHeaderSubscribe());
    if (listener == null) return;

    _chainTipListenerOn = true;
    listener(onHeadersResponse);
  }

  @action
  void _onConnectionStatusChange(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        if (syncStatus is NotConnectedSyncStatus ||
            syncStatus is LostConnectionSyncStatus ||
            syncStatus is ConnectingSyncStatus) {
          syncStatus = AttemptingSyncStatus();
          startSync();
        }

        break;
      case ConnectionStatus.disconnected:
        // if (syncStatus is! NotConnectedSyncStatus) {
        //   syncStatus = NotConnectedSyncStatus();
        // }
        break;
      case ConnectionStatus.failed:
        // if (syncStatus is! LostConnectionSyncStatus) {
        //   syncStatus = LostConnectionSyncStatus();
        // }
        break;
      case ConnectionStatus.connecting:
        if (syncStatus is! ConnectingSyncStatus) {
          syncStatus = ConnectingSyncStatus();
        }
        break;
      default:
    }
  }

  @action
  void syncStatusReaction(SyncStatus syncStatus) {
    if (syncStatus is NotConnectedSyncStatus || syncStatus is LostConnectionSyncStatus) {
      // Needs to re-subscribe to all scripthashes when reconnected
      scripthashesListening = {};
      _isTransactionUpdating = false;
      _chainTipListenerOn = false;

      if (_isTryingToConnect) return;

      _isTryingToConnect = true;

      Timer(Duration(seconds: 5), () {
        if (this.syncStatus is NotConnectedSyncStatus ||
            this.syncStatus is LostConnectionSyncStatus) {
          if (node == null) return;

          this.electrumClient.connectToUri(
                node!.uri,
                useSSL: node!.useSSL ?? false,
              );
        }
        _isTryingToConnect = false;
      });
    }
  }

  void _updateInputsAndOutputs(ElectrumTransactionInfo tx, ElectrumTransactionBundle bundle) {
    tx.inputAddresses = tx.inputAddresses?.where((address) => address.isNotEmpty).toList();

    if (tx.inputAddresses == null ||
        tx.inputAddresses!.isEmpty ||
        tx.outputAddresses == null ||
        tx.outputAddresses!.isEmpty) {
      List<String> inputAddresses = [];
      List<String> outputAddresses = [];

      for (int i = 0; i < bundle.originalTransaction.inputs.length; i++) {
        final input = bundle.originalTransaction.inputs[i];
        final inputTransaction = bundle.ins[i];
        final vout = input.txIndex;
        final outTransaction = inputTransaction.outputs[vout];
        final address = addressFromOutputScript(outTransaction.scriptPubKey, network);

        if (address.isNotEmpty) inputAddresses.add(address);
      }

      for (int i = 0; i < bundle.originalTransaction.outputs.length; i++) {
        final out = bundle.originalTransaction.outputs[i];
        final address = addressFromOutputScript(out.scriptPubKey, network);

        if (address.isNotEmpty) outputAddresses.add(address);

        // Check if the script contains OP_RETURN
        final script = out.scriptPubKey.script;
        if (script.contains('OP_RETURN')) {
          final index = script.indexOf('OP_RETURN');
          if (index + 1 <= script.length) {
            try {
              final opReturnData = script[index + 1].toString();
              final decodedString = utf8.decode(HEX.decode(opReturnData));
              outputAddresses.add('OP_RETURN:$decodedString');
            } catch (_) {
              outputAddresses.add('OP_RETURN:');
            }
          }
        }
      }
      tx.inputAddresses = inputAddresses;
      tx.outputAddresses = outputAddresses;

      transactionHistory.addOne(tx);
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

  // final bool sendsToSilentPayment;
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
