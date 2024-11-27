import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/electrum_worker/electrum_worker.dart';
import 'package:cw_bitcoin/electrum_worker/electrum_worker_methods.dart';
import 'package:cw_bitcoin/electrum_worker/electrum_worker_params.dart';
import 'package:cw_bitcoin/electrum_worker/methods/methods.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:collection/collection.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/bitcoin_wallet_keys.dart';
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
import 'package:cw_core/unspent_coin_type.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart' as ledger;
import 'package:mobx/mobx.dart';

part 'electrum_wallet.g.dart';

class ElectrumWallet = ElectrumWalletBase with _$ElectrumWallet;

abstract class ElectrumWalletBase
    extends WalletBase<ElectrumBalance, ElectrumTransactionHistory, ElectrumTransactionInfo>
    with Store, WalletKeysFile {
  ReceivePort? receivePort;
  SendPort? workerSendPort;
  StreamSubscription<dynamic>? _workerSubscription;
  Isolate? _workerIsolate;
  final Map<int, dynamic> _responseCompleters = {};
  final Map<int, dynamic> _errorCompleters = {};
  int _messageId = 0;

  ElectrumWalletBase({
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required this.network,
    required this.encryptionFileUtils,
    Map<CWBitcoinDerivationType, Bip32Slip10Secp256k1>? hdWallets,
    String? xpub,
    String? mnemonic,
    List<int>? seedBytes,
    this.passphrase,
    List<BitcoinAddressRecord>? initialAddresses,
    ElectrumBalance? initialBalance,
    CryptoCurrency? currency,
    this.alwaysScan,
    required this.mempoolAPIEnabled,
    List<BitcoinUnspent> initialUnspentCoins = const [],
  })  : hdWallets = hdWallets ??
            {
              CWBitcoinDerivationType.bip39: getAccountHDWallet(
                currency,
                network,
                seedBytes,
                xpub,
                walletInfo.derivationInfo,
              )
            },
        syncStatus = NotConnectedSyncStatus(),
        _password = password,
        isEnabledAutoGenerateSubaddress = true,
        unspentCoins = BitcoinUnspentCoins.of(initialUnspentCoins),
        scripthashesListening = [],
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
    this.walletInfo = walletInfo;
    transactionHistory = ElectrumTransactionHistory(
      walletInfo: walletInfo,
      password: password,
      encryptionFileUtils: encryptionFileUtils,
    );

    reaction((_) => syncStatus, syncStatusReaction);

    sharedPrefs.complete(SharedPreferences.getInstance());
  }

  // Sends a request to the worker and returns a future that completes when the worker responds
  Future<dynamic> sendWorker(ElectrumWorkerRequest request) {
    final messageId = ++_messageId;

    final completer = Completer<dynamic>();
    _responseCompleters[messageId] = completer;

    final json = request.toJson();
    json['id'] = messageId;
    workerSendPort!.send(json);

    try {
      return completer.future.timeout(Duration(seconds: 30));
    } catch (e) {
      _errorCompleters.addAll({messageId: e});
      _responseCompleters.remove(messageId);
      rethrow;
    }
  }

  @action
  Future<void> handleWorkerResponse(dynamic message) async {
    print('Main: received message: $message');

    Map<String, dynamic> messageJson;
    if (message is String) {
      messageJson = jsonDecode(message) as Map<String, dynamic>;
    } else {
      messageJson = message as Map<String, dynamic>;
    }

    final workerMethod = messageJson['method'] as String;
    final workerError = messageJson['error'] as String?;
    final responseId = messageJson['id'] as int?;

    if (responseId != null && _responseCompleters.containsKey(responseId)) {
      _responseCompleters[responseId]!.complete(message);
      _responseCompleters.remove(responseId);
    }

    switch (workerMethod) {
      case ElectrumWorkerMethods.connectionMethod:
        if (workerError != null) {
          _onConnectionStatusChange(ConnectionStatus.failed);
          break;
        }

        final response = ElectrumWorkerConnectionResponse.fromJson(messageJson);
        _onConnectionStatusChange(response.result);
        break;
      case ElectrumRequestMethods.headersSubscribeMethod:
        final response = ElectrumWorkerHeadersSubscribeResponse.fromJson(messageJson);
        await onHeadersResponse(response.result);
        break;
      case ElectrumRequestMethods.getBalanceMethod:
        final response = ElectrumWorkerGetBalanceResponse.fromJson(messageJson);
        onBalanceResponse(response.result);
        break;
      case ElectrumRequestMethods.getHistoryMethod:
        final response = ElectrumWorkerGetHistoryResponse.fromJson(messageJson);
        onHistoriesResponse(response.result);
        break;
      case ElectrumRequestMethods.listunspentMethod:
        final response = ElectrumWorkerListUnspentResponse.fromJson(messageJson);
        onUnspentResponse(response.result);
        break;
      case ElectrumRequestMethods.estimateFeeMethod:
        final response = ElectrumWorkerGetFeesResponse.fromJson(messageJson);
        onFeesResponse(response.result);
        break;
    }
  }

  static Bip32Slip10Secp256k1 getAccountHDWallet(CryptoCurrency? currency, BasedUtxoNetwork network,
      List<int>? seedBytes, String? xpub, DerivationInfo? derivationInfo) {
    if (seedBytes == null && xpub == null) {
      throw Exception(
          "To create a Wallet you need either a seed or an xpub. This should not happen");
    }

    if (seedBytes != null) {
      return Bip32Slip10Secp256k1.fromSeed(seedBytes);
    }

    return Bip32Slip10Secp256k1.fromExtendedKey(xpub!, getKeyNetVersion(network));
  }

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
  bool _updatingHistories = false;

  final Map<CWBitcoinDerivationType, Bip32Slip10Secp256k1> hdWallets;
  Bip32Slip10Secp256k1 get bip32 => walletAddresses.hdWallet;
  final String? _mnemonic;

  final EncryptionFileUtils encryptionFileUtils;

  @override
  final String? passphrase;

  @override
  @observable
  bool isEnabledAutoGenerateSubaddress;

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

  List<String> get addressesSet => walletAddresses.allAddresses
      .where((element) => element.addressType != SegwitAddresType.mweb)
      .map((addr) => addr.address)
      .toList();

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
  BitcoinUnspentCoins unspentCoins;

  @observable
  TransactionPriorities? feeRates;

  int feeRate(TransactionPriority priority) {
    if (priority is ElectrumTransactionPriority && feeRates is BitcoinTransactionPriorities) {
      final rates = feeRates as BitcoinTransactionPriorities;

      switch (priority) {
        case ElectrumTransactionPriority.slow:
          return rates.normal;
        case ElectrumTransactionPriority.medium:
          return rates.elevated;
        case ElectrumTransactionPriority.fast:
          return rates.priority;
        case ElectrumTransactionPriority.custom:
          return rates.custom;
      }
    }

    return feeRates![priority];
  }

  @observable
  List<String> scripthashesListening;

  bool _chainTipListenerOn = false;
  // TODO: improve this
  int _syncedTimes = 0;

  void Function(FlutterErrorDetails)? _onError;
  Timer? _autoSaveTimer;
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

      // INFO: FIRST (always): Call subscribe for headers, wait for completion to update currentChainTip (needed for other methods)
      await sendWorker(ElectrumWorkerHeadersSubscribeRequest());

      _syncedTimes = 0;

      // INFO: SECOND: Start loading transaction histories for every address, this will help discover addresses until the unused gap limit has been reached, which will help finding the full balance and unspents next
      await updateTransactions();

      // INFO: THIRD: Get the full wallet's balance with all addresses considered
      await updateBalance();

      // INFO: FOURTH: Finish getting unspent coins for all the addresses
      await updateAllUnspents();

      // INFO: FIFTH: Get the latest recommended fee rates and start update timer
      await updateFeeRates();
      _updateFeeRateTimer ??=
          Timer.periodic(const Duration(seconds: 5), (timer) async => await updateFeeRates());

      if (_syncedTimes == 3) {
        syncStatus = SyncedSyncStatus();
      }

      await save();
    } catch (e, stacktrace) {
      print("startSync $e");
      print(stacktrace);
      syncStatus = FailedSyncStatus();
    }
  }

  @action
  void callError(FlutterErrorDetails error) {
    _onError?.call(error);
  }

  @action
  Future<void> updateFeeRates() async {
    workerSendPort!.send(
      ElectrumWorkerGetFeesRequest(mempoolAPIEnabled: mempoolAPIEnabled).toJson(),
    );
  }

  @action
  Future<void> onFeesResponse(TransactionPriorities? result) async {
    if (result != null) {
      feeRates = result;
    }
  }

  Node? node;

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    this.node = node;

    try {
      syncStatus = ConnectingSyncStatus();

      if (_workerIsolate != null) {
        _workerIsolate!.kill(priority: Isolate.immediate);
        _workerSubscription?.cancel();
        receivePort?.close();
      }

      receivePort = ReceivePort();

      _workerIsolate = await Isolate.spawn<SendPort>(ElectrumWorker.run, receivePort!.sendPort);

      _workerSubscription = receivePort!.listen((message) {
        print('Main: received message: $message');
        if (message is SendPort) {
          workerSendPort = message;
          workerSendPort!.send(
            ElectrumWorkerConnectionRequest(
              uri: node.uri,
              useSSL: node.useSSL ?? false,
              network: network,
              walletType: walletInfo.type,
            ).toJson(),
          );
        } else {
          handleWorkerResponse(message);
        }
      });
    } catch (e, stacktrace) {
      print(stacktrace);
      print("connectToNode $e");
      syncStatus = FailedSyncStatus();
    }
  }

  int get _dustAmount => 546;

  bool _isBelowDust(int amount) => amount <= _dustAmount && network != BitcoinNetwork.testnet;

  TxCreateUtxoDetails _createUTXOS({
    required bool sendAll,
    required bool paysToSilentPayment,
    int credentialsAmount = 0,
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
    var availableInputs = unspentCoins.where((utx) {
      if (!utx.isSending || utx.isFrozen) {
        return false;
      }

      switch (coinTypeToSpendFrom) {
        case UnspentCoinType.mweb:
          return utx.bitcoinAddressRecord.addressType == SegwitAddresType.mweb;
        case UnspentCoinType.nonMweb:
          return utx.bitcoinAddressRecord.addressType != SegwitAddresType.mweb;
        case UnspentCoinType.any:
          return true;
      }
    }).toList();
    final unconfirmedCoins = availableInputs.where((utx) => utx.confirmations == 0).toList();

    // sort the unconfirmed coins so that mweb coins are first:
    availableInputs
        .sort((a, b) => a.bitcoinAddressRecord.addressType == SegwitAddresType.mweb ? -1 : 1);

    for (int i = 0; i < availableInputs.length; i++) {
      final utx = availableInputs[i];
      if (!spendsUnconfirmedTX) spendsUnconfirmedTX = utx.confirmations == 0;

      if (paysToSilentPayment) {
        // Check inputs for shared secret derivation
        if (utx.bitcoinAddressRecord.addressType == SegwitAddresType.p2wsh) {
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
        final addressRecord = (utx.bitcoinAddressRecord as BitcoinAddressRecord);
        final path = addressRecord.derivationInfo.derivationPath
            .addElem(Bip32KeyIndex(
              BitcoinAddressUtils.getAccountFromChange(addressRecord.isChange),
            ))
            .addElem(Bip32KeyIndex(addressRecord.index));

        privkey = ECPrivate.fromBip32(bip32: bip32.derive(path));
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
        pubKeyHex = walletAddresses.hdWallet
            .childKey(Bip32KeyIndex(utx.bitcoinAddressRecord.index))
            .publicKey
            .toHex();
      }

      if (utx.bitcoinAddressRecord is BitcoinAddressRecord) {
        final derivationPath = (utx.bitcoinAddressRecord as BitcoinAddressRecord)
            .derivationInfo
            .derivationPath
            .toString();
        publicKeys[address.pubKeyHash()] = PublicKeyWithDerivationPath(pubKeyHex, derivationPath);
      }

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

    return TxCreateUtxoDetails(
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
    bool hasSilentPayment = false,
    UnspentCoinType coinTypeToSpendFrom = UnspentCoinType.any,
  }) async {
    final utxoDetails = _createUTXOS(
      sendAll: true,
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

    // Attempting to send less than the dust limit
    if (_isBelowDust(amount)) {
      throw BitcoinTransactionNoDustException();
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
    // Attempting to send less than the dust limit
    if (_isBelowDust(credentialsAmount)) {
      throw BitcoinTransactionNoDustException();
    }

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

    final changeDerivationPath = changeAddress.derivationInfo.derivationPath.toString();
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

    if (_isBelowDust(amountLeftForChange)) {
      // If has change that is lower than dust, will end up with tx rejected by network rules
      // so remove the change amount
      updatedOutputs.removeLast();
      outputs.removeLast();

      if (amountLeftForChange < 0) {
        if (!spendingAllCoins) {
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
        } else {
          throw BitcoinTransactionWrongBalanceException();
        }
      }

      return EstimatedTxResult(
        utxos: utxoDetails.utxos,
        inputPrivKeyInfos: utxoDetails.inputPrivKeyInfos,
        publicKeys: utxoDetails.publicKeys,
        fee: fee,
        amount: amount,
        hasChange: false,
        isSendAll: spendingAllCoins,
        memo: memo,
        spendsUnconfirmedTX: utxoDetails.spendsUnconfirmedTX,
        spendsSilentPayment: utxoDetails.spendsSilentPayment,
      );
    } else {
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

      return EstimatedTxResult(
        utxos: utxoDetails.utxos,
        inputPrivKeyInfos: utxoDetails.inputPrivKeyInfos,
        publicKeys: utxoDetails.publicKeys,
        fee: fee,
        amount: amount,
        hasChange: true,
        isSendAll: spendingAllCoins,
        memo: memo,
        spendsUnconfirmedTX: utxoDetails.spendsUnconfirmedTX,
        spendsSilentPayment: utxoDetails.spendsSilentPayment,
      );
    }
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
      final updatedOutputs = outputs
          .map((e) => BitcoinOutput(
                address: e.address,
                value: e.value,
                isSilentPayment: e.isSilentPayment,
                isChange: e.isChange,
              ))
          .toList();

      if (sendAll) {
        estimatedTx = await estimateSendAllTx(
          updatedOutputs,
          feeRateInt,
          memo: memo,
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
          sendWorker: sendWorker,
          amount: estimatedTx.amount,
          fee: estimatedTx.fee,
          feeRate: feeRateInt.toString(),
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
        sendWorker: sendWorker,
        amount: estimatedTx.amount,
        fee: estimatedTx.fee,
        feeRate: feeRateInt.toString(),
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
        'walletAddresses': walletAddresses.toJson(),
        'address_page_type': walletInfo.addressPageType == null
            ? SegwitAddresType.p2wpkh.toString()
            : walletInfo.addressPageType.toString(),
        'balance': balance[currency]?.toJSON(),
        'derivationTypeIndex': walletInfo.derivationInfo?.derivationType?.index,
        'derivationPath': walletInfo.derivationInfo?.derivationPath,
        'alwaysScan': alwaysScan,
        'unspents': unspentCoins.map((e) => e.toJson()).toList(),
      });

  int feeAmountForPriority(TransactionPriority priority, int inputsCount, int outputsCount,
          {int? size}) =>
      feeRate(priority) * (size ?? estimatedTransactionSize(inputsCount, outputsCount));

  int feeAmountWithFeeRate(int feeRate, int inputsCount, int outputsCount, {int? size}) =>
      feeRate * (size ?? estimatedTransactionSize(inputsCount, outputsCount));

  @override
  int calculateEstimatedFee(TransactionPriority? priority, int? amount,
      {int? outputsCount, int? size}) {
    if (priority is BitcoinTransactionPriority) {
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
  Future<void> rescan({required int height}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> close({required bool shouldCleanup}) async {
    try {
      _workerIsolate!.kill(priority: Isolate.immediate);
      await _workerSubscription?.cancel();
      receivePort?.close();
    } catch (_) {}
    _autoSaveTimer?.cancel();
    _updateFeeRateTimer?.cancel();
  }

  @action
  Future<void> updateAllUnspents() async {
    workerSendPort!.send(
      ElectrumWorkerListUnspentRequest(
        scripthashes: walletAddresses.allScriptHashes.toList(),
      ).toJson(),
    );
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
  Future<void> onUnspentResponse(Map<String, List<ElectrumUtxo>> unspents) async {
    final updatedUnspentCoins = <BitcoinUnspent>[];

    await Future.wait(unspents.entries.map((entry) async {
      final unspent = entry.value;
      final scriptHash = entry.key;

      final addressRecord = walletAddresses.allAddresses.firstWhereOrNull(
        (element) => element.scriptHash == scriptHash,
      );

      if (addressRecord == null) {
        return null;
      }

      await Future.wait(unspent.map((unspent) async {
        final coin = BitcoinUnspent.fromJSON(addressRecord, unspent.toJson());
        coin.isChange = addressRecord.isChange;
        final tx = await fetchTransactionInfo(hash: coin.hash);
        if (tx != null) {
          coin.confirmations = tx.confirmations;
        }

        updatedUnspentCoins.add(coin);
      }));
    }));

    unspentCoins.addAll(updatedUnspentCoins);
    unspentCoins.forEach(updateCoin);

    await refreshUnspentCoinsInfo();

    _syncedTimes++;
    if (_syncedTimes == 3) {
      syncStatus = SyncedSyncStatus();
    }
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

  @action
  Future<void> onHeadersResponse(ElectrumHeaderResponse response) async {
    currentChainTip = response.height;

    bool updated = false;
    transactionHistory.transactions.values.forEach((tx) {
      if (tx.height != null && tx.height! > 0) {
        final newConfirmations = currentChainTip! - tx.height! + 1;

        if (tx.confirmations != newConfirmations) {
          tx.confirmations = newConfirmations;
          tx.isPending = tx.confirmations == 0;
          updated = true;
        }
      }
    });

    if (updated) {
      await save();
    }
  }

  @action
  Future<void> subscribeForHeaders() async {
    if (_chainTipListenerOn) return;

    workerSendPort!.send(ElectrumWorkerHeadersSubscribeRequest().toJson());
    _chainTipListenerOn = true;
  }

  @action
  Future<void> onHistoriesResponse(List<AddressHistoriesResponse> histories) async {
    if (histories.isEmpty || _updatingHistories) {
      _updatingHistories = false;
      _syncedTimes++;
      if (_syncedTimes == 3) {
        syncStatus = SyncedSyncStatus();
      }

      return;
    }

    _updatingHistories = true;

    final addressesWithHistory = <BitcoinAddressRecord>[];
    BitcoinAddressType? lastDiscoveredType;

    for (final addressHistory in histories) {
      final txs = addressHistory.txs;

      if (txs.isNotEmpty) {
        final addressRecord = addressHistory.addressRecord;
        final isChange = addressRecord.isChange;

        final addressList =
            (isChange ? walletAddresses.changeAddresses : walletAddresses.receiveAddresses).where(
                (element) =>
                    element.addressType == addressRecord.addressType &&
                    element.derivationType == addressRecord.derivationType);
        final totalAddresses = addressList.length;

        final gapLimit = (isChange
            ? ElectrumWalletAddressesBase.defaultChangeAddressesCount
            : ElectrumWalletAddressesBase.defaultReceiveAddressesCount);

        addressesWithHistory.add(addressRecord);

        for (final tx in txs) {
          transactionHistory.addOne(tx);
        }

        final hasUsedAddressesUnderGap = addressRecord.index >= totalAddresses - gapLimit;

        if (hasUsedAddressesUnderGap && lastDiscoveredType != addressRecord.addressType) {
          lastDiscoveredType = addressRecord.addressType;

          // Discover new addresses for the same address type until the gap limit is respected
          final newAddresses = await walletAddresses.discoverNewAddresses(
            isChange: isChange,
            derivationType: addressRecord.derivationType,
            addressType: addressRecord.addressType,
            derivationInfo: BitcoinAddressUtils.getDerivationFromType(
              addressRecord.addressType,
              isElectrum: [
                CWBitcoinDerivationType.electrum,
                CWBitcoinDerivationType.old_electrum,
              ].contains(addressRecord.derivationType),
            ),
          );

          final newAddressList =
              (isChange ? walletAddresses.changeAddresses : walletAddresses.receiveAddresses).where(
                  (element) =>
                      element.addressType == addressRecord.addressType &&
                      element.derivationType == addressRecord.derivationType);
          print(
              "discovered ${newAddresses.length} new addresses, new total: ${newAddressList.length}");

          if (newAddresses.isNotEmpty) {
            // Update the transactions for the new discovered addresses
            await updateTransactions(newAddresses);
          }
        }
      }
    }

    if (addressesWithHistory.isNotEmpty) {
      walletAddresses.updateAdresses(addressesWithHistory);
    }

    walletAddresses.updateHiddenAddresses();
    _updatingHistories = false;

    _syncedTimes++;
    if (_syncedTimes == 3) {
      syncStatus = SyncedSyncStatus();
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
    final changeOutput = outputs.firstWhereOrNull((output) => changeAddresses.any((element) =>
        element.address ==
        BitcoinAddressUtils.addressFromOutputScript(output.scriptPubKey, network)));

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
        final address =
            BitcoinAddressUtils.addressFromOutputScript(outTransaction.scriptPubKey, network);
        // allInputsAmount += outTransaction.amount.toInt();

        final addressRecord =
            walletAddresses.allAddresses.firstWhere((element) => element.address == address);

        final btcAddress = RegexUtils.addressTypeFromStr(addressRecord.address, network);
        final path = addressRecord.derivationInfo.derivationPath
            .addElem(Bip32KeyIndex(
              BitcoinAddressUtils.getAccountFromChange(addressRecord.isChange),
            ))
            .addElem(Bip32KeyIndex(addressRecord.index));

        final privkey = ECPrivate.fromBip32(bip32: bip32.derive(path));

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
              memo = StringUtils.decode(BytesUtils.fromHexString(opReturnData));
              continue;
            } catch (_) {
              throw Exception('Cannot decode OP_RETURN data');
            }
          }
        }

        final address = BitcoinAddressUtils.addressFromOutputScript(out.scriptPubKey, network);
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
        sendWorker: sendWorker,
        amount: sendingAmount,
        fee: newFee,
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
    return await sendWorker(
      ElectrumWorkerTxExpandedRequest(
        txHash: hash,
        currentChainTip: currentChainTip!,
        mempoolAPIEnabled: mempoolAPIEnabled,
      ),
    ) as ElectrumTransactionBundle;
  }

  Future<ElectrumTransactionInfo?> fetchTransactionInfo({required String hash, int? height}) async {
    try {
      return ElectrumTransactionInfo.fromElectrumBundle(
        await getTransactionExpanded(hash: hash),
        walletInfo.type,
        network,
        addresses: walletAddresses.allAddresses.map((e) => e.address).toSet(),
        height: height,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  @action
  Future<Map<String, ElectrumTransactionInfo>> fetchTransactions() async {
    throw UnimplementedError();
  }

  @action
  Future<void> updateTransactions([List<BitcoinAddressRecord>? addresses]) async {
    workerSendPort!.send(ElectrumWorkerGetHistoryRequest(
      addresses: walletAddresses.allAddresses.toList(),
      storedTxs: transactionHistory.transactions.values.toList(),
      walletType: type,
      // If we still don't have currentChainTip, txs will still be fetched but shown
      // with confirmations as 0 but will be auto fixed on onHeadersResponse
      chainTip: currentChainTip ?? getBitcoinHeightByDate(date: DateTime.now()),
      network: network,
      mempoolAPIEnabled: mempoolAPIEnabled,
    ).toJson());
  }

  @action
  Future<void> subscribeForUpdates([Iterable<String>? unsubscribedScriptHashes]) async {
    unsubscribedScriptHashes ??= walletAddresses.allScriptHashes.where(
      (sh) => !scripthashesListening.contains(sh),
    );

    Map<String, String> scripthashByAddress = {};
    walletAddresses.allAddresses.forEach((addressRecord) {
      scripthashByAddress[addressRecord.address] = addressRecord.scriptHash;
    });

    workerSendPort!.send(
      ElectrumWorkerScripthashesSubscribeRequest(
        scripthashByAddress: scripthashByAddress,
      ).toJson(),
    );

    scripthashesListening.addAll(scripthashByAddress.values);
  }

  @action
  void onBalanceResponse(ElectrumBalance balanceResult) {
    var totalFrozen = 0;
    var totalConfirmed = balanceResult.confirmed;
    var totalUnconfirmed = balanceResult.unconfirmed;

    unspentCoins.forInfo(unspentCoinsInfo.values).forEach((unspentCoinInfo) {
      if (unspentCoinInfo.isFrozen) {
        totalFrozen += unspentCoinInfo.value;
      }
    });

    balance[currency] = ElectrumBalance(
      confirmed: totalConfirmed,
      unconfirmed: totalUnconfirmed,
      frozen: totalFrozen,
    );

    _syncedTimes++;
    if (_syncedTimes == 3) {
      syncStatus = SyncedSyncStatus();
    }
  }

  @action
  Future<void> updateBalance() async {
    workerSendPort!.send(ElectrumWorkerGetBalanceRequest(
      scripthashes: walletAddresses.allScriptHashes,
    ).toJson());
  }

  @override
  void setExceptionHandler(void Function(FlutterErrorDetails) onError) => _onError = onError;

  Future<String> signMessage(String message, {String? address = null}) async {
    final record = walletAddresses.getFromAddresses(address!);

    final path = Bip32PathParser.parse(walletInfo.derivationInfo!.derivationPath!)
        .addElem(
          Bip32KeyIndex(BitcoinAddressUtils.getAccountFromChange(record.isChange)),
        )
        .addElem(Bip32KeyIndex(record.index));

    final priv = ECPrivate.fromHex(bip32.derive(path).privateKey.toHex());

    final hexEncoded = priv.signMessage(StringUtils.encode(message));
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
      sigDecodedBytes = BytesUtils.fromHexString(signature);
    }

    if (sigDecodedBytes.length != 64 && sigDecodedBytes.length != 65) {
      throw ArgumentException(
          "signature must be 64 bytes without recover-id or 65 bytes with recover-id");
    }

    String messagePrefix = '\x18Bitcoin Signed Message:\n';
    final messageHash = QuickCrypto.sha256Hash(
        BitcoinSignerUtils.magicMessage(StringUtils.encode(message), messagePrefix));

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
  void _onConnectionStatusChange(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        if (syncStatus is NotConnectedSyncStatus ||
            syncStatus is LostConnectionSyncStatus ||
            syncStatus is ConnectingSyncStatus) {
          syncStatus = ConnectedSyncStatus();
        }

        break;
      case ConnectionStatus.disconnected:
        if (syncStatus is! NotConnectedSyncStatus &&
            syncStatus is! ConnectingSyncStatus &&
            syncStatus is! SynchronizingSyncStatus) {
          syncStatus = NotConnectedSyncStatus();
        }
        break;
      case ConnectionStatus.failed:
        if (syncStatus is! LostConnectionSyncStatus) {
          syncStatus = LostConnectionSyncStatus();
        }
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
    final isDisconnectedStatus =
        syncStatus is NotConnectedSyncStatus || syncStatus is LostConnectionSyncStatus;

    if (syncStatus is ConnectingSyncStatus || isDisconnectedStatus) {
      // Needs to re-subscribe to all scripthashes when reconnected
      scripthashesListening = [];
      _chainTipListenerOn = false;
    }

    if (isDisconnectedStatus) {
      if (_isTryingToConnect) return;

      _isTryingToConnect = true;

      Timer(Duration(seconds: 5), () {
        if (this.syncStatus is NotConnectedSyncStatus ||
            this.syncStatus is LostConnectionSyncStatus) {
          if (node == null) return;

          connectToNode(node: this.node!);
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
        final address =
            BitcoinAddressUtils.addressFromOutputScript(outTransaction.scriptPubKey, network);

        if (address.isNotEmpty) inputAddresses.add(address);
      }

      for (int i = 0; i < bundle.originalTransaction.outputs.length; i++) {
        final out = bundle.originalTransaction.outputs[i];
        final address = BitcoinAddressUtils.addressFromOutputScript(out.scriptPubKey, network);

        if (address.isNotEmpty) outputAddresses.add(address);

        // Check if the script contains OP_RETURN
        final script = out.scriptPubKey.script;
        if (script.contains('OP_RETURN')) {
          final index = script.indexOf('OP_RETURN');
          if (index + 1 <= script.length) {
            try {
              final opReturnData = script[index + 1].toString();
              final decodedString = StringUtils.decode(BytesUtils.fromHexString(opReturnData));
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

class TxCreateUtxoDetails {
  final List<BitcoinUnspent> availableInputs;
  final List<BitcoinUnspent> unconfirmedCoins;
  final List<UtxoWithAddress> utxos;
  final List<Outpoint> vinOutpoints;
  final List<ECPrivateInfo> inputPrivKeyInfos;
  final Map<String, PublicKeyWithDerivationPath> publicKeys; // PubKey to derivationPath
  final int allInputsAmount;
  final bool spendsSilentPayment;
  final bool spendsUnconfirmedTX;

  TxCreateUtxoDetails({
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

class BitcoinUnspentCoins extends ObservableSet<BitcoinUnspent> {
  BitcoinUnspentCoins() : super();

  static BitcoinUnspentCoins of(Iterable<BitcoinUnspent> unspentCoins) {
    final coins = BitcoinUnspentCoins();
    coins.addAll(unspentCoins);
    return coins;
  }

  List<UnspentCoinsInfo> forInfo(Iterable<UnspentCoinsInfo> unspentCoinsInfo) {
    return unspentCoinsInfo.where((element) {
      final info = this.firstWhereOrNull(
        (info) =>
            element.hash == info.hash &&
            element.vout == info.vout &&
            element.address == info.bitcoinAddressRecord.address &&
            element.value == info.value,
      );

      return info != null;
    }).toList();
  }

  List<BitcoinUnspent> fromInfo(Iterable<UnspentCoinsInfo> unspentCoinsInfo) {
    return this.where((element) {
      final info = unspentCoinsInfo.firstWhereOrNull(
        (info) =>
            element.hash == info.hash &&
            element.vout == info.vout &&
            element.bitcoinAddressRecord.address == info.address &&
            element.value == info.value,
      );

      return info != null;
    }).toList();
  }
}
