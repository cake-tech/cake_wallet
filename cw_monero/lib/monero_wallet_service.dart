import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_core/monero_wallet_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_monero/api/account_list.dart';
import 'package:cw_monero/api/wallet_manager.dart' as monero_wallet_manager;
import 'package:cw_monero/api/wallet_manager.dart';
import 'package:cw_monero/bip39_seed.dart';
import 'package:cw_monero/ledger.dart';
import 'package:cw_monero/monero_wallet.dart';
import 'package:hive/hive.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:monero/monero.dart' as monero;
import 'package:polyseed/polyseed.dart';

enum MoneroSeedType { polyseed, legacy, bip39 }

class MoneroNewWalletCredentials extends WalletCredentials {
  MoneroNewWalletCredentials(
      {required String name,
      required this.language,
      required this.seedType,
      String? password,
      this.passphrase,
      this.mnemonic})
      : super(name: name, password: password);

  final String language;
  final MoneroSeedType seedType;
  final String? passphrase;
  final String? mnemonic;
}

class MoneroRestoreWalletFromHardwareCredentials extends WalletCredentials {
  MoneroRestoreWalletFromHardwareCredentials(
      {required String name,
      required this.ledgerConnection,
      int height = 0,
      String? password})
      : super(name: name, password: password, height: height);
  LedgerConnection ledgerConnection;
}

class MoneroRestoreWalletFromSeedCredentials extends WalletCredentials {
  MoneroRestoreWalletFromSeedCredentials(
      {required String name,
      required this.mnemonic,
      required this.passphrase,
      int height = 0,
      String? password})
      : super(name: name, password: password, height: height);

  final String mnemonic;
  final String passphrase;
}

class MoneroWalletLoadingException implements Exception {
  @override
  String toString() => 'Failure to load the wallet.';
}

