import 'dart:async';

import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/new-ui/widgets/wallet_deprecation_popup.dart';
import 'package:cake_wallet/reactions/on_authentication_state_change.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/exceptions.dart' show WalletDeprecationException;
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletLoadingService {
  WalletLoadingService(
    this.sharedPreferences,
    this.keyService,
    this.walletServiceFactory,
  );

  final SharedPreferences sharedPreferences;
  final KeyService keyService;
  final WalletService Function(WalletType type) walletServiceFactory;

  Future<void> renameWallet(WalletInfo walletInfo, String newName, {String? password}) async {
    try {
      final walletService = walletServiceFactory.call(walletInfo.type);
      final name = walletInfo.name;
      final walletPassword = password ?? (await keyService.getWalletPassword(walletName: name));

      // Save the current wallet's password to the new wallet name's key
      await keyService.saveWalletPassword(walletName: newName, password: walletPassword);
      await walletService.rename(walletInfo, walletPassword, newName);
      await keyService.deleteWalletPassword(walletName: name);

      if (walletInfo.type == WalletType.monero) {
        final oldNameKey = PreferencesKey.moneroWalletUpdateV1Key(name);
        final isPasswordUpdated = sharedPreferences.getBool(oldNameKey) ?? false;
        final newNameKey = PreferencesKey.moneroWalletUpdateV1Key(newName);
        await sharedPreferences.setBool(newNameKey, isPasswordUpdated);
      }
    } catch (error, stack) {
      await ExceptionHandler.resetLastPopupDate();
      await ExceptionHandler.onError(FlutterErrorDetails(exception: error, stack: stack));
    }
  }

  Future<WalletBase> load(WalletInfo walletInfo, {String? password, bool isBackground = false}) async {
    try {
      if (!isBackground) {
        await sharedPreferences.setString(
            PreferencesKey.backgroundSyncLastTrigger(walletInfo.name), DateTime.now().toIso8601String());
      }
      final walletService = walletServiceFactory.call(walletInfo.type);
      final walletPassword = password ?? (await keyService.getWalletPassword(walletName: walletInfo.name));
      final wallet = await walletService.openWallet(walletInfo, walletPassword);

      if (walletInfo.type == WalletType.monero) {
        await updateMoneroWalletPassword(wallet);
      }

      return wallet;
    } catch (error, stack) {
      String corruptedWalletsSeeds = "Corrupted wallets seeds (if retrievable, empty otherwise):";

      if (error is WalletDeprecationException) {
        if (navigatorKey.currentContext != null) {
          showModalBottomSheet(
              context: navigatorKey.currentContext!,
              builder: (context) => WalletDeprecationPopup(
                type: walletInfo.type,
                seed: error.seed,
              ));
        }
      } else {
        await ExceptionHandler.resetLastPopupDate();
        final isLedgerError = await ExceptionHandler.isLedgerError(error);
        if (isLedgerError || await requireHardwareWalletConnection(walletInfo)) rethrow;
        await ExceptionHandler.onError(FlutterErrorDetails(exception: error, stack: stack));
      }

      try {
        corruptedWalletsSeeds += await _getCorruptedWalletSeeds(walletInfo);
      } catch (e) {
        corruptedWalletsSeeds += "\nFailed to fetch ${walletInfo.name} seeds: $e";
      }

      WalletBase? wallet;
      for (var info in await WalletInfo.getAll()) {
        try {
          final walletService = walletServiceFactory.call(info.type);
          final walletPassword = await keyService.getWalletPassword(walletName: info.name);
          wallet = await walletService.openWallet(info, walletPassword);

          if (info.type == WalletType.monero) {
            await updateMoneroWalletPassword(wallet);
          }

          await sharedPreferences.setString(PreferencesKey.currentWalletName, wallet.name);
          await sharedPreferences.setInt(PreferencesKey.currentWalletType, serializeToInt(wallet.type));

          authenticatedErrorStreamController.add(corruptedWalletsSeeds);
        } catch (e) {
          printV(e);
          try {
            final seeds = await _getCorruptedWalletSeeds(info);
            if (!corruptedWalletsSeeds.contains(seeds)) {
              corruptedWalletsSeeds += seeds;
            }
          } catch (e) {
            corruptedWalletsSeeds += "\nFailed to fetch ${info.name} seeds: $e";
          }
        }
      }

      final msg = error.toString() + "\n" + corruptedWalletsSeeds;
      if (navigatorKey.currentContext != null) {
        await showPopUp<void>(
            context: navigatorKey.currentContext!,
            builder: (BuildContext context) => AlertWithTwoActions(
                alertTitle: "Corrupted seeds",
                alertContent: S.of(context).corrupted_seed_notice,
                leftButtonText: S.of(context).cancel,
                rightButtonText: S.of(context).show_seed,
                actionLeftButton: () {
                  if (context.mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                actionRightButton: () => showSeedsPopup(context, msg),
              ));
      } else {
        throw msg;
      }
      if (wallet == null) {
        throw Exception("Wallet is null");
      }
      return wallet;
    }
  }

  Future<void> showSeedsPopup(BuildContext context, String message) async {
    Navigator.of(context).pop();
    await showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertWithTwoActions(
            alertTitle: "Corrupted seeds",
            alertContent: message,
            leftButtonText: S.of(context).copy,
            rightButtonText: S.of(context).ok,
            actionLeftButton: () async {
              await Clipboard.setData(ClipboardData(text: message));
            },
            actionRightButton: () async {
              Navigator.of(context).pop();
            },
          );
        });
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

  Future<String> _getCorruptedWalletSeeds(WalletInfo walletInfo) async {
    final walletService = walletServiceFactory.call(walletInfo.type);
    final password = await keyService.getWalletPassword(walletName: walletInfo.name);

    return "\n\n${walletInfo.type} (${walletInfo.name}): ${await walletService.getSeeds(walletInfo, password)}";
  }

  Future<bool> requireHardwareWalletConnection(WalletInfo walletInfo) async {
    final walletService = walletServiceFactory.call(walletInfo.type);
    return await walletService.requireHardwareWalletConnection(walletInfo);
  }
}
