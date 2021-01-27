import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive_io.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/entities/encrypt.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

class BackupService {
  BackupService(this._flutterSecureStorage, this._walletInfoSource,
      this._keyService, this._sharedPreferences)
      : _cipher = chacha20Poly1305Aead;

  static const currentVersion = _v1;

  static const _v1 = 1;

  final Cipher _cipher;
  final FlutterSecureStorage _flutterSecureStorage;
  final SharedPreferences _sharedPreferences;
  final Box<WalletInfo> _walletInfoSource;
  final KeyService _keyService;

  Future<void> importBackup(Uint8List data, String password,
      {String nonce = secrets.backupSalt}) async {
    final version = getVersion(data);
    final backupBytes = data.toList()..removeAt(0);
    final backupData = Uint8List.fromList(backupBytes);

    switch (version) {
      case _v1:
        await _importBackupV1(backupData, password, nonce: nonce);
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
      default:
        return null;
    }
  }

  Future<Uint8List> _exportBackupV1(String password,
      {String nonce = secrets.backupSalt}) async {
    final zipEncoder = ZipFileEncoder();
    final appDir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final tmpDir = Directory('${appDir.path}/~_BACKUP_TMP');
    final archivePath = '${tmpDir.path}/backup_${now.toString()}.zip';
    final fileEntities = appDir.listSync(recursive: false);
    final keychainDump = await _exportKeychainDump(password, nonce: nonce);
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
    zipEncoder.addFile(preferencesDumpFile, '~_preferences_dump');
    zipEncoder.addFile(keychainDumpFile, '~_keychain_dump');
    zipEncoder.close();

    final content = File(archivePath).readAsBytesSync();
    tmpDir.deleteSync(recursive: true);
    final encryptedData = await _encrypt(content, password, nonce);

    return setVersion(encryptedData, currentVersion);
  }

  Future<void> _importBackupV1(Uint8List data, String password,
      {@required String nonce}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final decryptedData = await _decrypt(data, password, nonce);
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

    await _importKeychainDump(password, nonce: nonce);
    await _importPreferencesDump();
  }

  Future<void> _importPreferencesDump() async {
    final appDir = await getApplicationDocumentsDirectory();
    final preferencesFile = File('${appDir.path}/~_preferences_dump');
    const defaultSettingsMigrationVersionKey = PreferencesKey.currentDefaultSettingsMigrationVersion;

    if (!preferencesFile.existsSync()) {
      return;
    }

    final data =
        json.decode(preferencesFile.readAsStringSync()) as Map<String, Object>;

    await _sharedPreferences.setString(PreferencesKey.currentWalletName,
        data[PreferencesKey.currentWalletName] as String);
    await _sharedPreferences.setInt(PreferencesKey.currentNodeIdKey,
        data[PreferencesKey.currentNodeIdKey] as int);
    await _sharedPreferences.setInt(PreferencesKey.currentBalanceDisplayModeKey,
        data[PreferencesKey.currentBalanceDisplayModeKey] as int);
    await _sharedPreferences.setInt(PreferencesKey.currentWalletType,
        data[PreferencesKey.currentWalletType] as int);
    await _sharedPreferences.setString(PreferencesKey.currentFiatCurrencyKey,
        data[PreferencesKey.currentFiatCurrencyKey] as String);
    await _sharedPreferences.setBool(
        PreferencesKey.shouldSaveRecipientAddressKey,
        data[PreferencesKey.shouldSaveRecipientAddressKey] as bool);
    await _sharedPreferences.setInt(
        PreferencesKey.currentTransactionPriorityKeyLegacy,
        data[PreferencesKey.currentTransactionPriorityKeyLegacy] as int);
    await _sharedPreferences.setBool(
        PreferencesKey.allowBiometricalAuthenticationKey,
        data[PreferencesKey.allowBiometricalAuthenticationKey] as bool);
    await _sharedPreferences.setInt(
        PreferencesKey.currentBitcoinElectrumSererIdKey,
        data[PreferencesKey.currentBitcoinElectrumSererIdKey] as int);
    await _sharedPreferences.setInt(PreferencesKey.currentLanguageCode,
        data[PreferencesKey.currentLanguageCode] as int);
    await _sharedPreferences.setInt(PreferencesKey.displayActionListModeKey,
        data[PreferencesKey.displayActionListModeKey] as int);
    await _sharedPreferences.setInt(
        'current_theme', data['current_theme'] as int);
    await _sharedPreferences.setInt(defaultSettingsMigrationVersionKey,
        data[defaultSettingsMigrationVersionKey] as int);

    await preferencesFile.delete();
  }

