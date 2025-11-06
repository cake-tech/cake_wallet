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
      required this.keyService,
      required this.sharedPreferences,
      required this.settingsStore})
      : type = initialType {
    changeWalletType(type: type);
  }

  WalletType type;
  final SharedPreferences sharedPreferences;
  final SettingsStore settingsStore;
  final KeyService keyService;
  WalletService? _service;

  static const _isNewMoneroWalletPasswordUpdated = true;

  void changeWalletType({required WalletType type}) {
    this.type = type;
    _service = getIt.get<WalletService>(param1: type);
  }

  Future<bool> exists(String name) async {
    final walletName = name.toLowerCase();
    return (await WalletInfo.getAll())
        .any((walletInfo) => walletInfo.name.toLowerCase() == walletName);
  }

  Future<bool> typeExists(WalletType type) async {
    return (await WalletInfo.getAll())
        .any((walletInfo) => walletInfo.type == type);
  }

  Future<void> checkIfExists(String name) async {
    if (await exists(name)) {
      throw Exception('Wallet with name ${name} already exists!');
    }
  }

  Future<WalletBase> create(WalletCredentials credentials,
      {bool? isTestnet}) async {
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
          PreferencesKey.moneroWalletUpdateV1Key(wallet.name),
          _isNewMoneroWalletPasswordUpdated);
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
      case WalletType.solana:
      case WalletType.tron:
      case WalletType.dogecoin:
      case WalletType.decred:
      case WalletType.nano:
        return true;
      case WalletType.monero:
      case WalletType.wownero:
      case WalletType.none:
      case WalletType.haven:
      case WalletType.banano:
      case WalletType.zano:
        return false;
    }
  }

  Future<WalletBase> restoreFromKeys(WalletCredentials credentials,
      {bool? isTestnet}) async {
    checkIfExists(credentials.name);

    if (credentials.password == null) {
      credentials.password = generateWalletPassword();
    }
    await keyService.saveWalletPassword(
        password: credentials.password!, walletName: credentials.name);

    final wallet =
        await _service!.restoreFromKeys(credentials, isTestnet: isTestnet);

    if (wallet.type == WalletType.monero) {
      await sharedPreferences.setBool(
          PreferencesKey.moneroWalletUpdateV1Key(wallet.name),
          _isNewMoneroWalletPasswordUpdated);
    }

    return wallet;
  }

  Future<WalletBase> restoreFromSeed(WalletCredentials credentials,
      {bool? isTestnet}) async {
    checkIfExists(credentials.name);

    if (credentials.password == null) {
      credentials.password = generateWalletPassword();
    }
    await keyService.saveWalletPassword(
        password: credentials.password!, walletName: credentials.name);

    final wallet =
        await _service!.restoreFromSeed(credentials, isTestnet: isTestnet);

    if (wallet.type == WalletType.monero) {
      await sharedPreferences.setBool(
          PreferencesKey.moneroWalletUpdateV1Key(wallet.name),
          _isNewMoneroWalletPasswordUpdated);
    }

    return wallet;
  }

  Future<WalletBase> restoreFromHardwareWallet(
      WalletCredentials credentials) async {
    checkIfExists(credentials.name);
    final password = generateWalletPassword();
    credentials.password = password;
    await keyService.saveWalletPassword(
        password: password, walletName: credentials.name);
    final wallet = await _service!.restoreFromHardwareWallet(credentials);

    if (wallet.type == WalletType.monero) {
      await sharedPreferences.setBool(
          PreferencesKey.moneroWalletUpdateV1Key(wallet.name),
          _isNewMoneroWalletPasswordUpdated);
    }

    return wallet;
  }
}
