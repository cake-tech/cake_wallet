import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletLoadingService {
  WalletLoadingService(this.sharedPreferences, this.keyService, this.walletServiceFactory);

  final SharedPreferences sharedPreferences;
  final KeyService keyService;
  final WalletService Function(WalletType type) walletServiceFactory;

  Future<void> renameWallet(WalletType type, String name, String newName) async {
    final walletService = walletServiceFactory.call(type);
    final password = await keyService.getWalletPassword(walletName: name);

    // Save the current wallet's password to the new wallet name's key
    await keyService.saveWalletPassword(walletName: newName, password: password);
    // Delete previous wallet name from keyService to keep only new wallet's name
    // otherwise keeps duplicate (old and new names)
    await keyService.deleteWalletPassword(walletName: name);

    await walletService.rename(name, password, newName);

    // set shared preferences flag based on previous wallet name
    if (type == WalletType.monero) {
      final oldNameKey = PreferencesKey.moneroWalletUpdateV1Key(name);
      final isPasswordUpdated = sharedPreferences.getBool(oldNameKey) ?? false;
      final newNameKey = PreferencesKey.moneroWalletUpdateV1Key(newName);
      await sharedPreferences.setBool(newNameKey, isPasswordUpdated);
    }
  }

  Future<WalletBase> load(WalletType type, String name) async {
    try {
      final walletService = walletServiceFactory.call(type);
      final password = await keyService.getWalletPassword(walletName: name);
      final wallet = await walletService.openWallet(name, password);

      if (type == WalletType.monero) {
        await updateMoneroWalletPassword(wallet);
      }

      return wallet;
    } catch (error, stack) {
      ExceptionHandler.onError(FlutterErrorDetails(exception: error, stack: stack));

      // try opening another wallet that is not corrupted to give user access to the app
      final walletInfoSource = await CakeHive.openBox<WalletInfo>(WalletInfo.boxName);

      for (var walletInfo in walletInfoSource.values) {
        try {
          final walletService = walletServiceFactory.call(walletInfo.type);
          final password = await keyService.getWalletPassword(walletName: walletInfo.name);
          final wallet = await walletService.openWallet(walletInfo.name, password);

          if (walletInfo.type == WalletType.monero) {
            await updateMoneroWalletPassword(wallet);
          }

          await sharedPreferences.setString(PreferencesKey.currentWalletName, wallet.name);
          await sharedPreferences.setInt(
              PreferencesKey.currentWalletType, serializeToInt(wallet.type));

          return wallet;
        } catch (_) {}
      }

      // if all user's wallets are corrupted throw exception
      throw error;
    }
  }

  Future<void> updateMoneroWalletPassword(WalletBase wallet) async {
    final key = PreferencesKey.moneroWalletUpdateV1Key(wallet.name);
    var isPasswordUpdated = sharedPreferences.getBool(key) ?? false;

    if (isPasswordUpdated) {
      return;
    }

    final password = generateWalletPassword();
    // Save new generated password with backup key for case where
    // wallet will change password, but it will fail to update in secure storage
    final bakWalletName = '#__${wallet.name}_bak__#';
    await keyService.saveWalletPassword(walletName: bakWalletName, password: password);
    await wallet.changePassword(password);
    await keyService.saveWalletPassword(walletName: wallet.name, password: password);
    isPasswordUpdated = true;
    await sharedPreferences.setBool(key, isPasswordUpdated);
  }
}
