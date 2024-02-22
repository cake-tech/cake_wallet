import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cake_wallet/themes/theme_list.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
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

class BackupService {
  BackupService(
      this._flutterSecureStorage, this._walletInfoSource, this._keyService, this._sharedPreferences)
      : _cipher = Cryptography.instance.chacha20Poly1305Aead(),
        _correctWallets = <WalletInfo>[];

  static const currentVersion = _v2;

  static const _v1 = 1;
  static const _v2 = 2;

  final Cipher _cipher;
  final FlutterSecureStorage _flutterSecureStorage;
  final SharedPreferences _sharedPreferences;
  final Box<WalletInfo> _walletInfoSource;
  final KeyService _keyService;
  List<WalletInfo> _correctWallets;

  Future<void> importBackup(Uint8List data, String password,
      {String nonce = secrets.backupSalt}) async {
    final version = getVersion(data);

    switch (version) {
      case _v1:
        final backupBytes = data.toList()..removeAt(0);
        final backupData = Uint8List.fromList(backupBytes);
        await _importBackupV1(backupData, password, nonce: nonce);
        break;
      case _v2:
        await _importBackupV2(data, password);
        break;
      default:
        break;
    }
  }

  Future<Uint8List> exportBackup(String password,
      {String nonce = secrets.backupSalt, int version = currentVersion}) async {
    switch (version) {
      case _v1:
        return await _exportBackupV1(password, nonce: nonce);
      case _v2:
        return await _exportBackupV2(password);
      default:
        throw Exception('Incorrect version: $version for exportBackup');
    }
  }

  @Deprecated('Use v2 instead')
  Future<Uint8List> _exportBackupV1(String password, {String nonce = secrets.backupSalt}) async =>
      throw Exception('Deprecated. Export for backups v1 is deprecated. Please use export v2.');

  Future<Uint8List> _exportBackupV2(String password) async {
    final zipEncoder = ZipFileEncoder();
    final appDir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final tmpDir = Directory('${appDir.path}/~_BACKUP_TMP');
    final archivePath = '${tmpDir.path}/backup_${now.toString()}.zip';
    final fileEntities = appDir.listSync(recursive: false);
    final keychainDump = await _exportKeychainDumpV2(password);
    final preferencesDump = await _exportPreferencesJSON();
    final preferencesDumpFile = File('${tmpDir.path}/~_preferences_dump_TMP');
    final keychainDumpFile = File('${tmpDir.path}/~_keychain_dump_TMP');

    if (tmpDir.existsSync()) {
      tmpDir.deleteSync(recursive: true);
    }

    tmpDir.createSync();
    zipEncoder.create(archivePath);

    fileEntities.forEach((entity) {
      if (entity.path == archivePath || entity.path == tmpDir.path) {
        return;
      }

      if (entity.statSync().type == FileSystemEntityType.directory) {
        zipEncoder.addDirectory(Directory(entity.path));
      } else {
        zipEncoder.addFile(File(entity.path));
      }
    });
    await keychainDumpFile.writeAsBytes(keychainDump.toList());
    await preferencesDumpFile.writeAsString(preferencesDump);
    await zipEncoder.addFile(preferencesDumpFile, '~_preferences_dump');
    await zipEncoder.addFile(keychainDumpFile, '~_keychain_dump');
    zipEncoder.close();

    final content = File(archivePath).readAsBytesSync();
    tmpDir.deleteSync(recursive: true);
    return await _encryptV2(content, password);
  }

