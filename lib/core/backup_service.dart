import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/get_encryption_key.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/themes/theme_list.dart';
import 'package:cw_core/root_dir.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive_io.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/entities/encrypt.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cake_backup/backup.dart' as cake_backup;

class $BackupService {
  $BackupService(this._secureStorage, this.walletInfoSource, this.transactionDescriptionBox,
      this.keyService, this.sharedPreferences)
      : cipher = Cryptography.instance.chacha20Poly1305Aead(),
        correctWallets = <WalletInfo>[];

  static const currentVersion = _v3;

  static const _v2 = 2;
  static const _v3 = 3;

  final Cipher cipher;
  final SecureStorage _secureStorage;
  final SharedPreferences sharedPreferences;
  final Box<WalletInfo> walletInfoSource;
  final Box<TransactionDescription> transactionDescriptionBox;
  final KeyService keyService;
  List<WalletInfo> correctWallets;


  Future<void> importBackupV1(Uint8List data, String password, {required String nonce}) async {
    final appDir = await getAppDir();
    final decryptedData = await _decryptV1(data, password, nonce);
    final zip = ZipDecoder().decodeBytes(decryptedData);

    for (var file in zip.files) {
      final filename = file.name;

      if (file.isFile) {
        final content = file.content as List<int>;
        File('${appDir.path}/' + filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(content, flush: true);
      } else {
        Directory('${appDir.path}/' + filename)..create(recursive: true);
      }
    };

    await verifyWallets();
    await _importKeychainDumpV1(password, nonce: nonce);
    await importPreferencesDump();
  }

  // checked with .endsWith - so this should be the last part of the filename
  static const ignoreFiles = [
    "flutter_assets/kernel_blob.bin",
    "flutter_assets/vm_snapshot_data",
    "flutter_assets/isolate_snapshot_data",
    "README.txt",
    ".lock",
  ];

  Future<void> importBackupV2(Uint8List data, String password) async {
    final appDir = await getAppDir();
    final decryptedData = await _decryptV2(data, password);
    final zip = ZipDecoder().decodeBytes(decryptedData);

    outer:
    for (var file in zip.files) {
      final filename = file.name;
      for (var ignore in ignoreFiles) { 
        if (filename.endsWith(ignore) && !filename.contains("wallets/")) {
          printV("ignoring backup file: $filename");
          continue outer;
        }
      }
      printV("restoring: $filename");
      if (file.isFile) {
        final content = file.content as List<int>;
        File('${appDir.path}/' + filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(content, flush: true);
      } else {
        final dir = Directory('${appDir.path}/' + filename);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
      }
    };

    await verifyWallets();
    await importKeychainDumpV2(password);
    await importPreferencesDump();
    await importTransactionDescriptionDump(); // HiveError: Box has already been closed
  }

  Future<void> verifyWallets() async {
    final walletInfoSource = await _reloadHiveWalletInfoBox();
    correctWallets =
        walletInfoSource.values.where((info) => availableWalletTypes.contains(info.type)).toList();

    if (correctWallets.isEmpty) {
      throw Exception('Correct wallets not detected');
    }
  }

  Future<Box<WalletInfo>> _reloadHiveWalletInfoBox() async {
    final appDir = await getAppDir();
    await CakeHive.close();
    CakeHive.init(appDir.path);

    if (!CakeHive.isAdapterRegistered(WalletInfo.typeId)) {
      CakeHive.registerAdapter(WalletInfoAdapter());
    }

    return await CakeHive.openBox<WalletInfo>(WalletInfo.boxName);
  }

  Future<void> importTransactionDescriptionDump() async {
    final appDir = await getAppDir();
    final transactionDescriptionFile = File('${appDir.path}/~_transaction_descriptions_dump');

    if (!transactionDescriptionFile.existsSync()) {
      return;
    }

    final jsonData =
        json.decode(transactionDescriptionFile.readAsStringSync()) as Map<String, dynamic>;
    final descriptionsMap = jsonData.map((key, value) =>
        MapEntry(key, TransactionDescription.fromJson(value as Map<String, dynamic>)));
    var box = transactionDescriptionBox;
    if (!box.isOpen) {
      final transactionDescriptionsBoxKey = 
        await getEncryptionKey(secureStorage: _secureStorage, forKey: TransactionDescription.boxKey);
      box = await CakeHive.openBox<TransactionDescription>(
        TransactionDescription.boxName,
        encryptionKey: transactionDescriptionsBoxKey);
      }
    await box.putAll(descriptionsMap);
  }

  Future<void> importPreferencesDump() async {
    final appDir = await getAppDir();
    final preferencesFile = File('${appDir.path}/~_preferences_dump');

    if (!preferencesFile.existsSync()) {
      return;
    }

    final data = json.decode(preferencesFile.readAsStringSync()) as Map<String, dynamic>;
    String currentWalletName = data[PreferencesKey.currentWalletName] as String;
    int currentWalletType = data[PreferencesKey.currentWalletType] as int;

    final isCorrentCurrentWallet = correctWallets
        .any((info) => info.name == currentWalletName && info.type.index == currentWalletType);

    if (!isCorrentCurrentWallet) {
      currentWalletName = correctWallets.first.name;
      currentWalletType = serializeToInt(correctWallets.first.type);
    }

    final currentNodeId = data[PreferencesKey.currentNodeIdKey] as int?;
    final currentBalanceDisplayMode = data[PreferencesKey.currentBalanceDisplayModeKey] as int?;
    final currentFiatCurrency = data[PreferencesKey.currentFiatCurrencyKey] as String?;
    final shouldSaveRecipientAddress = data[PreferencesKey.shouldSaveRecipientAddressKey] as bool?;
    final isAppSecure = data[PreferencesKey.isAppSecureKey] as bool?;
    final disableTradeOption = data[PreferencesKey.disableTradeOption] as bool?;
    final currentTransactionPriorityKeyLegacy =
        data[PreferencesKey.currentTransactionPriorityKeyLegacy] as int?;
    final currentBitcoinElectrumSererId =
        data[PreferencesKey.currentBitcoinElectrumSererIdKey] as int?;
    final currentLanguageCode = data[PreferencesKey.currentLanguageCode] as String?;
    final displayActionListMode = data[PreferencesKey.displayActionListModeKey] as int?;
    final fiatApiMode = data[PreferencesKey.currentFiatApiModeKey] as int?;
    final currentPinLength = data[PreferencesKey.currentPinLength] as int?;
    final currentTheme = data[PreferencesKey.currentTheme] as int?;
    final exchangeStatus = data[PreferencesKey.exchangeStatusKey] as int?;
    final currentDefaultSettingsMigrationVersion =
        data[PreferencesKey.currentDefaultSettingsMigrationVersion] as int?;
    final moneroTransactionPriority = data[PreferencesKey.moneroTransactionPriority] as int?;
    final bitcoinTransactionPriority = data[PreferencesKey.bitcoinTransactionPriority] as int?;
    final sortBalanceTokensBy = data[PreferencesKey.sortBalanceBy] as int?;
    final pinNativeTokenAtTop = data[PreferencesKey.pinNativeTokenAtTop] as bool?;
    final useEtherscan = data[PreferencesKey.useEtherscan] as bool?;
    final defaultNanoRep = data[PreferencesKey.defaultNanoRep] as String?;
    final defaultBananoRep = data[PreferencesKey.defaultBananoRep] as String?;
    final lookupsTwitter = data[PreferencesKey.lookupsTwitter] as bool?;
    final lookupsMastodon = data[PreferencesKey.lookupsMastodon] as bool?;
    final lookupsYatService = data[PreferencesKey.lookupsYatService] as bool?;
    final lookupsUnstoppableDomains = data[PreferencesKey.lookupsUnstoppableDomains] as bool?;
    final lookupsOpenAlias = data[PreferencesKey.lookupsOpenAlias] as bool?;
    final lookupsENS = data[PreferencesKey.lookupsENS] as bool?;
    final lookupsWellKnown = data[PreferencesKey.lookupsWellKnown] as bool?;
    final syncAll = data[PreferencesKey.syncAllKey] as bool?;
    final syncMode = data[PreferencesKey.syncModeKey] as int?;
    final autoGenerateSubaddressStatus =
        data[PreferencesKey.autoGenerateSubaddressStatusKey] as int?;

    await sharedPreferences.setString(PreferencesKey.currentWalletName, currentWalletName);

    if (currentNodeId != null)
      await sharedPreferences.setInt(PreferencesKey.currentNodeIdKey, currentNodeId);

    if (currentBalanceDisplayMode != null)
      await sharedPreferences.setInt(
          PreferencesKey.currentBalanceDisplayModeKey, currentBalanceDisplayMode);

    await sharedPreferences.setInt(PreferencesKey.currentWalletType, currentWalletType);

    if (currentFiatCurrency != null)
      await sharedPreferences.setString(
          PreferencesKey.currentFiatCurrencyKey, currentFiatCurrency);

    if (shouldSaveRecipientAddress != null)
      await sharedPreferences.setBool(
          PreferencesKey.shouldSaveRecipientAddressKey, shouldSaveRecipientAddress);

    if (isAppSecure != null)
      await sharedPreferences.setBool(PreferencesKey.isAppSecureKey, isAppSecure);

    if (disableTradeOption != null)
      await sharedPreferences.setBool(PreferencesKey.disableTradeOption, disableTradeOption);

    if (currentTransactionPriorityKeyLegacy != null)
      await sharedPreferences.setInt(
          PreferencesKey.currentTransactionPriorityKeyLegacy, currentTransactionPriorityKeyLegacy);

    if (currentBitcoinElectrumSererId != null)
      await sharedPreferences.setInt(
          PreferencesKey.currentBitcoinElectrumSererIdKey, currentBitcoinElectrumSererId);

    if (currentLanguageCode != null)
      await sharedPreferences.setString(PreferencesKey.currentLanguageCode, currentLanguageCode);

    if (displayActionListMode != null)
      await sharedPreferences.setInt(
          PreferencesKey.displayActionListModeKey, displayActionListMode);

    if (fiatApiMode != null)
      await sharedPreferences.setInt(PreferencesKey.currentFiatApiModeKey, fiatApiMode);
    if (autoGenerateSubaddressStatus != null)
      await sharedPreferences.setInt(
          PreferencesKey.autoGenerateSubaddressStatusKey, autoGenerateSubaddressStatus);

    if (currentPinLength != null)
      await sharedPreferences.setInt(PreferencesKey.currentPinLength, currentPinLength);

    if (currentTheme != null && DeviceInfo.instance.isMobile) {
      await sharedPreferences.setInt(PreferencesKey.currentTheme, currentTheme);
      // enforce dark theme on desktop platforms until the design is ready:
    } else if (DeviceInfo.instance.isDesktop) {
      await sharedPreferences.setInt(PreferencesKey.currentTheme, ThemeList.darkTheme.raw);
    }

    if (exchangeStatus != null)
      await sharedPreferences.setInt(PreferencesKey.exchangeStatusKey, exchangeStatus);

    if (currentDefaultSettingsMigrationVersion != null)
      await sharedPreferences.setInt(PreferencesKey.currentDefaultSettingsMigrationVersion,
          currentDefaultSettingsMigrationVersion);

    if (moneroTransactionPriority != null)
      await sharedPreferences.setInt(
          PreferencesKey.moneroTransactionPriority, moneroTransactionPriority);

    if (bitcoinTransactionPriority != null)
      await sharedPreferences.setInt(
          PreferencesKey.bitcoinTransactionPriority, bitcoinTransactionPriority);

    if (sortBalanceTokensBy != null)
      await sharedPreferences.setInt(PreferencesKey.sortBalanceBy, sortBalanceTokensBy);

    if (pinNativeTokenAtTop != null)
      await sharedPreferences.setBool(PreferencesKey.pinNativeTokenAtTop, pinNativeTokenAtTop);

    if (useEtherscan != null)
      await sharedPreferences.setBool(PreferencesKey.useEtherscan, useEtherscan);

    if (defaultNanoRep != null)
      await sharedPreferences.setString(PreferencesKey.defaultNanoRep, defaultNanoRep);

    if (defaultBananoRep != null)
      await sharedPreferences.setString(PreferencesKey.defaultBananoRep, defaultBananoRep);

    if (syncAll != null) await sharedPreferences.setBool(PreferencesKey.syncAllKey, syncAll);
    if (lookupsTwitter != null)
      await sharedPreferences.setBool(PreferencesKey.lookupsTwitter, lookupsTwitter);

    if (lookupsMastodon != null)
      await sharedPreferences.setBool(PreferencesKey.lookupsMastodon, lookupsMastodon);

    if (lookupsYatService != null)
      await sharedPreferences.setBool(PreferencesKey.lookupsYatService, lookupsYatService);

    if (lookupsUnstoppableDomains != null)
      await sharedPreferences.setBool(
          PreferencesKey.lookupsUnstoppableDomains, lookupsUnstoppableDomains);

    if (lookupsOpenAlias != null)
      await sharedPreferences.setBool(PreferencesKey.lookupsOpenAlias, lookupsOpenAlias);

    if (lookupsENS != null) await sharedPreferences.setBool(PreferencesKey.lookupsENS, lookupsENS);

    if (lookupsWellKnown != null)
      await sharedPreferences.setBool(PreferencesKey.lookupsWellKnown, lookupsWellKnown);

    if (syncAll != null) await sharedPreferences.setBool(PreferencesKey.syncAllKey, syncAll);

    if (syncMode != null) await sharedPreferences.setInt(PreferencesKey.syncModeKey, syncMode);

    await preferencesFile.delete();
  }

  Future<void> _importKeychainDumpV1(String password,
      {required String nonce, String keychainSalt = secrets.backupKeychainSalt}) async {
    final appDir = await getAppDir();
    final keychainDumpFile = File('${appDir.path}/~_keychain_dump');
    final decryptedKeychainDumpFileData =
        await _decryptV1(keychainDumpFile.readAsBytesSync(), '$keychainSalt$password', nonce);
    final keychainJSON =
        json.decode(utf8.decode(decryptedKeychainDumpFileData)) as Map<String, dynamic>;
    final keychainWalletsInfo = keychainJSON['wallets'] as List;
    final decodedPin = keychainJSON['pin'] as String;
    final pinCodeKey = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final backupPasswordKey = generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    final backupPassword = keychainJSON[backupPasswordKey] as String;

    await _secureStorage.write(key: backupPasswordKey, value: backupPassword);

    keychainWalletsInfo.forEach((dynamic rawInfo) async {
      final info = rawInfo as Map<String, dynamic>;
      await importWalletKeychainInfo(info);
    });

    await _secureStorage.write(key: pinCodeKey, value: encodedPinCode(pin: decodedPin));

    keychainDumpFile.deleteSync();
  }

  Future<void> importKeychainDumpV2(String password,
      {String keychainSalt = secrets.backupKeychainSalt}) async {
    final appDir = await getAppDir();
    final keychainDumpFile = File('${appDir.path}/~_keychain_dump');
    final decryptedKeychainDumpFileData =
        await _decryptV2(keychainDumpFile.readAsBytesSync(), '$keychainSalt$password');
    final keychainJSON =
        json.decode(utf8.decode(decryptedKeychainDumpFileData)) as Map<String, dynamic>;
    final keychainWalletsInfo = keychainJSON['wallets'] as List;
    final decodedPin = keychainJSON['pin'] as String;
    final pinCodeKey = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final backupPasswordKey = generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    final backupPassword = keychainJSON[backupPasswordKey] as String;

    await _secureStorage.write(key: backupPasswordKey, value: backupPassword);

    keychainWalletsInfo.forEach((dynamic rawInfo) async {
      final info = rawInfo as Map<String, dynamic>;
      await importWalletKeychainInfo(info);
    });

    await _secureStorage.write(key: pinCodeKey, value: encodedPinCode(pin: decodedPin));

    keychainDumpFile.deleteSync();
  }

  Future<void> importWalletKeychainInfo(Map<String, dynamic> info) async {
    final name = info['name'] as String;
    final password = info['password'] as String;

    await keyService.saveWalletPassword(walletName: name, password: password);
  }

  @Deprecated('Use v2 instead')
  Future<Uint8List> _exportKeychainDumpV1(String password,
          {required String nonce, String keychainSalt = secrets.backupKeychainSalt}) async =>
      throw Exception('Deprecated');

  Future<Uint8List> exportKeychainDumpV2(String password,
      {String keychainSalt = secrets.backupKeychainSalt}) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final encodedPin = await _secureStorage.read(key: key);
    final decodedPin = decodedPinCode(pin: encodedPin!);
    final wallets = await Future.wait(walletInfoSource.values.map((walletInfo) async {
      return {
        'name': walletInfo.name,
        'type': walletInfo.type.toString(),
        'password': await keyService.getWalletPassword(walletName: walletInfo.name)
      };
    }));
    final backupPasswordKey = generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    final backupPassword = await _secureStorage.read(key: backupPasswordKey);
    final data = utf8.encode(
        json.encode({'pin': decodedPin, 'wallets': wallets, backupPasswordKey: backupPassword}));
    final encrypted = await _encryptV2(Uint8List.fromList(data), '$keychainSalt$password');

    return encrypted;
  }

  Future<String> exportPreferencesJSON() async {
    final preferences = <String, dynamic>{
      PreferencesKey.currentWalletName:
          sharedPreferences.getString(PreferencesKey.currentWalletName),
      PreferencesKey.currentNodeIdKey: sharedPreferences.getInt(PreferencesKey.currentNodeIdKey),
      PreferencesKey.currentBalanceDisplayModeKey:
          sharedPreferences.getInt(PreferencesKey.currentBalanceDisplayModeKey),
      PreferencesKey.currentWalletType: sharedPreferences.getInt(PreferencesKey.currentWalletType),
      PreferencesKey.currentFiatCurrencyKey:
          sharedPreferences.getString(PreferencesKey.currentFiatCurrencyKey),
      PreferencesKey.shouldSaveRecipientAddressKey:
          sharedPreferences.getBool(PreferencesKey.shouldSaveRecipientAddressKey),
      PreferencesKey.disableTradeOption: sharedPreferences.getBool(PreferencesKey.disableTradeOption),
      PreferencesKey.currentPinLength: sharedPreferences.getInt(PreferencesKey.currentPinLength),
      PreferencesKey.currentTransactionPriorityKeyLegacy:
          sharedPreferences.getInt(PreferencesKey.currentTransactionPriorityKeyLegacy),
      PreferencesKey.currentBitcoinElectrumSererIdKey:
          sharedPreferences.getInt(PreferencesKey.currentBitcoinElectrumSererIdKey),
      PreferencesKey.currentLanguageCode:
          sharedPreferences.getString(PreferencesKey.currentLanguageCode),
      PreferencesKey.displayActionListModeKey:
          sharedPreferences.getInt(PreferencesKey.displayActionListModeKey),
      PreferencesKey.currentTheme: sharedPreferences.getInt(PreferencesKey.currentTheme),
      PreferencesKey.exchangeStatusKey: sharedPreferences.getInt(PreferencesKey.exchangeStatusKey),
      PreferencesKey.currentDefaultSettingsMigrationVersion:
          sharedPreferences.getInt(PreferencesKey.currentDefaultSettingsMigrationVersion),
      PreferencesKey.bitcoinTransactionPriority:
          sharedPreferences.getInt(PreferencesKey.bitcoinTransactionPriority),
      PreferencesKey.moneroTransactionPriority:
          sharedPreferences.getInt(PreferencesKey.moneroTransactionPriority),
      PreferencesKey.currentFiatApiModeKey:
          sharedPreferences.getInt(PreferencesKey.currentFiatApiModeKey),
      PreferencesKey.sortBalanceBy: sharedPreferences.getInt(PreferencesKey.sortBalanceBy),
      PreferencesKey.pinNativeTokenAtTop:
          sharedPreferences.getBool(PreferencesKey.pinNativeTokenAtTop),
      PreferencesKey.useEtherscan: sharedPreferences.getBool(PreferencesKey.useEtherscan),
      PreferencesKey.defaultNanoRep: sharedPreferences.getString(PreferencesKey.defaultNanoRep),
      PreferencesKey.defaultBananoRep:
          sharedPreferences.getString(PreferencesKey.defaultBananoRep),
      PreferencesKey.lookupsTwitter: sharedPreferences.getBool(PreferencesKey.lookupsTwitter),
      PreferencesKey.lookupsMastodon: sharedPreferences.getBool(PreferencesKey.lookupsMastodon),
      PreferencesKey.lookupsYatService:
          sharedPreferences.getBool(PreferencesKey.lookupsYatService),
      PreferencesKey.lookupsUnstoppableDomains:
          sharedPreferences.getBool(PreferencesKey.lookupsUnstoppableDomains),
      PreferencesKey.lookupsOpenAlias: sharedPreferences.getBool(PreferencesKey.lookupsOpenAlias),
      PreferencesKey.lookupsENS: sharedPreferences.getBool(PreferencesKey.lookupsENS),
      PreferencesKey.lookupsWellKnown:
          sharedPreferences.getBool(PreferencesKey.lookupsWellKnown),
      PreferencesKey.syncModeKey: sharedPreferences.getInt(PreferencesKey.syncModeKey),
      PreferencesKey.syncAllKey: sharedPreferences.getBool(PreferencesKey.syncAllKey),
      PreferencesKey.autoGenerateSubaddressStatusKey:
          sharedPreferences.getInt(PreferencesKey.autoGenerateSubaddressStatusKey),
    };

    return json.encode(preferences);
  }

  int getVersion(Uint8List data) => data.toList().first;

  Uint8List setVersion(Uint8List data, int version) {
    final bytes = data.toList()..insert(0, version);
    return Uint8List.fromList(bytes);
  }

  @Deprecated('Use v2 instead')
  Future<Uint8List> _encryptV1(Uint8List data, String secretKeySource, String nonceBase64) async =>
      throw Exception('Deprecated');

  Future<Uint8List> _decryptV1(Uint8List data, String secretKeySource, String nonceBase64,
      {int macLength = 16}) async {
    final secretKeyHash = await Cryptography.instance.sha256().hash(utf8.encode(secretKeySource));
    final secretKey = SecretKey(secretKeyHash.bytes);
    final nonce = base64.decode(nonceBase64).toList();
    final box = SecretBox(Uint8List.sublistView(data, 0, data.lengthInBytes - macLength).toList(),
        nonce: nonce, mac: Mac(Uint8List.sublistView(data, data.lengthInBytes - macLength)));
    final plainData = await cipher.decrypt(box, secretKey: secretKey);
    return Uint8List.fromList(plainData);
  }

  Future<Uint8List> _encryptV2(Uint8List data, String passphrase) async =>
      cake_backup.encrypt(passphrase, data, version: _v2);

  Future<Uint8List> _decryptV2(Uint8List data, String passphrase) async =>
      cake_backup.decrypt(passphrase, data);
}
