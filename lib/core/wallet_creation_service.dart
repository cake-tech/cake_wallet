import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';

class WalletCreationService {
  WalletCreationService(
      {required WalletType initialType,
      required this.secureStorage,
      required this.keyService,
      required this.sharedPreferences,
      required this.settingsStore,
      required this.walletInfoSource})
      : type = initialType {
    changeWalletType(type: type);
  }

  WalletType type;
  final SecureStorage secureStorage;
  final SharedPreferences sharedPreferences;
  final SettingsStore settingsStore;
  final KeyService keyService;
  final Box<WalletInfo> walletInfoSource;
  WalletService? _service;

  static const _isNewMoneroWalletPasswordUpdated = true;

  void changeWalletType({required WalletType type}) {
    this.type = type;
    _service = getIt.get<WalletService>(param1: type);
  }

  bool exists(String name) {
    final walletName = name.toLowerCase();
    return walletInfoSource.values.any((walletInfo) => walletInfo.name.toLowerCase() == walletName);
  }

  Future<bool> checkIfWalletWithSeedExists(
      WalletCredentials seed, WalletType walletType) async {
    bool walletExists = false;
    for (final w in walletInfoSource.values) {
      if (walletType == w.type) {
        final password = await keyService.getWalletPassword(walletName: w.name);
        walletExists =
            await _service!.checkIfWalletWithSeedExists(w.name, password, seed);
        if (walletExists) break;
      }
    }
    return walletExists;
  }

  Future<bool> checkIfWalletWithKeyExists(
      WalletCredentials credentials, WalletType walletType) async {
    bool walletExists = false;
    for (final w in walletInfoSource.values) {
      if (walletType == w.type) {
        final password = await keyService.getWalletPassword(walletName: w.name);
        walletExists =
            await _service!.checkIfWalletWithKeyExists(w.name, password, credentials);
        if (walletExists) break;
      }
    }
    return walletExists;
  }

  bool typeExists(WalletType type) {
    return walletInfoSource.values.any((walletInfo) => walletInfo.type == type);
  }

  void checkIfExists(String name) {
    if (exists(name)) {
      throw Exception('Wallet with name ${name} already exists!');
    }
  }

  Future<WalletBase> create(WalletCredentials credentials, {bool? isTestnet}) async {
    checkIfExists(credentials.name);
    final password = generateWalletPassword();
    credentials.password = password;
    if (_hasSeedPhraseLengthOption) {
      credentials.seedPhraseLength = settingsStore.seedPhraseLength.value;
    }
    await keyService.saveWalletPassword(password: password, walletName: credentials.name);
    final wallet = await _service!.create(credentials, isTestnet: isTestnet);

    if (wallet.type == WalletType.monero) {
      await sharedPreferences.setBool(
          PreferencesKey.moneroWalletUpdateV1Key(wallet.name), _isNewMoneroWalletPasswordUpdated);
    }

    return wallet;
  }

  bool get _hasSeedPhraseLengthOption {
    switch (type) {
      case WalletType.ethereum:
      case WalletType.bitcoinCash:
      case WalletType.polygon:
      case WalletType.solana:
      case WalletType.tron:
        return true;
      case WalletType.monero:
      case WalletType.wownero:
      case WalletType.none:
      case WalletType.bitcoin:
      case WalletType.litecoin:
      case WalletType.haven:
      case WalletType.nano:
      case WalletType.banano:
      case WalletType.decred:
        return false;
    }
  }

  Future<WalletBase> restoreFromKeys(WalletCredentials credentials, {bool? isTestnet}) async {
    checkIfExists(credentials.name);
    final walletExists = await checkIfWalletWithKeyExists(credentials, credentials.walletInfo!.type);
    if (walletExists) throw Exception('Wallet with public key already exists!');
    final password = generateWalletPassword();
    credentials.password = password;
    await keyService.saveWalletPassword(password: password, walletName: credentials.name);
    final wallet = await _service!.restoreFromKeys(credentials, isTestnet: isTestnet);

    if (wallet.type == WalletType.monero) {
      await sharedPreferences.setBool(
          PreferencesKey.moneroWalletUpdateV1Key(wallet.name), _isNewMoneroWalletPasswordUpdated);
    }

    return wallet;
  }

  Future<WalletBase> restoreFromSeed(WalletCredentials credentials, {bool? isTestnet}) async {
    checkIfExists(credentials.name);
    final walletExists = await checkIfWalletWithSeedExists(credentials, credentials.walletInfo!.type);
    if (walletExists) throw Exception('Wallet with seed already exists!');
    final password = generateWalletPassword();
    credentials.password = password;
    await keyService.saveWalletPassword(password: password, walletName: credentials.name);
    final wallet = await _service!.restoreFromSeed(credentials, isTestnet: isTestnet);

    if (wallet.type == WalletType.monero) {
      await sharedPreferences.setBool(
          PreferencesKey.moneroWalletUpdateV1Key(wallet.name), _isNewMoneroWalletPasswordUpdated);
    }

    return wallet;
  }

  Future<WalletBase> restoreFromHardwareWallet(WalletCredentials credentials) async {
    checkIfExists(credentials.name);
    final password = generateWalletPassword();
    credentials.password = password;
    await keyService.saveWalletPassword(password: password, walletName: credentials.name);
    final wallet = await _service!.restoreFromHardwareWallet(credentials);

    if (wallet.type == WalletType.monero) {
      await sharedPreferences.setBool(
          PreferencesKey.moneroWalletUpdateV1Key(wallet.name), _isNewMoneroWalletPasswordUpdated);
    }

    return wallet;
  }
}