class MoneroRestoreWalletFromKeysCredentials extends WalletCredentials {
  MoneroRestoreWalletFromKeysCredentials(
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

enum OpenWalletTry {
  initial,
  cacheRestored,
  cacheRemoved,
}

class MoneroWalletService extends WalletService<
    MoneroNewWalletCredentials,
    MoneroRestoreWalletFromSeedCredentials,
    MoneroRestoreWalletFromKeysCredentials,
    MoneroRestoreWalletFromHardwareCredentials> {
  MoneroWalletService(this.walletInfoSource, this.unspentCoinsInfoSource);

  final Box<WalletInfo> walletInfoSource;
  final Box<UnspentCoinsInfo> unspentCoinsInfoSource;

  static bool walletFilesExist(String path) =>
      !File(path).existsSync() && !File('$path.keys').existsSync();

  @override
  WalletType getType() => WalletType.monero;

  @override
  Future<MoneroWallet> create(MoneroNewWalletCredentials credentials,
      {bool? isTestnet}) async {
    try {
      final path = await pathForWallet(name: credentials.name, type: getType());

      if (credentials.seedType == MoneroSeedType.bip39) {
        return _restoreFromBip39(
          path: path,
          password: credentials.password!,
          mnemonic: credentials.mnemonic ?? getBip39Seed(),
          passphrase: credentials.passphrase,
          walletInfo: credentials.walletInfo!,
        );
      }

      if (credentials.seedType == MoneroSeedType.polyseed) {
        final polyseed = Polyseed.create();
        final lang = PolyseedLang.getByEnglishName(credentials.language);

        if (credentials.passphrase != null)
          polyseed.crypt(credentials.passphrase!);

        final heightOverride = getMoneroHeigthByDate(
            date: DateTime.now().subtract(Duration(days: 2)));

        return _restoreFromPolyseed(path, credentials.password!, polyseed,
            credentials.walletInfo!, lang,
            overrideHeight: heightOverride, passphrase: credentials.passphrase);
      }

      monero_wallet_manager.createWallet(
          path: path,
          password: credentials.password!,
          language: credentials.language,
          passphrase: credentials.passphrase ?? "");
      final wallet = MoneroWallet(
          walletInfo: credentials.walletInfo!,
          unspentCoinsInfo: unspentCoinsInfoSource,
          password: credentials.password!);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      printV('MoneroWalletsManager Error: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<bool> isWalletExit(String name) async {
    try {
      final path = await pathForWallet(name: name, type: getType());
      return monero_wallet_manager.isWalletExist(path: path);
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      printV('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<MoneroWallet> openWallet(String name, String password,
      {OpenWalletTry openWalletTry = OpenWalletTry.initial}) async {
    try {
      final path = await pathForWallet(name: name, type: getType());

      if (walletFilesExist(path)) await repairOldAndroidWallet(name);

      await monero_wallet_manager
          .openWallet(path: path, password: password);
      final walletInfo = walletInfoSource.values
          .firstWhere((info) => info.id == WalletBase.idFor(name, getType()));
      final wallet = MoneroWallet(
          walletInfo: walletInfo,
          unspentCoinsInfo: unspentCoinsInfoSource,
          password: password);

      if (wallet.isHardwareWallet) {
        wallet.setLedgerConnection(gLedger!);
        gLedger = null;
      }

      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.

      switch (openWalletTry) {
        case OpenWalletTry.initial:
          await restoreOrResetWalletFiles(name);
          return await openWallet(name, password, openWalletTry: OpenWalletTry.cacheRestored);
        case OpenWalletTry.cacheRestored:
          await removeCache(name);
          return await openWallet(name, password, openWalletTry: OpenWalletTry.cacheRemoved);
        case OpenWalletTry.cacheRemoved:
          rethrow;
      }
    }
  }

  @override
  Future<void> remove(String wallet) async {
    final path = await pathForWalletDir(name: wallet, type: getType());
    if (openedWalletsByPath["$path/$wallet"] != null) {
      // NOTE: this is realistically only required on windows.
      printV("closing wallet");
      final w = openedWalletsByPath["$path/$wallet"]!;
      final wmaddr = wmPtr.ffiAddress();
      final waddr = w.ffiAddress();
      openedWalletsByPath.remove("$path/$wallet");
      await closeWalletAwaitIfShould(wmaddr, waddr);
      printV("wallet closed");
    }

    final file = Directory(path);
    final isExist = file.existsSync();

    if (isExist) {
      await file.delete(recursive: true);
    }

    final walletInfo = walletInfoSource.values
        .firstWhere((info) => info.id == WalletBase.idFor(wallet, getType()));
    await walletInfoSource.delete(walletInfo.key);
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = walletInfoSource.values.firstWhere(
        (info) => info.id == WalletBase.idFor(currentName, getType()));
    final currentWallet = MoneroWallet(
      walletInfo: currentWalletInfo,
      unspentCoinsInfo: unspentCoinsInfoSource,
      password: password,
    );

    await currentWallet.renameWalletFiles(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }

  @override
  Future<MoneroWallet> restoreFromKeys(MoneroRestoreWalletFromKeysCredentials credentials,
      {bool? isTestnet}) async {
    try {
      final path = await pathForWallet(name: credentials.name, type: getType());
      monero_wallet_manager.restoreWalletFromKeys(
          path: path,
          password: credentials.password!,
          language: credentials.language,
          restoreHeight: credentials.height!,
          address: credentials.address,
          viewKey: credentials.viewKey,
          spendKey: credentials.spendKey);
      final wallet = MoneroWallet(
          walletInfo: credentials.walletInfo!,
          unspentCoinsInfo: unspentCoinsInfoSource,
          password: credentials.password!);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      printV('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<MoneroWallet> restoreFromHardwareWallet(
      MoneroRestoreWalletFromHardwareCredentials credentials) async {
    try {
      final path = await pathForWallet(name: credentials.name, type: getType());
      final password = credentials.password;
      final height = credentials.height;

      enableLedgerExchange(credentials.ledgerConnection);

      await monero_wallet_manager.restoreWalletFromHardwareWallet(
          path: path,
          password: password!,
          restoreHeight: height!,
          deviceName: 'Ledger');

      final wallet = MoneroWallet(
          walletInfo: credentials.walletInfo!,
          unspentCoinsInfo: unspentCoinsInfoSource,
          password: credentials.password!);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      printV('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<MoneroWallet> restoreFromSeed(
      MoneroRestoreWalletFromSeedCredentials credentials,
      {bool? isTestnet}) async {
    // Restore from Polyseed
    try {
      if (Polyseed.isValidSeed(credentials.mnemonic)) {
        return restoreFromPolyseed(credentials);
      }
    } catch (e) {
      printV("Polyseed restore failed: $e");
      rethrow;
    }

    try {
      if (isBip39Seed(credentials.mnemonic)) {
        final path =
            await pathForWallet(name: credentials.name, type: getType());

        return _restoreFromBip39(
          path: path,
          password: credentials.password!,
          mnemonic: credentials.mnemonic,
          walletInfo: credentials.walletInfo!,
          overrideHeight: credentials.height!,
          passphrase: credentials.passphrase,
        );
      }
    } catch (e) {
      printV("Bip39 restore failed: $e");
      rethrow;
    }

    try {
      final path = await pathForWallet(name: credentials.name, type: getType());

      monero_wallet_manager.restoreWalletFromSeedSync(
          path: path,
          password: credentials.password!,
          passphrase: credentials.passphrase,
          seed: credentials.mnemonic,
          restoreHeight: credentials.height!);
      final wallet = MoneroWallet(
          walletInfo: credentials.walletInfo!,
          unspentCoinsInfo: unspentCoinsInfoSource,
          password: credentials.password!);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      printV('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }

  Future<MoneroWallet> _restoreFromBip39({
    required String path,
    required String password,
    required String mnemonic,
    required WalletInfo walletInfo,
    String? passphrase,
    int? overrideHeight,
  }) async {
    walletInfo.derivationInfo = DerivationInfo(
        derivationType: DerivationType.bip39,
        derivationPath: "m/44'/128'/0'/0/0",
    );

    final legacyMnemonic =
        getLegacySeedFromBip39(mnemonic, passphrase: passphrase ?? "");
    final height =
        overrideHeight ?? getMoneroHeigthByDate(date: DateTime.now());

    walletInfo.isRecovery = true;
    walletInfo.restoreHeight = height;

    monero_wallet_manager.restoreWalletFromSeedSync(
      path: path,
      password: password,
      passphrase: '',
      seed: legacyMnemonic,
      restoreHeight: height,
    );

    currentWallet!.setCacheAttribute(
        key: "cakewallet.seed.bip39", value: mnemonic);
    currentWallet!.setCacheAttribute(
        key: "cakewallet.passphrase", value: passphrase ?? '');

    currentWallet!.store();

    final wallet = MoneroWallet(
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfoSource,
      password: password,
    );
    await wallet.init();

    return wallet;
  }

  Future<MoneroWallet> restoreFromPolyseed(
      MoneroRestoreWalletFromSeedCredentials credentials) async {
    try {
      final path = await pathForWallet(name: credentials.name, type: getType());
      final polyseedCoin = PolyseedCoin.POLYSEED_MONERO;
      final lang = PolyseedLang.getByPhrase(credentials.mnemonic);
      final polyseed =
          Polyseed.decode(credentials.mnemonic, lang, polyseedCoin);

      return _restoreFromPolyseed(
          path, credentials.password!, polyseed, credentials.walletInfo!, lang,
          passphrase: credentials.passphrase);
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      printV('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }

  Future<MoneroWallet> _restoreFromPolyseed(String path, String password,
      Polyseed polyseed, WalletInfo walletInfo, PolyseedLang lang,
      {PolyseedCoin coin = PolyseedCoin.POLYSEED_MONERO,
      int? overrideHeight,
      String? passphrase}) async {
    if (polyseed.isEncrypted == false && (passphrase ?? '') != "") {
      // Fallback to the different passphrase offset method, when a passphrase
      // was provided but the polyseed is not encrypted.
      monero_wallet_manager.restoreWalletFromPolyseedWithOffset(
          path: path,
          password: password,
          seed: polyseed.encode(lang, coin),
          seedOffset: passphrase ?? '',
          language: "English");

      final wallet = MoneroWallet(
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource,
        password: password,
      );
      await wallet.init();

      return wallet;
    }

    if (polyseed.isEncrypted) polyseed.crypt(passphrase ?? '');

    final height = overrideHeight ??
        getMoneroHeigthByDate(date: DateTime.fromMillisecondsSinceEpoch(polyseed.birthday * 1000));
    final spendKey = polyseed.generateKey(coin, 32).toHexString();
    final seed = polyseed.encode(lang, coin);

    walletInfo.isRecovery = true;
    walletInfo.restoreHeight = height;

    monero_wallet_manager.restoreWalletFromSpendKeySync(
        path: path,
        password: password,
        seed: seed,
        language: lang.nameEnglish,
        restoreHeight: height,
        spendKey: spendKey);


    currentWallet!.setCacheAttribute(key: "cakewallet.seed", value: seed);
    currentWallet!.setCacheAttribute(key: "cakewallet.passphrase", value: passphrase??'');

    final wallet = MoneroWallet(
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfoSource,
      password: password,
    );
    await wallet.init();

    return wallet;
  }

  Future<void> repairOldAndroidWallet(String name) async {
    try {
      if (!Platform.isAndroid) return;

      final oldAndroidWalletDirPath = await outdatedAndroidPathForWalletDir(name: name);
      final dir = Directory(oldAndroidWalletDirPath);

      if (!dir.existsSync()) return;

      final newWalletDirPath = await pathForWalletDir(name: name, type: getType());

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

  @override
  Future<String> getSeeds(String name, String password, WalletType type) async {
    try {
      final path = await pathForWallet(name: name, type: getType());

      if (walletFilesExist(path)) await repairOldAndroidWallet(name);

      await monero_wallet_manager
          .openWallet(path: path, password: password);
      final walletInfo = walletInfoSource.values
          .firstWhere((info) => info.id == WalletBase.idFor(name, getType()));
      final wallet = MoneroWallet(
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource,
        password: password,
      );
      return wallet.seed;
    } catch (_) {
      // if the file couldn't be opened or read
      return '';
    }
  }

  @override
  bool requireHardwareWalletConnection(String name) {
    return walletInfoSource.values
            .firstWhereOrNull(
                (info) => info.id == WalletBase.idFor(name, getType()))
            ?.isHardwareWallet ??
        false;
  }
}

Future<void> closeWalletAwaitIfShould(int wmaddr, int waddr) async {
  if (Platform.isWindows) {
    await Isolate.run(() {
      monero.WalletManager_closeWallet(
          Pointer.fromAddress(wmaddr), Pointer.fromAddress(waddr), true);
      monero.WalletManager_errorString(Pointer.fromAddress(wmaddr));
    });
  } else {
    unawaited(Isolate.run(() {
      monero.WalletManager_closeWallet(
          Pointer.fromAddress(wmaddr), Pointer.fromAddress(waddr), true);
      monero.WalletManager_errorString(Pointer.fromAddress(wmaddr));
    }));
  }
}