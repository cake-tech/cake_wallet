import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:cw_core/amount/money.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_core/zano_asset.dart';
import 'package:cw_zano/api/model/create_wallet_result.dart';
import 'package:cw_zano/api/model/destination.dart';
import 'package:cw_zano/api/model/get_recent_txs_and_info_result.dart';
import 'package:cw_zano/api/model/get_wallet_status_result.dart';
import 'package:cw_zano/api/model/transfer.dart';
import 'package:cw_zano/model/pending_zano_transaction.dart';
import 'package:cw_zano/model/zano_balance.dart';
import 'package:cw_zano/model/zano_transaction_creation_exception.dart';
import 'package:cw_zano/model/zano_transaction_credentials.dart';
import 'package:cw_zano/model/zano_transaction_info.dart';
import 'package:cw_zano/model/zano_wallet_keys.dart';
import 'package:cw_zano/zano_transaction_history.dart';
import 'package:cw_zano/zano_wallet_addresses.dart';
import 'package:cw_zano/zano_wallet_api.dart';
import 'package:cw_zano/zano_wallet_exceptions.dart';
import 'package:cw_zano/zano_wallet_service.dart';
import 'package:cw_zano/zano_utils.dart';
import 'package:cw_zano/api/model/balance.dart';
import 'package:cw_zano/bip39_seed.dart';
import 'package:path/path.dart' as p;

import 'package:mobx/mobx.dart';

part 'zano_wallet.g.dart';

class ZanoWallet = ZanoWalletBase with _$ZanoWallet;

