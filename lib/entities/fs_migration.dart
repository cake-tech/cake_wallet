import 'dart:io';
import 'dart:convert';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

const reservedNames = ["flutter_assets", "wallets", "db"];

Future<void> migrate_android_v1() async {
  final appDocDir = await getApplicationDocumentsDirectory();

  await migrate_hives(appDocDir: appDocDir);
  await migrate_wallets(appDocDir: appDocDir);
}

Future<void> migrate_ios_v1() async {
  final appDocDir = await getApplicationDocumentsDirectory();
  //get the new shared preferences instance
  SharedPreferences prefs = await SharedPreferences.getInstance();

  //translate the node uri
  String nodeURI = prefs.getString('node_uri');
  await prefs.setString('current_node_id', nodeURI);

  //should we provide default btc node key?
  int activeCurrency = prefs.getInt('currency');
  await prefs.setInt('current_fiat_currency', activeCurrency);

  //translate fee priority
  int activeFeeTier = prefs.getInt('saved_fee_priority');
  await prefs.setInt('current_fee_priority', activeFeeTier);

  //translate current balance mode
  int currentBalanceMode = prefs.getInt('display_balance_mode');
  await prefs.setInt('current_balance_display_mode', currentBalanceMode);

  //translate should save recipient address
  bool shouldSave = prefs.getBool('should_save_recipient_address');
  await prefs.setBool('save_recipient_address', shouldSave);

  //translate biometric
  bool biometricOn = prefs.getBool('biometric_authentication_on');
  await prefs.setBool('allow_biometrical_authentication', biometricOn);

  //read the current theme as integer, write it back as a bool
  int currentTheme = prefs.getInt('current-theme');
  bool isDark = false;
  if (currentTheme == 1) {
    isDark = true;
  }
  await prefs.setBool('dark_theme', isDark);

  //assign the pin lenght
  int pinLength = prefs.getInt('pin-length');
  await prefs.setInt('pin-length', pinLength);

  //default value for display list key?
  String walletName = prefs.getString('current_wallet_name');
  await prefs.setString('current_wallet_name', walletName);
}

Future<void> migrate_hives({Directory appDocDir}) async {
  final dbDir = Directory('${appDocDir.path}/db');
  final files = List<File>();

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

Future<void> migrate_wallets({Directory appDocDir}) async {
  final walletsDir = Directory('${appDocDir.path}/wallets');
  final moneroWalletsDir = Directory('${walletsDir.path}/monero');
  final dirs = List<Directory>();

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

Future<void> migrate_ios_wallet_info(
    {@required Directory appDocDir,
    @required Box<WalletInfo> walletsInfo}) async {
  // final walletsDir = Directory('${appDocDir.path}/wallets');
  // final moneroWalletsDir = Directory('${walletsDir.path}/monero');

  // moneroWalletsDir.listSync().forEach((item) async {
  //   try {
  //     if (item is Directory) {
  //       final name = item.path.split('/').last;
  //       final configFile = File('${item.path}/$name.json');
  //       final config =
  //           json.decode(configFile.readAsStringSync()) as Map<String, dynamic>;
  //       final isRecovery = config["isRecovery"] as bool ?? false;
  //       final id =
  //           walletTypeToString(WalletType.monero).toLowerCase() + '_' + name;
  //       final walletInfo =
  //           WalletInfo(id: id, name: name, isRecovery: isRecovery);

  //       await walletsInfo.add(walletInfo);
  //     }
  //   } catch (e) {
  //     print(e.toString());
  //   }
  // });
}

Future<void> migrate_ios_trades_list(
    {@required Directory appDocDir, @required Box<Trade> trades}) async {
  final adderessBookJSON = File('${appDocDir.path}/trades_list.json');
  final List<dynamic> trades =
      json.decode(adderessBookJSON.readAsStringSync()) as List<dynamic>;
}

Future<void> migrate_ios_address_book(
    {@required Directory appDocDir, @required Box<Contact> contacts}) async {
  final adderessBookJSON = File('${appDocDir.path}/address_book.json');
  final List<dynamic> addresses =
      json.decode(adderessBookJSON.readAsStringSync()) as List<dynamic>;

  addresses.forEach((dynamic item) async {
    final _item = item as Map<String, dynamic>;
    final type = _item["type"] as String;
    final address = _item["address"] as String;
    final name = _item["name"] as String;
    final contact = Contact(
        address: address, name: name, type: CryptoCurrency.fromString(type));

    await contacts.add(contact);
  });
}
