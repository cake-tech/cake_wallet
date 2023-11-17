import 'dart:io';

import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/view_model/settings/sync_mode.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/di.dart';

const moneroSyncTaskKey = "com.fotolockr.cakewallet.monero_sync_task";
const bitcoinSilentPaymentsSyncTaskKey = "com.fotolockr.cakewallet.bitcoin_sync_task";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case moneroSyncTaskKey:

          /// The work manager runs on a separate isolate from the main flutter isolate.
          /// thus we initialize app configs first; hive, getIt, etc...
          await initializeAppConfigs();

          final walletLoadingService = getIt.get<WalletLoadingService>();

          final node = getIt.get<SettingsStore>().getCurrentNode(WalletType.monero);

          final typeRaw = getIt.get<SharedPreferences>().getInt(PreferencesKey.currentWalletType);

          WalletBase? wallet;

          if (inputData!['sync_all'] as bool) {
            /// get all Monero wallets of the user and sync them
            final List<WalletListItem> moneroWallets = getIt
                .get<WalletListViewModel>()
                .wallets
                .where((element) => element.type == WalletType.monero)
                .toList();

            for (int i = 0; i < moneroWallets.length; i++) {
              wallet = await walletLoadingService.load(WalletType.monero, moneroWallets[i].name);

              await wallet.connectToNode(node: node);
              await wallet.startSync();
            }
          } else {
            /// if the user chose to sync only active wallet
            /// if the current wallet is monero; sync it only
            if (typeRaw == WalletType.monero.index) {
              final name =
                  getIt.get<SharedPreferences>().getString(PreferencesKey.currentWalletName);

              wallet = await walletLoadingService.load(WalletType.monero, name!);

              await wallet.connectToNode(node: node);
              await wallet.startSync();
            }
          }

          if (wallet?.syncStatus.progress() == null) {
            return Future.error("No Monero wallet found");
          }

          for (int i = 0;; i++) {
            await Future<void>.delayed(const Duration(seconds: 1));
            if (wallet?.syncStatus.progress() == 1.0) {
              break;
            }
            if (i > 600) {
              return Future.error("Synchronization Timed out");
            }
          }
          break;

        case bitcoinSilentPaymentsSyncTaskKey:

          /// The work manager runs on a separate isolate from the main flutter isolate.
          /// thus we initialize app configs first; hive, getIt, etc...
          await initializeAppConfigs();

          final walletLoadingService = getIt.get<WalletLoadingService>();

          final name = getIt.get<SharedPreferences>().getString(PreferencesKey.currentWalletName);
          final wallet =
              await walletLoadingService.load(WalletType.bitcoin, name!) as BitcoinWallet;

          String? checkpointTx = inputData!["checkpoint_tx"] as String?;

          try {
            final height = wallet.walletInfo.restoreHeight;

            print(["HEIGHT:", height]);

            List<String> txids = [];
            int pos = 0;
            while (pos < 150) {
              var txid = await wallet.electrumClient.getTxidFromPos(height: height, pos: pos);
              print(["TXID", txid]);
              txids.add(txid);
              pos++;
            }

            if (checkpointTx != null && checkpointTx.isNotEmpty) {
              txids = txids.sublist(txids.indexOf(checkpointTx) + 1);
            }

            List<BitcoinUnspent> unspentCoins = [];

            for (var txid in txids) {
              checkpointTx = txid.toString();

              List<String> pubkeys = [];
              List<bitcoin.Outpoint> outpoints = [];
              Map<String, bitcoin.Outpoint> outpointsByP2TRpubkey = {};

              // final txInfo =
              //     await wallet.fetchTransactionInfo(hash: txid.toString(), height: height);

              // print(txInfo);

              bool skip = false;
              // obj["vin"].forEach((input) {
              //   if (input["witness"] == null) {
              //     skip = true;
              //     return;
              //   }

              //   final witness = input["witness"] as List<dynamic>;
              //   if (witness.length != 2) {
              //     skip = true;
              //     return;
              //   }

              //   final pubkey = witness[1] as String;
              //   pubkeys.add(pubkey);
              //   outpoints.add(bitcoin.Outpoint(txid: input["txid"] as String, index: input["vout"] as int));
              // });

              // if (skip) continue;

              // int i = 0;
              // obj['vout'].forEach((out) {
              //   if (out["scriptpubkey_type"] != "v1_p2tr") {
              //     return;
              //   }

              //   outpointsByP2TRpubkey[out['scriptpubkey_address'] as String] =
              //       bitcoin.Outpoint(txid: txid.toString(), index: i, value: out["value"] as int);

              //   i++;
              // });

              if (pubkeys.isEmpty && outpoints.isEmpty && outpointsByP2TRpubkey.isEmpty) {
                continue;
              }

              Uint8List sumOfInputPublicKeys =
                  bitcoin.getSumInputPubKeys(pubkeys).toCompressedHex().fromHex;
              final outpointHash = bitcoin.SilentPayment.hashOutpoints(outpoints);

              final result = bitcoin.scanOutputs(
                  wallet.walletAddresses.silentAddress!.scanPrivkey.toCompressedHex().fromHex,
                  wallet.walletAddresses.silentAddress!.spendPubkey.toCompressedHex().fromHex,
                  sumOfInputPublicKeys,
                  outpointHash,
                  outpointsByP2TRpubkey.keys.toList());

              if (result.isEmpty) {
                continue;
              }

              result.forEach((key, value) {
                final outpoint = outpointsByP2TRpubkey[key];

                if (outpoint == null) {
                  return;
                }

                unspentCoins.add(BitcoinUnspent(
                  BitcoinAddressRecord(key, index: 0),
                  outpoint.txid,
                  outpoint.value!,
                  outpoint.index,
                  silentPaymentTweak: value,
                ));
              });
            }

            break;
          } catch (e, stacktrace) {
            print(stacktrace);
            print(e.toString());
            // timeout, wait 30sec
            // return Future.delayed(const Duration(seconds: 30),
            //     () => startRefresh({"checkpoint_tx": checkpointTx ?? ""}));
          }
          break;
      }

      return Future.value(true);
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
      return Future.error(error);
    }
  });
}

