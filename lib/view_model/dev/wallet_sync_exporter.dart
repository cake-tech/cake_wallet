import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

part 'wallet_sync_exporter.g.dart';

class WalletSyncExporter = WalletSyncExporterBase with _$WalletSyncExporter;

abstract class WalletSyncExporterBase with Store {
  WalletSyncExporterBase();

  static const String _exportPathKey = 'wallet_sync_export_path';
  static const String _exportIntervalKey = 'wallet_sync_export_interval';

  final walletLoadingService = getIt.get<WalletLoadingService>();
  final walletListViewModel = getIt.get<WalletListViewModel>();
  final settingsStore = getIt.get<SettingsStore>();
  final keyService = getIt.get<KeyService>();

  @observable
  Timer? syncTimer;
  
  @observable
  bool isTimerActive = false;

  @observable
  String exportPath = '';
  
  @observable
  int exportIntervalMinutes = 30;

  @observable
  bool isSyncing = false;

  @observable
  String statusMessage = '';

  @observable
  int progress = 0;

  @observable
  int totalWallets = 0;

  @observable
  int currentWalletIndex = 0;

  @observable
  String lastExportTime = '';

  @observable
  Map<String, dynamic> exportData = {};
  
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    exportPath = prefs.getString(_exportPathKey) ?? await _getDefaultExportPath();
    exportIntervalMinutes = prefs.getInt(_exportIntervalKey) ?? 30;
  }

  Future<String> _getDefaultExportPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/wallet_export.json';
  }

  Future<void> setExportPath(String path) async {
    exportPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_exportPathKey, exportPath);
  }

  Future<void> setExportInterval(int minutes) async {
    exportIntervalMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_exportIntervalKey, exportIntervalMinutes);
    
    if (isTimerActive) {
      stopPeriodicSync();
      startPeriodicSync();
    }
  }

  void startPeriodicSync() {
    stopPeriodicSync();
    syncTimer = Timer.periodic(
      Duration(minutes: exportIntervalMinutes),
      (_) => syncAndExport(),
    );
    isTimerActive = true;
    statusMessage = 'Periodic sync started (every $exportIntervalMinutes minutes)';
  }

  void stopPeriodicSync() {
    syncTimer?.cancel();
    syncTimer = null;
    isTimerActive = false;
    statusMessage = 'Periodic sync stopped';
  }

  Future<void> syncAndExport() async {
    if (isSyncing) {
      statusMessage = 'Sync already in progress';
      return;
    }

    try {
      isSyncing = true;
      statusMessage = 'Starting sync and export process...';
      
      final wallets = walletListViewModel.wallets;
      totalWallets = wallets.length;
      currentWalletIndex = 0;
      progress = 0;

      final Map<String, dynamic> newExportData = {
        'timestamp': DateTime.now().toIso8601String(),
        'wallets': <Map<String, dynamic>>[],
      };

      for (final walletItem in wallets) {
        currentWalletIndex++;
        progress = ((currentWalletIndex / totalWallets) * 100).round();
        statusMessage = 'Processing wallet ${currentWalletIndex}/$totalWallets: ${walletItem.name}';
        
        try {
          final wallet = await walletLoadingService.load(walletItem.type, walletItem.name);
          await _syncWallet(wallet);
          
          final walletData = await _collectWalletData(wallet);
          (newExportData['wallets'] as List).add(walletData);
          
          await wallet.close(shouldCleanup: true);
        } catch (e) {
          (newExportData['wallets'] as List).add({
            'name': walletItem.name,
            'type': walletItem.type.toString(),
            'error': e.toString(),
          });
          statusMessage = 'Error processing ${walletItem.name}: $e';
        }
      }

      exportData = newExportData;
      await _saveJsonToFile(exportData);
      lastExportTime = DateTime.now().toString();
      
      statusMessage = 'Export completed successfully';
    } catch (e) {
      statusMessage = 'Export failed: $e';
    } finally {
      isSyncing = false;
    }
  }

  Future<void> _syncWallet(WalletBase wallet) async {
    final node = settingsStore.getCurrentNode(wallet.type);
    await wallet.connectToNode(node: node);
    await wallet.startSync();
    
    int stuckTicks = 0;
    bool isSynced = false;

    while (!isSynced && stuckTicks < 30) {
      await Future.delayed(const Duration(seconds: 1));
      final syncStatus = wallet.syncStatus;
      
      if (syncStatus is AttemptingSyncStatus || 
          syncStatus is NotConnectedSyncStatus ||
          syncStatus is ConnectedSyncStatus) {
        statusMessage = 'Syncing ${wallet.name}: ${syncStatus.toString()} (stuckTicks: $stuckTicks)';
        stuckTicks++;
      } else {
        stuckTicks = 0;
      }
      
      if (syncStatus is SyncedSyncStatus || syncStatus.progress() > 0.999) {
        isSynced = true;
      }
      
      statusMessage = 'Syncing ${wallet.name}: ${(syncStatus.progress() * 100).round()}%';
    }
  }

  Future<Map<String, dynamic>> _collectWalletData(WalletBase wallet) async {
    final Map<String, dynamic> walletData = {
      'name': wallet.name,
      'type': wallet.type.toString(),
      'balance': {
        'formattedAvailableBalance': wallet.balance[wallet.currency]?.formattedAvailableBalance,
        'formattedAdditionalBalance': wallet.balance[wallet.currency]?.formattedAdditionalBalance,
        'formattedUnAvailableBalance': wallet.balance[wallet.currency]?.formattedUnAvailableBalance,
        'formattedSecondAvailableBalance': wallet.balance[wallet.currency]?.formattedSecondAvailableBalance,
        'formattedSecondAdditionalBalance': wallet.balance[wallet.currency]?.formattedSecondAdditionalBalance,
        'formattedFullAvailableBalance': wallet.balance[wallet.currency]?.formattedFullAvailableBalance,
      },
      'transactions': <Map<String, dynamic>>[],
      'addresses': {
        'primary': wallet.walletAddresses.address,
        'all': wallet.walletAddresses.allAddressesMap,
      }
    };

    final transactions = wallet.transactionHistory.transactions.values;
    for (final tx in transactions) {
      walletData['transactions'].add({
        'id': tx.id,
        'amount': tx.amount.toString(),
        'fee': tx.fee?.toString(),
        'date': tx.date.toIso8601String(),
        'direction': tx.direction.toString(),
        'confirmations': tx.confirmations,
        'isPending': tx.isPending,
      });
    }

    return walletData;
  }

  Future<void> _saveJsonToFile(Map<String, dynamic> data) async {
    try {
      final file = File(exportPath);
      final jsonStr = JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonStr);
      statusMessage = 'Saved to: $exportPath';
    } catch (e) {
      statusMessage = 'Failed to save: $e';
      throw e;
    }
  }
} 