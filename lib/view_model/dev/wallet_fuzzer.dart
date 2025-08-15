import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';

import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:path/path.dart' as p;
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/bitcoin_cash/bitcoin_cash.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/zano/zano.dart';
import 'package:cake_wallet/decred/decred.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/core/generate_wallet_password.dart';

part 'wallet_fuzzer.g.dart';

class WalletFuzzerViewModel = WalletFuzzerViewModelBase with _$WalletFuzzerViewModel;

class FuzzyLogEntry {
  final DateTime timestamp;
  final String action;
  final String? result;

  FuzzyLogEntry({required this.timestamp, required this.action, this.result});

  @override
  String toString() {
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(timestamp);
    if (result != null) {
      return '[$formattedTime] $action - $result';
    }
    return '[$formattedTime] $action';
  }
}

abstract class WalletFuzzerViewModelBase with Store {
  WalletFuzzerViewModelBase() {
    unawaited(_initialize());
  }

  static final DateTime appStartDate = DateTime.now();
  
  List<FuzzyLogEntry> logs = [];
  
  @observable
  bool isRunning = false;
  
  @observable
  String currentOperation = 'Idle';
  
  @observable
  String currentWallet = '';
  
  @observable
  int operationsCompleted = 0;
  
  @observable
  int errorsEncountered = 0;

  @observable
  Map<String, int> operationStats = {
    'loadWallet': 0,
    'syncWallet': 0,
    'closeWallet': 0,
    'switchWallet': 0,
    'restartWallet': 0,
    'checkAndCreateWallets': 0,
    'createWalletsForType': 0,
    'performRandomOperation': 0,
  };

  @computed
  String get formattedOperationStats {
    final buffer = StringBuffer();
    final sortedEntries = operationStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedEntries) {
      final opName = entry.key;
      final opCount = entry.value;
      
      String formattedName = switch (opName) {
        'loadWallet' => 'Load Wallet',
        'syncWallet' => 'Sync Wallet',
        'closeWallet' => 'Close Wallet',
        'switchWallet' => 'Switch Wallet',
        'restartWallet' => 'Restart Wallet',
        'checkAndCreateWallets' => 'Create Wallets',
        'performRandomOperation' => 'Perform Random Operation',
        _ => opName,
      };
      
      buffer.writeln('$formattedName: $opCount');
    }
    