class BackgroundTasks {
  void registerSyncTask({bool changeExisting = false}) async {
    try {
      bool hasMonero = getIt
          .get<WalletListViewModel>()
          .wallets
          .any((element) => element.type == WalletType.monero);

      /// if its not android nor ios, or the user has no monero wallets; exit
      if (DeviceInfo.instance.isMobile && hasMonero) {
        final settingsStore = getIt.get<SettingsStore>();

        final SyncMode syncMode = settingsStore.currentSyncMode;
        final bool syncAll = settingsStore.currentSyncAll;

        if (syncMode.type == SyncType.disabled) {
          cancelSyncTask();
          return;
        }

        await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: kDebugMode,
        );

        final inputData = <String, dynamic>{"sync_all": syncAll};
        final constraints = Constraints(
          networkType:
              syncMode.type == SyncType.unobtrusive ? NetworkType.unmetered : NetworkType.connected,
          requiresBatteryNotLow: syncMode.type == SyncType.unobtrusive,
          requiresCharging: syncMode.type == SyncType.unobtrusive,
          requiresDeviceIdle: syncMode.type == SyncType.unobtrusive,
        );

        if (Platform.isIOS) {
          await Workmanager().registerOneOffTask(
            moneroSyncTaskKey,
            moneroSyncTaskKey,
            initialDelay: syncMode.frequency,
            existingWorkPolicy: ExistingWorkPolicy.replace,
            inputData: inputData,
            constraints: constraints,
          );
          return;
        }

        await Workmanager().registerPeriodicTask(
          moneroSyncTaskKey,
          moneroSyncTaskKey,
          initialDelay: syncMode.frequency,
          frequency: syncMode.frequency,
          existingWorkPolicy: changeExisting ? ExistingWorkPolicy.replace : ExistingWorkPolicy.keep,
          inputData: inputData,
          constraints: constraints,
        );
      }

      bool hasBitcoin = getIt
          .get<WalletListViewModel>()
          .wallets
          .any((element) => element.type == WalletType.bitcoin);

      /// if its not android nor ios, or the user has no monero wallets; exit
      if (hasBitcoin) {
        final settingsStore = getIt.get<SettingsStore>();

        final SyncMode syncMode = settingsStore.currentSyncMode;
        final bool syncAll = settingsStore.currentSyncAll;

        if (syncMode.type == SyncType.disabled) {
          cancelSyncTask();
          return;
        }

        await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: kDebugMode,
        );

        final inputData = <String, dynamic>{"sync_all": syncAll};
        final constraints = Constraints(
          networkType:
              syncMode.type == SyncType.unobtrusive ? NetworkType.unmetered : NetworkType.connected,
          requiresBatteryNotLow: syncMode.type == SyncType.unobtrusive,
          requiresCharging: syncMode.type == SyncType.unobtrusive,
          requiresDeviceIdle: syncMode.type == SyncType.unobtrusive,
        );

        if (Platform.isIOS) {
          await Workmanager().registerOneOffTask(
            bitcoinSilentPaymentsSyncTaskKey,
            bitcoinSilentPaymentsSyncTaskKey,
            initialDelay: syncMode.frequency,
            existingWorkPolicy: ExistingWorkPolicy.replace,
            inputData: inputData,
            constraints: constraints,
          );
          return;
        }

        await Workmanager().registerPeriodicTask(
          bitcoinSilentPaymentsSyncTaskKey,
          bitcoinSilentPaymentsSyncTaskKey,
          initialDelay: syncMode.frequency,
          frequency: syncMode.frequency,
          existingWorkPolicy: changeExisting ? ExistingWorkPolicy.replace : ExistingWorkPolicy.keep,
          inputData: inputData,
          constraints: constraints,
        );
      }
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
    }
  }

  void cancelSyncTask() {
    try {
      Workmanager().cancelByUniqueName(moneroSyncTaskKey);
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
    }
  }
}

