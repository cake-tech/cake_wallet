import 'package:cake_wallet/core/key_service.dart';
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
  		return wallet;
	}
}