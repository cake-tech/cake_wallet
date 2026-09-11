import 'dart:ffi';
import 'dart:io';
import 'package:cw_core/exceptions.dart' show WalletDeprecationException;
import 'package:cw_core/monero_wallet_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_wownero/api/account_list.dart';
import 'package:cw_wownero/api/exceptions/wallet_opening_exception.dart';
import 'package:cw_wownero/api/wallet_manager.dart' as wownero_wallet_manager;
import 'package:cw_wownero/api/wallet_manager.dart';
import 'package:cw_wownero/wownero_wallet.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:polyseed/polyseed.dart';
import 'package:monero/wownero.dart' as wownero;

class WowneroNewWalletCredentials extends WalletCredentials {
  WowneroNewWalletCredentials(
      {required String name,
      required this.language,
      required this.isPolyseed,
      this.passphrase,
      String? password})
      : super(name: name, password: password);

  final String language;
  final bool isPolyseed;
  final String? passphrase;
}

class WowneroRestoreWalletFromSeedCredentials extends WalletCredentials {
  WowneroRestoreWalletFromSeedCredentials(
      {required String name,
      required this.mnemonic,
      required this.passphrase,
      int height = 0,
      String? password})
      : super(name: name, password: password, height: height);

  final String mnemonic;
  final String passphrase;
}

class WowneroWalletLoadingException implements Exception {
  @override
  String toString() => 'Failure to load the wallet.';
}

class WowneroRestoreWalletFromKeysCredentials extends WalletCredentials {
  WowneroRestoreWalletFromKeysCredentials(
      {required String name,
      required String password,
      required this.language,
      required this.address,
      required this.viewKey,
      required this.spendKey,
      int height = 0})
      : super(name: name, password: password, height: height);

  final String language;
  final String address;
  final String viewKey;
  final String spendKey;
}

