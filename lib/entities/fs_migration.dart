import 'dart:io';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/entities/encrypt.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/ios_legacy_helper.dart'
    as ios_legacy_helper;
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

const reservedNames = ["flutter_assets", "wallets", "db"];

Future<void> migrate_android_v1() async {
  final appDocDir = await getApplicationDocumentsDirectory();

  await android_migrate_hives(appDocDir: appDocDir);
  await android_migrate_wallets(appDocDir: appDocDir);
}

Future<void> ios_migrate_v1(Box<WalletInfo> walletInfoSource,
    Box<Trade> tradeSource, Box<Contact> contactSource) async {
  final prefs = await SharedPreferences.getInstance();

  if (prefs.getBool('ios_migration_v1_completed') ?? false) {
    return;
  }

  await ios_migrate_user_defaults();
  await ios_migrate_pin();
  await ios_migrate_wallet_passwords();
  await ios_migrate_wallet_info(walletInfoSource);
  await ios_migrate_trades_list(tradeSource);
  await ios_migrate_address_book(contactSource);

  await prefs.setBool('ios_migration_v1_completed', true);
}

Future<void> ios_migrate_user_defaults() async {
  //get the new shared preferences instance
  final prefs = await SharedPreferences.getInstance();

  if (prefs.getBool('ios_migration_user_defaults_completed') ?? false) {
    return;
  }

  //translate the node uri
  final nodeURI = await ios_legacy_helper.getString('node_uri');
  // await prefs.setString('current_node_id', nodeURI);
  await prefs.setInt('current_node_id', 0);

  //should we provide default btc node key?
  final activeCurrency = await ios_legacy_helper.getInt('currency');

  if (activeCurrency != null) {
    final convertedCurrency = convertFiatLegacy(activeCurrency);

    if (convertedCurrency != null) {
      await prefs.setString(
        'current_fiat_currency', convertedCurrency.serialize());
    }
  }

  //translate fee priority
  final activeFeeTier = await ios_legacy_helper.getInt('saved_fee_priority');

  if (activeFeeTier != null) {
    await prefs.setInt('current_fee_priority', activeFeeTier);
  }

  //translate current balance mode
  final currentBalanceMode =
      await ios_legacy_helper.getInt('display_balance_mode');
  if (currentBalanceMode != null) {
    await prefs.setInt('current_balance_display_mode', currentBalanceMode);
  }

  //translate should save recipient address
  final shouldSave =
      await ios_legacy_helper.getBool('should_save_recipient_address');
  
  if (shouldSave != null) {
    await prefs.setBool('save_recipient_address', shouldSave);
  }

  //translate biometric
  final biometricOn =
      await ios_legacy_helper.getBool('biometric_authentication_on');
  
  if (biometricOn != null) {
    await prefs.setBool('allow_biometrical_authentication', biometricOn);
  }

  //read the current theme as integer, write it back as a bool
  final currentTheme = prefs.getInt('current-theme');
  bool isDark = false;
  if (currentTheme == 1) {
    isDark = true;
  }
  await prefs.setBool('dark_theme', isDark);

  //assign the pin length
  final pinLength = await ios_legacy_helper.getInt('pin-length');

  if (pinLength != null) {
    await prefs.setInt(PreferencesKey.currentPinLength, pinLength);
  }

  //default value for display list key?
  final walletName = await ios_legacy_helper.getString('current_wallet_name');

  if (walletName != null) {
    await prefs.setString('current_wallet_name', walletName);
  }

  await prefs.setInt('current_wallet_type', serializeToInt(WalletType.monero));

  await prefs.setBool('ios_migration_user_defaults_completed', true);
}

Future<void> ios_migrate_pin() async {
  final prefs = await SharedPreferences.getInstance();

  if (prefs.getBool('ios_migration_pin_completed') ?? false) {
    return;
  }

  final flutterSecureStorage = FlutterSecureStorage();
  final pinPassword = await flutterSecureStorage.read(
      key: 'pin_password', iOptions: IOSOptions());
  // No pin
  if (pinPassword == null) {
    await prefs.setBool('ios_migration_pin_completed', true);
    return;
  }

  final key = generateStoreKeyFor(key: SecretStoreKey.pinCodePassword);
  final encodedPassword = encodedPinCode(pin: pinPassword);
  await flutterSecureStorage.delete(key: key);
  await flutterSecureStorage.write(key: key, value: encodedPassword);
  await prefs.setBool('ios_migration_pin_completed', true);
}

