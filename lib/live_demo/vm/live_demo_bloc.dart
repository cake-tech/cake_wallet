import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:cake_wallet/core/reset_service.dart';
import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/live_demo/client/live_demo_client.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/wallet_creation_vm.dart';
import 'package:cw_core/balance_card_style_settings.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'live_demo_event.dart';
part 'live_demo_state.dart';

class NewWalletDefinition {
  final String name;
  final WalletType type;

  NewWalletDefinition(this.name, this.type);
}

class LiveDemoBloc extends Bloc<LiveDemoEvent, LiveDemoState> {
  final LiveDemoClient client;
  final WalletCreationVM walletCreationVM;
  final AppStore appStore;
  final SecureStorage secureStorage;
  final SharedPreferences sharedPreferences;
  final ResetService resetService;

  LiveDemoBloc({required this.client, required this.walletCreationVM, required this.appStore, required this.secureStorage, required this.sharedPreferences, required this.resetService}) : super(LiveDemoInitial()) {
    on<ConnectionRequested>(_onConnectionRequested);
    on<PageReset>(_onPageReset);
  }

  void _onConnectionRequested(ConnectionRequested event, Emitter<LiveDemoState> emit) async {
    try{
      emit(LiveDemoConfiguring("cleaning data"));
      await _cleanAppData();

      emit(LiveDemoConfiguring("connecting"));
      await client.connect(event.host, event.port);

      emit(LiveDemoConfiguring("downloading video"));
      await client.ensureVideoInitialized();

      emit(LiveDemoConfiguring("fetching config"));
      final config = await client.getConfig();
      final List<NewWalletDefinition> walletDefs = (config["wallets"] as List<dynamic>)
          .map((item) {
            item as Map<String, dynamic>;
        final type = stringToWalletType(item["type"] as String? ?? "");
        if (type == null) return null;
        final name = item["name"] as String? ?? "${walletTypeToString(type)} Wallet";

        return NewWalletDefinition(name, type);
      })
          .whereType<NewWalletDefinition>()
          .toList();

      emit(LiveDemoConfiguring("creating wallets"));
      for(final def in walletDefs) {
        walletCreationVM.name = def.name;
        walletCreationVM.type = def.type;
        walletCreationVM.walletCreationService.changeWalletType(type: def.type);
        await walletCreationVM.create();
      }

      emit(LiveDemoReady());


    }catch(e, st) {

      emit(LiveDemoError(e.toString(),st));
    }

  }

  void _onPageReset(PageReset event, Emitter<LiveDemoState> emit) async {
    emit(LiveDemoConfiguring("cleaning"));
    await _cleanAppData();
    emit(LiveDemoInitial());
  }

  Future<void> _cleanAppData() async {
    try {
      if (appStore.wallet != null) {
        await appStore.wallet!.close();
      }
      appStore.wallet = null;
    } catch (e) {
    }

    // Reset shared preference flag for new install
    try {
      await sharedPreferences.setBool(PreferencesKey.isNewInstall, true);
    } catch (e) {
    }

    // Reset auth data
    await resetService.resetAuthDataOnNewInstall(sharedPreferences);

    // wipe secure storage
    try {
      await secureStorage.deleteAll();
    } catch (e) {
    }

    // Delete wallet directories
    try {
      final appDir = await getAppDir();
      final walletsDir = Directory('${appDir.path}/wallets');

      if (walletsDir.existsSync()) {
        walletsDir.deleteSync(recursive: true);
      }
    } catch (e) {
    }

    // Wipe wallet-related database tables
    try {
      await db!.transaction((txn) async {
        await txn.delete(WalletInfoAddressInfo.tableName);
        await txn.delete(WalletInfoAddressMap.tableName);
        await txn.delete(WalletInfoAddress.tableName);
        await txn.delete(DerivationInfo.tableName);
        await txn.delete(WalletInfo.tableName);
        await txn.delete(BalanceCardStyleSettings.tableName);
      });
    } catch (e) {
    }

  }
}