  Future<void> _importKeychainDump(String password,
      {@required String nonce,
      String keychainSalt = secrets.backupKeychainSalt}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final keychainDumpFile = File('${appDir.path}/~_keychain_dump');
    final decryptedKeychainDumpFileData = await _decrypt(
        keychainDumpFile.readAsBytesSync(), '$keychainSalt$password', nonce);
    final keychainJSON = json.decode(utf8.decode(decryptedKeychainDumpFileData))
        as Map<String, dynamic>;
    final keychainWalletsInfo = keychainJSON['wallets'] as List;
    final decodedPin = keychainJSON['pin'] as String;
    final pinCodeKey = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final backupPasswordKey =
        generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    final backupPassword = keychainJSON[backupPasswordKey] as String;

    await _flutterSecureStorage.write(
        key: backupPasswordKey, value: backupPassword);

    keychainWalletsInfo.forEach((dynamic rawInfo) async {
      final info = rawInfo as Map<String, dynamic>;
      await importWalletKeychainInfo(info);
    });

    await _flutterSecureStorage.write(
        key: pinCodeKey, value: encodedPinCode(pin: decodedPin));

    keychainDumpFile.deleteSync();
  }

  Future<void> importWalletKeychainInfo(Map<String, dynamic> info) async {
    final name = info['name'] as String;
    final password = info['password'] as String;

    await _keyService.saveWalletPassword(walletName: name, password: password);
  }

  Future<Uint8List> _exportKeychainDump(String password,
      {@required String nonce,
      String keychainSalt = secrets.backupKeychainSalt}) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final encodedPin = await _flutterSecureStorage.read(key: key);
    final decodedPin = decodedPinCode(pin: encodedPin);
    final wallets =
        await Future.wait(_walletInfoSource.values.map((walletInfo) async {
      return {
        'name': walletInfo.name,
        'type': walletInfo.type.toString(),
        'password':
            await _keyService.getWalletPassword(walletName: walletInfo.name)
      };
    }));
    final backupPasswordKey =
        generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    final backupPassword =
        await _flutterSecureStorage.read(key: backupPasswordKey);
    final data = utf8.encode(json.encode({
      'pin': decodedPin,
      'wallets': wallets,
      backupPasswordKey: backupPassword
    }));
    final encrypted = await _encrypt(
        Uint8List.fromList(data), '$keychainSalt$password', nonce);

    return encrypted;
  }

  Future<String> _exportPreferencesJSON() async {
    const defaultSettingsMigrationVersionKey =
        'current_default_settings_migration_version';

    final preferences = <String, Object>{
      PreferencesKey.currentWalletName:
          _sharedPreferences.getString(PreferencesKey.currentWalletName),
      PreferencesKey.currentNodeIdKey:
          _sharedPreferences.getInt(PreferencesKey.currentNodeIdKey),
      PreferencesKey.currentBalanceDisplayModeKey: _sharedPreferences
          .getInt(PreferencesKey.currentBalanceDisplayModeKey),
      PreferencesKey.currentWalletType:
          _sharedPreferences.getInt(PreferencesKey.currentWalletType),
      PreferencesKey.currentFiatCurrencyKey:
          _sharedPreferences.getString(PreferencesKey.currentFiatCurrencyKey),
      PreferencesKey.shouldSaveRecipientAddressKey: _sharedPreferences
          .getBool(PreferencesKey.shouldSaveRecipientAddressKey),
      PreferencesKey.isDarkThemeLegacy:
          _sharedPreferences.getBool(PreferencesKey.isDarkThemeLegacy),
      PreferencesKey.currentPinLength:
          _sharedPreferences.getInt(PreferencesKey.currentPinLength),
      PreferencesKey.currentTransactionPriorityKeyLegacy: _sharedPreferences
          .getInt(PreferencesKey.currentTransactionPriorityKeyLegacy),
      PreferencesKey.allowBiometricalAuthenticationKey: _sharedPreferences
          .getBool(PreferencesKey.allowBiometricalAuthenticationKey),
      PreferencesKey.currentBitcoinElectrumSererIdKey: _sharedPreferences
          .getInt(PreferencesKey.currentBitcoinElectrumSererIdKey),
      PreferencesKey.currentLanguageCode:
          _sharedPreferences.getString(PreferencesKey.currentLanguageCode),
      PreferencesKey.displayActionListModeKey:
          _sharedPreferences.getInt(PreferencesKey.displayActionListModeKey),
      PreferencesKey.currentTheme:
          _sharedPreferences.getInt(PreferencesKey.currentTheme),
      defaultSettingsMigrationVersionKey:
          _sharedPreferences.getInt(defaultSettingsMigrationVersionKey)
    };

    return json.encode(preferences);
  }

  int getVersion(Uint8List data) => data.toList().first;

  Uint8List setVersion(Uint8List data, int version) {
    final bytes = data.toList()..insert(0, version);
    return Uint8List.fromList(bytes);
  }

  Future<Uint8List> _encrypt(
      Uint8List data, String secretKeySource, String nonceBase64) async {
    final secretKeyHash = await sha256.hash(utf8.encode(secretKeySource));
    final secretKey = SecretKey(secretKeyHash.bytes);
    final nonce = Nonce(base64.decode(nonceBase64));
    return await _cipher.encrypt(data, secretKey: secretKey, nonce: nonce);
  }

  Future<Uint8List> _decrypt(
      Uint8List data, String secretKeySource, String nonceBase64) async {
    final secretKeyHash = await sha256.hash(utf8.encode(secretKeySource));
    final secretKey = SecretKey(secretKeyHash.bytes);
    final nonce = Nonce(base64.decode(nonceBase64));
    return await _cipher.decrypt(data, secretKey: secretKey, nonce: nonce);
  }
}
