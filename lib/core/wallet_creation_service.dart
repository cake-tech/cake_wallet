import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_keychain/cw_keychain.dart';

class WalletCreationService {
  WalletCreationService(
      {required WalletType initialType,
      required this.keyService,
      required this.sharedPreferences,
      required this.settingsStore,
      required this.keychain})
      : type = initialType {
    changeWalletType(type: type);
  }

  WalletType type;
  final SharedPreferences sharedPreferences;
  final SettingsStore settingsStore;
  final KeyService keyService;
  final CwKeychain keychain;
  WalletService? _service;

  static const _isNewMoneroWalletPasswordUpdated = true;

  void changeWalletType({required WalletType type}) {
    this.type = type;
    _service = getIt.get<WalletService>(param1: type);
  }

  Future<bool> exists(String name, {bool checkKeychain = true}) async {
    final walletName = name.toLowerCase();
    final existsLocally = (await WalletInfo.getAll())
        .any((walletInfo) => walletInfo.name.toLowerCase() == walletName);

    if (existsLocally) {
      return true;
    }

    return checkKeychain && await existsInKeychain(name);
  }

  Future<bool> existsInKeychain(String name) async {
    if (!await keychain.available()) {
      return false;
    }

    try {
      final v1names = (await keychain.getAll()).map((item) => item.name.toLowerCase());
      final unsupportedNames =
          (await keychain.getUnsupported()).map((item) => item.name.toLowerCase());

      return [...v1names, ...unsupportedNames].any((item) => item == name.toLowerCase());
    } catch (_) {
      return false;
    }
  }

  Future<bool> typeExists(WalletType type) async {
    return (await WalletInfo.getAll()).any((walletInfo) => walletInfo.type == type);
  }

  Future<void> checkIfExists(String name, {bool checkKeychain = true}) async {
    if (await exists(name, checkKeychain: checkKeychain)) {
      throw Exception('Wallet with name ${name} already exists!');
    }
  }

  Future<WalletBase> create(WalletCredentials credentials, {bool? isTestnet}) async {
    await checkIfExists(credentials.name);

    if (credentials.password == null) {
      credentials.password = generateWalletPassword();
    }
    await keyService.saveWalletPassword(
        password: credentials.password!, walletName: credentials.name);

    if (_hasSeedPhraseLengthOption) {
      credentials.seedPhraseLength = settingsStore.seedPhraseLength.value;
    }
    final wallet = await _service!.create(credentials, isTestnet: isTestnet);

    if (wallet.type == WalletType.monero) {
      await sharedPreferences.setBool(
          PreferencesKey.moneroWalletUpdateV1Key(wallet.name), _isNewMoneroWalletPasswordUpdated);
    }

    return wallet;
  }

  bool get _hasSeedPhraseLengthOption {
    switch (type) {
      case WalletType.bitcoin:
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.bsc:
      case WalletType.solana:
      case WalletType.tron:
      case WalletType.dogecoin:
      case WalletType.nano:
      case WalletType.zcash:
      case WalletType.zano:
      case WalletType.decred:
        return true;
      case WalletType.monero:
      case WalletType.wownero:
      case WalletType.none:
      case WalletType.haven:
      case WalletType.banano:
        return false;
    }
  }

  Future<WalletBase> restoreFromKeys(WalletCredentials credentials, {bool? isTestnet}) async {
    await checkIfExists(credentials.name);

    if (credentials.password == null) {
      credentials.password = generateWalletPassword();
    }
    await keyService.saveWalletPassword(
        password: credentials.password!, walletName: credentials.name);

    final wallet = await _service!.restoreFromKeys(credentials, isTestnet: isTestnet);

    if (wallet.type == WalletType.monero) {
      await sharedPreferences.setBool(
          PreferencesKey.moneroWalletUpdateV1Key(wallet.name), _isNewMoneroWalletPasswordUpdated);
    }

    return wallet;
  }

  Future<WalletBase> restoreFromSeed(WalletCredentials credentials,
      {bool? isTestnet, bool checkKeychain = true}) async {
    await checkIfExists(credentials.name, checkKeychain: checkKeychain);

    if (credentials.password == null) {
      credentials.password = generateWalletPassword();
    }
    await keyService.saveWalletPassword(
        password: credentials.password!, walletName: credentials.name);

    final wallet = await _service!.restoreFromSeed(credentials, isTestnet: isTestnet);

    if (wallet.type == WalletType.monero) {
      await sharedPreferences.setBool(
          PreferencesKey.moneroWalletUpdateV1Key(wallet.name), _isNewMoneroWalletPasswordUpdated);
    }

    return wallet;
  }

  Future<WalletBase> restoreFromHardwareWallet(WalletCredentials credentials) async {
    await checkIfExists(credentials.name);
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