    return buffer.toString();
  }

  @observable
  String? logFilePath;

  @observable
  Directory? logDir;
  
  
  WalletLoadingService walletLoadingService = getIt.get<WalletLoadingService>();
  WalletListViewModel walletListViewModel = getIt.get<WalletListViewModel>();
  SettingsStore settingsStore = getIt.get<SettingsStore>();
  KeyService keyService = getIt.get<KeyService>();
  
  final _random = Random();
  Timer? _fuzzerTimer;
  
  static const String _fuzzyFileName = '.wallet-fuzzer';
  static const String _lastFuzzFile = 'last_fuzz';
  static const String _statsFile = 'fuzzer_stats';
  
  final allTypes = [
    WalletType.monero,
    WalletType.bitcoin,
    WalletType.litecoin,
    WalletType.ethereum,
    WalletType.bitcoinCash,
    WalletType.polygon,
    WalletType.solana,
    WalletType.tron,
    WalletType.zano,
  ];

  Future<void> _initialize() async {
    
    final appDir = await getAppDir();
    logDir = Directory(p.join(appDir.path, 'fuzzy'));
    
    if (!await logDir!.exists()) {
      await logDir!.create(recursive: true);
    }
    
    final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(appStartDate);
    logFilePath = p.join(logDir!.path, 'log-$formattedDate.txt');
    
    await _logToFile('Wallet Fuzzer initialized');
    
    await _loadOperationStats();
  }
  
  Future<void> _loadOperationStats() async {
    try {
      final appDir = await getAppDir();
      final statsFilePath = p.join(appDir.path, _statsFile);
      final statsFile = File(statsFilePath);
      
      if (await statsFile.exists()) {
        final statsJson = await statsFile.readAsString();
        final stats = jsonDecode(statsJson) as Map<String, dynamic>;
        
        operationStats = stats.map((key, value) => MapEntry(key, value as int));
        
        await _logAction('Loaded operation statistics', 
            result: operationStats.entries.map((e) => '${e.key}: ${e.value}').join(', '));
      } else {
        await _logAction('No previous operation statistics found');
      }
    } catch (e) {
      await _logAction('Failed to load operation statistics', result: e.toString());
    }
  }

  Future<void> _saveOperationStats() async {
    try {
      final appDir = await getAppDir();
      final statsFilePath = p.join(appDir.path, _statsFile);
      final statsFile = File(statsFilePath);
      
      final statsJson = jsonEncode(operationStats);
      await statsFile.writeAsString(statsJson);
    } catch (e) {
      await _logAction('Failed to save operation statistics', result: e.toString());
    }
  }

  Future<void> _incrementOperationStat(String operation) async {
    if (operationStats.containsKey(operation)) {
      operationStats[operation] = operationStats[operation]! + 1;
    } else {
      operationStats[operation] = 1;
    }
    await _saveOperationStats();
  }
  
  Future<void> startFuzzing() async {
    if (isRunning) return;
    
    isRunning = true;
    await _logAction('Starting wallet fuzzer');
    
    await _clearLastFuzzFile();
    
    await _ensureEnoughWallets();
    
    _fuzzerTimer = Timer.periodic(Duration(seconds: 1), (_) => _performRandomOperation());
  }
  
  Future<void> _createFuzzyFile() async {
    final appDir = await getAppDir();
    final fuzzyFile = File(p.join(appDir.path, _fuzzyFileName));
    if (!await fuzzyFile.exists()) {
      await fuzzyFile.create();
      await _logAction('Created fuzzy file marker for auto-restart');
    }
  }
  
  Future<void> _removeFuzzyFile() async {
    final appDir = await getAppDir();
    final fuzzyFile = File(p.join(appDir.path, _fuzzyFileName));
    if (await fuzzyFile.exists()) {
      await fuzzyFile.delete();
      await _logAction('Removed fuzzy file marker');
    }
  }
  
  @action
  Future<void> stopFuzzing() async {
    if (!isRunning) return;
    
    _fuzzerTimer?.cancel();
    _fuzzerTimer = null;
    isRunning = false;
    
    await _logAction('Stopping wallet fuzzer');
  }
  
  Future<void> _ensureEnoughWallets() async {
    await _logAction('Checking if we need to create wallets');
    
    final wallets = walletListViewModel.wallets;
    final walletsByType = <WalletType, List<WalletListItem>>{};
    
    for (final wallet in wallets.where((w) => !w.isHardware)) {
      if (!walletsByType.containsKey(wallet.type)) {
        walletsByType[wallet.type] = [];
      }
      walletsByType[wallet.type]!.add(wallet);
    }
    
    const MIN_WALLETS = 8;
    for (final type in allTypes) {
      final count = walletsByType[type]?.length ?? 0;
      if (count < MIN_WALLETS) {
        await _logAction('Not enough wallets of type ${type.toString()}. Have: $count, Need: $MIN_WALLETS');
        await _createWalletsForType(type, MIN_WALLETS - count);
      } else {
        await _logAction('Enough wallets of type ${type.toString()}. Have: $count');
      }
    }
  }
  
  Future<void> _createWalletsForType(WalletType type, int count) async {
    await _incrementOperationStat('createWalletsForType');
    await _logAction('Creating $count wallets for type ${type.toString()}');
    final walletCreationService = getIt.get<WalletCreationService>(param1: type);
    
    for (int i = 0; i < count; i++) {
      await _logAction('Creating wallet ${i+1} of $count');
      final index = i;
      await _createSingleWallet(type, index, count, walletCreationService);
      await Future.delayed(Duration(milliseconds: 500));
    }
  }
  
  Future<void> _createSingleWallet(
      WalletType type, int index, int totalCount, WalletCreationService service) async {
    try {
      currentOperation = 'Creating wallet of type ${type.toString()} (${index+1}/$totalCount)';
      
      final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
      final randomSuffix = _random.nextInt(9999).toString().padLeft(4, '0');
      final walletName = 'fuzzy_${type.toString().split('.').last}_${timestamp}_$randomSuffix';
      
      await _logAction('Creating wallet credentials', result: walletName);
      
      final dirPath = await pathForWalletDir(name: walletName, type: type);
      final path = await pathForWallet(name: walletName, type: type);
      final credentials = await _prepareCredentialsForType(type, walletName);
      credentials.walletInfo = WalletInfo.external(
        id: WalletBase.idFor(walletName, type),
        name: walletName,
        type: type,
        isRecovery: false,
        restoreHeight: credentials.height ?? 0,
        date: DateTime.now(),
        path: path,
        dirPath: dirPath,
        address: '',
        showIntroCakePayCard: false,
        derivationInfo: credentials.derivationInfo,
        hardwareWalletType: credentials.hardwareWalletType,
      );
      _logAction('Creating wallet', result: walletName);
      final wallet = await service.create(credentials, isTestnet: false);
      _logAction('Wallet created', result: walletName);
      await _logWalletState(wallet);
      final node = settingsStore.getCurrentNode(wallet.type);
      _logAction('Connecting to node', result: walletName);
      await wallet.connectToNode(node: node);
      _logAction('Starting sync', result: walletName);
      await wallet.startSync();
      await Future.delayed(Duration(seconds: 5 + _random.nextInt(25)));
      _logAction('Stopping sync', result: walletName);
      await wallet.stopSync();
      _logAction('Closing wallet', result: walletName);
      await wallet.close(shouldCleanup: true);
      _logAction('Wallet closed', result: walletName);
    } catch (e) {
      errorsEncountered++;
      await _logAction('Failed to create wallet of type ${type.toString()}', result: e.toString());
    }
  }
  
  Future<WalletCredentials> _prepareCredentialsForType(WalletType type, String name) async {
    final password = generateWalletPassword();
    
    switch (type) {
      case WalletType.monero:
        return monero!.createMoneroNewWalletCredentials(
          name: name,
          language: 'English',
          seedType: MoneroSeedType.legacy.raw,
          passphrase: '',
          password: password,
        );
      case WalletType.bitcoin:
        return bitcoin!.createBitcoinNewWalletCredentials(
          name: name,
          password: password,
          passphrase: '',
        );
      case WalletType.litecoin:
        return bitcoin!.createBitcoinNewWalletCredentials(
          name: name,
          password: password,
          passphrase: '',
        );
      case WalletType.bitcoinCash:
        return bitcoinCash!.createBitcoinCashNewWalletCredentials(
          name: name,
          password: password,
          passphrase: '',
        );
      case WalletType.ethereum:
        return ethereum!.createEthereumNewWalletCredentials(
          name: name,
          password: password,
          passphrase: '',
        );
      case WalletType.nano:
      case WalletType.banano:
        return nano!.createNanoNewWalletCredentials(
          name: name,
          password: password,
          passphrase: '',
        );
      case WalletType.polygon:
        return polygon!.createPolygonNewWalletCredentials(
          name: name,
          password: password,
          passphrase: '',
        );
      case WalletType.solana:
        return solana!.createSolanaNewWalletCredentials(
          name: name,
          password: password,
          passphrase: '',
        );
      case WalletType.tron:
        return tron!.createTronNewWalletCredentials(
          name: name,
          password: password,
          passphrase: '',
        );
      case WalletType.zano:
        return zano!.createZanoNewWalletCredentials(
          name: name,
          password: password,
          passphrase: '',
        );
      case WalletType.decred:
        return decred!.createDecredNewWalletCredentials(name: name);
      default:
        throw Exception('Wallet creation not yet implemented for ${type.toString()}');
    }
  }
  
  Future<void> clearLogs() async {
    logs.clear();
    await _logAction('Logs cleared from UI');
  }
  
  @action
  Future<void> _logAction(String action, {String? result}) async {
    final entry = FuzzyLogEntry(
      timestamp: DateTime.now(),
      action: action,
      result: result,
    );
    
    logs.insert(0, entry);
    
    if (logs.length > 500) {
      logs.removeLast();
    }
    
    await _logToFile(entry.toString());
  }
  
  Future<void> _logToFile(String message) async {
    try {
      final file = File(logFilePath!);
      final sink = await file.open(mode: FileMode.append);
      sink.writeStringSync('$message\n');
      await sink.close();
    } catch (e) {
      printV('Error writing to log file: $e');
    }
  }
  bool isBusy = false;
  
  Future<void> _performRandomOperation() async {
    if (!isRunning) return;
    if (isBusy) return;
    isBusy = true;
    final wallets = walletListViewModel.wallets;
    if (wallets.isEmpty) {
      await _logAction('No wallets available to test');
      return;
    }
    
    try {
      await _incrementOperationStat('performRandomOperation');
      final operations = [
        _loadRandomWallet,
        _syncRandomWallet,
        _checkAndCreateWallets,
      ];
      
      final operation = operations[_random.nextInt(operations.length)];
      await operation();
      operationsCompleted++;
    } catch (e, s) {
      errorsEncountered++;
      await _logAction('Error performing operation', result: e.toString());
      printV('Error: $e\nStack trace: $s');
    } finally {
      isBusy = false;
    }
  }
  
  Future<void> _loadRandomWallet() async {
    await _incrementOperationStat('loadWallet');
    
    final wallets = walletListViewModel.wallets
        .where((wallet) => !wallet.isHardware)
        .toList();
    
    if (wallets.isEmpty) {
      await _logAction('No non-hardware wallets available to load');
      return;
    }
    
    final walletItem = wallets[_random.nextInt(wallets.length)];
    currentWallet = walletItem.name;
    currentOperation = 'Loading wallet ${walletItem.name}';
    
    await _logAction('Loading wallet', result: walletItem.name);
    
    try {
      final wallet = await walletLoadingService.load(walletItem.type, walletItem.name);
      await _logAction('Wallet loaded successfully', result: walletItem.name);
      
      await _logWalletState(wallet);
      
      await _closeWallet(wallet);
    } catch (e) {
      await _logWalletStateByName(walletItem.name, e.toString().replaceAll("\n", ";"));

      await _logAction('Failed to load wallet', result: '${walletItem.name}: $e');
      throw e;
    }
  }
  
  Future<void> _syncRandomWallet() async {
    await _incrementOperationStat('syncWallet');
    
    final wallets = walletListViewModel.wallets
        .where((wallet) => !wallet.isHardware)
        .toList();
    
    if (wallets.isEmpty) {
      await _logAction('No non-hardware wallets available to sync');
      return;
    }
    
    final walletItem = wallets[_random.nextInt(wallets.length)];
    currentWallet = walletItem.name;

    currentOperation = 'Syncing wallet ${walletItem.name}';
    
    await _logAction('Starting sync for wallet', result: walletItem.name);
    
    try {
      WalletBase wallet;
      wallet = await walletLoadingService.load(walletItem.type, walletItem.name);
      await _logAction("loaded wallet: ${wallet.name} as ${walletItem.name}");
      await _logWalletState(wallet);
      
      final node = settingsStore.getCurrentNode(wallet.type);
      await wallet.connectToNode(node: node);
      
      await wallet.startSync();
      await _logAction('Sync started for wallet', result: walletItem.name);
      
      final syncDuration = Duration(seconds: 5 + _random.nextInt(5));
      await _logAction('Syncing for ${syncDuration.inSeconds} seconds', result: walletItem.name);
      await Future.delayed(syncDuration);
      
      final syncStatus = wallet.syncStatus;
      await _logAction('Sync status', result: '${walletItem.name}: ${syncStatus.runtimeType}');
      
      await wallet.stopSync();
      await _logAction('Sync stopped for wallet', result: walletItem.name);
      
      await _logWalletState(wallet);
      
      await _closeWallet(wallet);
    } catch (e) {
      await _logAction('Error during sync operation', result: '${walletItem.name}: $e');
      throw e;
    }
  }
  
  Future<void> _closeWallet(WalletBase wallet) async {
    final walletName = wallet.name;
    await _logAction('Starting wallet close procedure', result: walletName);
    
    try {
      if (wallet.syncStatus is SyncingSyncStatus) {
        await wallet.stopSync();
        await _logAction('Stopped sync before closing', result: walletName);
      }
      
      await wallet.close(shouldCleanup: true);
      await _logAction('Wallet closed successfully', result: walletName);
    } catch (e) {
      await _logAction('Error in wallet close procedure', result: '$walletName: $e');
      throw e;
    }
  }
  
  Future<void> _checkAndCreateWallets() async {
    await _incrementOperationStat('checkAndCreateWallets');
    
    currentOperation = 'Checking wallet counts and creating new ones if needed';
    await _logAction('Performing wallet count check and creation');
    await _ensureEnoughWallets();
  }
  
  Future<void> _logWalletStateByName(String walletName, String data) async {
    try {
      final appDir = await getAppDir();
      final lastFuzzFile = File(p.join(appDir.path, _lastFuzzFile));
      
      await lastFuzzFile.writeAsString('$walletName|$data\n', mode: FileMode.append);
      await _logAction('Updated wallet state file');
    } catch (e) {
      await _logAction('Failed to update wallet state file', result: e.toString());
    }
  }

  Future<void> _logWalletState(WalletBase wallet) async {
    try {
      final appDir = await getAppDir();
      final walletInfo = _getWalletStateInfo(wallet);
      final lastFuzzFile = File(p.join(appDir.path, _lastFuzzFile));
      
      await lastFuzzFile.writeAsString('$walletInfo\n', mode: FileMode.append);
      await _logAction('Updated wallet state file', result: walletInfo);
    } catch (e) {
      await _logAction('Failed to update wallet state file', result: e.toString());
    }
  }
  
  String _getWalletStateInfo(WalletBase wallet) {
    String seed = wallet.seed??'noseed';
    String keys = "";
    try {
      keys = wallet.keys.toString();
    } catch (e) {
      keys = 'nokeys$e';
    }
    final data = '${wallet.name}|${wallet.type}|${seed}|${keys}'.replaceAll("\n", ";");
    return data;
  }
  
  Future<void> _clearLastFuzzFile() async {
    try {
      final appDir = await getAppDir();
      final lastFuzzFile = File(p.join(appDir.path, _lastFuzzFile));
      
      if (await lastFuzzFile.exists()) {
        await lastFuzzFile.writeAsString('');
        await _logAction('Cleared last_fuzz file');
      }
    } catch (e) {
      await _logAction('Failed to clear last_fuzz file', result: e.toString());
    }
  }

  Map<String, dynamic> getOperationStatsWithTiming() {
    final now = DateTime.now();
    final runDuration = now.difference(appStartDate);
    final totalOps = operationStats.values.fold(0, (a, b) => a + b);
    
    double opsPerHour = 0;
    if (runDuration.inMinutes >= 1) {
      final runHours = runDuration.inMilliseconds / (1000 * 60 * 60);
      opsPerHour = totalOps / runHours;
    }
    
    return {
      'stats': Map.from(operationStats),
      'totalOperations': totalOps,
      'runningTimeMinutes': runDuration.inMinutes,
      'operationsPerHour': opsPerHour,
      'startTimestamp': appStartDate.toIso8601String(),
      'currentTimestamp': now.toIso8601String(),
    };
  }
} 