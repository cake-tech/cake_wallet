import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}