Future<List<BitcoinUnspent>> startRefresh(Map<dynamic, dynamic> data) async {
  // final rootIsolateToken = data["rootIsolateToken"] as RootIsolateToken;

  // BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

  /// The work manager runs on a separate isolate from the main flutter isolate.
  /// thus we initialize app configs first; hive, getIt, etc...
  await initializeAppConfigs();

  final walletLoadingService = getIt.get<WalletLoadingService>();

  final name = getIt.get<SharedPreferences>().getString(PreferencesKey.currentWalletName);
  final wallet = await walletLoadingService.load(WalletType.bitcoin, name!) as BitcoinWallet;

  String? checkpointTx = data["checkpoint_tx"] as String?;

  try {
    final height = wallet.walletInfo.restoreHeight;

    print(["HEIGHT:", height]);

    List<String> txids = [];
    int pos = 0;
    while (pos < 150) {
      var txid = await wallet.electrumClient.getTxidFromPos(height: height, pos: pos);
      print(["TXID", txid]);
      txids.add(txid);
      pos++;
    }

    if (checkpointTx != null && checkpointTx.isNotEmpty) {
      txids = txids.sublist(txids.indexOf(checkpointTx) + 1);
    }

    List<BitcoinUnspent> unspentCoins = [];

    for (var txid in txids) {
      checkpointTx = txid.toString();

      List<String> pubkeys = [];
      List<bitcoin.Outpoint> outpoints = [];
      Map<String, bitcoin.Outpoint> outpointsByP2TRpubkey = {};

      // final txInfo = await wallet.fetchTransactionInfo(hash: txid.toString(), height: height);

      // print(txInfo);

      bool skip = false;
      // obj["vin"].forEach((input) {
      //   if (input["witness"] == null) {
      //     skip = true;
      //     return;
      //   }

      //   final witness = input["witness"] as List<dynamic>;
      //   if (witness.length != 2) {
      //     skip = true;
      //     return;
      //   }

      //   final pubkey = witness[1] as String;
      //   pubkeys.add(pubkey);
      //   outpoints.add(bitcoin.Outpoint(txid: input["txid"] as String, index: input["vout"] as int));
      // });

      // if (skip) continue;

      // int i = 0;
      // obj['vout'].forEach((out) {
      //   if (out["scriptpubkey_type"] != "v1_p2tr") {
      //     return;
      //   }

      //   outpointsByP2TRpubkey[out['scriptpubkey_address'] as String] =
      //       bitcoin.Outpoint(txid: txid.toString(), index: i, value: out["value"] as int);

      //   i++;
      // });

      if (pubkeys.isEmpty && outpoints.isEmpty && outpointsByP2TRpubkey.isEmpty) {
        continue;
      }

      Uint8List sumOfInputPublicKeys =
          bitcoin.getSumInputPubKeys(pubkeys).toCompressedHex().fromHex;
      final outpointHash = bitcoin.SilentPayment.hashOutpoints(outpoints);

      final result = bitcoin.scanOutputs(
          wallet.walletAddresses.silentAddress!.scanPrivkey.toCompressedHex().fromHex,
          wallet.walletAddresses.silentAddress!.spendPubkey.toCompressedHex().fromHex,
          sumOfInputPublicKeys,
          outpointHash,
          outpointsByP2TRpubkey.keys.toList());

      if (result.isEmpty) {
        continue;
      }

      result.forEach((key, value) {
        final outpoint = outpointsByP2TRpubkey[key];

        if (outpoint == null) {
          return;
        }

        unspentCoins.add(BitcoinUnspent(
          BitcoinAddressRecord(key, index: 0),
          outpoint.txid,
          outpoint.value!,
          outpoint.index,
          silentPaymentTweak: value,
        ));
      });
    }

    return unspentCoins;
  } catch (e, stacktrace) {
    print(stacktrace);
    print(e.toString());
    // timeout, wait 30sec
    return Future.delayed(
        const Duration(seconds: 30), () => startRefresh({"checkpoint_tx": checkpointTx ?? ""}));
  }
}