class WowneroWalletService extends WalletService<
    WowneroNewWalletCredentials,
    WowneroRestoreWalletFromSeedCredentials,
    WowneroRestoreWalletFromKeysCredentials,
    WowneroNewWalletCredentials> {
  WowneroWalletService(this.unspentCoinsInfoSource);

  final Box<UnspentCoinsInfo> unspentCoinsInfoSource;

  static bool walletFilesExist(String path) =>
      !File(path).existsSync() && !File('$path.keys').existsSync();

  @override
  WalletType getType() => WalletType.wownero;

  @override
  Future<WowneroWallet> create(WowneroNewWalletCredentials credentials, {bool? isTestnet}) async {
    try {
      final path = await pathForWallet(id: credentials.walletInfo!.id, type: getType());

      if (credentials.isPolyseed) {
        final polyseed = Polyseed.create();
        final lang = PolyseedLang.getByEnglishName(credentials.language);

        if (credentials.passphrase != null) polyseed.crypt(credentials.passphrase!);

        final heightOverride =
            getWowneroHeightByDate(date: DateTime.now().subtract(Duration(days: 2)));

        return _restoreFromPolyseed(
            path, credentials.password!, polyseed, credentials.walletInfo!, lang,
            overrideHeight: heightOverride, passphrase: credentials.passphrase);
      }

      await wownero_wallet_manager.createWallet(
          path: path,
          password: credentials.password!,
          language: credentials.language,
          passphrase: credentials.passphrase ?? '');
      final wallet = WowneroWallet(
          walletInfo: credentials.walletInfo!,
          derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
          unspentCoinsInfo: unspentCoinsInfoSource,
          password: credentials.password!);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      printV('WowneroWalletsManager Error: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<bool> isWalletExit(WalletInfo walletInfo) async {
    try {
      return wownero_wallet_manager.isWalletExist(path: walletInfo.path);
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      printV('WowneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<WowneroWallet> openWallet(WalletInfo walletInfo, String password) async {
    WowneroWallet? wallet;
    final name = walletInfo.name;
    try {
      final path = walletInfo.path;

      if (walletFilesExist(path)) {
        await repairOldAndroidWallet(walletInfo);
      }

      await wownero_wallet_manager.openWalletAsync({'path': path, 'password': password});

      wallet = WowneroWallet(
          walletInfo: walletInfo,
          derivationInfo: await walletInfo.getDerivationInfo(),
          unspentCoinsInfo: unspentCoinsInfoSource,
          password: password);
      throw WalletDeprecationException(seed: wallet.seed, curr: wallet.currency);

      final isValid = wallet.walletAddresses.validate();

      if (!isValid) {
        await restoreOrResetWalletFiles(walletInfo);
        wallet.close(shouldCleanup: false);
        return openWallet(walletInfo, password);
      }

      await wallet.init();
      return wallet;
    } catch (e, s) {
      rethrow;
      // TODO: Implement Exception for wallet list service.

      final bool isBadAlloc = e.toString().contains('bad_alloc') ||
          (e is WalletOpeningException &&
              (e.message == 'std::bad_alloc' || e.message.contains('bad_alloc')));

      final bool doesNotCorrespond = e.toString().contains('does not correspond') ||
          (e is WalletOpeningException && e.message.contains('does not correspond'));

      final bool isMissingCacheFilesIOS = e.toString().contains('basic_string') ||
          (e is WalletOpeningException && e.message.contains('basic_string'));

      final bool isMissingCacheFilesAndroid = e.toString().contains('input_stream') ||
          e.toString().contains('input stream error') ||
          (e is WalletOpeningException &&
              (e.message.contains('input_stream') || e.message.contains('input stream error')));

      final bool invalidSignature = e.toString().contains('invalid signature') ||
          (e is WalletOpeningException && e.message.contains('invalid signature'));

      if (!isBadAlloc &&
          !doesNotCorrespond &&
          !isMissingCacheFilesIOS &&
          !isMissingCacheFilesAndroid &&
          !invalidSignature &&
          wallet != null &&
          wallet.onError != null) {
        wallet.onError!(FlutterErrorDetails(exception: e, stack: s));
      }

      await restoreOrResetWalletFiles(walletInfo);
      return openWallet(walletInfo, password);
    }
  }

  @override
  Future<void> remove(WalletInfo walletInfo) async {
    final path = walletInfo.dirPath;
    if (openedWalletsByPath["$path/${walletInfo.name}"] != null) {
      printV("closing wallet");
      final wmaddr = wmPtr.address;
      final waddr = openedWalletsByPath["$path/${walletInfo.name}"]!.address;
      wownero.WalletManager_closeWallet(
          Pointer.fromAddress(wmaddr), Pointer.fromAddress(waddr), false);
      openedWalletsByPath.remove("$path/${walletInfo.name}");
      printV("wallet closed");
    }

    await super.remove(walletInfo);
  }

  @override
  Future<WowneroWallet> restoreFromKeys(WowneroRestoreWalletFromKeysCredentials credentials,
      {bool? isTestnet}) async {
    try {
      final path = await pathForWallet(id: credentials.walletInfo!.id, type: getType());
      await wownero_wallet_manager.restoreFromKeys(
          path: path,
          password: credentials.password!,
          language: credentials.language,
          restoreHeight: credentials.height!,
          address: credentials.address,
          viewKey: credentials.viewKey,
          spendKey: credentials.spendKey);
      final wallet = WowneroWallet(
          walletInfo: credentials.walletInfo!,
          derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
          unspentCoinsInfo: unspentCoinsInfoSource,
          password: credentials.password!);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      printV('WowneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<WowneroWallet> restoreFromHardwareWallet(WowneroNewWalletCredentials credentials) {
    throw UnimplementedError(
        "Restoring a Wownero wallet from a hardware wallet is not yet supported!");
  }

  @override
  Future<WowneroWallet> restoreFromSeed(WowneroRestoreWalletFromSeedCredentials credentials,
      {bool? isTestnet}) async {
    // Restore from Polyseed
    if (Polyseed.isValidSeed(credentials.mnemonic)) {
      return restoreFromPolyseed(credentials);
    }

    try {
      final path = await pathForWallet(id: credentials.walletInfo!.id, type: getType());
      await wownero_wallet_manager.restoreFromSeed(
          path: path,
          password: credentials.password!,
          passphrase: credentials.passphrase,
          seed: credentials.mnemonic,
          restoreHeight: credentials.height!);
      final wallet = WowneroWallet(
          walletInfo: credentials.walletInfo!,
          derivationInfo: await credentials.walletInfo!.getDerivationInfo(),
          unspentCoinsInfo: unspentCoinsInfoSource,
          password: credentials.password!);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      printV('WowneroWalletsManager Error: $e');
      rethrow;
    }
  }

  Future<WowneroWallet> restoreFromPolyseed(
      WowneroRestoreWalletFromSeedCredentials credentials) async {
    try {
      final path = await pathForWallet(id: credentials.walletInfo!.id, type: getType());
      final polyseedCoin = PolyseedCoin.POLYSEED_WOWNERO;
      final lang = PolyseedLang.getByPhrase(credentials.mnemonic);
      final polyseed = Polyseed.decode(credentials.mnemonic, lang, polyseedCoin);

      return _restoreFromPolyseed(
          path, credentials.password!, polyseed, credentials.walletInfo!, lang,
          passphrase: credentials.passphrase);
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      printV('WowneroWalletsManager Error: $e');
      rethrow;
    }
  }

  Future<WowneroWallet> _restoreFromPolyseed(
      String path, String password, Polyseed polyseed, WalletInfo walletInfo, PolyseedLang lang,
      {PolyseedCoin coin = PolyseedCoin.POLYSEED_WOWNERO,
      int? overrideHeight,
      String? passphrase}) async {
    if (polyseed.isEncrypted == false && (passphrase ?? '') != "") {
      // Fallback to the different passphrase offset method, when a passphrase
      // was provided but the polyseed is not encrypted.
      wownero_wallet_manager.restoreWalletFromPolyseedWithOffset(
          path: path,
          password: password,
          seed: polyseed.encode(lang, coin),
          seedOffset: passphrase ?? '',
          language: "English");

      final wallet = WowneroWallet(
        walletInfo: walletInfo,
        derivationInfo: await walletInfo.getDerivationInfo(),
        unspentCoinsInfo: unspentCoinsInfoSource,
        password: password,
      );
      await wallet.init();

      return wallet;
    }

    if (polyseed.isEncrypted) polyseed.crypt(passphrase ?? '');

    final height = overrideHeight ??
        getWowneroHeightByDate(date: DateTime.fromMillisecondsSinceEpoch(polyseed.birthday * 1000));
    final spendKey = polyseed.generateKey(coin, 32).toHexString();
    final seed = polyseed.encode(lang, coin);

    walletInfo.isRecovery = true;
    walletInfo.restoreHeight = height;

    await wownero_wallet_manager.restoreFromSpendKey(
        path: path,
        password: password,
        seed: seed,
        language: lang.nameEnglish,
        restoreHeight: height,
        spendKey: spendKey);

    wownero.Wallet_setCacheAttribute(wptr!, key: "cakewallet.seed", value: seed);
    wownero.Wallet_setCacheAttribute(wptr!, key: "cakewallet.passphrase", value: passphrase ?? '');

    final wallet = WowneroWallet(
        walletInfo: walletInfo,
        derivationInfo: await walletInfo.getDerivationInfo(),
        unspentCoinsInfo: unspentCoinsInfoSource,
        password: password);
    await wallet.init();

    return wallet;
  }

  Future<void> repairOldAndroidWallet(WalletInfo walletInfo) async {
    try {
      if (!Platform.isAndroid) {
        return;
      }

      final oldAndroidWalletDirPath = await outdatedAndroidPathForWalletDir(name: walletInfo.name);
      final dir = Directory(oldAndroidWalletDirPath);

      if (!dir.existsSync()) {
        return;
      }

      final newWalletDirPath = walletInfo.dirPath;

      dir.listSync().forEach((f) {
        final file = File(f.path);
        final name = f.path.split('/').last;
        final newPath = newWalletDirPath + '/$name';
        final newFile = File(newPath);

        if (!newFile.existsSync()) {
          newFile.createSync();
        }
        newFile.writeAsBytesSync(file.readAsBytesSync());
      });
    } catch (e) {
      printV(e.toString());
    }
  }
}
