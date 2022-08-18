import 'dart:io';

import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:cake_wallet/main.dart';
import 'package:flutter/foundation.dart';
import 'package:cake_wallet/di.dart';

const moneroSyncTaskKey = "com.cake_wallet.monero_sync_task";

void callbackDispatcher() {
	Workmanager().executeTask((task, inputData) async {
		try {
			switch (task) {
				case moneroSyncTaskKey:
					/// The work manager runs on a separate isolate from the main flutter isolate.
					/// thus we initialize app configs first; hive, getIt, etc...
					await initializeAppConfigs();

					final walletLoadingService = getIt.get<WalletLoadingService>();

					final List<WalletListItem> moneroWallets = getIt.get<WalletListViewModel>()
							.wallets.where((element) => element.type == WalletType.monero).toList();

					for (int i=0;i<moneroWallets.length;i++) {
						await walletLoadingService.load(WalletType.monero, moneroWallets[i].name);
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

class WalletLoadingService {
	WalletLoadingService(
		this.sharedPreferences,
		this.keyService,
		this.walletServiceFactory);

	final SharedPreferences sharedPreferences;
	final KeyService keyService;
	final WalletService Function(WalletType type) walletServiceFactory;

	Future<WalletBase> load(WalletType type, String name) async {
		if (walletServiceFactory == null) {
			throw Exception('WalletLoadingService.walletServiceFactory is not set');
		}
		final walletService = walletServiceFactory?.call(type);
		final password = await keyService.getWalletPassword(walletName: name);
		final wallet = await walletService.openWallet(name, password);

		if (type == WalletType.monero) {
			await upateMoneroWalletPassword(wallet);
		}

		registerSyncTask();

		return wallet;
	}

	Future<void> upateMoneroWalletPassword(WalletBase wallet) async {
		final key = PreferencesKey.moneroWalletUpdateV1Key(wallet.name);
		var isPasswordUpdated = sharedPreferences.getBool(key) ?? false;

		if (isPasswordUpdated) {
			return;
		}

		final password = generateWalletPassword();
		// Save new generated password with backup key for case
		// if wallet will change password, but it will faild to updated in secure storage
		final bakWalletName = '#__${wallet.name}_bak__#';
		await keyService.saveWalletPassword(walletName: bakWalletName, password: password);
		await wallet.changePassword(password);
		await keyService.saveWalletPassword(walletName: wallet.name, password: password);
		isPasswordUpdated = true;
		await sharedPreferences.setBool(key, isPasswordUpdated);
	}

	void registerSyncTask() async {
		try {
			/// if its not android or the user has no monero wallets
			if (!Platform.isAndroid ||
					!getIt.get<WalletListViewModel>().wallets.any((element) => element.type == WalletType.monero)) {
				return;
			}

			await Workmanager().initialize(
				callbackDispatcher,
				isInDebugMode: kDebugMode,
			);

			await Workmanager().registerPeriodicTask(
				moneroSyncTaskKey,
				moneroSyncTaskKey,
				// TODO: change duration to the desired intervals to run this task
				initialDelay: const Duration(hours: 1),
				frequency: Duration(hours: 1),
				existingWorkPolicy: ExistingWorkPolicy.keep,
			);
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