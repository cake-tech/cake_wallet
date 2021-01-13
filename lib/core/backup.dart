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

class BackupService {
  BackupService(this._flutterSecureStorage, this._authService,
      this._walletInfoSource, this._keyService, this._sharedPreferences)
      : _cipher = chacha20Poly1305Aead;

  final Cipher _cipher;
  final FlutterSecureStorage _flutterSecureStorage;
  final SharedPreferences _sharedPreferences;
  final AuthService _authService;
  final Box<WalletInfo> _walletInfoSource;
  final KeyService _keyService;

  Future<void> importBackup(Uint8List data, String password,
      {@required String nonce}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final decryptedData = await _decrypt(data, password, nonce);
    final zip = ZipDecoder().decodeBytes(decryptedData);

    zip.files.forEach((file) {
      final filename = file.name;

      if (file.isFile) {
        final data = file.content as List<int>;
        File('${appDir.path}/' + filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory('${appDir.path}/' + filename)..create(recursive: true);
      }

      print(filename);
    });

    await importKeychainDump(password, nonce: nonce);
    await importPreferencesDump();
  }

  Future<void> importPreferencesDump() async {
    final appDir = await getApplicationDocumentsDirectory();
    final preferencesFile = File('${appDir.path}/~_preferences_dump');

    if (!preferencesFile.existsSync()) {
      return;
    }

    final data =
        json.decode(preferencesFile.readAsStringSync()) as Map<String, Object>;
    print('data $data');

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
        PreferencesKey.currentTransactionPriorityKey,
        data[PreferencesKey.currentTransactionPriorityKey] as int);
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

    await preferencesFile.delete();
  }

  Future<void> importKeychainDump(String password,
      {@required String nonce}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final keychainDumpFile = File('${appDir.path}/~_keychain_dump');
    final decryptedKeychainDumpFileData =
        await _decrypt(keychainDumpFile.readAsBytesSync(), password, nonce);
    final keychainJSON = json.decode(utf8.decode(decryptedKeychainDumpFileData))
        as Map<String, dynamic>;
    final keychainWalletsInfo = keychainJSON['wallets'] as List;
    final decodedPin = keychainJSON['pin'] as String;
    final pinCodeKey = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);

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

  Future<Uint8List> exportBackup(String password,
      {@required String nonce}) async {
    final zipEncoder = ZipFileEncoder();
    final appDir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final tmpDir = Directory('${appDir.path}/~_BACKUP_TMP');
    final archivePath = '${tmpDir.path}/backup_${now.toString()}.zip';
    final fileEntities = appDir.listSync(recursive: false);
    final keychainDump = await exportKeychainDump(password, nonce: nonce);
    final preferencesDump = await exportPreferencesJSON();
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

    return await _encrypt(content, password, nonce);
  }

  Future<Uint8List> exportKeychainDump(String password,
      {@required String nonce}) async {
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

    final data =
        utf8.encode(json.encode({'pin': decodedPin, 'wallets': wallets}));
    final encrypted = await _encrypt(Uint8List.fromList(data), password, nonce);

    return encrypted;
  }

  Future<String> exportPreferencesJSON() async {
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
      PreferencesKey.currentTransactionPriorityKey: _sharedPreferences
          .getInt(PreferencesKey.currentTransactionPriorityKey),
      PreferencesKey.allowBiometricalAuthenticationKey: _sharedPreferences
          .getBool(PreferencesKey.allowBiometricalAuthenticationKey),
      PreferencesKey.currentBitcoinElectrumSererIdKey: _sharedPreferences
          .getInt(PreferencesKey.currentBitcoinElectrumSererIdKey),
      PreferencesKey.currentLanguageCode:
          _sharedPreferences.getString(PreferencesKey.currentLanguageCode),
      PreferencesKey.displayActionListModeKey:
          _sharedPreferences.getInt(PreferencesKey.displayActionListModeKey),
      PreferencesKey.currentTheme: _sharedPreferences.getInt(PreferencesKey.currentTheme)
      // FIX-ME: Unnamed constant.
    };

    return json.encode(preferences);
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