Future<void> ios_migrate_wallet_passwords() async {
  final prefs = await SharedPreferences.getInstance();

  if (prefs.getBool('ios_migration_wallet_passwords_completed') ?? false) {
    return;
  }

  final appDocDir = await getApplicationDocumentsDirectory();
  final flutterSecureStorage = FlutterSecureStorage();
  final keyService = KeyService(flutterSecureStorage);
  final walletsDir = Directory('${appDocDir.path}/wallets');
  final moneroWalletsDir = Directory('${walletsDir.path}/monero');

  if (!moneroWalletsDir.existsSync() || moneroWalletsDir.listSync().isEmpty) {
    await prefs.setBool('ios_migration_wallet_passwords_completed', true);
    return;
  }

  moneroWalletsDir.listSync().forEach((item) async {
    try {
      if (item is Directory) {
        final name = item.path.split('/').last;
        final oldKey = 'wallet_monero_' + name + '_password';
        final password = await flutterSecureStorage.read(
            key: oldKey, iOptions: IOSOptions());
        await keyService.saveWalletPassword(
            walletName: name, password: password!);
      }
    } catch (e) {
      print(e.toString());
    }
  });

  await prefs.setBool('ios_migration_wallet_passwords_completed', true);
}

FiatCurrency convertFiatLegacy(int raw) {
  final _map = {
    0: 'aud',
    1: 'bgn',
    2: 'brl',
    3: 'cad',
    4: 'chf',
    5: 'cny',
    6: 'czk',
    7: 'eur',
    8: 'dkk',
    9: 'gbp',
    10: 'hkd',
    11: 'hrk',
    12: 'huf',
    13: 'idr',
    14: 'ils',
    15: 'inr',
    16: 'isk',
    17: 'jpy',
    18: 'krw',
    19: 'mxn',
    20: 'myr',
    21: 'nok',
    22: 'nzd',
    23: 'php',
    24: 'pln',
    25: 'ron',
    26: 'rub',
    27: 'sek',
    28: 'sgd',
    29: 'thb',
    30: 'try',
    31: 'usd',
    32: 'zar',
    33: 'vef'
  };
  final fiatAsString = _map[raw]!;

  return FiatCurrency.deserialize(raw: fiatAsString.toUpperCase());
}

Future<void> android_migrate_hives({required Directory appDocDir}) async {
  final dbDir = Directory('${appDocDir.path}/db');
  final files = <File>[];

  appDocDir.listSync().forEach((FileSystemEntity item) {
    final ext = item.path.split('.').last;

    if (item is File && (ext == "hive" || ext == "lock")) {
      files.add(item);
    }
  });

  if (!dbDir.existsSync()) {
    dbDir.createSync();
  }

  files.forEach((File hive) {
    final name = hive.path.split('/').last;
    hive.copySync('${dbDir.path}/$name');
    hive.deleteSync();
  });
}

Future<void> android_migrate_wallets({required Directory appDocDir}) async {
  final walletsDir = Directory('${appDocDir.path}/wallets');
  final moneroWalletsDir = Directory('${walletsDir.path}/monero');
  final dirs = <Directory>[];

  appDocDir.listSync().forEach((FileSystemEntity item) {
    final name = item.path.split('/').last;

    if (item is Directory && !reservedNames.contains(name)) {
      dirs.add(item);
    }
  });

  if (!moneroWalletsDir.existsSync()) {
    await moneroWalletsDir.create(recursive: true);
  }

  dirs.forEach((Directory dir) {
    final name = dir.path.split('/').last;
    final newDir = Directory('${moneroWalletsDir.path}/$name');
    newDir.createSync();

    dir.listSync().forEach((file) {
      if (file is File) {
        final fileName = file.path.split('/').last;
        file.copySync('${newDir.path}/$fileName');
        file.deleteSync();
      }
    });

    dir.deleteSync();
  });
}