abstract class ZanoWalletBase
    extends WalletBase<ZanoBalance, ZanoTransactionHistory, ZanoTransactionInfo>
    with Store, ZanoWalletApi, WalletKeysFile {
  static const int _autoSaveIntervalSeconds = 30;
  static const int _pollIntervalMilliseconds = 5000;
  static const int _maxLoadAssetsRetries = 5;
  static const int _walletStateReady = 2;
  static const String _cakeKeysFileSuffix = '.cw.keys';

  @override
  void setPassword(String password) {
    _password = password;
    super.setPassword(password);
  }

  String _password;
  final EncryptionFileUtils _encryptionFileUtils;
  bool _didSyncSecrets = false;

  @override
  String get password => _password;

  @override
  Future<String> makeKeysFilePath() async => "${await makePath()}$_cakeKeysFileSuffix";

  @override
  WalletKeysData get walletKeysData => WalletKeysData(
        mnemonic: _hasSeed ? seed : null,
        passphrase: (passphrase ?? '').isEmpty ? null : passphrase,
      );

  bool get _hasSeed => seed.trim().isNotEmpty;

  @override
  Future<String> signMessage(String message, {String? address = null}) =>
      super.signMessage(message, address: address);

  @override
  Future<bool> verifyMessage(String message, String signature, {String? address = null}) {
    throw UnimplementedError();
  }

  @override
  ZanoWalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  ObservableMap<CryptoCurrency, ZanoBalance> balance;

  @override
  String seed = '';

  @override
  String? passphrase = '';

  @override
  ZanoWalletKeys keys = ZanoWalletKeys(
      privateSpendKey: '', privateViewKey: '', publicSpendKey: '', publicViewKey: '');

  static const String zanoAssetId =
      'd6329b5b1f7c0805b5c345f4957554002a2f557845f64d7645dae0e051a6498a';

  Map<String, ZanoAsset> zanoAssets = {};

  Timer? _updateSyncInfoTimer;

  int _lastKnownBlockHeight = 0;
  int _initialSyncHeight = 0;
  int currentDaemonHeight = 0;
  bool _isTransactionUpdating;
  bool _hasSyncAfterStartup;
  Timer? _autoSaveTimer;

  /// number of transactions in each request
  static final int _txChunkSize = (pow(2, 32) - 1).toInt();

  ZanoWalletBase(WalletInfo walletInfo, DerivationInfo derivationInfo, String password,
      this._encryptionFileUtils)
      : balance = ObservableMap.of({CryptoCurrency.zano: ZanoBalance.empty(CryptoCurrency.zano)}),
        _isTransactionUpdating = false,
        _hasSyncAfterStartup = false,
        walletAddresses = ZanoWalletAddresses(walletInfo),
        syncStatus = NotConnectedSyncStatus(),
        _password = password,
        super(walletInfo, derivationInfo) {
    transactionHistory = ZanoTransactionHistory();
    if (!CakeHive.isAdapterRegistered(ZanoAsset.typeId)) {
      CakeHive.registerAdapter(ZanoAssetAdapter());
    }
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, [int? amount = null]) =>
      getCurrentTxFee(priority);

  @override
  Future<void> changePassword(String password) async {
    setPassword(password);
    if (_hasSeed) {
      await saveKeysFile(_password, _encryptionFileUtils);
      saveKeysFile(_password, _encryptionFileUtils, true);
    }
  }

  static Future<ZanoWallet> create({
    required WalletCredentials credentials,
    required EncryptionFileUtils encryptionFileUtils,
  }) async {
    final wallet = ZanoWallet(credentials.walletInfo!,
        await credentials.walletInfo!.getDerivationInfo(), credentials.password!, encryptionFileUtils);
    await wallet.initWallet();
    final path = await pathForWallet(name: credentials.name, type: credentials.walletInfo!.type);
    final strength = credentials.seedPhraseLength == 24 ? 256 : 128;
    final providedMnemonic =
        credentials is ZanoNewWalletCredentials ? credentials.mnemonic : null;
    final mnemonic = providedMnemonic ?? generateBip39Mnemonic(strength: strength);
    final passphrase = credentials.passphrase ?? '';
    final secretDerivation = getSecretDerivationFromBip39(mnemonic, passphrase: passphrase);
    final creationTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final createWalletResult = await wallet.restoreWalletFromDerivations(
      path,
      credentials.password!,
      secretDerivation,
      creationTimestamp: creationTimestamp,
    );
    await wallet.initWallet();
    wallet.seed = mnemonic;
    wallet.passphrase = passphrase;
    await wallet.parseCreateWalletResult(createWalletResult);
    await wallet._syncSecretsAndDerivation();
    await wallet.init(createWalletResult.wi.address);
    await wallet.save();
    return wallet;
  }

  static Future<ZanoWallet> restore({
    required ZanoRestoreWalletFromSeedCredentials credentials,
    required EncryptionFileUtils encryptionFileUtils,
  }) async {
    final wallet = ZanoWallet(credentials.walletInfo!,
        await credentials.walletInfo!.getDerivationInfo(), credentials.password!, encryptionFileUtils);
    await wallet.initWallet();
    final path = await pathForWallet(name: credentials.name, type: credentials.walletInfo!.type);
    final passphrase = credentials.passphrase ?? '';
    final CreateWalletResult createWalletResult;
    final isBip39 = isBip39Seed(credentials.mnemonic);
    final creationTimestamp = ZanoUtils.creationTimestampFromHeight(credentials.height ?? 0);
    if (isBip39) {
      final secretDerivation =
          getSecretDerivationFromBip39(credentials.mnemonic, passphrase: passphrase);
      createWalletResult = await wallet.restoreWalletFromDerivations(
        path,
        credentials.password!,
        secretDerivation,
        creationTimestamp: creationTimestamp,
      );
    } else {
      createWalletResult = await wallet.restoreWalletFromSeed(
        path,
        credentials.password!,
        credentials.mnemonic,
        credentials.passphrase,
        creationTimestamp: creationTimestamp,
      );
    }
    await wallet.initWallet();
    wallet.seed = credentials.mnemonic;
    wallet.passphrase = passphrase;
    await wallet.parseCreateWalletResult(createWalletResult);
    if (!isBip39) {
      try {
        final nativeSeed = await createWalletResult.seed(wallet);
        if (nativeSeed.isNotEmpty) {
          wallet.seed = nativeSeed;
        }
      } catch (e) {
        printV('native seed not available yet: $e');
      }
    }
    await wallet._syncSecretsAndDerivation();
    await wallet.init(createWalletResult.wi.address);
    await wallet.save();
    return wallet;
  }

  static Future<ZanoWallet> open(
      {required String name,
      required String password,
      required WalletInfo walletInfo,
      required EncryptionFileUtils encryptionFileUtils}) async {
    final path = await pathForWallet(name: name, type: walletInfo.type);
    final wallet =
        ZanoWallet(walletInfo, await walletInfo.getDerivationInfo(), password, encryptionFileUtils);

    await wallet._loadKeysFileIfPresent();

    late final CreateWalletResult createWalletResult;
    if (ZanoWalletApi.openWalletCache[path] != null) {
      createWalletResult = ZanoWalletApi.openWalletCache[path]!;
    } else {
      await wallet.initWallet();
      createWalletResult = await wallet.loadWallet(path, password);
    }
    await wallet.parseCreateWalletResult(createWalletResult);
    if (!wallet._hasSeed) {
      await wallet._loadSeedIfAvailable();
    }
    await wallet._syncSecretsAndDerivation();
    unawaited(wallet.init(createWalletResult.wi.address));
    return wallet;
  }

  Future<void> parseCreateWalletResult(CreateWalletResult result) async {
    hWallet = result.walletId;
    keys = ZanoWalletKeys(
      privateSpendKey: result.privateSpendKey,
      privateViewKey: result.privateViewKey,
      publicSpendKey: result.publicSpendKey,
      publicViewKey: result.publicViewKey,
    );
    if ((passphrase ?? '').isEmpty) {
      try {
        passphrase = await getPassphrase();
      } catch (e) {
        printV('passphrase not available yet: $e');
      }
    }

    printV('setting hWallet = ${result.walletId}');
    walletAddresses.address = result.wi.address;
    await loadAssets(result.wi.balances, maxRetries: _maxLoadAssetsRetries);
    for (final item in result.wi.balances) {
      if (item.assetInfo.assetId == zanoAssetId) {
        balance[CryptoCurrency.zano] = ZanoBalance(
          total: Money(item.total, CryptoCurrency.zano),
          unlocked: Money(item.unlocked, CryptoCurrency.zano),
        );
      }
    }
    if (result.recentHistory.history != null) {
      final transfers = result.recentHistory.history!;
      final transactions = Transfer.makeMap(transfers, zanoAssets, currentDaemonHeight);
      transactionHistory.addMany(transactions);
      await transactionHistory.save();
    }
  }

  bool _isWalletReady(GetWalletStatusResult walletStatus) =>
      !walletStatus.isInLongRefresh && walletStatus.walletState == _walletStateReady;

  Future<bool> _hasKeysFile() async {
    try {
      final path = await makeKeysFilePath();
      return File(path).existsSync() || File('$path.backup').existsSync();
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadKeysFileIfPresent() async {
    if (!await _hasKeysFile()) {
      return;
    }
    final path = await makeKeysFilePath();
    Future<WalletKeysData> read(String readPath) async {
      final jsonSource = await _encryptionFileUtils.read(path: readPath, password: _password);
      return WalletKeysData.fromJSON(json.decode(jsonSource) as Map<String, dynamic>);
    }

    try {
      WalletKeysData keysData;
      if (File(path).existsSync()) {
        keysData = await read(path);
      } else {
        keysData = await read('$path.backup');
        await saveKeysFile(_password, _encryptionFileUtils);
      }
      if (keysData.mnemonic != null && keysData.mnemonic!.trim().isNotEmpty) {
        seed = keysData.mnemonic!;
      }
      if (keysData.passphrase != null && keysData.passphrase!.isNotEmpty) {
        passphrase = keysData.passphrase;
      }
    } catch (e) {
      printV('error reading zano keys file $e');
    }
  }

  Future<void> _saveKeysFileIfNeeded() async {
    if (!_hasSeed || await _hasKeysFile()) {
      return;
    }
    await saveKeysFile(_password, _encryptionFileUtils);
    saveKeysFile(_password, _encryptionFileUtils, true);
  }

  Future<void> _loadSeedIfAvailable() async {
    if (!isBip39Seed(seed)) {
      try {
        final loaded = await getSeed();
        if (loaded.isNotEmpty) {
          seed = loaded;
        }
      } catch (e) {
        printV('seed not available yet: $e');
      }
    }
    if ((passphrase ?? '').isEmpty) {
      try {
        passphrase = await getPassphrase() ?? passphrase;
      } catch (e) {
        printV('passphrase not available yet: $e');
      }
    }
  }

  Future<void> _syncSecretsAndDerivation() async {
    if (!_hasSeed || _didSyncSecrets) {
      return;
    }
    try {
      await _persistSecretsIfNeeded();
      await _setDerivationForSeed();
      await _saveKeysFileIfNeeded();
      _didSyncSecrets = true;
    } catch (e) {
      printV('error persisting zano secrets $e');
    }
  }

  Future<void> _persistSecretsIfNeeded() async {
    if (isBip39Seed(seed) && await getBip39Mnemonic() == null) {
      await setBip39Secrets(
        mnemonic: seed,
        creationTimestamp: walletInfo.restoreHeight > 0
            ? ZanoUtils.creationTimestampFromHeight(walletInfo.restoreHeight)
            : DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }
    if ((passphrase ?? '').isNotEmpty && await getPassphrase() == null) {
      await setPassphrase(passphrase!);
    }
  }

  Future<void> _setDerivationForSeed() async {
    if (!_hasSeed) {
      return;
    }
    final di = await walletInfo.getDerivationInfo();
    if (isBip39Seed(seed)) {
      if (di.derivationType == DerivationType.bip39 &&
          (di.derivationPath ?? '').isNotEmpty) {
        return;
      }
      di.derivationType = DerivationType.bip39;
      di.derivationPath = "m/44'/128'/0'/0/0";
      await di.save();
      return;
    }
    if (di.derivationType != DerivationType.bip39 && di.derivationPath == 'legacy') {
      return;
    }
    di.derivationType = DerivationType.unknown;
    di.derivationPath = 'legacy';
    await di.save();
  }

  @override
  Future<void> close({bool shouldCleanup = true}) async {
    closeWallet(null);
    _updateSyncInfoTimer?.cancel();
    _autoSaveTimer?.cancel();
  }

  @override
  Future<void> connectToNode({required Node node}) async {
    syncStatus = ConnectingSyncStatus();
    await setupNode(node.uriRaw);
    syncStatus = ConnectedSyncStatus();
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    credentials as ZanoTransactionCredentials;
    final isZano = credentials.currency == CryptoCurrency.zano;
    final outputs = credentials.outputs;
    final hasMultiDestination = outputs.length > 1;
    final unlockedBalanceZano =
        balance[CryptoCurrency.zano]?.unlocked ?? Money.zero(CryptoCurrency.zano);
    final unlockedBalanceCurrency =
        balance[credentials.currency]?.unlocked ?? Money.zero(credentials.currency);
    final fee =
        Money(BigInt.from(calculateEstimatedFee(credentials.priority)), CryptoCurrency.zano);

    var totalAmount = Money.zero(credentials.currency);
    void checkForEnoughBalances() {
      if (isZano) {
        if (totalAmount + fee > unlockedBalanceZano) {
          throw ZanoTransactionCreationException(
              "You don't have enough coins (required: ${(totalAmount + fee).toStringWithSymbol()}, unlocked ${unlockedBalanceZano.toStringWithSymbol()}).");
        }
      } else {
        if (fee > unlockedBalanceZano) {
          throw ZanoTransactionCreationException(
              "You don't have enough coins (required: ${fee.toStringWithSymbol()}, unlocked ${unlockedBalanceZano.toStringWithSymbol()}).");
        }
        if (totalAmount > unlockedBalanceCurrency) {
          throw ZanoTransactionCreationException(
              "You don't have enough coins (required: ${totalAmount.toStringWithSymbol()}, unlocked ${unlockedBalanceCurrency.toStringWithSymbol()}).");
        }
      }
    }

    final assetId = isZano ? zanoAssetId : (credentials.currency as ZanoAsset).assetId;
    late List<Destination> destinations;
    if (hasMultiDestination) {
      if (outputs.any((output) => output.sendAll || output.cryptoAmount.amount <= BigInt.zero)) {
        throw ZanoTransactionCreationException("You don't have enough coins.");
      }
      totalAmount =
          outputs.fold(Money.zero(credentials.currency), (acc, value) => acc + value.cryptoAmount);
      checkForEnoughBalances();
      destinations = outputs
          .map((output) => Destination(
                amount: output.cryptoAmount.amount,
                address: output.isParsedAddress ? output.extractedAddress! : output.address,
                assetId: assetId,
              ))
          .toList();
    } else {
      final output = outputs.first;
      if (output.sendAll) {
        if (isZano) {
          totalAmount = unlockedBalanceZano - fee;
        } else {
          totalAmount = unlockedBalanceCurrency;
        }
      } else {
        totalAmount = output.cryptoAmount;
      }
      checkForEnoughBalances();
      destinations = [
        Destination(
          amount: totalAmount.amount,
          address: output.isParsedAddress ? output.extractedAddress! : output.address,
          assetId: assetId,
        )
      ];
    }
    return PendingZanoTransaction(
      zanoWallet: this,
      destinations: destinations,
      fee: fee,
      comment: outputs.first.note ?? '',
      assetId: assetId,
      amount: totalAmount,
    );
  }

  @override
  Future<Map<String, ZanoTransactionInfo>> fetchTransactions() async {
    try {
      final transfers = <Transfer>[];
      var offset = 0;
      late GetRecentTxsAndInfoResult result;
      do {
        result = await getRecentTxsAndInfo(offset: offset, count: _txChunkSize);
        transfers.addAll(result.transfers);
        offset = result.lastItemIndex + 1;
      } while (offset < result.totalTransfers);
      return Transfer.makeMap(transfers, zanoAssets, currentDaemonHeight);
    } catch (e) {
      printV((e.toString()));
      return {};
    }
  }

  Future<void> init(String address) async {
    await walletAddresses.init();
    await walletAddresses.updateAddress(address);
    await updateTransactions();
    _autoSaveTimer = Timer.periodic(Duration(seconds: _autoSaveIntervalSeconds), (_) async {
      await save();
    });
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    final currentWalletPath = await pathForWallet(name: name, type: type);
    final currentCacheFile = File(currentWalletPath);
    final currentKeysFile = File('$currentWalletPath.keys');
    final currentAddressListFile = File('$currentWalletPath.address.txt');
    final currentSecretsFile = File(p.join(p.dirname(currentWalletPath), 'zano-secrets.json.bin'));
    final currentCakeKeysFile = File('$currentWalletPath$_cakeKeysFileSuffix');
    final currentCakeKeysBackupFile = File('$currentWalletPath$_cakeKeysFileSuffix.backup');

    final newWalletPath = await pathForWallet(name: newWalletName, type: type);

    // Copies current wallet files into new wallet name's dir and files
    if (currentCacheFile.existsSync()) {
      await currentCacheFile.copy(newWalletPath);
    }
    if (currentKeysFile.existsSync()) {
      await currentKeysFile.copy('$newWalletPath.keys');
    }
    if (currentAddressListFile.existsSync()) {
      await currentAddressListFile.copy('$newWalletPath.address.txt');
    }
    if (currentSecretsFile.existsSync()) {
      await currentSecretsFile.copy(p.join(p.dirname(newWalletPath), 'zano-secrets.json.bin'));
    }
    if (currentCakeKeysFile.existsSync()) {
      await currentCakeKeysFile.copy('$newWalletPath$_cakeKeysFileSuffix');
    }
    if (currentCakeKeysBackupFile.existsSync()) {
      await currentCakeKeysBackupFile.copy('$newWalletPath$_cakeKeysFileSuffix.backup');
    }

    // Delete old name's dir and files
    await Directory(currentWalletPath).delete(recursive: true);
  }

  @override
  Future<void> rescan({required int height}) => throw UnimplementedError();

  @override
  Future<void> save() async {
    try {
      await _saveKeysFileIfNeeded();
      await store();
      await walletAddresses.updateAddressesInBox();
    } catch (e) {
      printV(('Error while saving Zano wallet file ${e.toString()}'));
    }
  }

  Future<void> loadAssets(List<Balance> balances, {int maxRetries = 1}) async {
    List<ZanoAsset> assets = [];
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        assets = await getAssetsWhitelist();
        break;
      } on ZanoWalletBusyException {
        if (retryCount < maxRetries - 1) {
          retryCount++;
          await Future.delayed(Duration(seconds: 1));
        } else {
          printV(('failed to load assets after $retryCount retries'));
          break;
        }
      }
    }
    zanoAssets = {};
    for (final asset in assets) {
      final newAsset = ZanoAsset.copyWith(
        asset,
        enabled: balances.any((element) => element.assetId == asset.assetId),
      );
      zanoAssets.putIfAbsent(asset.assetId, () => newAsset);
    }
  }

  @override
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();
      _lastKnownBlockHeight = 0;
      _initialSyncHeight = 0;
      _updateSyncInfoTimer ??= Timer.periodic(
          Duration(milliseconds: _pollIntervalMilliseconds), (_) => _updateSyncInfo());
    } catch (e) {
      syncStatus = FailedSyncStatus();
      printV((e.toString()));
    }
  }

  @override
  Future<void>? updateBalance() => null;

  @override
  Future<bool> checkNodeHealth() async {
    try {
      final status = await getWalletStatus();

      return status.isDaemonConnected;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateTransactions() async {
    try {
      if (_isTransactionUpdating) {
        return;
      }
      _isTransactionUpdating = true;
      final transactions = await fetchTransactions();
      transactionHistory.clear();
      transactionHistory.addMany(transactions);
      await transactionHistory.save();
      _isTransactionUpdating = false;
    } catch (e) {
      printV("e: $e");
      printV((e.toString()));
      _isTransactionUpdating = false;
    }
  }

  Future<CryptoCurrency> addZanoAssetById(String assetId) async {
    if (zanoAssets.containsKey(assetId)) {
      throw ZanoWalletException('zano asset with id $assetId already added');
    }
    final assetDescriptor = await addAssetsWhitelist(assetId);
    if (assetDescriptor == null) {
      throw ZanoWalletException("there's no zano asset with id $assetId");
    }
    final asset = ZanoAsset.copyWith(
      assetDescriptor,
      assetId: assetId,
      enabled: true,
    );
    zanoAssets[asset.assetId] = asset;
    balance[asset] = ZanoBalance.empty(asset);
    return asset;
  }

  Future<void> changeZanoAssetAvailability(ZanoAsset asset) async {
    if (asset.enabled) {
      final assetDescriptor = await addAssetsWhitelist(asset.assetId);
      if (assetDescriptor == null) {
        printV(('Error adding zano asset'));
      }
    } else {
      final result = await removeAssetsWhitelist(asset.assetId);
      if (result == false) {
        printV(('Error removing zano asset'));
      }
    }
  }

  Future<void> deleteZanoAsset(ZanoAsset asset) async {
    final _ = await removeAssetsWhitelist(asset.assetId);
  }

  Future<ZanoAsset?> getZanoAsset(String assetId) async {
    // wallet api is not available while the wallet is syncing so only call it if it's synced
    if (syncStatus is SyncedSyncStatus) {
      return await getAssetInfo(assetId);
    }
    return null;
  }

  Future<void> _askForUpdateTransactionHistory() async => await updateTransactions();

  void _onNewBlock(int height, int blocksLeft, double ptc) async {
    try {
      if (blocksLeft < 1000) {
        await _askForUpdateTransactionHistory();
        syncStatus = SyncedSyncStatus();

        if (!_hasSyncAfterStartup) {
          _hasSyncAfterStartup = true;
          await save();
        }
      } else {
        syncStatus = SyncingSyncStatus(blocksLeft, ptc);
      }
    } catch (e) {
      printV((e.toString()));
    }
  }

  void _updateSyncProgress(GetWalletStatusResult walletStatus) {
    final syncHeight = walletStatus.currentWalletHeight;
    if (_initialSyncHeight <= 0) {
      _initialSyncHeight = syncHeight;
    }
    final bchHeight = walletStatus.currentDaemonHeight;

    if (_lastKnownBlockHeight == syncHeight) {
      return;
    }

    _lastKnownBlockHeight = syncHeight;
    final track = bchHeight - _initialSyncHeight;
    final diff = track - (bchHeight - syncHeight);
    final ptc = diff <= 0 ? 0.0 : diff / track;
    final left = bchHeight - syncHeight;

    if (syncHeight < 0 || left < 0) {
      return;
    }

    // 1. Actual new height; 2. Blocks left to finish; 3. Progress in percents;
    _onNewBlock.call(syncHeight, left, ptc);
  }

  void _updateSyncInfo() async {
    GetWalletStatusResult walletStatus;
    // ignoring get wallet status exception (in case of wrong wallet id)
    try {
      walletStatus = await getWalletStatus();
    } on ZanoWalletException {
      return;
    }
    currentDaemonHeight = walletStatus.currentDaemonHeight;
    _updateSyncProgress(walletStatus);

    // we can call getWalletInfo ONLY if getWalletStatus returns NOT is in long refresh and wallet state is 2 (ready)
    if (_isWalletReady(walletStatus)) {
      if (!_hasSeed) {
        await _loadSeedIfAvailable();
      }
      await _syncSecretsAndDerivation();
      final walletInfo = await getWalletInfo();
      keys = ZanoWalletKeys(
        privateSpendKey: walletInfo.wiExtended.spendPrivateKey,
        privateViewKey: walletInfo.wiExtended.viewPrivateKey,
        publicSpendKey: walletInfo.wiExtended.spendPublicKey,
        publicViewKey: walletInfo.wiExtended.viewPublicKey,
      );
      loadAssets(walletInfo.wi.balances);
      // matching balances and whitelists
      // 1. show only balances available in whitelists
      // 2. set whitelists available in balances as 'enabled' ('disabled' by default)
      for (final b in walletInfo.wi.balances) {
        if (b.assetId == zanoAssetId) {
          balance[CryptoCurrency.zano] = ZanoBalance(
            total: Money(b.total, CryptoCurrency.zano),
            unlocked: Money(b.unlocked, CryptoCurrency.zano),
          );
        } else {
          final asset = zanoAssets[b.assetId];
          if (asset == null) {
            printV('balance for an unknown asset ${b.assetInfo.assetId}');
            continue;
          }

          final assetBalanceKey =
              balance.keys.where((e) => e is ZanoAsset && e.assetId == asset.assetId).firstOrNull;
          if (assetBalanceKey != null) {
            balance[assetBalanceKey] = ZanoBalance(
              total: Money(b.total, assetBalanceKey),
              unlocked: Money(b.unlocked, assetBalanceKey),
            );
          } else {
            balance[asset] = ZanoBalance(
              total: Money(b.total, asset),
              unlocked: Money(b.unlocked, asset),
            );
          }
        }
      }
      await updateTransactions();
      // removing balances for assets missing in wallet info balances
      balance.removeWhere(
        (key, _) =>
            key != CryptoCurrency.zano &&
            !walletInfo.wi.balances.any((element) => element.assetId == (key as ZanoAsset).assetId),
      );
    }
  }
}