  Future<void> _importBackupV1(Uint8List data, String password, {required String nonce}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final decryptedData = await _decryptV1(data, password, nonce);
    final zip = ZipDecoder().decodeBytes(decryptedData);

    zip.files.forEach((file) {
      final filename = file.name;

      if (file.isFile) {
        final content = file.content as List<int>;
        File('${appDir.path}/' + filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(content);
      } else {
        Directory('${appDir.path}/' + filename)..create(recursive: true);
      }
    });

    await _verifyWallets();
    await _importKeychainDumpV1(password, nonce: nonce);
    await _importPreferencesDump();
  }

  Future<void> _importBackupV2(Uint8List data, String password) async {
    final appDir = await getApplicationDocumentsDirectory();
    final decryptedData = await _decryptV2(data, password);
    final zip = ZipDecoder().decodeBytes(decryptedData);

    zip.files.forEach((file) {
      final filename = file.name;

      if (file.isFile) {
        final content = file.content as List<int>;
        File('${appDir.path}/' + filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(content);
      } else {
        Directory('${appDir.path}/' + filename)..create(recursive: true);
      }
    });

    await _verifyWallets();
    await _importKeychainDumpV2(password);
    await _importPreferencesDump();
  }

  Future<void> _verifyWallets() async {
    final walletInfoSource = await _reloadHiveWalletInfoBox();
    _correctWallets =
        walletInfoSource.values.where((info) => availableWalletTypes.contains(info.type)).toList();

    if (_correctWallets.isEmpty) {
      throw Exception('Correct wallets not detected');
    }
  }

  Future<Box<WalletInfo>> _reloadHiveWalletInfoBox() async {
    final appDir = await getApplicationDocumentsDirectory();
    await CakeHive.close();
    CakeHive.init(appDir.path);

    if (!CakeHive.isAdapterRegistered(WalletInfo.typeId)) {
      CakeHive.registerAdapter(WalletInfoAdapter());
    }

    return await CakeHive.openBox<WalletInfo>(WalletInfo.boxName);
  }

  Future<void> _importPreferencesDump() async {
    final appDir = await getApplicationDocumentsDirectory();
    final preferencesFile = File('${appDir.path}/~_preferences_dump');

    if (!preferencesFile.existsSync()) {
      return;
    }

    final data = json.decode(preferencesFile.readAsStringSync()) as Map<String, dynamic>;
    String currentWalletName = data[PreferencesKey.currentWalletName] as String;
    int currentWalletType = data[PreferencesKey.currentWalletType] as int;

    final isCorrentCurrentWallet = _correctWallets
        .any((info) => info.name == currentWalletName && info.type.index == currentWalletType);

    if (!isCorrentCurrentWallet) {
      currentWalletName = _correctWallets.first.name;
      currentWalletType = serializeToInt(_correctWallets.first.type);
    }

    final currentNodeId = data[PreferencesKey.currentNodeIdKey] as int?;
    final currentBalanceDisplayMode = data[PreferencesKey.currentBalanceDisplayModeKey] as int?;
    final currentFiatCurrency = data[PreferencesKey.currentFiatCurrencyKey] as String?;
    final shouldSaveRecipientAddress = data[PreferencesKey.shouldSaveRecipientAddressKey] as bool?;
    final isAppSecure = data[PreferencesKey.isAppSecureKey] as bool?;
    final disableBuy = data[PreferencesKey.disableBuyKey] as bool?;
    final disableSell = data[PreferencesKey.disableSellKey] as bool?;
    final defaultBuyProvider = data[PreferencesKey.defaultBuyProvider] as int?;
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
    final syncAll = data[PreferencesKey.syncAllKey] as bool?;
    final syncMode = data[PreferencesKey.syncModeKey] as int?;
    final autoGenerateSubaddressStatus =
        data[PreferencesKey.autoGenerateSubaddressStatusKey] as int?;

    await _sharedPreferences.setString(PreferencesKey.currentWalletName, currentWalletName);

    if (currentNodeId != null)
      await _sharedPreferences.setInt(PreferencesKey.currentNodeIdKey, currentNodeId);

    if (currentBalanceDisplayMode != null)
      await _sharedPreferences.setInt(
          PreferencesKey.currentBalanceDisplayModeKey, currentBalanceDisplayMode);

    await _sharedPreferences.setInt(PreferencesKey.currentWalletType, currentWalletType);

    if (currentFiatCurrency != null)
      await _sharedPreferences.setString(
          PreferencesKey.currentFiatCurrencyKey, currentFiatCurrency);

    if (shouldSaveRecipientAddress != null)
      await _sharedPreferences.setBool(
          PreferencesKey.shouldSaveRecipientAddressKey, shouldSaveRecipientAddress);

    if (isAppSecure != null)
      await _sharedPreferences.setBool(PreferencesKey.isAppSecureKey, isAppSecure);

    if (disableBuy != null)
      await _sharedPreferences.setBool(PreferencesKey.disableBuyKey, disableBuy);

    if (disableSell != null)
      await _sharedPreferences.setBool(PreferencesKey.disableSellKey, disableSell);

    if (defaultBuyProvider != null)
      await _sharedPreferences.setInt(PreferencesKey.defaultBuyProvider, defaultBuyProvider);

    if (currentTransactionPriorityKeyLegacy != null)
      await _sharedPreferences.setInt(
          PreferencesKey.currentTransactionPriorityKeyLegacy, currentTransactionPriorityKeyLegacy);
    
    if (currentBitcoinElectrumSererId != null)
      await _sharedPreferences.setInt(
          PreferencesKey.currentBitcoinElectrumSererIdKey, currentBitcoinElectrumSererId);

    if (currentLanguageCode != null)
      await _sharedPreferences.setString(PreferencesKey.currentLanguageCode, currentLanguageCode);

    if (displayActionListMode != null)
      await _sharedPreferences.setInt(
          PreferencesKey.displayActionListModeKey, displayActionListMode);

    if (fiatApiMode != null)
      await _sharedPreferences.setInt(PreferencesKey.currentFiatApiModeKey, fiatApiMode);
    if (autoGenerateSubaddressStatus != null)
      await _sharedPreferences.setInt(
          PreferencesKey.autoGenerateSubaddressStatusKey, autoGenerateSubaddressStatus);

    if (currentPinLength != null)
      await _sharedPreferences.setInt(PreferencesKey.currentPinLength, currentPinLength);

    if (currentTheme != null && DeviceInfo.instance.isMobile) {
      await _sharedPreferences.setInt(PreferencesKey.currentTheme, currentTheme);
      // enforce dark theme on desktop platforms until the design is ready:
    } else if (DeviceInfo.instance.isDesktop) {
      await _sharedPreferences.setInt(PreferencesKey.currentTheme, ThemeList.darkTheme.raw);
    }

    if (exchangeStatus != null)
      await _sharedPreferences.setInt(PreferencesKey.exchangeStatusKey, exchangeStatus);

    if (currentDefaultSettingsMigrationVersion != null)
      await _sharedPreferences.setInt(PreferencesKey.currentDefaultSettingsMigrationVersion,
          currentDefaultSettingsMigrationVersion);

    if (moneroTransactionPriority != null)
      await _sharedPreferences.setInt(
          PreferencesKey.moneroTransactionPriority, moneroTransactionPriority);

    if (bitcoinTransactionPriority != null)
      await _sharedPreferences.setInt(
          PreferencesKey.bitcoinTransactionPriority, bitcoinTransactionPriority);

    if (sortBalanceTokensBy != null)
      await _sharedPreferences.setInt(PreferencesKey.sortBalanceBy, sortBalanceTokensBy);

    if (pinNativeTokenAtTop != null)
      await _sharedPreferences.setBool(PreferencesKey.pinNativeTokenAtTop, pinNativeTokenAtTop);

    if (useEtherscan != null)
      await _sharedPreferences.setBool(PreferencesKey.useEtherscan, useEtherscan);

    if (defaultNanoRep != null)
      await _sharedPreferences.setString(PreferencesKey.defaultNanoRep, defaultNanoRep);

    if (defaultBananoRep != null)
      await _sharedPreferences.setString(PreferencesKey.defaultBananoRep, defaultBananoRep);

    if (syncAll != null) await _sharedPreferences.setBool(PreferencesKey.syncAllKey, syncAll);
    if (lookupsTwitter != null)
      await _sharedPreferences.setBool(PreferencesKey.lookupsTwitter, lookupsTwitter);

    if (lookupsMastodon != null)
      await _sharedPreferences.setBool(PreferencesKey.lookupsMastodon, lookupsMastodon);

    if (lookupsYatService != null)
      await _sharedPreferences.setBool(PreferencesKey.lookupsYatService, lookupsYatService);

    if (lookupsUnstoppableDomains != null)
      await _sharedPreferences.setBool(
          PreferencesKey.lookupsUnstoppableDomains, lookupsUnstoppableDomains);

    if (lookupsOpenAlias != null)
      await _sharedPreferences.setBool(PreferencesKey.lookupsOpenAlias, lookupsOpenAlias);

    if (lookupsENS != null) await _sharedPreferences.setBool(PreferencesKey.lookupsENS, lookupsENS);

    if (syncAll != null) await _sharedPreferences.setBool(PreferencesKey.syncAllKey, syncAll);

    if (syncMode != null) await _sharedPreferences.setInt(PreferencesKey.syncModeKey, syncMode);

    await preferencesFile.delete();
  }

  Future<void> _importKeychainDumpV1(String password,
      {required String nonce, String keychainSalt = secrets.backupKeychainSalt}) async {
    final appDir = await getApplicationDocumentsDirectory();
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

    await _flutterSecureStorage.delete(key: backupPasswordKey);
    await _flutterSecureStorage.write(key: backupPasswordKey, value: backupPassword);

    keychainWalletsInfo.forEach((dynamic rawInfo) async {
      final info = rawInfo as Map<String, dynamic>;
      await importWalletKeychainInfo(info);
    });

    await _flutterSecureStorage.delete(key: pinCodeKey);
    await _flutterSecureStorage.write(key: pinCodeKey, value: encodedPinCode(pin: decodedPin));

    keychainDumpFile.deleteSync();
  }

  Future<void> _importKeychainDumpV2(String password,
      {String keychainSalt = secrets.backupKeychainSalt}) async {
    final appDir = await getApplicationDocumentsDirectory();
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

    await _flutterSecureStorage.delete(key: backupPasswordKey);
    await _flutterSecureStorage.write(key: backupPasswordKey, value: backupPassword);

    keychainWalletsInfo.forEach((dynamic rawInfo) async {
      final info = rawInfo as Map<String, dynamic>;
      await importWalletKeychainInfo(info);
    });

    await _flutterSecureStorage.delete(key: pinCodeKey);
    await _flutterSecureStorage.write(key: pinCodeKey, value: encodedPinCode(pin: decodedPin));

    keychainDumpFile.deleteSync();
  }

  Future<void> importWalletKeychainInfo(Map<String, dynamic> info) async {
    final name = info['name'] as String;
    final password = info['password'] as String;

    await _keyService.saveWalletPassword(walletName: name, password: password);
  }

  @Deprecated('Use v2 instead')
  Future<Uint8List> _exportKeychainDumpV1(String password,
          {required String nonce, String keychainSalt = secrets.backupKeychainSalt}) async =>
      throw Exception('Deprecated');

  Future<Uint8List> _exportKeychainDumpV2(String password,
      {String keychainSalt = secrets.backupKeychainSalt}) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final encodedPin = await _flutterSecureStorage.read(key: key);
    final decodedPin = decodedPinCode(pin: encodedPin!);
    final wallets = await Future.wait(_walletInfoSource.values.map((walletInfo) async {
      return {
        'name': walletInfo.name,
        'type': walletInfo.type.toString(),
        'password': await _keyService.getWalletPassword(walletName: walletInfo.name)
      };
    }));
    final backupPasswordKey = generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    final backupPassword = await _flutterSecureStorage.read(key: backupPasswordKey);
    final data = utf8.encode(
        json.encode({'pin': decodedPin, 'wallets': wallets, backupPasswordKey: backupPassword}));
    final encrypted = await _encryptV2(Uint8List.fromList(data), '$keychainSalt$password');

    return encrypted;
  }

  Future<String> _exportPreferencesJSON() async {
    final preferences = <String, dynamic>{
      PreferencesKey.currentWalletName:
          _sharedPreferences.getString(PreferencesKey.currentWalletName),
      PreferencesKey.currentNodeIdKey: _sharedPreferences.getInt(PreferencesKey.currentNodeIdKey),
      PreferencesKey.currentBalanceDisplayModeKey:
          _sharedPreferences.getInt(PreferencesKey.currentBalanceDisplayModeKey),
      PreferencesKey.currentWalletType: _sharedPreferences.getInt(PreferencesKey.currentWalletType),
      PreferencesKey.currentFiatCurrencyKey:
          _sharedPreferences.getString(PreferencesKey.currentFiatCurrencyKey),
      PreferencesKey.shouldSaveRecipientAddressKey:
          _sharedPreferences.getBool(PreferencesKey.shouldSaveRecipientAddressKey),
      PreferencesKey.disableBuyKey: _sharedPreferences.getBool(PreferencesKey.disableBuyKey),
      PreferencesKey.disableSellKey: _sharedPreferences.getBool(PreferencesKey.disableSellKey),
      PreferencesKey.defaultBuyProvider:
          _sharedPreferences.getInt(PreferencesKey.defaultBuyProvider),
      PreferencesKey.currentPinLength: _sharedPreferences.getInt(PreferencesKey.currentPinLength),
      PreferencesKey.currentTransactionPriorityKeyLegacy:
          _sharedPreferences.getInt(PreferencesKey.currentTransactionPriorityKeyLegacy),
      PreferencesKey.currentBitcoinElectrumSererIdKey:
          _sharedPreferences.getInt(PreferencesKey.currentBitcoinElectrumSererIdKey),
      PreferencesKey.currentLanguageCode:
          _sharedPreferences.getString(PreferencesKey.currentLanguageCode),
      PreferencesKey.displayActionListModeKey:
          _sharedPreferences.getInt(PreferencesKey.displayActionListModeKey),
      PreferencesKey.currentTheme: _sharedPreferences.getInt(PreferencesKey.currentTheme),
      PreferencesKey.exchangeStatusKey: _sharedPreferences.getInt(PreferencesKey.exchangeStatusKey),
      PreferencesKey.currentDefaultSettingsMigrationVersion:
          _sharedPreferences.getInt(PreferencesKey.currentDefaultSettingsMigrationVersion),
      PreferencesKey.bitcoinTransactionPriority:
          _sharedPreferences.getInt(PreferencesKey.bitcoinTransactionPriority),
      PreferencesKey.moneroTransactionPriority:
          _sharedPreferences.getInt(PreferencesKey.moneroTransactionPriority),
      PreferencesKey.currentFiatApiModeKey:
          _sharedPreferences.getInt(PreferencesKey.currentFiatApiModeKey),
      PreferencesKey.sortBalanceBy: _sharedPreferences.getInt(PreferencesKey.sortBalanceBy),
      PreferencesKey.pinNativeTokenAtTop:
          _sharedPreferences.getBool(PreferencesKey.pinNativeTokenAtTop),
      PreferencesKey.useEtherscan: _sharedPreferences.getBool(PreferencesKey.useEtherscan),
      PreferencesKey.defaultNanoRep: _sharedPreferences.getString(PreferencesKey.defaultNanoRep),
      PreferencesKey.defaultBananoRep:
          _sharedPreferences.getString(PreferencesKey.defaultBananoRep),
      PreferencesKey.lookupsTwitter: _sharedPreferences.getBool(PreferencesKey.lookupsTwitter),
      PreferencesKey.lookupsMastodon: _sharedPreferences.getBool(PreferencesKey.lookupsMastodon),
      PreferencesKey.lookupsYatService:
          _sharedPreferences.getBool(PreferencesKey.lookupsYatService),
      PreferencesKey.lookupsUnstoppableDomains:
          _sharedPreferences.getBool(PreferencesKey.lookupsUnstoppableDomains),
      PreferencesKey.lookupsOpenAlias: _sharedPreferences.getBool(PreferencesKey.lookupsOpenAlias),
      PreferencesKey.lookupsENS: _sharedPreferences.getBool(PreferencesKey.lookupsENS),
      PreferencesKey.syncModeKey: _sharedPreferences.getInt(PreferencesKey.syncModeKey),
      PreferencesKey.syncAllKey: _sharedPreferences.getBool(PreferencesKey.syncAllKey),
      PreferencesKey.autoGenerateSubaddressStatusKey:
          _sharedPreferences.getInt(PreferencesKey.autoGenerateSubaddressStatusKey),
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
    final plainData = await _cipher.decrypt(box, secretKey: secretKey);
    return Uint8List.fromList(plainData);
  }

  Future<Uint8List> _encryptV2(Uint8List data, String passphrase) async =>
      cake_backup.encrypt(passphrase, data, version: _v2);

  Future<Uint8List> _decryptV2(Uint8List data, String passphrase) async =>
      cake_backup.decrypt(passphrase, data);
}
