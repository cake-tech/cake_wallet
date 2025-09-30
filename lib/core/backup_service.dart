import 'dart:convert';
import 'dart:io';
import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/get_encryption_key.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/themes/utils/theme_list.dart';
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
  $BackupService(this._secureStorage, this.transactionDescriptionBox,
      this.keyService, this.sharedPreferences)
      : cipher = Cryptography.instance.chacha20Poly1305Aead(),
        correctWallets = <WalletInfo>[];

  static const currentVersion = _v3;

  static const _v2 = 2;
  static const _v3 = 3;

  final Cipher cipher;
  final SecureStorage _secureStorage;
  final SharedPreferences sharedPreferences;
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
    final decryptedData = await decryptV2(data, password);
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
    await performHiveMigration(); // for backups made before sqlite migration
    correctWallets = (await WalletInfo.getAll()).where((info) => availableWalletTypes.contains(info.type)).toList();

    if (correctWallets.isEmpty) {
      printV('Correct wallets not detected');
    }
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

    try { // shouldn't throw an error but just in case, so it doesn't stop the backup restore
      for (var entry in data.entries) {
        String key = entry.key;
        dynamic value = entry.value;

        // Check the type of the value and save accordingly
        if (value is String) {
          await sharedPreferences.setString(key, value);
        } else if (value is int) {
          await sharedPreferences.setInt(key, value);
        } else if (value is double) {
          await sharedPreferences.setDouble(key, value);
        } else if (value is bool) {
          await sharedPreferences.setBool(key, value);
        } else if (value is List<String>) {
          await sharedPreferences.setStringList(key, value);
        } else {
          if (kDebugMode) {
            printV('Skipping individual save for key "$key": Unsupported type (${value.runtimeType}). Value: $value');
          }
        }
      }
    } catch (_) {}

    String currentWalletName = data[PreferencesKey.currentWalletName] as String;
    int currentWalletType = data[PreferencesKey.currentWalletType] as int;

    final isCorrentCurrentWallet = correctWallets
        .any((info) => info.name == currentWalletName && info.type.index == currentWalletType);

    if (!isCorrentCurrentWallet) {
      currentWalletName = correctWallets.first.name;
      currentWalletType = serializeToInt(correctWallets.first.type);
    }

    if (DeviceInfo.instance.isDesktop) {
      await sharedPreferences.setInt(PreferencesKey.currentTheme, ThemeList.darkTheme.raw);
    }

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
        await decryptV2(keychainDumpFile.readAsBytesSync(), '$keychainSalt$password');
    final keychainJSON =
        json.decode(utf8.decode(decryptedKeychainDumpFileData)) as Map<String, dynamic>;
    final keychainWalletsInfo = keychainJSON['wallets'] as List;
    final backupPasswordKey = generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    final backupPassword = keychainJSON[backupPasswordKey] as String;

    await _secureStorage.write(key: backupPasswordKey, value: backupPassword);

    keychainWalletsInfo.forEach((dynamic rawInfo) async {
      final info = rawInfo as Map<String, dynamic>;
      await importWalletKeychainInfo(info);
    });

    if (keychainJSON['_all'] is Map<String, dynamic>) {
      for (var key in (keychainJSON['_all'] as Map<String, dynamic>).keys) {
        try {
          if (!key.startsWith('MONERO_WALLET_')) continue;
          final decodedPassword = decodeWalletPassword(
              password: keychainJSON['_all'][key].toString());
          final walletName = key.split('_WALLET_')[1];
          final walletType = key.split('_WALLET_')[0].toLowerCase();
          await importWalletKeychainInfo({
            'name': walletName,
            'type': "WalletType.$walletType",
            'password': decodedPassword,
          });
        } catch (e) {
          printV('Error importing wallet ($key) password: $e');
        }
      }
    }

    keychainDumpFile.deleteSync();
  }

  Future<void> importWalletKeychainInfo(Map<String, dynamic> info) async {
    final name = info['name'] as String;
    final password = info['password'] as String;

    await keyService.saveWalletPassword(walletName: name, password: password);
  }

  Future<Uint8List> exportKeychainDumpV2(String password,
      {String keychainSalt = secrets.backupKeychainSalt}) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
    final wallets = await Future.wait((await WalletInfo.getAll()).map((walletInfo) async {
      try {
        return {
          'name': walletInfo.name,
          'type': walletInfo.type.toString(),
          'password': await keyService.getWalletPassword(walletName: walletInfo.name),
          'hardwareWalletType': walletInfo.hardwareWalletType?.index,
        };
      } catch (e) {
        return {
          'name': walletInfo.name,
          'type': walletInfo.type.toString(),
          'password': '',
          'hardwareWalletType': walletInfo.hardwareWalletType?.index,
        };
      }
    }));
    final backupPasswordKey = generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    final backupPassword = await _secureStorage.read(key: backupPasswordKey);
    final data = utf8.encode(
        json.encode({'wallets': wallets, backupPasswordKey: backupPassword, '_all': await _secureStorage.readAll()}));
    final encrypted = await _encryptV2(Uint8List.fromList(data), '$keychainSalt$password');

    return encrypted;
  }

  static const List<String> _excludedPrefsKeys = [
    PreferencesKey.currentPinLength,
    PreferencesKey.showCameraConsent,
    PreferencesKey.lastSeenAppVersion,
    PreferencesKey.failedTotpTokenTrials,
  ];

  Future<String> exportPreferencesJSON() async {
    final preferences = <String, dynamic>{};
    sharedPreferences.getKeys().forEach((key) => preferences[key] = sharedPreferences.get(key));

    _excludedPrefsKeys.forEach((key) => preferences.remove(key));

    return json.encode(preferences);
  }

  int getVersion(Uint8List data) => data.toList().first;

  Uint8List setVersion(Uint8List data, int version) {
    final bytes = data.toList()..insert(0, version);
    return Uint8List.fromList(bytes);
  }

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

  Future<Uint8List> decryptV2(Uint8List data, String passphrase) async =>
      cake_backup.decrypt(passphrase, data);
}
