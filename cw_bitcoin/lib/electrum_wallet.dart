import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/lightning/lightning_wallet.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_bitcoin/litecoin_wallet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:collection/collection.dart';
import 'package:cw_bitcoin/address_from_output.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/bitcoin_wallet_keys.dart';
import 'package:cw_bitcoin/electrum.dart' as electrum;
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_derivations.dart';
import 'package:cw_bitcoin/electrum_transaction_history.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/exceptions.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/socket_health_logger.dart';
import 'package:cw_core/utils/tor/abstract.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:rxdart/subjects.dart';
import 'package:sp_scanner/sp_scanner.dart';

part 'electrum_wallet.g.dart';

class ElectrumWallet = ElectrumWalletBase with _$ElectrumWallet;

abstract class ElectrumWalletBase
    extends WalletBase<ElectrumBalance, ElectrumTransactionHistory, ElectrumTransactionInfo>
    with Store, WalletKeysFile {
  ElectrumWalletBase({
    required String password,
    required WalletInfo walletInfo,
    required DerivationInfo derivationInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required this.network,
    required this.encryptionFileUtils,
    String? xpub,
    String? mnemonic,
    Uint8List? seedBytes,
    this.passphrase,
    List<BitcoinAddressRecord>? initialAddresses,
    electrum.ElectrumClient? electrumClient,
    ElectrumBalance? initialBalance,
    CryptoCurrency? currency,
    bool? alwaysScan,
    bool useLightning = true,
  })  : _masterHD = getMasterHD(seedBytes, network, walletInfo.hardwareWalletType),
        accountHD = getAccountHDWallet(
            currency, network, seedBytes, xpub, derivationInfo, walletInfo.hardwareWalletType),
        syncStatus = NotConnectedSyncStatus(),
        _password = password,
        _feeRates = <int>[],
        _isTransactionUpdating = false,
        isEnabledAutoGenerateSubaddress = true,
        unspentCoins = [],
        _scripthashesUpdateSubject = {},
        this.alwaysScan = alwaysScan,
        silentPaymentsScanningActive = alwaysScan ?? false,
        balance = ObservableMap<CryptoCurrency, ElectrumBalance>.of(currency != null
            ? {
                currency: initialBalance ??
                    ElectrumBalance(
                      confirmed: Money.zero(currency),
                      unconfirmed: Money.zero(currency),
                      frozen: Money.zero(currency),
                    )
              }
            : {}),
        this.unspentCoinsInfo = unspentCoinsInfo,
        this.isTestnet = !network.isMainnet,
        this._mnemonic = mnemonic,
        _useLightning = useLightning,
        super(walletInfo, derivationInfo) {
    this.electrumClient = electrumClient ?? electrum.ElectrumClient();
    this.walletInfo = walletInfo;
    this.derivationInfo = derivationInfo;
    transactionHistory = ElectrumTransactionHistory(
      walletInfo: walletInfo,
      password: password,
      encryptionFileUtils: encryptionFileUtils,
    );

    reaction((_) => syncStatus, _syncStatusReaction);

    sharedPrefs.complete(SharedPreferences.getInstance());

    final supportedTypes = supportedAddressTypes(walletInfo.type);
    mainHdByType = <BitcoinAddressType, Bip32Slip10Secp256k1>{};
    sideHdByType = <BitcoinAddressType, Bip32Slip10Secp256k1>{};

    final isElectrumDerivation = derivationInfo.derivationType == DerivationType.electrum;

    final canDeriveFromSeed = _masterHD != null && currency != null;

    if (isElectrumDerivation) {
      // Electrum derivation does not follow BIP44/49/84 etc. standards
      for (final type in supportedTypes) {
        mainHdByType[type] = mainHd; // accountHD.child(0)
        sideHdByType[type] = sideHd; // accountHD.child(1)
      }
    } else if (canDeriveFromSeed) {
      final coinType = _coinTypeFor(currency);
      final accountIndex = _parseAccountIndex(derivationInfo.derivationPath);

      for (final type in supportedTypes) {
        final purpose = _purposeForType(type);
        final accountPath = "m/$purpose'/$coinType'/$accountIndex'";

        mainHdByType[type] = _masterHD!.derivePath("$accountPath/0") as Bip32Slip10Secp256k1;
        sideHdByType[type] = _masterHD!.derivePath("$accountPath/1") as Bip32Slip10Secp256k1;
      }
    } else {
      // View-only wallet (xpub only)
      for (final type in supportedTypes) {
        mainHdByType[type] = mainHd;
        sideHdByType[type] = sideHd;
      }
    }
  }

  int _purposeForType(BitcoinAddressType type) {
    switch (type.value) {
      case 'P2PKH':
        return 44;
      case 'P2SH/P2WPKH':
        return 49;
      case 'P2WPKH':
        return 84;
      case 'P2TR':
        return 86;
      default:
        return 84;
    }
  }

  int _coinTypeFor(CryptoCurrency cur) {
    if (!network.isMainnet) return 1;
    switch (cur) {
      case CryptoCurrency.btc:
      case CryptoCurrency.tbtc:
        return 0;
      case CryptoCurrency.ltc:
        return 2;
      case CryptoCurrency.bch:
        return 145;
      case CryptoCurrency.doge:
        return 3;
      default:
        return 0;
    }
  }

  /// Returns the BIP32 account derivation path (m/purpose'/coinType'/0') for STANDARD addresses.
  /// For LEGACY addresses, returns the wallet's legacy derivation base (derivationInfo.derivationPath)
  /// which is already the account path used historically (e.g. m/0' or m/84'/0'/0').
  String _accountDerivationPathForRecord(BaseBitcoinAddressRecord record) {
    if (derivationInfo.derivationType == DerivationType.electrum) {
      return derivationInfo.derivationPath ?? electrum_path; // m/0'
    }

    if (record.isLegacyDerivation) {
      return derivationInfo.derivationPath ?? electrum_path;
    }

    final coinType = _coinTypeFor(currency);
    final purpose = _purposeForType(record.type);
    final accountIndex = _parseAccountIndex(derivationInfo.derivationPath);
    return "m/$purpose'/$coinType'/$accountIndex'";
  }

  List<BitcoinAddressType> supportedAddressTypes(WalletType type) {
    switch (type) {
      case WalletType.bitcoin:
        return BITCOIN_ADDRESS_TYPES;
      case WalletType.bitcoinCash:
        return BITCOIN_CASH_ADDRESS_TYPES;
      case WalletType.dogecoin:
        return DOGECOIN_ADDRESS_TYPES;
      case WalletType.litecoin:
        return LITECOIN_ADDRESS_TYPES;
      default:
        return BITCOIN_ADDRESS_TYPES;
    }
  }

  static Bip32Slip10Secp256k1 getAccountHDWallet(
      CryptoCurrency? currency,
      BasedUtxoNetwork network,
      Uint8List? seedBytes,
      String? xpub,
      DerivationInfo? derivationInfo,
      HardwareWalletType? hardwareWalletType) {
    if (seedBytes == null && xpub == null) {
      throw Exception(
          "To create a Wallet you need either a seed or an xpub. This should not happen");
    }

    if (seedBytes != null) {
      switch (currency) {
        case CryptoCurrency.btc:
        case CryptoCurrency.ltc:
        case CryptoCurrency.tbtc:
          return Bip32Slip10Secp256k1.fromSeed(
                      seedBytes, getKeyNetVersion(network, hardwareWalletType))
                  .derivePath(
                      _hardenedDerivationPath(derivationInfo?.derivationPath ?? electrum_path))
              as Bip32Slip10Secp256k1;
        case CryptoCurrency.bch:
          return bitcoinCashHDWallet(seedBytes);
        case CryptoCurrency.doge:
          return dogecoinHDWallet(seedBytes);
        default:
          throw Exception("Unsupported currency");
      }
    }

    return Bip32Slip10Secp256k1.fromExtendedKey(
        xpub!, getKeyNetVersion(network, hardwareWalletType));
  }

  static Bip32Slip10Secp256k1 bitcoinCashHDWallet(Uint8List seedBytes) =>
      Bip32Slip10Secp256k1.fromSeed(seedBytes).derivePath("m/44'/145'/0'") as Bip32Slip10Secp256k1;

  static Bip32Slip10Secp256k1 dogecoinHDWallet(Uint8List seedBytes) =>
      Bip32Slip10Secp256k1.fromSeed(seedBytes).derivePath("m/44'/3'/0'") as Bip32Slip10Secp256k1;

  static int estimatedTransactionSize(int inputsCount, int outputsCounts) =>
      inputsCount * 68 + outputsCounts * 34 + 10;

  // Parses the account index from a BIP-44/49/84/86 derivation path.
  // e.g. "m/84'/0'/1'" → 1.  Returns 0 for unrecognised formats.
  static int _parseAccountIndex(String? derivationPath) {
    if (derivationPath == null) return 0;
    final parts = derivationPath.split('/');
    if (parts.length < 4) return 0;
    return int.tryParse(parts[3].replaceAll("'", "")) ?? 0;
  }

  static Bip32KeyNetVersions? getKeyNetVersion(BasedUtxoNetwork network,
      [HardwareWalletType? hardwareWalletType]) {
    switch (network) {
      case LitecoinNetwork.mainnet:
        if ([HardwareWalletType.ledger, HardwareWalletType.trezor].contains(hardwareWalletType))
          return Bip44Conf.litecoinMainNet.altKeyNetVer;
        return null;
      default:
        return null;
    }
  }

  static Bip32Slip10Secp256k1? getMasterHD(Uint8List? seedBytes,
      [BasedUtxoNetwork? network, HardwareWalletType? hardwareWalletType]) {
    if (seedBytes == null) return null;

    return Bip32Slip10Secp256k1.fromSeed(
        seedBytes, network != null ? getKeyNetVersion(network, hardwareWalletType) : null);
  }

  static const int addressHistoryChunkSize = 150;
  static const int transactionChunkSize = 150;
  static const int inputTransactionChunkSize = 150;
  static const int discoveryHistoryChunkSize = 20;

  static const int transactionBatchTimeoutMs = 15000;

  static const int batchTestTimeoutMs = 4000;
  static const int batchTestHashesCount = 2;

  static const bool useBatchForHistory = true;

  @observable
  bool? alwaysScan;

  @computed
  bool get useLightning => _useLightning && LightningWallet.isAvailable;

  set useLightning(bool val) => _useLightning = val && LightningWallet.isAvailable;

  @observable
  bool _useLightning;

  final Bip32Slip10Secp256k1? _masterHD;
  final Bip32Slip10Secp256k1 accountHD;
  final String? _mnemonic;

  late final Map<BitcoinAddressType, Bip32Slip10Secp256k1> mainHdByType;
  late final Map<BitcoinAddressType, Bip32Slip10Secp256k1> sideHdByType;

  Bip32Slip10Secp256k1 get mainHd => accountHD.childKey(Bip32KeyIndex(0));

  Bip32Slip10Secp256k1 get sideHd => accountHD.childKey(Bip32KeyIndex(1));

  final EncryptionFileUtils encryptionFileUtils;

  @override
  final String? passphrase;

  @override
  @observable
  bool isEnabledAutoGenerateSubaddress;

  late electrum.ElectrumClient electrumClient;
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
      .map((addr) => (addr as BitcoinAddressRecord).getScriptHash(network))
      .toList();

  List<String> get publicScriptHashes => walletAddresses.allAddresses
      .where((addr) => !addr.isHidden)
      .where((addr) => RegexUtils.addressTypeFromStr(addr.address, network) is! MwebAddress)
      .map((addr) => addr.getScriptHash(network))
      .toList();

  String get xpub => accountHD.publicKey.toExtended;

  bool get shouldUseBatchFetching => useBatchForHistory && _isBatchSupported == true;

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

  bool get hasSilentPaymentsScanning => type == WalletType.bitcoin && keys.privateKey.isNotEmpty;

  @observable
  bool nodeSupportsSilentPayments = true;
  @observable
  bool silentPaymentsScanningActive = false;

  bool _isTryingToConnect = false;
  bool? _isBatchSupported;
  DateTime? _syncBenchmarkStartTime;

  Completer<SharedPreferences> sharedPrefs = Completer();

  Future<bool> checkIfMempoolAPIIsEnabled() async {
    bool isMempoolAPIEnabled = (await sharedPrefs.future).getBool("use_mempool_fee_api") ?? true;
    return isMempoolAPIEnabled;
  }

  @action
  Future<void> setSilentPaymentsScanning(bool active) async {
    silentPaymentsScanningActive = active;

    if (active) {
      syncStatus = AttemptingScanSyncStatus();

      final tip = await getUpdatedChainTip();

      if (tip == walletInfo.restoreHeight) {
        syncStatus = SyncedTipSyncStatus(tip);
        return;
      }

      if (tip > walletInfo.restoreHeight) {
        _setListeners(walletInfo.restoreHeight, chainTipParam: currentChainTip);
      }
    } else {
      alwaysScan = false;

      _isolate?.then((value) => value.kill(priority: Isolate.immediate));

      if (electrumClient.isConnected) {
        syncStatus = SyncedSyncStatus();
      } else {
        syncStatus = NotConnectedSyncStatus();
      }
    }
  }

  int? currentChainTip;

  Future<int> getCurrentChainTip() async {
    if ((currentChainTip ?? 0) > 0) {
      return currentChainTip!;
    }
    currentChainTip = await electrumClient.getCurrentBlockChainTip() ?? 0;

    return currentChainTip!;
  }

  Future<int> getUpdatedChainTip() async {
    final newTip = await electrumClient.getCurrentBlockChainTip();
    if (newTip != null && newTip > (currentChainTip ?? 0)) {
      currentChainTip = newTip;
    }
    return currentChainTip ?? 0;
  }

  @override
  BitcoinWalletKeys get keys {
    String? wif;
    String? privateKey;
    String? publicKey;

    final hd = mainHdByType[SegwitAddresType.p2wpkh] ?? mainHd;

    try {
      wif = WifEncoder.encode(hd.privateKey.raw, netVer: network.wifNetVer);
    } catch (_) {}
    try {
      privateKey = hd.privateKey.toHex();
    } catch (_) {}
    try {
      publicKey = hd.publicKey.toHex();
    } catch (_) {}

    return BitcoinWalletKeys(
      wif: wif ?? '',
      privateKey: privateKey ?? '',
      publicKey: publicKey ?? '',
      xpub: xpub,
      masterFingerprint: _masterHD?.fingerPrint.toHex() ?? '',
    );
  }

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
  StreamSubscription<dynamic>? _receiveStream;
  Timer? _updateFeeRateTimer;
  static const int _autoSaveInterval = 1;

  Future<void> init() async {
    await walletAddresses.init();
    await transactionHistory.init();
    await cleanUpDuplicateUnspentCoins();
    await save();

    _autoSaveTimer =
        Timer.periodic(Duration(minutes: _autoSaveInterval), (_) async => await save());
  }

  @action
  Future<void> _setListeners(int height,
      {int? chainTipParam, bool? doSingleScan, List<int>? rescanHeights}) async {
    if (this is! BitcoinWallet) return;
    if (isHardwareWallet) return;
    if (seed?.isEmpty ?? true) return;

    final chainTip = chainTipParam ?? await getUpdatedChainTip();
    final shouldUpdateSyncStatus = rescanHeights == null || rescanHeights.isEmpty;

    if (chainTip == height) {
      syncStatus = SyncedSyncStatus();
      return;
    }

    if (shouldUpdateSyncStatus) syncStatus = AttemptingScanSyncStatus();

    if (_isolate != null) {
      final runningIsolate = await _isolate!;
      runningIsolate.kill(priority: Isolate.immediate);
    }

    final appDir = await getAppDir();
    String debugLogPath = "${appDir.path}/logs/debug.log";

    final receivePort = ReceivePort();
    _isolate = Isolate.spawn(
      _handleScanSilentPayments,
      ScanData(
        sendPort: receivePort.sendPort,
        silentAddress: walletAddresses.silentAddress!,
        masterHD: _masterHD!,
        network: network,
        height: height,
        chainTip: chainTip,
        electrumClient: electrum.ElectrumClient(),
        transactionHistoryIds: transactionHistory.transactions.keys.toList(),
        node: (await getNodeSupportsSilentPayments()) == true
            ? ScanNode(node!.uri, node!.useSSL)
            : null,
        labels: walletAddresses.labels,
        labelIndexes: walletAddresses.silentAddresses
            .where((addr) => addr.type == SilentPaymentsAddresType.p2sp && addr.index >= 1)
            .map((addr) => addr.index)
            .toList(),
        isSingleScan: doSingleScan ?? false,
        debugLogPath: debugLogPath,
        rescanHeights: rescanHeights,
      ),
    );

    await _receiveStream?.cancel();
    _receiveStream = receivePort.listen((var message) async {
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
              existingTxInfo.date = tx.date;
              existingTxInfo.isReceivedSilentPayment = tx.isReceivedSilentPayment;
              existingTxInfo.direction = tx.direction;
              existingTxInfo.isPending = tx.isPending;
              existingTxInfo.unspents = tx.unspents;

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
                  existingTxInfo.amount += Money.fromInt(newAmount, currency);
                }

                // Updates existing TX
                transactionHistory.addOne(existingTxInfo);
                // Update balance record
                balance[currency]!.confirmed += Money.fromInt(newAmount, currency);
              }
            } else {
              // else: First time seeing this TX after scanning
              tx.unspents!.forEach(_updateSilentAddressRecord);

              // Add new TX record
              transactionHistory.addMany(message);

              // Update balance record
              balance[currency]!.confirmed += tx.amount;

              await save();
            }

            await updateAllUnspents();
          }
        }
      }

      if (message is SyncResponse) {
        if (message.syncStatus is UnsupportedSyncStatus) {
          nodeSupportsSilentPayments = false;
        }

        if (message.syncStatus is SyncingSyncStatus) {
          var status = message.syncStatus as SyncingSyncStatus;
          if (shouldUpdateSyncStatus) syncStatus = SyncingSyncStatus(status.blocksLeft, status.ptc);
        } else {
          if (shouldUpdateSyncStatus) syncStatus = message.syncStatus;
        }

        await walletInfo.updateRestoreHeight(message.height);
      }
    });
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
    );

    final addressRecord = walletAddresses.silentAddresses
        .firstWhereOrNull((address) => address.address == silentPaymentAddress.toString());
    addressRecord?.txCount += 1;
    addressRecord?.balance += unspent.value;

    walletAddresses.addSilentAddresses(
      [unspent.bitcoinAddressRecord as BitcoinSilentPaymentAddressRecord],
    );
  }

  DateTime? _lastSilentPaymentsScan;
  static const Duration _silentPaymentsScanDelay = Duration(minutes: 1);

  @action
  @override
  Future<void> startSync() async {
    try {
      if (syncStatus is SyncronizingSyncStatus) {
        return;
      }

      if (_syncBenchmarkStartTime == null) {
        _syncBenchmarkStartTime = DateTime.now();
        printV('[ELECTRUM_WALLET SYNC] Starting: ${_syncBenchmarkStartTime!}');
      }

      syncStatus = SyncronizingSyncStatus();

      if (hasSilentPaymentsScanning) {
        silentPaymentsScanningActive = alwaysScan ?? false;
        await _setInitialHeight();

        final now = DateTime.now();
        final shouldForceRescan = _lastSilentPaymentsScan == null ||
            now.difference(_lastSilentPaymentsScan!) >= _silentPaymentsScanDelay;

        // Timer prevents server failure and this infinite looping and requesting
        if (shouldForceRescan) {
          _lastSilentPaymentsScan = now;

          final rescanHeights = <int>[];

          transactionHistory.transactions.values.forEach((tx) {
            if (tx.unspents != null && tx.unspents!.isNotEmpty)
              for (final unspent in tx.unspents!) {
                if (unspent.silentPaymentTweak != null && tx.height != null && tx.height! > 0) {
                  rescanHeights.add(tx.height!);
                  break;
                }
              }
          });

          if (rescanHeights.isNotEmpty)
            _setListeners(walletInfo.restoreHeight, rescanHeights: rescanHeights);
        }
      }

      await subscribeForUpdates();
      await checkIfBatchSupported();
      await updateTransactions();

      await updateAllUnspents();
      await updateBalance();
      await updateFeeRates();

      _updateFeeRateTimer ??=
          Timer.periodic(const Duration(minutes: 1), (timer) async => await updateFeeRates());

      if (alwaysScan == true) {
        setSilentPaymentsScanning(true);
      } else {
        if (syncStatus is LostConnectionSyncStatus) {
          return;
        }

        final syncEnd = DateTime.now();
        final totalMs = _syncBenchmarkStartTime != null
            ? syncEnd.difference(_syncBenchmarkStartTime!).inMilliseconds
            : 0;

        printV('[ELECTRUM_WALLET SYNC] Finished: $syncEnd, took ${totalMs} ms');

        _syncBenchmarkStartTime = null;
        syncStatus = SyncedSyncStatus();
      }
    } catch (e, stacktrace) {
      final syncEnd = DateTime.now();
      final totalMs = _syncBenchmarkStartTime != null
          ? syncEnd.difference(_syncBenchmarkStartTime!).inMilliseconds
          : 0;

      printV(stacktrace);
      printV("startSync $e");
      printV('[ELECTRUM_WALLET SYNC] Finished: $syncEnd, took ${totalMs} ms');

      _syncBenchmarkStartTime = null;
      syncStatus = FailedSyncStatus();
    }
  }

  @action
  Future<void> updateFeeRates() async {
    if (await checkIfMempoolAPIIsEnabled() && type == WalletType.bitcoin) {
      try {
        final response = await ProxyWrapper()
            .get(clearnetUri: Uri.parse("https://mempool.cakewallet.com/api/v1/fees/recommended"))
            .timeout(Duration(seconds: 15));

        final result = json.decode(response.body) as Map<String, dynamic>;
        final slowFee = (result['economyFee'] as num?)?.toInt() ?? 0;
        int mediumFee = (result['hourFee'] as num?)?.toInt() ?? 0;
        int fastFee = (result['fastestFee'] as num?)?.toInt() ?? 0;
        if (slowFee == mediumFee) {
          mediumFee++;
        }
        while (fastFee <= mediumFee) {
          fastFee++;
        }
        _feeRates = [slowFee, mediumFee, fastFee];
        return;
      } catch (e) {
        printV(e);
      }
    }

    final feeRates = await electrumClient.feeRates(network: network);
    if (feeRates != [0, 0, 0]) {
      _feeRates = feeRates;
    } else if (isTestnet) {
      _feeRates = [1, 1, 1];
    }
  }

  Node? node;

  Future<bool> getNodeIsElectrs() async {
    if (node == null) {
      return false;
    }

    final version = await electrumClient.version();

    if (version.isNotEmpty) {
      final server = version[0];

      if (server.toLowerCase().contains('electrs')) {
        node!.isElectrs = true;
        // TODO figure out why condition was needed
        // if (node!.isInBox) {
        node!.save();
        // }
        return node!.isElectrs!;
      }
    }

    node!.isElectrs = false;
    return node!.isElectrs!;
  }

  Future<bool> getNodeSupportsSilentPayments() async {
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
    } on electrum.RequestFailedTimeoutException catch (_) {
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
    this.node = node;
    _isBatchSupported = null;

    if (syncStatus is ConnectingSyncStatus) return;

    try {
      syncStatus = ConnectingSyncStatus();

      await _receiveStream?.cancel();
      await electrumClient.close();
      _isBatchSupported = null;

      electrumClient.onConnectionStatusChange = _onConnectionStatusChange;

      await electrumClient.connectToUri(node.uri, useSSL: node.useSSL);
    } catch (e, stacktrace) {
      printV(stacktrace);
      printV("connectToNode $e");
      syncStatus = FailedSyncStatus();
    }
  }

  BigInt get networkDustAmount => BigInt.from(546);

  bool _isBelowDust(BigInt amount) =>
      amount <= networkDustAmount && network != BitcoinNetwork.testnet;

  UtxoDetails _createUTXOS({
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
          return utx.bitcoinAddressRecord.type == SegwitAddresType.mweb;
        case UnspentCoinType.nonMweb:
          return utx.bitcoinAddressRecord.type != SegwitAddresType.mweb;
        case UnspentCoinType.any:
        case UnspentCoinType.lightning:
          return true;
      }
    }).toList();
    final unconfirmedCoins = availableInputs.where((utx) => utx.confirmations == 0).toList();

    // sort the unconfirmed coins so that mweb coins are last:
    availableInputs.sort((a, b) => a.bitcoinAddressRecord.type == SegwitAddresType.mweb ? 1 : -1);

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
      final hd = _hdFor(record: utx.bitcoinAddressRecord);

      if (utx.bitcoinAddressRecord is BitcoinSilentPaymentAddressRecord) {
        final unspentAddress = utx.bitcoinAddressRecord as BitcoinSilentPaymentAddressRecord;
        privkey = ECPrivate.fromHex(
                _masterHD!.derivePath(unspentAddress.spendDerivationPath).privateKey.toHex())
            .tweakAdd(
          BigintUtils.fromBytes(BytesUtils.fromHexString(unspentAddress.silentPaymentTweak!)),
        );
        spendsSilentPayment = true;
        isSilentPayment = true;
      } else if (!isHardwareWallet && keys.privateKey.isNotEmpty) {
        privkey =
            generateECPrivate(hd: hd, index: utx.bitcoinAddressRecord.index, network: network);
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
        pubKeyHex = hd.childKey(Bip32KeyIndex(utx.bitcoinAddressRecord.index)).publicKey.toHex();
      }

      final baseDerivationPath = _accountDerivationPathForRecord(utx.bitcoinAddressRecord);

      final derivationPath = "${_hardenedDerivationPath(baseDerivationPath)}"
          "/${utx.bitcoinAddressRecord.isHidden ? "1" : "0"}"
          "/${utx.bitcoinAddressRecord.index}";
      publicKeys[address.pubKeyHash()] = PublicKeyWithDerivationPath(pubKeyHex, derivationPath);

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
      network: network,
      memo: memo,
      feeRate: feeRate,
      inputPrivKeyInfos: utxoDetails.inputPrivKeyInfos,
      vinOutpoints: utxoDetails.vinOutpoints,
    );

    if (fee == 0) {
      throw BitcoinTransactionNoFeeException();
    }

    // Here, when sending all, the output amount equals to the input value - fee to fully spend every input on the transaction and have no amount left for change
    final amount = BigInt.from(utxoDetails.allInputsAmount - fee);

    if (amount <= BigInt.zero) {
      throw BitcoinTransactionWrongBalanceException(amount: utxoDetails.allInputsAmount + fee);
    }

    // Attempting to send less than the dust limit
    if (_isBelowDust(amount)) {
      throw BitcoinTransactionNoDustException();
    }

    if (outputs.length == 1) {
      outputs[0] = BitcoinOutput(
        address: outputs.last.address,
        value: amount,
        isSilentPayment: hasSilentPayment,
      );
    }

    return EstimatedTxResult(
      utxos: utxoDetails.utxos,
      inputPrivKeyInfos: utxoDetails.inputPrivKeyInfos,
      publicKeys: utxoDetails.publicKeys,
      fee: Money.fromInt(fee, currency),
      amount: Money(amount, currency),
      isSendAll: true,
      hasChange: false,
      memo: memo,
      spendsUnconfirmedTX: utxoDetails.spendsUnconfirmedTX,
      spendsSilentPayment: utxoDetails.spendsSilentPayment,
    );
  }

  Future<EstimatedTxResult> estimateTxForAmount(
    Money credentialsAmount,
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
    if (_isBelowDust(credentialsAmount.amount)) {
      throw BitcoinTransactionNoDustException();
    }

    // if mweb isn't enabled, don't consider spending mweb coins:
    if (this is LitecoinWallet) {
      var mwebEnabled = (this as LitecoinWallet).mwebEnabled;
      if (!mwebEnabled) {
        coinTypeToSpendFrom = UnspentCoinType.nonMweb;
      }
    }

    // If there is only one output, and the amount to send is more than the max spendable amount
    // then it is actually a send all transaction

    if (outputs.length == 1) {
      final maxSpendable = await _maxSpendableNoChangeAmount(
        initialOutput: outputs.first,
        feeRate: feeRate,
        memo: memo,
        hasSilentPayment: hasSilentPayment,
        coinTypeToSpendFrom: coinTypeToSpendFrom,
      );
      if (credentialsAmount > maxSpendable) {
        throw BitcoinTransactionWrongBalanceException();
      }
      if (credentialsAmount >= maxSpendable) {
        final estimateOutput = [
          BitcoinOutput(
            address: outputs.first.address,
            value: BigInt.zero,
            isSilentPayment: outputs.first.isSilentPayment,
          )
        ];
        return estimateSendAllTx(
          estimateOutput,
          feeRate,
          memo: memo,
          hasSilentPayment: hasSilentPayment,
          coinTypeToSpendFrom: coinTypeToSpendFrom,
        );
      }
    }

    final utxoDetails = _createUTXOS(
      sendAll: false,
      credentialsAmount: credentialsAmount.amount.toInt(),
      inputsCount: inputsCount,
      paysToSilentPayment: hasSilentPayment,
      coinTypeToSpendFrom: coinTypeToSpendFrom,
    );

    final spendingAllCoins = utxoDetails.availableInputs.length == utxoDetails.utxos.length;
    final spendingAllConfirmedCoins = !utxoDetails.spendsUnconfirmedTX &&
        utxoDetails.utxos.length ==
            utxoDetails.availableInputs.length - utxoDetails.unconfirmedCoins.length;

    final amountLeftForChangeAndFee =
        utxoDetails.allInputsAmount - credentialsAmount.amount.toInt();

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
      coinTypeToSpendFrom: coinTypeToSpendFrom,
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

    // Must match the address' account root (purpose/coinType) and legacy derivation when applicable.
    final changeBaseDerivationPath = _accountDerivationPathForRecord(changeAddress);
    final changeDerivationPath = "${_hardenedDerivationPath(changeBaseDerivationPath)}"
        "/${changeAddress.isHidden ? "1" : "0"}"
        "/${changeAddress.index}";
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
      network: network,
      memo: memo,
      feeRate: feeRate,
      inputPrivKeyInfos: utxoDetails.inputPrivKeyInfos,
      vinOutpoints: utxoDetails.vinOutpoints,
    );

    updatedOutputs.clear();
    for (int i = 0; i < temp.length; i++) {
      final output = temp[i];
      final oldOutput = outputs[i];

      updatedOutputs.add(BitcoinOutput(
        address: output.address,
        value: output.value,
        isSilentPayment: oldOutput.isSilentPayment,
        isChange: output.isChange,
      ));
    }

    if (fee == 0) {
      throw BitcoinTransactionNoFeeException();
    }

    var amount = credentialsAmount;
    final lastOutput = updatedOutputs.last;
    final amountLeftForChange = BigInt.from(amountLeftForChangeAndFee - fee);

    if (_isBelowDust(amountLeftForChange)) {
      // If has change that is lower than dust, will end up with tx rejected by network rules
      // so remove the change amount
      updatedOutputs.removeLast();
      outputs.removeLast();

      // If the computed change is negative or below dust:
      //   - negative: try a no-change tx (recalculate fee without change)
      //   - non-negative but dust: drop change and add remainder to fee
      if (amountLeftForChange < BigInt.zero) {
        final tempNoChange = outputs.map((o) => o).toList();
        final feeNoChange = await calcFee(
          utxos: utxoDetails.utxos,
          outputs: tempNoChange,
          network: network,
          memo: memo,
          feeRate: feeRate,
          inputPrivKeyInfos: utxoDetails.inputPrivKeyInfos,
          vinOutpoints: utxoDetails.vinOutpoints,
        );
        final leftover =
            utxoDetails.allInputsAmount - credentialsAmount.amount.toInt() - feeNoChange;

        if (leftover >= 0) {
          final finalFee = feeNoChange + leftover; // absorb tiny remainder
          return EstimatedTxResult(
            utxos: utxoDetails.utxos,
            inputPrivKeyInfos: utxoDetails.inputPrivKeyInfos,
            publicKeys: utxoDetails.publicKeys,
            fee: Money.fromInt(finalFee, currency),
            amount: amount,
            hasChange: false,
            isSendAll: spendingAllCoins,
            memo: memo,
            spendsUnconfirmedTX: utxoDetails.spendsUnconfirmedTX,
            spendsSilentPayment: utxoDetails.spendsSilentPayment,
          );
        }

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

      // if the amount left for change is less than dust, but not less than 0
      // then add it to the fees
      fee += amountLeftForChange.toInt();

      return EstimatedTxResult(
        utxos: utxoDetails.utxos,
        inputPrivKeyInfos: utxoDetails.inputPrivKeyInfos,
        publicKeys: utxoDetails.publicKeys,
        fee: Money.fromInt(fee, currency),
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
        value: amountLeftForChange,
        isSilentPayment: lastOutput.isSilentPayment,
        isChange: true,
      );
      outputs[outputs.length - 1] = BitcoinOutput(
        address: lastOutput.address,
        value: amountLeftForChange,
        isSilentPayment: lastOutput.isSilentPayment,
        isChange: true,
      );

      return EstimatedTxResult(
        utxos: utxoDetails.utxos,
        inputPrivKeyInfos: utxoDetails.inputPrivKeyInfos,
        publicKeys: utxoDetails.publicKeys,
        fee: Money.fromInt(fee, currency),
        amount: amount,
        hasChange: true,
        isSendAll: spendingAllCoins,
        memo: memo,
        spendsUnconfirmedTX: utxoDetails.spendsUnconfirmedTX,
        spendsSilentPayment: utxoDetails.spendsSilentPayment,
      );
    }
  }

  Future<Money> _maxSpendableNoChangeAmount({
    required BitcoinOutput initialOutput,
    required int feeRate,
    String? memo,
    bool hasSilentPayment = false,
    UnspentCoinType coinTypeToSpendFrom = UnspentCoinType.any,
  }) async {
    final utxoDetailsAll = _createUTXOS(
      sendAll: true,
      paysToSilentPayment: hasSilentPayment,
      coinTypeToSpendFrom: coinTypeToSpendFrom,
    );

    final output = [
      BitcoinOutput(
        address: initialOutput.address,
        value: BigInt.zero,
        isSilentPayment: initialOutput.isSilentPayment,
      )
    ];

    final feeNoChange = await calcFee(
      utxos: utxoDetailsAll.utxos,
      outputs: output,
      network: network,
      memo: memo,
      feeRate: feeRate,
      inputPrivKeyInfos: utxoDetailsAll.inputPrivKeyInfos,
      vinOutpoints: utxoDetailsAll.vinOutpoints,
    );

    final maxSpendable = utxoDetailsAll.allInputsAmount - feeNoChange;
    return Money.fromInt(maxSpendable > 0 ? maxSpendable : 0, currency);
  }

  Future<int> calcFee({
    required List<UtxoWithAddress> utxos,
    required List<BitcoinBaseOutput> outputs,
    required BasedUtxoNetwork network,
    String? memo,
    required int feeRate,
    List<ECPrivateInfo>? inputPrivKeyInfos,
    List<Outpoint>? vinOutpoints,
  }) async {
    int estimatedSize;
    if (network is BitcoinCashNetwork) {
      estimatedSize = ForkedTransactionBuilder.estimateTransactionSize(
        utxos: utxos,
        outputs: outputs,
        network: network,
        memo: memo,
      );
    } else {
      estimatedSize = BitcoinTransactionBuilder.estimateTransactionSize(
        utxos: utxos,
        outputs: outputs,
        network: network,
        memo: memo,
        inputPrivKeyInfos: inputPrivKeyInfos,
        vinOutpoints: vinOutpoints,
      );
    }

    return feeAmountWithFeeRate(feeRate, 0, 0, size: estimatedSize);
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    try {
      // start by updating unspent coins
      await updateAllUnspents();

      final outputs = <BitcoinOutput>[];
      final transactionCredentials = credentials as BitcoinTransactionCredentials;
      final hasMultiDestination = transactionCredentials.outputs.length > 1;
      final sendAll = !hasMultiDestination && transactionCredentials.outputs.first.sendAll;
      final memo = transactionCredentials.outputs.first.memo;
      final coinTypeToSpendFrom = transactionCredentials.coinTypeToSpendFrom;

      var credentialsAmount = Money.zero(currency);
      var hasSilentPayment = false;

      for (final out in transactionCredentials.outputs) {
        final outputAmount = out.cryptoAmount;

        if (!sendAll && _isBelowDust(outputAmount.amount)) {
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
            value: BigInt.zero,
            isSilentPayment: isSilentPayment,
          ));
        } else {
          outputs.add(BitcoinOutput(
            address: address,
            value: outputAmount.amount,
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

      for (final output in updatedOutputs) {
        // TODO: get from server
        // if (output.isSilentPayment && output.value.toInt() > silentPaymentsMin) {
        if (output.isSilentPayment && output.value.toInt() <= 1000) {
          throw BitcoinTransactionNoDustException();
        }
      }

      if (walletInfo.isHardwareWallet) {
        final transaction = await buildHardwareWalletTransaction(
          utxos: estimatedTx.utxos,
          outputs: updatedOutputs,
          publicKeys: estimatedTx.publicKeys,
          fee: estimatedTx.fee.amount,
          network: network,
          memo: estimatedTx.memo,
          // Shuffle so the change output isn't placed deterministically last
          // (privacy fingerprint). Applied by orderOutputs in the builder.
          outputOrdering: BitcoinOrdering.shuffle,
          enableRBF: true,
          cwOutputs: transactionCredentials.outputs,
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
          hasTaprootInputs: false,
          // ToDo: (Konsti) Support Taproot,
          isViewOnly: false,
        )..addListener((transaction) async {
            transactionHistory.addOne(transaction);
            await updateBalance();
            await updateAllUnspents();
          });
      }

      BasedBitcoinTransacationBuilder txb;
      if (network is BitcoinCashNetwork) {
        txb = ForkedTransactionBuilder(
          utxos: estimatedTx.utxos,
          outputs: updatedOutputs,
          fee: estimatedTx.fee.amount,
          network: network,
          memo: estimatedTx.memo,
          // Shuffle so the change output isn't placed deterministically last
          // (privacy fingerprint). Change is found by isChange, not position.
          inputOrdering: BitcoinOrdering.shuffle,
          outputOrdering: BitcoinOrdering.shuffle,
          enableRBF: !estimatedTx.spendsUnconfirmedTX,
        );
      } else {
        txb = BitcoinTransactionBuilder(
          utxos: estimatedTx.utxos,
          outputs: updatedOutputs,
          fee: estimatedTx.fee.amount,
          network: network,
          memo: estimatedTx.memo,
          inputOrdering: BitcoinOrdering.shuffle,
          outputOrdering: BitcoinOrdering.shuffle,
          enableRBF: !estimatedTx.spendsUnconfirmedTX,
        );
      }

      bool hasTaprootInputs = false;

      final transaction = txb.buildTransaction((txDigest, utxo, publicKey, sighash) {
        if (keys.privateKey.isEmpty) return "";
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
        derivedOutputs: updatedOutputs,
        publicKeys: estimatedTx.publicKeys,
        isViewOnly: keys.privateKey.isEmpty,
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
          await updateAllUnspents();
        });
    } catch (e) {
      throw e;
    }
  }

  HardwareWalletService? hardwareWalletService;

  Future<BtcTransaction> buildHardwareWalletTransaction({
    required List<BitcoinBaseOutput> outputs,
    required BigInt fee,
    required BasedUtxoNetwork network,
    required List<UtxoWithAddress> utxos,
    required List<OutputInfo> cwOutputs,
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
        'lightningBalance': balance[CryptoCurrency.btcln]?.toJSON(),
        'derivationTypeIndex': derivationInfo.derivationType?.index,
        'derivationPath': derivationInfo.derivationPath,
        'silent_addresses': walletAddresses.silentAddresses.map((addr) => addr.toJSON()).toList(),
        'silent_address_index': walletAddresses.currentSilentAddressIndex.toString(),
        'mweb_addresses': walletAddresses.mwebAddresses.map((addr) => addr.toJSON()).toList(),
        'alwaysScan': alwaysScan,
        'useLightning': useLightning,
        'cachedLightningAddress': walletAddresses.lightningAddress
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
    if (!(await WalletKeysFile.hasKeysFile(walletInfo.name, walletInfo.type))) {
      await saveKeysFile(_password, encryptionFileUtils);
      saveKeysFile(_password, encryptionFileUtils, true);
    }

    final path = await makePath();
    await encryptionFileUtils.write(path: path, password: _password, data: toJSON());
    await transactionHistory.save();
  }

  @override
  Future<void> changePassword(String password) async {
    _password = password;
    await save();
    await transactionHistory.changePassword(password);
  }

  @action
  @override
  Future<void> rescan({required int height, bool? doSingleScan}) async {
    if (keys.privateKey.isEmpty) return;

    silentPaymentsScanningActive = true;
    _setListeners(height, doSingleScan: doSingleScan);
  }

  @override
  Future<void> close({bool shouldCleanup = false}) async {
    try {
      await _receiveStream?.cancel();
      await electrumClient.close();
      _isBatchSupported = null;
    } catch (_) {}
    _autoSaveTimer?.cancel();
    _updateFeeRateTimer?.cancel();
  }

  @action
  Future<void> updateAllUnspents() async {
    List<BitcoinUnspent> updatedUnspentCoins = [];

    final previousUnspentCoins = List<BitcoinUnspent>.from(unspentCoins.where((utxo) =>
        utxo.bitcoinAddressRecord.type != SegwitAddresType.mweb &&
        utxo.bitcoinAddressRecord is! BitcoinSilentPaymentAddressRecord));

    if (hasSilentPaymentsScanning) {
      // Update unspents stored from scanned silent payment transactions
      transactionHistory.transactions.values.forEach((tx) {
        if (tx.unspents != null) {
          updatedUnspentCoins.addAll(tx.unspents!);
        }
      });
    }

    // Set the balance of all non-silent payment and non-mweb addresses to 0 before updating

    final targetAddresses = walletAddresses.allAddresses
        .where((element) => element.type != SegwitAddresType.mweb)
        .toList();

    for (final addr in targetAddresses) {
      if (addr is! BitcoinSilentPaymentAddressRecord) {
        addr.balance = 0;
      }
    }

    final results = shouldUseBatchFetching
        ? await _fetchUnspentsBatch(targetAddresses)
        : await _fetchUnspentsRegular(targetAddresses);

    final failedCount = results.where((result) => result == null).length;

    if (failedCount == 0) {
      for (final result in results) {
        updatedUnspentCoins.addAll(result!);
      }
      unspentCoins = updatedUnspentCoins;
    } else {
      if (updatedUnspentCoins.isEmpty) {
        unspentCoins = handleFailedUtxoFetch(
          failedCount: failedCount,
          previousUnspentCoins: previousUnspentCoins,
          updatedUnspentCoins: updatedUnspentCoins,
          results: results,
        );
      } else {
        unspentCoins = updatedUnspentCoins;
      }
    }

    final currentWalletUnspentCoins =
        unspentCoinsInfo.values.where((element) => element.walletId == id);

    if (currentWalletUnspentCoins.length != updatedUnspentCoins.length) {
      unspentCoins.forEach((coin) => addCoinInfo(coin));
    }

    await updateCoins(unspentCoins);
    await _refreshUnspentCoinsInfo();
  }

  Future<List<List<BitcoinUnspent>?>> _fetchUnspentsRegular(
    List<BitcoinAddressRecord> addresses,
  ) async {
    final addressFutures = addresses.map((address) => fetchUnspent(address)).toList();
    return Future.wait(addressFutures);
  }

  Future<List<List<BitcoinUnspent>?>> _fetchUnspentsBatch(
    List<BitcoinAddressRecord> addresses,
  ) async {
    final byScriptHash = <String, BitcoinAddressRecord>{
      for (final address in addresses) address.getScriptHash(network): address,
    };

    final scriptHashes = byScriptHash.keys.toList();

    try {
      final unspentByScriptHash =
          await _processChunksToMap<String, String, List<Map<String, dynamic>>>(
        items: scriptHashes,
        chunkSize: addressHistoryChunkSize,
        processChunk: _getListUnspentBatch,
      );

      final txHashes = <String>{};
      final coinsByScriptHash = <String, List<BitcoinUnspent>>{};

      for (final entry in unspentByScriptHash.entries) {
        final addressRecord = byScriptHash[entry.key];
        if (addressRecord == null) continue;

        final coins = <BitcoinUnspent>[];

        for (final unspent in entry.value) {
          final coin = BitcoinUnspent.fromJSON(addressRecord, unspent);
          coin.isChange = addressRecord.isHidden;
          coins.add(coin);
          txHashes.add(coin.hash);
        }

        coinsByScriptHash[entry.key] = coins;
      }

      final txInfoByHash = await fetchTransactionInfoBatch(
        hashes: txHashes.toList(),
        retryOnFailure: true,
        retryDelay: const Duration(seconds: 1),
      );

      for (final coins in coinsByScriptHash.values) {
        for (final coin in coins) {
          final tx = txInfoByHash[coin.hash];
          coin.confirmations = tx?.confirmations;
          coin.isPegOut = tx?.isHogEx;
        }
      }

      return addresses.map((address) {
        final scriptHash = address.getScriptHash(network);
        return coinsByScriptHash[scriptHash] ?? <BitcoinUnspent>[];
      }).toList();
    } catch (e) {
      printV('fetchUnspentsBatch failed: $e');
      return List<List<BitcoinUnspent>?>.filled(addresses.length, null);
    }
  }

  List<BitcoinUnspent> handleFailedUtxoFetch({
    required int failedCount,
    required List<BitcoinUnspent> previousUnspentCoins,
    required List<BitcoinUnspent> updatedUnspentCoins,
    required List<List<BitcoinUnspent>?> results,
  }) {
    if (failedCount == results.length) {
      printV("All UTXOs failed to fetch, falling back to previous UTXOs");
      return previousUnspentCoins;
    }

    final successfulUtxos = <BitcoinUnspent>[];
    for (final result in results) {
      if (result != null) {
        successfulUtxos.addAll(result);
      }
    }

    if (failedCount > 0 && successfulUtxos.isEmpty) {
      printV("Some UTXOs failed, but no successful UTXOs, falling back to previous UTXOs");
      return previousUnspentCoins;
    }

    if (failedCount > 0) {
      printV("Some UTXOs failed, updating with successful UTXOs");
      updatedUnspentCoins.addAll(successfulUtxos);
    }

    return updatedUnspentCoins;
  }

  Future<void> updateCoins(List<BitcoinUnspent> newUnspentCoins) async {
    if (newUnspentCoins.isEmpty) {
      return;
    }

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
        addCoinInfo(coin);
      }
    });
  }

  @action
  Future<void> updateUnspentsForAddress(BitcoinAddressRecord address) async {
    final newUnspentCoins = await fetchUnspent(address);
    await updateCoins(newUnspentCoins ?? []);
  }

  @action
  Future<List<BitcoinUnspent>?> fetchUnspent(BitcoinAddressRecord address) async {
    List<BitcoinUnspent> updatedUnspentCoins = [];

    final unspents = await electrumClient.getListUnspent(address.getScriptHash(network));

    // Failed to fetch unspents
    if (unspents == null) return null;

    await Future.wait(unspents.map((unspent) async {
      try {
        final coin = BitcoinUnspent.fromJSON(address, unspent);
        final tx = await fetchTransactionInfo(hash: coin.hash);
        coin.isChange = address.isHidden;
        coin.confirmations = tx?.confirmations;
        coin.isPegOut = tx?.isHogEx;

        updatedUnspentCoins.add(coin);
      } catch (_) {}
    }));

    return updatedUnspentCoins;
  }

  @action
  Future<void> addCoinInfo(BitcoinUnspent coin) async {
    // Check if the coin is already in the unspentCoinsInfo for the wallet
    final existingCoinInfo = unspentCoinsInfo.values.firstWhereOrNull(
      (element) =>
          element.walletId == walletInfo.id &&
          element.hash == coin.hash &&
          element.vout == coin.vout,
    );

    if (existingCoinInfo == null) {
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
  }

  Future<void> _refreshUnspentCoinsInfo() async {
    try {
      final List<dynamic> keys = [];
      final currentWalletUnspentCoins =
          unspentCoinsInfo.values.where((record) => record.walletId == id);

      for (final element in currentWalletUnspentCoins) {
        if (element.isFrozen) continue;
        if (RegexUtils.addressTypeFromStr(element.address, network) is MwebAddress) continue;

        final existUnspentCoins = unspentCoins.where((coin) => element == coin);

        if (existUnspentCoins.isEmpty) {
          keys.add(element.key);
        }
      }

      if (keys.isNotEmpty) {
        await unspentCoinsInfo.deleteAll(keys);
      }
    } catch (e) {
      printV("refreshUnspentCoinsInfo $e");
    }
  }

  Future<void> cleanUpDuplicateUnspentCoins() async {
    final currentWalletUnspentCoins =
        unspentCoinsInfo.values.where((element) => element.walletId == id);
    final Map<String, UnspentCoinsInfo> uniqueUnspentCoins = {};
    final List<dynamic> duplicateKeys = [];

    for (final unspentCoin in currentWalletUnspentCoins) {
      final key = '${unspentCoin.hash}:${unspentCoin.vout}';
      if (!uniqueUnspentCoins.containsKey(key)) {
        uniqueUnspentCoins[key] = unspentCoin;
      } else {
        duplicateKeys.add(unspentCoin.key);
      }
    }

    if (duplicateKeys.isNotEmpty) await unspentCoinsInfo.deleteAll(duplicateKeys);
  }

  int transactionVSize(String transactionHex) => BtcTransaction.fromRaw(transactionHex).getVSize();

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

    final ownAddresses = walletAddresses.allAddresses.map((addr) => addr.address).toSet();

    final receiverAmount = outputs
        .where((output) =>
            !ownAddresses.contains(addressFromOutputScript(output.scriptPubKey, network)))
        .fold<int>(0, (sum, output) => sum + output.amount.toInt());

    if (receiverAmount == 0) {
      throw Exception("Receiver output not found.");
    }

    final availableInputs = unspentCoins.where((utxo) => utxo.isSending && !utxo.isFrozen).toList();
    int totalBalance = availableInputs.fold<int>(
        0, (previousValue, element) => previousValue + element.value.toInt());

    int allInputsAmount = 0;
    for (int i = 0; i < bundle.originalTransaction.inputs.length; i++) {
      final input = bundle.originalTransaction.inputs[i];
      final inputTransaction = bundle.ins[i];
      if (inputTransaction == null) {
        throw Exception("Missing input transaction for fee calculation");
      }
      final vout = input.txIndex;
      final outTransaction = inputTransaction.outputs[vout];
      allInputsAmount += outTransaction.amount.toInt();
    }

    final totalOutAmount = bundle.originalTransaction.outputs
        .fold<int>(0, (previousValue, element) => previousValue + element.amount.toInt());
    var currentFee = allInputsAmount - totalOutAmount;

    final remainingFee = (newFee - currentFee > 0) ? newFee - currentFee : newFee;
    return totalBalance - receiverAmount - remainingFee >= networkDustAmount.toInt();
  }

  Future<PendingBitcoinTransaction> replaceByFee(String hash, int newFee) async {
    try {
      final bundle = await getTransactionExpanded(hash: hash);

      final utxos = <UtxoWithAddress>[];
      final outputs = <BitcoinOutput>[];
      List<ECPrivate> privateKeys = [];

      var allInputsAmount = 0;
      String? memo;

      // Add original inputs
      for (var i = 0; i < bundle.originalTransaction.inputs.length; i++) {
        final input = bundle.originalTransaction.inputs[i];
        final inputTransaction = bundle.ins[i];
        if (inputTransaction == null) {
          throw Exception("Missing input transaction for replace-by-fee");
        }
        final vout = input.txIndex;
        final outTransaction = inputTransaction.outputs[vout];
        final address = addressFromOutputScript(outTransaction.scriptPubKey, network);
        allInputsAmount += outTransaction.amount.toInt();

        final addressRecord =
            walletAddresses.allAddresses.firstWhere((element) => element.address == address);
        final btcAddress = RegexUtils.addressTypeFromStr(addressRecord.address, network);

        final hd = _hdFor(record: addressRecord);

        final privkey = generateECPrivate(hd: hd, index: addressRecord.index, network: network);

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

      // Add original outputs
      for (final out in bundle.originalTransaction.outputs) {
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
      var remainingFee = BigInt.from(newFee - currentFee);

      if (remainingFee <= BigInt.zero) {
        throw Exception("New fee must be higher than the current fee.");
      }

      // Deduct fee from change outputs first, if possible
      if (remainingFee > BigInt.zero) {
        final changeAddresses = walletAddresses.allAddresses.where((element) => element.isHidden);
        for (int i = outputs.length - 1; i >= 0; i--) {
          final output = outputs[i];
          final isChange = changeAddresses
              .any((element) => element.address == output.address.toAddress(network));

          if (isChange) {
            final outputAmount = output.value;
            if (outputAmount > networkDustAmount) {
              final deduction = (outputAmount - networkDustAmount >= remainingFee)
                  ? remainingFee
                  : outputAmount - networkDustAmount;
              outputs[i] = BitcoinOutput(address: output.address, value: outputAmount - deduction);
              remainingFee -= deduction;

              if (remainingFee <= BigInt.zero) break;
            }
          }
        }
      }

      // If still not enough, add UTXOs until the fee is covered
      if (remainingFee > BigInt.zero) {
        final unusedUtxos = unspentCoins
            .where((utxo) => utxo.isSending && !utxo.isFrozen && utxo.confirmations! > 0)
            .toList();

        for (final utxo in unusedUtxos) {
          final address = RegexUtils.addressTypeFromStr(utxo.address, network);

          final hd = _hdFor(record: utxo.bitcoinAddressRecord);

          final privkey = generateECPrivate(
            hd: hd,
            index: utxo.bitcoinAddressRecord.index,
            network: network,
          );
          privateKeys.add(privkey);

          utxos.add(UtxoWithAddress(
            utxo: BitcoinUtxo(
                txHash: utxo.hash,
                value: BigInt.from(utxo.value),
                vout: utxo.vout,
                scriptType: _getScriptType(address)),
            ownerDetails:
                UtxoAddressDetails(publicKey: privkey.getPublic().toHex(), address: address),
          ));

          allInputsAmount += utxo.value;
          remainingFee -= BigInt.from(utxo.value);

          if (remainingFee < BigInt.zero) {
            final changeOutput = outputs.firstWhereOrNull((output) => walletAddresses.allAddresses
                .any((addr) => addr.address == output.address.toAddress(network)));
            if (changeOutput != null) {
              final newValue = changeOutput.value + (-remainingFee);
              outputs[outputs.indexOf(changeOutput)] =
                  BitcoinOutput(address: changeOutput.address, value: newValue);
            } else {
              final changeAddress = await walletAddresses.getChangeAddress();
              outputs.add(BitcoinOutput(
                  address: RegexUtils.addressTypeFromStr(changeAddress.address, network),
                  value: -remainingFee));
            }

            remainingFee = BigInt.zero;
            break;
          }

          if (remainingFee <= BigInt.zero) break;
        }
      }

      // Deduct from the receiver's output if remaining fee is still greater than 0
      if (remainingFee > BigInt.zero) {
        for (int i = 0; i < outputs.length; i++) {
          final output = outputs[i];
          final outputAmount = output.value;

          if (outputAmount > networkDustAmount) {
            final deduction = (outputAmount - networkDustAmount >= remainingFee)
                ? remainingFee
                : outputAmount - networkDustAmount;

            outputs[i] = BitcoinOutput(address: output.address, value: outputAmount - deduction);
            remainingFee -= deduction;

            if (remainingFee <= BigInt.zero) break;
          }
        }
      }

      // Final check if the remaining fee couldn't be deducted
      if (remainingFee > BigInt.zero) {
        throw Exception("Not enough funds to cover the fee.");
      }

      // Identify all change outputs
      final changeAddresses = walletAddresses.allAddresses.where((element) => element.isHidden);
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
        inputOrdering: BitcoinOrdering.shuffle,
        outputOrdering: BitcoinOrdering.shuffle,
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
        amount: Money.fromInt(sendingAmount, currency),
        fee: Money.fromInt(newFee, currency),
        network: network,
        hasChange: changeOutputs.isNotEmpty,
        feeRate: newFee.toString(),
        isViewOnly: keys.privateKey.isEmpty,
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
          await updateAllUnspents();
        });
    } catch (e) {
      throw e;
    }
  }

  Future<ElectrumTransactionBundle> getTransactionExpanded(
      {required String hash, int? height}) async {
    String transactionHex;
    int? time;
    int? confirmations;

    final verboseTransaction = await electrumClient.getTransactionVerbose(hash: hash);

    if (verboseTransaction.isEmpty) {
      transactionHex = await electrumClient.getTransactionHex(hash: hash);

      if (height != null && height > 0 && await checkIfMempoolAPIIsEnabled()) {
        try {
          final blockHash = await ProxyWrapper()
              .get(
                clearnetUri: Uri.parse(
                  "https://mempool.cakewallet.com/api/v1/block-height/$height",
                ),
              )
              .timeout(Duration(seconds: 15));

          if (blockHash.statusCode == 200 &&
              blockHash.body.isNotEmpty &&
              jsonDecode(blockHash.body) != null) {
            final blockResponse = await ProxyWrapper()
                .get(
                  clearnetUri: Uri.parse(
                    "https://mempool.cakewallet.com/api/v1/block/${blockHash.body}",
                  ),
                )
                .timeout(Duration(seconds: 15));
            if (blockResponse.statusCode == 200 &&
                blockResponse.body.isNotEmpty &&
                jsonDecode(blockResponse.body)['timestamp'] != null) {
              time = int.parse(jsonDecode(blockResponse.body)['timestamp'].toString());
            }
          }
        } catch (_) {}
      }
    } else {
      transactionHex = verboseTransaction['hex'] as String;
      time = verboseTransaction['time'] as int?;
      confirmations = verboseTransaction['confirmations'] as int?;
    }

    if (height != null) {
      if (time == null && height > 0) {
        time = (getDateByBitcoinHeight(height).millisecondsSinceEpoch / 1000).round();
      }

      if (confirmations == null) {
        final tip = await getUpdatedChainTip();
        if (tip > 0 && height > 0) {
          // Add one because the block itself is the first confirmation
          confirmations = tip - height + 1;
        }
      }
    }

    final original = BtcTransaction.fromRaw(transactionHex);
    final ins = <BtcTransaction?>[];

    for (final vin in original.inputs) {
      try {
        final verboseTransaction = await electrumClient.getTransactionVerbose(hash: vin.txId);

        final String inputTransactionHex;

        if (verboseTransaction.isEmpty) {
          inputTransactionHex = await electrumClient.getTransactionHex(hash: vin.txId);
        } else {
          inputTransactionHex = verboseTransaction['hex'] as String;
        }

        ins.add(inputTransactionHex.isEmpty ? null : BtcTransaction.fromRaw(inputTransactionHex));
      } catch (_) {
        ins.add(null);
      }
    }

    return ElectrumTransactionBundle(
      original,
      ins: ins,
      time: time,
      confirmations: confirmations ?? 0,
    );
  }

  Future<ElectrumTransactionInfo?> fetchTransactionInfo(
      {required String hash, int? height, bool? retryOnFailure}) async {
    try {
      return ElectrumTransactionInfo.fromElectrumBundle(
        await getTransactionExpanded(hash: hash, height: height),
        walletInfo.type,
        network,
        addresses: addressesSet,
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

  bool isMine(Script script) {
    final derivedAddress = addressFromOutputScript(script, network);
    return addressesSet.contains(derivedAddress);
  }

  @override
  Future<Map<String, ElectrumTransactionInfo>> fetchTransactions() async {
    try {
      final Map<String, ElectrumTransactionInfo> historiesWithDetails = {};
      ;

      printV('[BATCH_TEST] Fetching transactions with batch: $shouldUseBatchFetching');

      if (type == WalletType.bitcoin) {
        await Future.wait(BITCOIN_ADDRESS_TYPES.map((type) => shouldUseBatchFetching
            ? fetchTransactionsForAddressTypeBatch(historiesWithDetails, type)
            : fetchTransactionsForAddressType(historiesWithDetails, type)));
      } else if (type == WalletType.bitcoinCash) {
        await Future.wait(BITCOIN_CASH_ADDRESS_TYPES.map((type) => shouldUseBatchFetching
            ? fetchTransactionsForAddressTypeBatch(historiesWithDetails, type)
            : fetchTransactionsForAddressType(historiesWithDetails, type)));
      } else if (type == WalletType.litecoin) {
        await Future.wait(LITECOIN_ADDRESS_TYPES.where((type) => type != SegwitAddresType.mweb).map(
            (type) => shouldUseBatchFetching
                ? fetchTransactionsForAddressTypeBatch(historiesWithDetails, type)
                : fetchTransactionsForAddressType(historiesWithDetails, type)));
      } else if (type == WalletType.dogecoin) {
        await Future.wait(DOGECOIN_ADDRESS_TYPES.map((type) => shouldUseBatchFetching
            ? fetchTransactionsForAddressTypeBatch(historiesWithDetails, type)
            : fetchTransactionsForAddressType(historiesWithDetails, type)));
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
      printV("fetchTransactions $e");
      return {};
    }
  }

  Future<void> fetchTransactionsForAddressType(
    Map<String, ElectrumTransactionInfo> historiesWithDetails,
    BitcoinAddressType type,
  ) async {

    final addressesByType =
    walletAddresses.allAddresses.where((addr) => addr.type == type).toList();

    final receiveStandard = getAddressBranchByType(hidden: false, legacy: false, type: type);
    final changeStandard = getAddressBranchByType(hidden: true,  legacy: false, type: type);
    final receiveLegacy = getAddressBranchByType(hidden: false, legacy: true, type: type);
    final changeLegacy = getAddressBranchByType(hidden: true,  legacy: true, type: type);

    walletAddresses.hiddenAddresses.addAll([...changeStandard, ...changeLegacy].map((e) => e.address));
    await walletAddresses.saveAddressesInBox();
    await Future.wait(addressesByType.map((addressRecord) async {
      final history = await _fetchAddressHistory(addressRecord, await getCurrentChainTip());

      if (history.isNotEmpty) {
        addressRecord.txCount = history.length;
        historiesWithDetails.addAll(history);

        final matchedAddresses = addressRecord.isHidden
            ? (addressRecord.isLegacyDerivation ? changeLegacy : changeStandard)
            : (addressRecord.isLegacyDerivation ? receiveLegacy : receiveStandard);
        final isUsedAddressAboveGap = matchedAddresses.toList().indexOf(addressRecord) >=
            matchedAddresses.length -
                (addressRecord.isHidden
                    ? ElectrumWalletAddressesBase.defaultChangeAddressesCount
                    : ElectrumWalletAddressesBase.defaultReceiveAddressesCount);

        if (isUsedAddressAboveGap) {
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
            isLegacyDerivation: addressRecord.isLegacyDerivation,
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
    String txid = "";

    try {
      final Map<String, ElectrumTransactionInfo> historiesWithDetails = {};

      final history = await electrumClient.getHistory(addressRecord.getScriptHash(network));

      if (history.isNotEmpty) {
        addressRecord.setAsUsed();
        walletAddresses.clearLockIfMatches(addressRecord.type, addressRecord.address);

        if (this is BitcoinWallet) {
          //removes transactions no longer returned by the api, presumed replaced/invalid.
          transactionHistory.transactions.removeWhere(
            (hash, tx) =>
                tx.outputAddresses != null &&
                tx.outputAddresses!.contains(addressRecord.address) &&
                !history.any((newTransaction) => newTransaction['tx_hash'] == hash),
          );
        }

        await Future.wait(history.map((transaction) async {
          txid = transaction['tx_hash'] as String;
          final height = transaction['height'] as int;
          final storedTx = transactionHistory.transactions[txid];

          if (storedTx != null) {
            if (height > 0) {
              storedTx.height = height;
              // the tx's block itself is the first confirmation so add 1
              if ((currentHeight ?? 0) > 0) {
                storedTx.confirmations = currentHeight! - height + 1;
              }
              storedTx.isPending = storedTx.confirmations == 0;
            }

            historiesWithDetails[txid] = storedTx;
          } else {
            final tx = await fetchTransactionInfo(hash: txid, height: height, retryOnFailure: true);

            if (tx != null) {
              historiesWithDetails[txid] = tx;

              // Got a new transaction fetched, add it to the transaction history
              // instead of waiting all to finish, and next time it will be faster

              _applyLitecoinPegOutTag(tx);
              transactionHistory.addOne(tx);
              await transactionHistory.save();
            }
          }

          return Future.value(null);
        }));
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

  Future<void> fetchTransactionsForAddressTypeBatch(
      Map<String, ElectrumTransactionInfo> historiesWithDetails, BitcoinAddressType type) async {

    final receiveStandard = getAddressBranchByType(hidden: false, legacy: false, type: type);
    final changeStandard = getAddressBranchByType(hidden: true,  legacy: false, type: type);
    final receiveLegacy = getAddressBranchByType(hidden: false, legacy: true, type: type);
    final changeLegacy = getAddressBranchByType(hidden: true,  legacy: true, type: type);

    walletAddresses.hiddenAddresses.addAll([...changeStandard, ...changeLegacy].map((e) => e.address));
    await walletAddresses.saveAddressesInBox();

    await fetchTransactionsForAddressesBranchBatch(
      historiesWithDetails,
      type,
      receiveStandard,
      isHidden: false,
      isLegacyDerivation: false,
    );

    await fetchTransactionsForAddressesBranchBatch(
      historiesWithDetails,
      type,
      changeStandard,
      isHidden: true,
      isLegacyDerivation: false,
    );

    await fetchTransactionsForAddressesBranchBatch(
      historiesWithDetails,
      type,
       receiveLegacy,
      isHidden: false,
      isLegacyDerivation: true,
    );

    await fetchTransactionsForAddressesBranchBatch(
      historiesWithDetails,
      type,
      changeLegacy,
      isHidden: true,
      isLegacyDerivation: true,
    );
  }

  Future<void> fetchTransactionsForAddressesBranchBatch(
    Map<String, ElectrumTransactionInfo> historiesWithDetails,
    BitcoinAddressType type,
    List<BitcoinAddressRecord> branchAddresses, {
    required bool isHidden,
    required bool isLegacyDerivation,
  }) async {
    if (branchAddresses.isEmpty) return;

    final tip = await getCurrentChainTip();
    final currentBranch = [...branchAddresses];

    final initialHistory =
        await _processChunksToMap<BitcoinAddressRecord, String, ElectrumTransactionInfo>(
      items: currentBranch,
      chunkSize: addressHistoryChunkSize,
      processChunk: (chunk) => _fetchBatchAddressHistory(
        chunk,
        tip,
        addressHistoryChunkSize,
      ),
    );

    if (initialHistory.isNotEmpty) {
      historiesWithDetails.addAll(initialHistory);
    }

    final gapLimit = isHidden
        ? ElectrumWalletAddressesBase.defaultChangeAddressesCount
        : ElectrumWalletAddressesBase.defaultReceiveAddressesCount;

    final highestUsedIndex = _highestUsedIndex(currentBranch);
    final shouldDiscover =
        highestUsedIndex >= 0 && highestUsedIndex >= currentBranch.length - gapLimit;

    if (!shouldDiscover) return;

    final newAddresses = await walletAddresses.discoverAddressesBatch(
      currentBranch,
      isHidden,
      (newAddresses) async {
        final newHistory = await _fetchBatchAddressHistory(
          newAddresses,
          tip,
          discoveryHistoryChunkSize,
        );

        if (newHistory.isNotEmpty) {
          historiesWithDetails.addAll(newHistory);
        }

        return newAddresses
            .where((addressRecord) => addressRecord.isUsed)
            .map((addressRecord) => addressRecord.address)
            .toSet();
      },
      type: type,
      isLegacyDerivation: isLegacyDerivation,
    );

    if (newAddresses.isNotEmpty) {
      currentBranch.addAll(newAddresses);

      if (isHidden) {
        walletAddresses.hiddenAddresses.addAll(newAddresses.map((e) => e.address));
        await walletAddresses.saveAddressesInBox();
      }
    }
  }

  List<BitcoinAddressRecord> getAddressBranchByType({required bool hidden, required bool legacy, required BitcoinAddressType
  type}) => walletAddresses.allAddresses.where((addr) => addr.type == type && addr.isHidden == hidden && addr.isLegacyDerivation == legacy)
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));

  int _highestUsedIndex(List<BitcoinAddressRecord> addresses) {
    for (int i = addresses.length - 1; i >= 0; i--) {
      if (addresses[i].isUsed) return i;
    }
    return -1;
  }

  Future<Map<String, ElectrumTransactionInfo>> _fetchBatchAddressHistory(
      List<BitcoinAddressRecord> addressRecords, int? currentHeight, int historyChunkSize) async {
    String lastTxId = '';
    bool didUpdateHistory = false;

    try {
      final Map<String, ElectrumTransactionInfo> historiesWithDetails = {};

      // List of script hashes for the given address records
      final scriptHashes = addressRecords.map((a) => a.getScriptHash(network)).toList();

      final historyByScriptHash =
          await _processChunksToMap<String, String, List<Map<String, dynamic>>>(
              items: scriptHashes, chunkSize: historyChunkSize, processChunk: _getHistoryBatch);

      // Map scriptHash -> addressRecord
      final byScriptHash = <String, BitcoinAddressRecord>{};
      for (final a in addressRecords) {
        byScriptHash[a.getScriptHash(network)] = a;
      }

      // Split into already-known txs vs missing txs
      final missingHistoryItems = <Map<String, dynamic>>[];

      for (final entry in historyByScriptHash.entries) {
        final sh = entry.key;
        final addressRecord = byScriptHash[sh];
        if (addressRecord == null) continue;

        final history = entry.value;
        if (history.isEmpty) continue;

        addressRecord.setAsUsed();
        walletAddresses.clearLockIfMatches(addressRecord.type, addressRecord.address);

        //removes transactions no longer returned by the api, presumed replaced/invalid.
        if (this is BitcoinWallet) {
          final beforeLen = transactionHistory.transactions.length;
          transactionHistory.transactions.removeWhere((hash, tx) {
            return tx.outputAddresses != null &&
                tx.outputAddresses!.contains(addressRecord.address) &&
                !history.any((h) => h['tx_hash'] == hash);
          });
          if (transactionHistory.transactions.length != beforeLen) {
            didUpdateHistory = true;
          }
        }

        // For each transaction in the history, check if we already have it in our transaction history. If we do, update its details if necessary. If we don't, add it to the list of missing history items to fetch later.
        for (final item in history) {
          final txid = item['tx_hash'] as String?;
          final height = item['height'] as int? ?? 0;
          if (txid == null || txid.isEmpty) continue;

          lastTxId = txid;

          final storedTx = transactionHistory.transactions[txid];
          if (storedTx != null) {
            if (height > 0) {
              final oldHeight = storedTx.height;
              final oldConfs = storedTx.confirmations;
              final oldPending = storedTx.isPending;

              storedTx.height = height;

              if ((currentHeight ?? 0) > 0) {
                storedTx.confirmations = currentHeight! - height + 1;
              }

              storedTx.isPending = storedTx.confirmations == 0;

              if (storedTx.height != oldHeight ||
                  storedTx.confirmations != oldConfs ||
                  storedTx.isPending != oldPending) {
                transactionHistory.addOne(storedTx);
                didUpdateHistory = true;
              }
            }

            historiesWithDetails[txid] = storedTx;
          } else {
            missingHistoryItems.add({
              'tx_hash': txid,
              'height': height,
              'script_hash': sh,
              'address': addressRecord.address,
            });
          }
        }
      }

      // Batch fetch missing tx verbose details
      if (missingHistoryItems.isEmpty) {
        if (didUpdateHistory) await transactionHistory.save();
        return historiesWithDetails;
      }

      for (var i = 0; i < missingHistoryItems.length; i += historyChunkSize) {
        final end = (i + historyChunkSize < missingHistoryItems.length)
            ? i + historyChunkSize
            : missingHistoryItems.length;
        final chunkHistory = missingHistoryItems.sublist(i, end);

        final hashes = chunkHistory
            .map((e) => (e['tx_hash'] as String).trim())
            .where((h) => h.isNotEmpty)
            .toList(growable: false);

        final heightsByHash = <String, int?>{
          for (final e in chunkHistory) (e['tx_hash'] as String): (e['height'] as int?),
        };

        final infosByHash = await fetchTransactionInfoBatch(
          hashes: hashes,
          heightsByHash: heightsByHash,
          retryOnFailure: true,
          retryDelay: const Duration(seconds: 1),
        );

        for (final txid in hashes) {
          final tx = infosByHash[txid];
          if (tx == null) continue;

          historiesWithDetails[tx.id] = tx;

          _applyLitecoinPegOutTag(tx);

          transactionHistory.addOne(tx);
          didUpdateHistory = true;
        }
      }

      if (didUpdateHistory) {
        await transactionHistory.save();
      }

      return historiesWithDetails;
    } catch (e, stacktrace) {
      final prefix = lastTxId.isNotEmpty ? '$lastTxId - ' : '';
      _onError?.call(FlutterErrorDetails(
        exception: '$prefix$e',
        stack: stacktrace,
        library: runtimeType.toString(),
      ));
      return {};
    }
  }

  Future<Map<String, Map<String, dynamic>>> _getTransactionVerboseBatch(List<String> hashes) {
    return electrumClient.getBatchTransactionVerbose(
      hashes,
      timeout: transactionBatchTimeoutMs,
    );
  }

  Future<Map<String, String?>> _getTransactionHexBatch(List<String> hashes) {
    return electrumClient.getBatchTransactionHex(
      hashes,
      timeout: transactionBatchTimeoutMs,
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> _getHistoryBatch(List<String> scriptHashes) {
    return electrumClient.getBatchHistory(
      scriptHashes,
      timeout: transactionBatchTimeoutMs,
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> _getListUnspentBatch(List<String> scriptHashes) {
    return electrumClient.getBatchUnspent(
      scriptHashes,
      timeout: transactionBatchTimeoutMs,
    );
  }

  Future<Map<String, Map<String, dynamic>>> _getBalanceBatch(List<String> scriptHashes) {
    return electrumClient.getBatchBalance(
      scriptHashes,
      timeout: transactionBatchTimeoutMs,
    );
  }

  Future<Map<String, ElectrumTransactionInfo?>> fetchTransactionInfoBatch({
    required List<String> hashes,
    Map<String, int?>? heightsByHash,
    bool retryOnFailure = false,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    final result = <String, ElectrumTransactionInfo?>{};
    final uniqueHashes = hashes.map((h) => h.trim()).where((h) => h.isNotEmpty).toSet().toList();

    if (uniqueHashes.isEmpty) return result;

    await _processTransactionInfoBatch(
      txIds: uniqueHashes,
      result: result,
      heightsByHash: heightsByHash,
    );

    if (retryOnFailure) {
      final failedHashes = uniqueHashes.where((txId) => result[txId] == null).toList();

      if (failedHashes.isNotEmpty) {
        await Future.delayed(retryDelay);

        await _processTransactionInfoBatch(
          txIds: failedHashes,
          result: result,
          heightsByHash: heightsByHash,
        );
      }
    }

    return result;
  }

  Future<void> _processTransactionInfoBatch({
    required List<String> txIds,
    required Map<String, ElectrumTransactionInfo?> result,
    required Map<String, int?>? heightsByHash,
  }) async {
    for (var i = 0; i < txIds.length; i += transactionChunkSize) {
      final end =
          (i + transactionChunkSize < txIds.length) ? i + transactionChunkSize : txIds.length;
      final chunk = txIds.sublist(i, end);

      final bundlesByHash = await getTransactionExpandedBatch(
        hashes: chunk,
        heightsByHash: heightsByHash,
      );

      for (final txId in chunk) {
        try {
          final bundle = bundlesByHash[txId];
          if (bundle == null) {
            result[txId] = null;
            continue;
          }

          final info = ElectrumTransactionInfo.fromElectrumBundle(
            bundle,
            walletInfo.type,
            network,
            addresses: addressesSet,
            height: heightsByHash?[txId],
          );
          info.id = txId;
          result[txId] = info;
        } catch (_) {
          result[txId] = null;
        }
      }
    }
  }

  Future<Map<String, ElectrumTransactionBundle>> getTransactionExpandedBatch(
      {required List<String> hashes, Map<String, int?>? heightsByHash}) async {
    final bundles = <String, ElectrumTransactionBundle>{};
    if (hashes.isEmpty) return bundles;

    final verboseByHash = await _fetchTransactionVerboseBatch(hashes);

    final originalByHash = _parseTransactions(verboseByHash);

    final inputTxIdsByHash = _collectInputTxIdsByHash(originalByHash);

    final allInputTxids = <String>{};
    for (final txids in inputTxIdsByHash.values) {
      allInputTxids.addAll(txids);
    }

    final inputTxIds = allInputTxids.toList(growable: false);

    final inputVerboseByTxId = inputTxIds.isEmpty
        ? <String, Map<String, dynamic>>{}
        : await _fetchTransactionVerboseBatch(inputTxIds);

    final parsedInputTxById = _parseTransactions(inputVerboseByTxId);

    return _buildTransactionBundlesBatch(
      unique: hashes,
      heightsByHash: heightsByHash,
      tip: await getUpdatedChainTip(),
      originalByHash: originalByHash,
      verboseByHash: verboseByHash,
      inputTxidsByHash: inputTxIdsByHash,
      parsedInputTxById: parsedInputTxById,
    );
  }

  Future<Map<String, Map<String, dynamic>>> _fetchTransactionVerboseBatch(
      List<String> txIds) async {
    final verboseTransactionByHash =
        await _processChunksToMap<String, String, Map<String, dynamic>>(
      items: txIds,
      chunkSize: transactionChunkSize,
      processChunk: _getTransactionVerboseBatch,
    );

    final emptyHex = <String>[];
    for (final txId in txIds) {
      final vTx = verboseTransactionByHash[txId];
      if (vTx == null || vTx.isEmpty || vTx['hex'] == null) {
        emptyHex.add(txId);
      }
    }

    final hexByHash = await _processChunksToMap<String, String, String?>(
      items: emptyHex,
      chunkSize: transactionChunkSize,
      processChunk: _getTransactionHexBatch,
    );

    for (final txId in txIds) {
      final verbose = verboseTransactionByHash[txId] ?? <String, dynamic>{};
      if ((verbose['hex'] as String?) == null) {
        final hex = hexByHash[txId];
        if (hex != null && hex.isNotEmpty) {
          verboseTransactionByHash[txId] = {
            ...verbose,
            'hex': hex,
          };
        }
      }
    }

    return verboseTransactionByHash;
  }

  Map<String, BtcTransaction> _parseTransactions(
    Map<String, Map<String, dynamic>> verboseByHash,
  ) {
    final result = <String, BtcTransaction>{};

    for (final entry in verboseByHash.entries) {
      final hex = entry.value['hex'] as String?;
      if (hex == null || hex.isEmpty) continue;

      try {
        result[entry.key] = BtcTransaction.fromRaw(hex);
      } catch (_) {}
    }

    return result;
  }

  Map<String, List<String>> _collectInputTxIdsByHash(
    Map<String, BtcTransaction> originalByHash,
  ) {
    final inputTxIdsByHash = <String, List<String>>{};

    for (final entry in originalByHash.entries) {
      final txId = entry.key;
      final original = entry.value;

      final inputTxIds = <String>[];
      for (final vin in original.inputs) {
        inputTxIds.add(vin.txId);
      }

      inputTxIdsByHash[txId] = inputTxIds;
    }

    return inputTxIdsByHash;
  }

  Future<Map<String, ElectrumTransactionBundle>> _buildTransactionBundlesBatch({
    required List<String> unique,
    required Map<String, int?>? heightsByHash,
    required int tip,
    required Map<String, BtcTransaction> originalByHash,
    required Map<String, Map<String, dynamic>> verboseByHash,
    required Map<String, List<String>> inputTxidsByHash,
    required Map<String, BtcTransaction> parsedInputTxById,
  }) async {
    final bundles = <String, ElectrumTransactionBundle>{};

    // Identify heights that need mempool timestamp lookup
    final heightsNeedingTime = <int>{};
    for (final txid in originalByHash.keys) {
      final verbose = verboseByHash[txid] ?? const <String, dynamic>{};
      final time = verbose['time'] as int?;
      final h = heightsByHash?[txid];
      if (time == null && h != null && h > 0) {
        heightsNeedingTime.add(h);
      }
    }

    final mempoolTimes = await _fetchBlockTimestampsFromMempoolByHeights(heightsNeedingTime);

    for (final txid in unique) {
      final original = originalByHash[txid];
      if (original == null) continue;

      final verbose = verboseByHash[txid] ?? const <String, dynamic>{};

      int? time = verbose['time'] as int?;
      int? confirmations = verbose['confirmations'] as int?;
      final h = heightsByHash?[txid];

      if (h != null) {
        if (time == null && h > 0) {
          final mp = mempoolTimes[h];
          time = mp ?? (getDateByBitcoinHeight(h).millisecondsSinceEpoch / 1000).round();
        }

        if (confirmations == null && tip > 0 && h > 0) {
          confirmations = tip - h + 1;
          if (confirmations < 0) confirmations = 0;
        }
      }

      final inputTxids = inputTxidsByHash[txid] ?? const <String>[];

      final ins = <BtcTransaction?>[
        for (final inputTxid in inputTxids) parsedInputTxById[inputTxid],
      ];

      bundles[txid] = ElectrumTransactionBundle(
        original,
        ins: ins,
        time: time,
        confirmations: confirmations ?? 0,
      );
    }

    return bundles;
  }

  Future<Map<int, int>> _fetchBlockTimestampsFromMempoolByHeights(
    Set<int> heights,
  ) async {
    final out = <int, int>{};
    if (heights.isEmpty) return out;
    if (!(await checkIfMempoolAPIIsEnabled())) return out;

    // Best-effort: if any call fails, we just skip that height.
    await Future.wait(heights.map((h) async {
      try {
        final blockHashResp = await ProxyWrapper()
            .get(
              clearnetUri: Uri.parse(
                'https://mempool.cakewallet.com/api/v1/block-height/$h',
              ),
            )
            .timeout(const Duration(seconds: 15));

        if (blockHashResp.statusCode != 200 || blockHashResp.body.isEmpty) return;

        final blockHash = blockHashResp.body.trim();
        if (blockHash.isEmpty) return;

        final blockResp = await ProxyWrapper()
            .get(
              clearnetUri: Uri.parse(
                'https://mempool.cakewallet.com/api/v1/block/$blockHash',
              ),
            )
            .timeout(const Duration(seconds: 15));

        if (blockResp.statusCode != 200 || blockResp.body.isEmpty) return;

        final decoded = jsonDecode(blockResp.body);
        final ts = decoded is Map<String, dynamic> ? decoded['timestamp'] : null;
        if (ts == null) return;

        final parsed = int.tryParse(ts.toString());
        if (parsed == null) return;

        out[h] = parsed;
      } catch (_) {
        // ignore
      }
    }));

    return out;
  }

  Future<Map<K, V>> _processChunksToMap<T, K, V>({
    required List<T> items,
    required int chunkSize,
    required Future<Map<K, V>> Function(List<T> chunk) processChunk,
    void Function(List<T> chunk, Object error)? onChunkError,
  }) async {
    final result = <K, V>{};

    for (var i = 0; i < items.length; i += chunkSize) {
      final end = (i + chunkSize < items.length) ? i + chunkSize : items.length;
      final chunk = items.sublist(i, end);

      try {
        final chunkResult = await processChunk(chunk);
        result.addAll(chunkResult);
      } on electrum.RequestFailedTimeoutException catch (e) {
        onChunkError?.call(chunk, e);
        continue;
      } catch (e) {
        onChunkError?.call(chunk, e);
        continue;
      }
    }

    return result;
  }

  Future<void> updateTransactions() async {
    printV("updateTransactions() called!");
    try {
      if (_isTransactionUpdating) {
        return;
      }
      currentChainTip = await getUpdatedChainTip();

      bool updated = false;
      transactionHistory.transactions.values.forEach((tx) {
        if ((tx.height ?? 0) > 0 && (currentChainTip ?? 0) > 0) {
          var confirmations = currentChainTip! - tx.height! + 1;
          if (confirmations < 0) {
            // if our chain tip is outdated then it could lead to negative confirmations so this is just a failsafe:
            confirmations = 0;
          }
          if (confirmations != tx.confirmations) {
            updated = true;
            tx.confirmations = confirmations;
            transactionHistory.addOne(tx);
          }
        }
      });

      if (updated) {
        await transactionHistory.save();
      }

      _isTransactionUpdating = true;
      await fetchTransactions();
      walletAddresses.updateReceiveAddresses();
      _isTransactionUpdating = false;
    } catch (e, stacktrace) {
      printV(stacktrace);
      printV(e);
      _isTransactionUpdating = false;
    }
  }

  Future<void> subscribeForUpdates() async {
    final unsubscribedScriptHashes = walletAddresses.allAddresses.where(
      (address) =>
          !_scripthashesUpdateSubject.containsKey(address.getScriptHash(network)) &&
          address.type != SegwitAddresType.mweb,
    );

    await Future.wait(unsubscribedScriptHashes.map((address) async {
      final sh = address.getScriptHash(network);
      if (!(_scripthashesUpdateSubject[sh]?.isClosed ?? true)) {
        try {
          await _scripthashesUpdateSubject[sh]?.close();
        } catch (e) {
          printV("failed to close: $e");
        }
      }
      try {
        _scripthashesUpdateSubject[sh] = await electrumClient.scripthashUpdate(sh);
      } catch (e) {
        printV("failed scripthashUpdate: $e");
      }
      _scripthashesUpdateSubject[sh]?.listen((event) async {
        try {
          await updateUnspentsForAddress(address);

          await updateBalance();

          await _fetchAddressHistory(address, await getCurrentChainTip());
        } catch (e, s) {
          printV("sub error: $e");
          _onError?.call(FlutterErrorDetails(
            exception: e,
            stack: s,
            library: this.runtimeType.toString(),
          ));
        }
      }, onError: (e, s) {
        printV("sub_listen error: $e $s");
      });
    }));
  }

  Future<List<Map<String, dynamic>>> fetchBalancesBatch(
    List<BitcoinAddressRecord> addresses,
  ) async {
    final scriptHashes = addresses.map((address) => address.getScriptHash(network)).toList();

    if (scriptHashes.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    try {
      final balancesByScriptHash = await _processChunksToMap<String, String, Map<String, dynamic>>(
        items: scriptHashes,
        chunkSize: addressHistoryChunkSize,
        processChunk: _getBalanceBatch,
      );

      final balances = scriptHashes
          .map((scriptHash) => balancesByScriptHash[scriptHash] ?? <String, dynamic>{})
          .toList();

      final hasMissingBalance = balances.any((balance) => balance['confirmed'] == null);
      if (hasMissingBalance) {
        printV('fetchBalancesBatch returned missing balances, falling back to regular flow');
        return fetchBalancesRegular(addresses);
      }

      return balances;
    } catch (e) {
      printV('fetchBalancesBatch failed, falling back to regular flow: $e');
      return fetchBalancesRegular(addresses);
    }
  }

  Future<List<Map<String, dynamic>>> fetchBalancesRegular(
    List<BitcoinAddressRecord> addresses,
  ) async {
    final balanceFutures = <Future<Map<String, dynamic>>>[];

    for (final address in addresses) {
      final sh = address.getScriptHash(network);
      balanceFutures.add(electrumClient.getBalance(sh));
    }

    return Future.wait(balanceFutures);
  }

  Future<ElectrumBalance> fetchBalances() async {
    final addresses = walletAddresses.allAddresses
        .where((address) => address.address.isNotEmpty)
        .where((address) => RegexUtils.addressTypeFromStr(address.address, network) is! MwebAddress)
        .toList();

    final balances = shouldUseBatchFetching
        ? await fetchBalancesBatch(addresses)
        : await fetchBalancesRegular(addresses);

    printV(
        'Fetched balances for ${addresses.length} addresses. Batch fetching: $shouldUseBatchFetching');

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

    unspentCoinsInfo.values.forEach((info) {
      unspentCoins.forEach((element) {
        if (element.bitcoinAddressRecord is BitcoinSilentPaymentAddressRecord) return;

        if (element.hash == info.hash &&
            element.vout == info.vout &&
            element.bitcoinAddressRecord.address == info.address &&
            element.value == info.value) {
          if (info.isFrozen) {
            totalFrozen += element.value;
          }
        }
      });
    });

    if (balances.isNotEmpty && balances.first['confirmed'] == null) {
      // if we got null balance responses from the server, set our connection status to lost and return our last known balance:
      printV("got null balance responses from the server, setting connection status to lost");
      syncStatus = LostConnectionSyncStatus();
      return balance[currency] ??
          ElectrumBalance(
            confirmed: Money.zero(currency),
            unconfirmed: Money.zero(currency),
            frozen: Money.zero(currency),
          );
    }

    for (var i = 0; i < balances.length; i++) {
      final addressRecord = addresses[i];
      final balance = balances[i];
      final confirmed = balance['confirmed'] as int? ?? 0;
      final unconfirmed = balance['unconfirmed'] as int? ?? 0;
      totalConfirmed += confirmed;
      totalUnconfirmed += unconfirmed;

      addressRecord.balance = confirmed + unconfirmed;
      if (confirmed > 0 || unconfirmed > 0) {
        addressRecord.setAsUsed();
        walletAddresses.clearLockIfMatches(addressRecord.type, addressRecord.address);
      }
    }

    return ElectrumBalance(
      confirmed: Money.fromInt(totalConfirmed, currency),
      unconfirmed: Money.fromInt(totalUnconfirmed, currency),
      frozen: Money.fromInt(totalFrozen, currency),
    );
  }

  Future<void> updateBalance() async {
    printV("updateBalance() called!");
    balance[currency] = await fetchBalances();
    await save();
  }

  @override
  Future<bool> checkNodeHealth() async {
    try {
      final addresses = walletAddresses.allAddresses
          .where(
              (address) => RegexUtils.addressTypeFromStr(address.address, network) is! MwebAddress)
          .toList();

      if (addresses.isEmpty) {
        return false;
      }

      final firstAddress = addresses.first;
      final sh = firstAddress.getScriptHash(network);
      await electrumClient.getBalance(sh, throwOnError: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void setExceptionHandler(void Function(FlutterErrorDetails) onError) => _onError = onError;

  @override
  Future<String> signMessage(String message, {String? address = null}) async {
    final addressRecord = address != null
        ? walletAddresses.allAddresses.firstWhereOrNull((addr) => addr.address == address)
        : null;

    if (addressRecord != null && addressRecord.type == SegwitAddresType.p2tr) {
      throw UnsupportedError("Cannot sign message with Taproot address");
    }

    final hd = addressRecord != null
        ? _hdFor(record: addressRecord).childKey(Bip32KeyIndex(addressRecord.index))
        : mainHd;

    final priv = ECPrivate.fromHex(hd.privateKey.privKey.toHex());

    String messagePrefix = '\x18Bitcoin Signed Message:\n';
    final hexEncoded = priv.signMessage(utf8.encode(message), messagePrefix: messagePrefix);
    final decodedSig = hex.decode(hexEncoded);
    return base64Encode(decodedSig);
  }

  void _applyLitecoinPegOutTag(ElectrumTransactionInfo tx) {
    if (this is! LitecoinWallet) return;

    // if we have a peg out transaction with the same value
    // that matches this received transaction, mark it as being from a peg out:
    for (final tx2 in transactionHistory.transactions.values) {
      final heightDiff = ((tx2.height ?? 0) - (tx.height ?? 0)).abs();
      // this isn't a perfect matching algorithm since we don't have the right input/output information from these transaction models (the addresses are in different formats), but this should be more than good enough for now as it's extremely unlikely a user receives the EXACT same amount from 2 different sources and one of them is a peg out and the other isn't WITHIN 5 blocks of each other
      if (tx2.additionalInfo["isPegOut"] == true && tx2.amount == tx.amount && heightDiff <= 5) {
        tx.additionalInfo["fromPegOut"] = true;
      }
    }
  }

  Future<void> checkIfBatchSupported() async {
    if (_isBatchSupported != null) {
      printV('[BATCH_TEST] Already checked: $_isBatchSupported');
      return;
    }

    final hashes = publicScriptHashes.take(batchTestHashesCount).toList();

    if (hashes.length < batchTestHashesCount) {
      _isBatchSupported = false;
      printV('[BATCH_TEST] Failed: not enough script hashes');
      return;
    }

    try {
      final paramsList = hashes.map((hash) => <Object>[hash]).toList();

      printV('[BATCH_TEST] Start: hashes=${hashes.length}, timeout=${batchTestTimeoutMs}ms');

      final result = await electrumClient.callBatchWithTimeout(
        method: 'blockchain.scripthash.get_history',
        paramsList: paramsList,
        timeout: batchTestTimeoutMs,
      );

      final hasError = result.any((item) =>
          item is Map<String, dynamic> && item.containsKey('error') && item['error'] != null);

      if (hasError) {
        _isBatchSupported = false;
        printV('[BATCH_TEST] Result: supported=false (server returned error)');
        return;
      }

      _isBatchSupported = true;
      printV('[BATCH_TEST] Result: supported=true');
    } on electrum.RequestFailedTimeoutException catch (e) {
      _isBatchSupported = false;
      printV('[BATCH_TEST] Timeout: $e');
    } catch (e) {
      _isBatchSupported = false;
      printV('[BATCH_TEST] Exception: $e');
    }
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

  Future<void> _setInitialHeight() async {
    if (_chainTipUpdateSubject != null) return;

    currentChainTip = await getUpdatedChainTip();

    if ((currentChainTip == null || currentChainTip! == 0) && walletInfo.restoreHeight == 0) {
      await walletInfo.updateRestoreHeight(currentChainTip!);
    }

    _chainTipUpdateSubject = electrumClient.chainTipSubscribe();
    _chainTipUpdateSubject?.listen((e) async {
      final event = e as Map<String, dynamic>;
      final height = int.tryParse(event['height'].toString());

      if (height != null) {
        currentChainTip = height;

        if (alwaysScan == true && syncStatus is SyncedSyncStatus) {
          _setListeners(walletInfo.restoreHeight);
        }
      }
    });
  }

  static String _hardenedDerivationPath(String derivationPath) =>
      derivationPath.substring(0, derivationPath.lastIndexOf("'") + 1);

  @action
  void _onConnectionStatusChange(electrum.ConnectionStatus status) {
    switch (status) {
      case electrum.ConnectionStatus.connected:
        if (syncStatus is NotConnectedSyncStatus ||
            syncStatus is LostConnectionSyncStatus ||
            syncStatus is ConnectingSyncStatus) {
          syncStatus = ConnectedSyncStatus();
        }

        break;
      case electrum.ConnectionStatus.disconnected:
        // Always show disconnected status when connection is lost, regardless of current sync state
        if (syncStatus is! NotConnectedSyncStatus) {
          syncStatus = NotConnectedSyncStatus();
        }
        break;
      case electrum.ConnectionStatus.failed:
        if (syncStatus is! LostConnectionSyncStatus) {
          syncStatus = LostConnectionSyncStatus();
        }
        break;
      case electrum.ConnectionStatus.connecting:
        if (syncStatus is! ConnectingSyncStatus) {
          syncStatus = ConnectingSyncStatus();
        }
        break;
    }
  }

  void _syncStatusReaction(SyncStatus syncStatus) async {
    printV("SYNC_STATUS_CHANGE: ${syncStatus}");
    if (syncStatus is SyncingSyncStatus) {
      return;
    }

    if (syncStatus is NotConnectedSyncStatus || syncStatus is LostConnectionSyncStatus) {
      // Needs to re-subscribe to all scripthashes when reconnected
      _scripthashesUpdateSubject = {};

      if (_isTryingToConnect) return;

      _isTryingToConnect = true;

      Timer(Duration(seconds: 5), () {
        if (this.syncStatus is NotConnectedSyncStatus ||
            this.syncStatus is LostConnectionSyncStatus) {
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
        if (inputTransaction == null) continue;
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

  /// Checks the health of the socket connection
  /// and triggers a full reconnection if needed
  @override
  Future<bool> checkSocketHealth() async {
    try {
      SocketHealthLogger().logHealthCheck(
        walletType: type,
        walletName: name,
        syncStatus: syncStatus.toString(),
        wasReconnected: false,
        trigger: 'socket_health_check_start',
      );

      if (!electrumClient.isConnected || !electrumClient.isInternalStateConsistent) {
        if (!electrumClient.isConnected) {
          SocketHealthLogger().logHealthCheck(
            walletType: type,
            walletName: name,
            isHealthy: false,
            syncStatus: syncStatus.toString(),
            wasReconnected: false,
            trigger: 'socket_health_check_socket_not_connected',
          );
        }

        if (!electrumClient.isInternalStateConsistent) {
          SocketHealthLogger().logHealthCheck(
            walletType: type,
            walletName: name,
            isHealthy: false,
            syncStatus: syncStatus.toString(),
            wasReconnected: false,
            trigger: 'socket_health_check_internal_state_inconsistent',
          );
        }

        await _performFullReconnection();

        SocketHealthLogger().logHealthCheck(
          walletType: type,
          walletName: name,
          isHealthy: true,
          syncStatus: syncStatus.toString(),
          wasReconnected: true,
          trigger:
              'socket_health_check_reconnection_success_for_unhealthy_basic_check_or_internal_state_inconsistent',
        );

        return true;
      }

      // Make a call to the server to check if the connection is healthy
      // If the call fails, we need to reconnect
      try {
        final result = await electrumClient.call(
          method: 'server.version',
          params: ['', '1.4'],
        );

        if (result == null) {
          throw Exception('Call mechanism test returned null');
        }

        SocketHealthLogger().logHealthCheck(
          walletType: type,
          walletName: name,
          isHealthy: true,
          syncStatus: syncStatus.toString(),
          wasReconnected: false,
          trigger: 'socket_health_check_server_state_ok',
        );

        return true;
      } catch (e) {
        SocketHealthLogger().logHealthCheck(
          walletType: type,
          walletName: name,
          isHealthy: false,
          error: e.toString(),
          syncStatus: syncStatus.toString(),
          wasReconnected: false,
          trigger: 'socket_health_check_server_state_failed',
        );

        await _performFullReconnection();

        SocketHealthLogger().logHealthCheck(
          walletType: type,
          walletName: name,
          isHealthy: true,
          syncStatus: syncStatus.toString(),
          wasReconnected: true,
          trigger: 'socket_health_check_reconnection_success_for_server_state_failed',
        );

        return true;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> _performFullReconnection() async {
    try {
      SocketHealthLogger().logHealthCheck(
        walletType: type,
        walletName: name,
        syncStatus: syncStatus.toString(),
        wasReconnected: true,
        trigger: 'full_reconnection_start',
      );

      await _receiveStream?.cancel();

      await electrumClient.close();

      if (node != null) {
        electrumClient.onConnectionStatusChange = _onConnectionStatusChange;

        await electrumClient.connectToUri(node!.uri, useSSL: node!.useSSL);

        await startSync();

        SocketHealthLogger().logHealthCheck(
          walletType: type,
          walletName: name,
          isHealthy: true,
          syncStatus: syncStatus.toString(),
          wasReconnected: true,
          trigger: 'full_reconnection_success',
        );
      }
    } catch (e) {
      SocketHealthLogger().logHealthCheck(
        walletType: type,
        walletName: name,
        isHealthy: false,
        error: e.toString(),
        syncStatus: syncStatus.toString(),
        wasReconnected: false,
        trigger: 'full_reconnection_failed',
      );

      syncStatus = FailedSyncStatus();
    }
  }

  Bip32Slip10Secp256k1 _hdFor({required BaseBitcoinAddressRecord record}) {
    final addrType = record.type;

    if (record.isLegacyDerivation) {
      if (record.isHidden) {
        return walletAddresses.legacySideHd;
      } else {
        return walletAddresses.legacyMainHd;
      }
    }

    if (record.isHidden) {
      return sideHdByType[addrType] ?? sideHd;
    } else {
      return mainHdByType[addrType] ?? mainHd;
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
  final Bip32Slip10Secp256k1 masterHD;
  final int height;
  final ScanNode? node;
  final BasedUtxoNetwork network;
  final int chainTip;
  final electrum.ElectrumClient electrumClient;
  final List<String> transactionHistoryIds;
  final Map<String, String> labels;
  final List<int> labelIndexes;
  final bool isSingleScan;
  final String debugLogPath;
  final List<int>? rescanHeights;

  ScanData({
    required this.sendPort,
    required this.silentAddress,
    required this.masterHD,
    required this.height,
    required this.node,
    required this.network,
    required this.chainTip,
    required this.electrumClient,
    required this.transactionHistoryIds,
    required this.labels,
    required this.labelIndexes,
    required this.isSingleScan,
    required this.debugLogPath,
    required this.rescanHeights,
  });

  factory ScanData.fromHeight(ScanData scanData, int newHeight) {
    return ScanData(
      sendPort: scanData.sendPort,
      silentAddress: scanData.silentAddress,
      masterHD: scanData.masterHD,
      height: newHeight,
      node: scanData.node,
      network: scanData.network,
      chainTip: scanData.chainTip,
      transactionHistoryIds: scanData.transactionHistoryIds,
      electrumClient: scanData.electrumClient,
      labels: scanData.labels,
      labelIndexes: scanData.labelIndexes,
      isSingleScan: scanData.isSingleScan,
      debugLogPath: scanData.debugLogPath,
      rescanHeights: scanData.rescanHeights,
    );
  }
}

class SyncResponse {
  final int height;
  final SyncStatus syncStatus;

  SyncResponse(this.height, this.syncStatus);
}

Future<void> _handleScanSilentPayments(ScanData scanData) async {
  final shouldUpdateSyncStatus = scanData.rescanHeights == null || scanData.rescanHeights!.isEmpty;
  final hasForcedRescanHeights = !shouldUpdateSyncStatus;
  CakeTor.instance = await CakeTorInstance.getInstance();

  var node = scanData.node?.uri ?? Uri.parse("tcp://electrs.cakewallet.com:50001");

  void log(String message, LogLevel level) {
    printV("[Scanning] $message", file: scanData.debugLogPath, level: level);
  }

  try {
    // if (scanData.shouldSwitchNodes) {
    var scanningClient = await ElectrumProvider.connect(
      ElectrumTCPService.connect(node),
    );
    // }

    log("connected to ${node.toString()}", LogLevel.info);

    final receivers = [
      Receiver(
        scanData.silentAddress.b_scan.toHex(),
        scanData.silentAddress.B_spend.toHex(),
        scanData.network == BitcoinNetwork.testnet,
        scanData.labelIndexes,
        scanData.labelIndexes.length,
      ),
      Receiver(
        scanData.masterHD.derivePath(SILENT_PAYMENTS_SCAN_PATH_TESTNET).privateKey.toHex(),
        scanData.masterHD.derivePath(SILENT_PAYMENTS_SPEND_PATH_TESTNET).publicKey.toHex(),
        scanData.network == BitcoinNetwork.testnet,
        scanData.labelIndexes,
        scanData.labelIndexes.length,
      )
    ];

    log(
      "using receiver: b_scan: ${scanData.silentAddress.b_scan.toHex()}, b_spend: ${scanData.silentAddress.B_spend.toHex()}, network: ${scanData.network.value}, labelIndexes: ${scanData.labelIndexes}",
      LogLevel.info,
    );
    log(
      "using receiver: b_scan: ${receivers[1].bScan}, b_spend: ${receivers[1].BSpend}, network: ${scanData.network.value}, labelIndexes: ${scanData.labelIndexes}",
      LogLevel.info,
    );

    void scan(int syncHeight, bool isSingleScan) async {
      int initialSyncHeight = syncHeight;

      int getCountToScanPerRequest(int syncHeight) {
        if (isSingleScan) {
          return 1;
        }

        final amountLeft = scanData.chainTip - syncHeight + 1;
        return amountLeft;
      }

      // Initial status UI update, send how many blocks in total to scan
      if (shouldUpdateSyncStatus)
        scanData.sendPort.send(SyncResponse(syncHeight, StartingScanSyncStatus(syncHeight)));

      final req = ElectrumTweaksSubscribe(
        height: syncHeight,
        count: getCountToScanPerRequest(syncHeight),
        historicalMode: hasForcedRescanHeights,
      );

      var _scanningStream = await scanningClient.subscribe(req);

      log(
        "initial request: height: $syncHeight, count: ${getCountToScanPerRequest(syncHeight)}",
        LogLevel.info,
      );

      void endScanningSuccesfully() {
        if (isSingleScan) {
          scanData.sendPort.send(SyncResponse(syncHeight, SyncedSyncStatus()));
        } else {
          scanData.sendPort.send(
            SyncResponse(syncHeight, SyncedTipSyncStatus(scanData.chainTip)),
          );
        }

        _scanningStream?.close();
        _scanningStream = null;

        log(
          "ended: syncHeight: $syncHeight, chainTip: ${scanData.chainTip}, isSingleScan: ${isSingleScan}",
          LogLevel.info,
        );
      }

      void listenFn(Map<String, dynamic> event, ElectrumTweaksSubscribe req) async {
        final response = req.onResponse(event);

        if (response == null || _scanningStream == null) {
          log(
            "ending: response = $response, stream = $_scanningStream",
            LogLevel.error,
          );
          return;
        }

        // is success or error msg
        final noData = response.message != null;

        if (noData) {
          if (isSingleScan) {
            log("ending: noData and isSingleScan", LogLevel.info);

            endScanningSuccesfully();
            return;
          }

          // re-subscribe to continue receiving messages, starting from the next unscanned height
          final nextHeight = syncHeight + 1;

          if (nextHeight <= scanData.chainTip) {
            log(
              "resubscribing: nextHeight: $nextHeight, count: ${getCountToScanPerRequest(nextHeight)}",
              LogLevel.info,
            );

            final nextStream = scanningClient.subscribe(
              ElectrumTweaksSubscribe(
                height: nextHeight,
                count: getCountToScanPerRequest(nextHeight),
                historicalMode: hasForcedRescanHeights,
              ),
            );

            if (nextStream != null) {
              nextStream.listen((event) => listenFn(event, req));
            } else {
              if (shouldUpdateSyncStatus)
                scanData.sendPort.send(
                  SyncResponse(scanData.height, LostConnectionSyncStatus()),
                );
            }
          }

          log(
            "ending: resubscribing: nextHeight: $nextHeight, count: ${getCountToScanPerRequest(nextHeight)}",
            LogLevel.info,
          );
          return;
        }

        final tweakHeight = response.block;

        // Continuous status UI update, send how many blocks left to scan
        final syncingStatus = isSingleScan
            ? SyncingSyncStatus(1, 0)
            : SyncingSyncStatus.fromHeightValues(scanData.chainTip, initialSyncHeight, tweakHeight);

        if (shouldUpdateSyncStatus) scanData.sendPort.send(SyncResponse(syncHeight, syncingStatus));

        try {
          final blockTweaks = response.blockTweaks;

          var blockDate = DateTime.now();
          bool isDateNow = true;

          for (final txid in blockTweaks.keys) {
            final tweakData = blockTweaks[txid];
            final outputPubkeys = tweakData!.outputPubkeys;
            final tweak = tweakData.tweak;

            try {
              final addToWallet = <String, dynamic>{};

              receivers.forEach((receiver) {
                final preparedList = outputPubkeys.keys.toList().map((e) => [e]).toList();
                // NOTE: scanOutputs, from sp_scanner package, called from rust here
                final scanResult = scanOutputs(preparedList, tweak, receiver);

                if (scanResult.isEmpty) return;

                if (addToWallet[receiver.BSpend] == null) {
                  addToWallet[receiver.BSpend] = scanResult;
                } else {
                  addToWallet[receiver.BSpend].addAll(scanResult);
                }
              });

              if (addToWallet.isEmpty) {
                // no results tx, continue to next tx
                continue;
              }

              log(
                "FOUND: addToWallet: ${addToWallet.length}, txid: $txid, tweak: $tweak, height: $tweakHeight",
                LogLevel.info,
              );

              // Every tx in the block has the same date (the block date)
              // So, if blockDate exists, reuse
              if (isDateNow) {
                try {
                  final rootURL = "https://cake.mempool.space";
                  final tweakBlockHash = await ProxyWrapper()
                      .get(clearnetUri: Uri.parse("$rootURL/api/block-height/$tweakHeight"))
                      .timeout(Duration(seconds: 15));
                  final blockResponse = await ProxyWrapper()
                      .get(clearnetUri: Uri.parse("$rootURL/api/block/${tweakBlockHash.body}"))
                      .timeout(Duration(seconds: 15));

                  if (blockResponse.statusCode == 200 &&
                      blockResponse.body.isNotEmpty &&
                      jsonDecode(blockResponse.body)['timestamp'] != null) {
                    blockDate = DateTime.fromMillisecondsSinceEpoch(
                      int.parse(jsonDecode(blockResponse.body)['timestamp'].toString()) * 1000,
                    );
                    isDateNow = false;
                  }
                } catch (e, stacktrace) {
                  printV(stacktrace);
                  printV(e.toString());
                }
              }

              // initial placeholder ElectrumTransactionInfo object to update values based on new scanned unspent(s) on the following loop
              final txInfo = ElectrumTransactionInfo(
                WalletType.bitcoin,
                id: txid,
                height: tweakHeight,
                amount: Money.zero(CryptoCurrency.btc),
                fee: Money.zero(CryptoCurrency.btc),
                direction: TransactionDirection.incoming,
                isReplaced: false,
                date: scanData.network == BitcoinNetwork.mainnet
                    ? (isDateNow ? getDateByBitcoinHeight(tweakHeight) : blockDate)
                    : DateTime.now(),
                confirmations: scanData.chainTip - tweakHeight + 1,
                isReceivedSilentPayment: true,
                isPending: false,
                unspents: [],
              );

              List<BitcoinUnspent> unspents = [];

              addToWallet.forEach((BSpend, scanResultPerLabel) {
                scanResultPerLabel.forEach((label, scanOutput) {
                  final labelValue = label == "None" ? null : label.toString();

                  (scanOutput as Map<String, dynamic>).forEach((outputPubkey, tweak) {
                    final t_k = tweak as String;

                    final receivingOutputAddress = ECPublic.fromHex(outputPubkey)
                        .toTaprootAddress(tweak: false)
                        .toAddress(scanData.network);

                    final matchingOutput = outputPubkeys[outputPubkey]!;
                    final amount = matchingOutput.amount;
                    final pos = matchingOutput.vout;
                    final spent = matchingOutput.spendingInput;

                    final matchingReceiver =
                        receivers.indexWhere((receiver) => receiver.BSpend == BSpend);

                    // final labelIndex = labelValue != null ? scanData.labels[label] : 0;
                    // final balance = ElectrumBalance();
                    // balance.confirmed = amount;

                    final receivedAddressRecord = BitcoinSilentPaymentAddressRecord(
                      receivingOutputAddress,
                      index: 0,
                      isHidden: false,
                      isUsed: true,
                      network: scanData.network,
                      silentPaymentTweak: t_k,
                      type: SegwitAddresType.p2tr,
                      txCount: 1,
                      balance: amount,
                      spendDerivationPath: matchingReceiver == 0
                          ? SILENT_PAYMENTS_SPEND_PATH
                          : SILENT_PAYMENTS_SPEND_PATH_TESTNET,
                    );

                    final unspent = BitcoinSilentPaymentsUnspent(
                      receivedAddressRecord,
                      txid,
                      amount,
                      pos,
                      silentPaymentTweak: t_k,
                      silentPaymentLabel: labelValue,
                    );

                    if (spent == null) {
                      unspents.add(unspent);
                      txInfo.unspents!.add(unspent);
                    }

                    txInfo.amount += Money.fromInt(unspent.value, txInfo.amount.currency);
                  });
                });
              });

              scanData.sendPort.send({txInfo.id: txInfo});
            } catch (e, stacktrace) {
              if (shouldUpdateSyncStatus)
                scanData.sendPort.send(
                  SyncResponse(syncHeight, LostConnectionSyncStatus()),
                );

              log(stacktrace.toString(), LogLevel.error);
              log(e.toString(), LogLevel.error);
              return;
            }
          }
        } catch (e, stacktrace) {
          if (shouldUpdateSyncStatus)
            scanData.sendPort.send(
              SyncResponse(syncHeight, LostConnectionSyncStatus()),
            );

          log(stacktrace.toString(), LogLevel.error);
          log(e.toString(), LogLevel.error);
          return;
        }

        syncHeight = tweakHeight;

        if ((tweakHeight >= scanData.chainTip) || isSingleScan) {
          endScanningSuccesfully();
        }
      }

      _scanningStream?.listen((event) => listenFn(event, req));
    }

    if (scanData.rescanHeights != null) {
      for (final height in scanData.rescanHeights!) {
        log("rescanning from height: $height", LogLevel.info);
        scan(height, true);
      }
    } else {
      scan(scanData.height, scanData.isSingleScan);
    }
  } catch (e) {
    log("Error in _handleScanSilentPayments: $e", LogLevel.error);
    if (shouldUpdateSyncStatus)
      scanData.sendPort.send(SyncResponse(scanData.height, LostConnectionSyncStatus()));
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
  final Money fee;
  final Money amount;
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

BitcoinAddressType _getScriptType(BitcoinBaseAddress type) {
  if (type is P2pkhAddress) {
    return P2pkhAddressType.p2pkh;
  } else if (type is P2shAddress) {
    return P2shAddressType.p2wpkhInP2sh;
  } else if (type is P2wshAddress) {
    return SegwitAddresType.p2wsh;
  } else if (type is P2trAddress) {
    return SegwitAddresType.p2tr;
  } else if (type is MwebAddress) {
    return SegwitAddresType.mweb;
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