Future<void> ios_migrate_wallet_info(Box<WalletInfo> walletsInfoSource) async {
  final prefs = await SharedPreferences.getInstance();

  if (prefs.getBool('ios_migration_wallet_info_completed') ?? false) {
    return;
  }

  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    final walletsDir = Directory('${appDocDir.path}/wallets');
    final moneroWalletsDir = Directory('${walletsDir.path}/monero');
    final infoRecords = moneroWalletsDir
        .listSync()
        .map((item) {
          try {
            if (item is Directory) {
              final name = item.path.split('/').last;
              final configFile = File('${item.path}/$name.json');

              if (!configFile.existsSync()) {
                return null;
              }

              final config = json.decode(configFile.readAsStringSync())
                  as Map<String, dynamic>;
              final isRecovery = config['isRecovery'] as bool ?? false;
              final dateAsDouble = config['date'] as double;
              final timestamp = dateAsDouble.toInt() * 1000;
              final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
              final id = walletTypeToString(WalletType.monero).toLowerCase() +
                  '_' +
                  name;
              final exist = walletsInfoSource.values
                      .firstWhereOrNull((el) => el.id == id) != null;
                      
              if (exist) {
                return null;
              }

              final walletInfo = WalletInfo.external(
                  id: id,
                  type: WalletType.monero,
                  name: name,
                  isRecovery: isRecovery,
                  restoreHeight: 0,
                  date: date,
                  dirPath: item.path,
                  path: '${item.path}/$name',
                  address: '');

              return walletInfo;
            }
          } catch (e) {
            print(e.toString());
            return null;
          }
        })
        .where((el) => el != null)
        .whereType<WalletInfo>()
        .toList();
    await walletsInfoSource.addAll(infoRecords);
    await prefs.setBool('ios_migration_wallet_info_completed', true);
  } catch (e) {
    print(e.toString());
  }
}

Future<void> ios_migrate_trades_list(Box<Trade> tradeSource) async {
  final prefs = await SharedPreferences.getInstance();

  if (prefs.getBool('ios_migration_trade_list_completed') ?? false) {
    return;
  }

  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    final url = '${appDocDir.path}/trades_list.json';
    final file = File(url);

    if (!file.existsSync()) {
      await prefs.setBool('ios_migration_trade_list_completed', true);
      return;
    }

    final content = file.readAsBytesSync();
    final flutterSecureStorage = FlutterSecureStorage();
    final masterPassword = await flutterSecureStorage.read(
        key: 'master_password', iOptions: IOSOptions());
    final key = masterPassword!.replaceAll('-', '');
    final decoded =
        await ios_legacy_helper.decrypt(content, key: key, salt: secrets.salt);
    final decodedJson = json.decode(decoded) as List<dynamic>;
    final trades = decodedJson.map((dynamic el) {
      final elAsMap = el as Map<String, dynamic>;
      final providerAsString = elAsMap['provider'] as String;
      final fromAsString = elAsMap['from'] as String;
      final toAsString = elAsMap['to'] as String;
      final dateAsDouble = elAsMap['date'] as double;
      final tradeId = elAsMap['tradeID'] as String;
      final to = CryptoCurrency.fromString(toAsString);
      final from = CryptoCurrency.fromString(fromAsString);
      final timestamp = dateAsDouble.toInt() * 1000;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      ExchangeProviderDescription? provider;

      switch (providerAsString.toLowerCase()) {
        case 'changenow':
          provider = ExchangeProviderDescription.changeNow;
          break;
        case 'xmr.to':
          provider = ExchangeProviderDescription.xmrto;
          break;
        case 'morph':
          provider = ExchangeProviderDescription.morphToken;
          break;
        default:
          break;
      }

      return Trade(
          id: tradeId, provider: provider!, from: from, to: to, createdAt: date, amount: '');
    });
    await tradeSource.addAll(trades);
    await prefs.setBool('ios_migration_trade_list_completed', true);
  } catch (e) {
    print(e.toString());
  }
}

Future<void> ios_migrate_address_book(Box<Contact> contactSource) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool('ios_migration_address_book_completed') ?? false) {
      return;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final addressBookJSON = File('${appDocDir.path}/address_book.json');

    if (!addressBookJSON.existsSync()) {
      await prefs.setBool('ios_migration_address_book_completed', true);
      return;
    }

    final List<dynamic> addresses =
        json.decode(addressBookJSON.readAsStringSync()) as List<dynamic>;
    final contacts = addresses.map((dynamic item) {
      final _item = item as Map<String, dynamic>;
      final type = _item["type"] as String;
      final address = _item["address"] as String;
      final name = _item["name"] as String;

      return Contact(
          address: address, name: name, type: CryptoCurrency.fromString(type));
    });

    await contactSource.addAll(contacts);
    await prefs.setBool('ios_migration_address_book_completed', true);
  } catch (e) {
    print(e.toString());
  }
}
