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
    if (initialType != WalletType.none) {
      changeWalletType(type: initialType);
    } else {
      // Wait until type is provided
      _service = null;
    }
  }

  WalletType type;
  final SharedPreferences sharedPreferences;
  final SettingsStore settingsStore;
  final KeyService keyService;
  WalletService? _service;

  static const _isNewMoneroWalletPasswordUpdated = true;
  static const _groupNameKeyPrefix = 'wallet_group_name_';

  void changeWalletType({required WalletType type}) {
    this.type = type;
    if (type == WalletType.none) {
      _service = null;
      return;
    }
    _service = getIt.get<WalletService>(param1: type);
  }

  List<String> getAllCustomGroupNames() {
    final result = <String>[];
    for (final key in sharedPreferences.getKeys()) {
      if (!key.startsWith(_groupNameKeyPrefix)) continue;
      final value = sharedPreferences.getString(key);
      if (value != null && value.trim().isNotEmpty) {
        result.add(value.trim());
      }
    }
    return result;
  }

  Future<void> setGroupNameForKey(String groupKey, String name) async {
    await sharedPreferences.setString('$_groupNameKeyPrefix$groupKey', name);
  }

  Future<bool> exists(String name) async {
    final walletName = name.toLowerCase();
    return (await WalletInfo.getAll()).any((walletInfo) => walletInfo.name.toLowerCase() == walletName);
  }

  bool groupNameExists(String name) {
    final groupName = name.toLowerCase();
    return getAllCustomGroupNames().any((name) => name.toLowerCase() == groupName);
  }

  Future<bool> typeExists(WalletType type) async {
    return (await WalletInfo.getAll()).any((walletInfo) => walletInfo.type == type);
  }

  Future<void> checkIfExists(String name) async {
    if (await exists(name)) {
      throw Exception('Wallet with name ${name} already exists!');
    }
  }

  Future<WalletBase> create(WalletCredentials credentials, {bool? isTestnet}) async {
    _ensureServiceAvailable();
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
      case WalletType.solana:
      case WalletType.tron:
      case WalletType.dogecoin:
      case WalletType.nano:
        return true;
      case WalletType.monero:
      case WalletType.wownero:
      case WalletType.none:
      case WalletType.haven:
      case WalletType.banano:
      case WalletType.zano:
      case WalletType.decred:
        return false;
    }
  }

  Future<WalletBase> restoreFromKeys(WalletCredentials credentials, {bool? isTestnet}) async {
    _ensureServiceAvailable();

    checkIfExists(credentials.name);

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

  Future<WalletBase> restoreFromSeed(WalletCredentials credentials, {bool? isTestnet}) async {
    _ensureServiceAvailable();
    checkIfExists(credentials.name);

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
    _ensureServiceAvailable();

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

  void _ensureServiceAvailable() {
    if (_service == null || type == WalletType.none) throw Exception('Wallet type is not set for WalletCreationService');
  }
}
