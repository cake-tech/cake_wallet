import 'dart:async';

import 'package:cw_core/db/sqlite.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/wallet_info_legacy.dart' as wiLegacy;
import "package:cw_core/node_legacy.dart" as node_legacy;

Future<void> performHiveMigration() async {
  try {
    if (!CakeHive.isAdapterRegistered(wiLegacy.WalletInfo.typeId)) {
      CakeHive.registerAdapter(wiLegacy.WalletInfoAdapter());
    }
    if (!CakeHive.isAdapterRegistered(DERIVATION_TYPE_TYPE_ID)) {
      CakeHive.registerAdapter(wiLegacy.DerivationTypeAdapter());
    }
    if (!CakeHive.isAdapterRegistered(wiLegacy.DerivationInfo.typeId)) {
      CakeHive.registerAdapter(wiLegacy.DerivationInfoAdapter());
    }
    if (!CakeHive.isAdapterRegistered(HARDWARE_WALLET_TYPE_TYPE_ID)) {
      CakeHive.registerAdapter(wiLegacy.HardwareWalletTypeAdapter());
    }
    if(!CakeHive.isAdapterRegistered(node_legacy.Node.typeId)) {
      CakeHive.registerAdapter(node_legacy.NodeAdapter());
    }
    final walletInfoBox = await CakeHive.openBox<wiLegacy.WalletInfo>(wiLegacy.WalletInfo.boxName);
    await wiLegacy.WalletInfo.migrateAllToSqlite(walletInfoBox);


    final nodeBox = await CakeHive.openBox<node_legacy.Node>(node_legacy.Node.boxName);
    final powNodeBox = await CakeHive.openBox<node_legacy.Node>(node_legacy.Node.boxName+"pow");
    await node_legacy.Node.migrateAllToSqlite(nodeBox, powNodeBox);

  } catch (e) {
    printV('Error performing Hive migration: $e, continuing anyway');
  }
}

enum DerivationType {
  unknown,
  def, // default is a reserved word
  nano,
  bip39,
  electrum,
}

enum HardwareWalletType {
  ledger,
  bitbox,
  cupcake,
  coldcard,
  seedsigner,
  keystone,
  trezor,
}

enum WalletInfoAddressType {
  used,
  hidden,
  manual,
}

class WalletInfoAddressInfo {
  WalletInfoAddressInfo({
    this.id = 0,
    required this.walletInfoId,
    required this.mapKey,
    required this.accountIndex,
    required this.address,
    required this.label,
  });

  int id;
  int walletInfoId;
  int mapKey;
  int accountIndex;
  String address;
  String label;

  static String get tableName => 'walletInfoAddressInfo'; 
  static String get selfIdColumn => "${tableName}Id";

  static Future<List<WalletInfoAddressInfo>> selectList(int walletInfoId) async {
    final query = await db.query(tableName, where: 'walletInfoId = ?', whereArgs: [walletInfoId]);
    return List.generate(query.length, (index) => WalletInfoAddressInfo.fromJson(query[index]));
  }

  static Future<int> deleteByWalletInfoId(int walletInfoId) async {
    return await db.delete(tableName, where: 'walletInfoId = ?', whereArgs: [walletInfoId]);
  }
  static Future<int> insert({
    required int walletInfoId,
    required int mapKey,
    required int accountIndex,
    required String address,
    required String label,
  }) async {
    return await db.insert(tableName, {
      "walletInfoId": walletInfoId,
      "mapKey": mapKey,
      "mapValueAccountIndex": accountIndex,
      "mapValueAddress": address,
      "mapValueLabel": label,
    });
  }

  Map<String, dynamic> toJson() {
    return {
      selfIdColumn: id,
      "walletInfoId": walletInfoId,
      "mapKey": mapKey,
      "mapValueAccountIndex": accountIndex,
      "mapValueAddress": address,
      "mapValueLabel": label,
    };
  }

  factory WalletInfoAddressInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfoAddressInfo(
      id: json[selfIdColumn] as int,
      walletInfoId: json['walletInfoId'] as int,
      mapKey: json['mapKey'] as int,
      accountIndex: json['mapValueAccountIndex'] as int,
      address: json['mapValueAddress'] as String,
      label: json['mapValueLabel'] as String,
    );
  }
}

class WalletInfoAddressMap {
  WalletInfoAddressMap({
    required this.id,
    required this.walletInfoId,
    required this.addressKey,
    required this.addressValue,
  });


  int id;
  int walletInfoId;
  String addressKey;
  String addressValue;

  static String get tableName => 'walletInfoAddressMap'; 
  static String get selfIdColumn => "${tableName}Id"; 

  static Future<List<WalletInfoAddressMap>> selectList(int walletInfoId) async {
    final query = await db.query(tableName, where: 'walletInfoId = ?', whereArgs: [walletInfoId]);
    return List.generate(query.length, (index) => WalletInfoAddressMap.fromJson(query[index]));
  }
  static Future<int> deleteByWalletInfoId(int walletInfoId) async {
    return await db.delete(tableName, where: 'walletInfoId = ?', whereArgs: [walletInfoId]);
  }
  static Future<int> insert(int walletInfoId, String addressKey, String addressValue) async {
    return await db.insert(tableName, {
      "walletInfoId": walletInfoId,
      "addressKey": addressKey,
      "addressValue": addressValue,
    });
  }

  Map<String, dynamic> toJson() {
    return {
      selfIdColumn: id,
      "walletInfoId": walletInfoId,
      "addressKey": addressKey,
      "addressValue": addressValue,
    };
  }

  factory WalletInfoAddressMap.fromJson(Map<String, dynamic> json) {
    return WalletInfoAddressMap(
      id: json[selfIdColumn] as int,
      walletInfoId: json['walletInfoId'] as int,
      addressKey: json['addressKey'] as String,
      addressValue: json['addressValue'] as String,
    );
  }
}

class WalletInfoAddress {
  WalletInfoAddress({
    this.id = 0,
    required this.walletInfoId,
    required this.type,
    required this.address,
  });

  int id;
  int walletInfoId;
  WalletInfoAddressType type;
  String address;

  static String get tableName => 'walletInfoAddress'; 
  static String get selfIdColumn => "${tableName}Id";

  static Future<List<WalletInfoAddress>> selectList(int walletInfoId, WalletInfoAddressType type) async {
    final query = await db.query(tableName, where: 'walletInfoId = ? AND type = ?', whereArgs: [walletInfoId, type.index]);
    return List.generate(query.length, (index) => WalletInfoAddress.fromJson(query[index]));
  }

  static Future<int> deleteByAddress(int walletInfoId, WalletInfoAddressType type, String address) async {
    return await db.delete(tableName, where: 'walletInfoId = ? AND type = ? AND address = ?', whereArgs: [walletInfoId, type.index, address]);
  }

  static Future<int> deleteByType(int walletInfoId, WalletInfoAddressType type) async {
    return await db.delete(tableName, where: 'walletInfoId = ? AND type = ?', whereArgs: [walletInfoId, type.index]);
  }

  static Future<int> insert(int walletInfoId, WalletInfoAddressType type, String address) async {
    final select = await db.query(tableName, where: 'walletInfoId = ? AND type = ? AND address = ?', whereArgs: [walletInfoId, type.index, address]);
    if (select.isNotEmpty) {
      return select[0][selfIdColumn] as int;
    }
    return await db.insert(tableName, {
      "walletInfoId": walletInfoId,
      "type": type.index,
      "address": address,
    });
  }

  Map<String, dynamic> toJson() {
    return {
      selfIdColumn: id,
      "walletInfoId": walletInfoId,
      "type": type.index,
      "address": address,
    };
  }

  factory WalletInfoAddress.fromJson(Map<String, dynamic> json) {
    return WalletInfoAddress(
      id: json[selfIdColumn] as int,
      walletInfoId: json['walletInfoId'] as int,
      type: WalletInfoAddressType.values[json['type'] as int],
      address: json['address'] as String,
    );
  }
}

class DerivationInfo {
  DerivationInfo({
    this.id = 0,
    this.derivationType,
    this.derivationPath,
    this.balance = "",
    this.address = "",
    this.transactionsCount = 0,
    this.scriptType,
    this.description,
  });

  int id;

  static String get tableName => 'walletInfoDerivationInfo'; 
  static String get selfIdColumn => "${tableName}Id";

  String address;
  String balance;
  int transactionsCount;
  DerivationType? derivationType;
  String? derivationPath;
  String? scriptType;
  String? description;

  static Future<List<DerivationInfo>> selectList(String where, List<dynamic> whereArgs) async {
    final query = await db.query(
      tableName,
      columns: [
        selfIdColumn,
        'address',
        'balance', 
        'transactionsCount',
        'derivationType',
        'derivationPath',
        'scriptType',
        'description',
      ],
      where: where.isNotEmpty ? where : "1 = 1",
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );
    return List.generate(query.length, (index) => DerivationInfo.fromJson(query[index]));
  }

  Map<String, dynamic> toJson() {
    return {
      selfIdColumn: id,
      "address": address,
      "balance": balance,
      "transactionsCount": transactionsCount,
      "derivationType": derivationType?.index,
      "derivationPath": derivationPath,
      "scriptType": scriptType,
      "description": description,
    };
  }

  factory DerivationInfo.fromJson(Map<String, dynamic> json ) {
    return DerivationInfo(
      id: json[selfIdColumn] as int,
      derivationType: DerivationType.values[json['derivationType'] as int? ?? 0],
      derivationPath: json['derivationPath'] as String?,
      balance: json['balance'] as String? ?? "",
      address: json['address'] as String? ?? "",
      transactionsCount: json['transactionsCount'] as int? ?? 0,
      scriptType: json['scriptType'] as String?,
      description: json['description'] as String?,
    );
  }

  Future<int> save() async {
    final json = toJson();
    if (json[selfIdColumn] == 0) {
      json[selfIdColumn] = null;
    }
    id = await db.insert(tableName, json, conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }
}

class WalletInfo {
  WalletInfo(
    this.internalId,
    this.id,
    this.name,
    this.type,
    this.isRecovery,
    this.restoreHeight,
    this.timestamp,
    this.dirPath,
    this.path,
    this.address,
    this.yatEid,
    this.yatLastUsedAddressRaw,
    this.showIntroCakePayCard,
    this.derivationInfoId,
    this.hardwareWalletType,
    this.parentAddress,
    this.hashedWalletIdentifier,
    this.isNonSeedWallet,
    this.sortOrder,
  ) : _yatLastUsedAddressController = StreamController<String>.broadcast();

  factory WalletInfo.external({
    required String id,
    required String name,
    required WalletType type,
    required bool isRecovery,
    required int restoreHeight,
    required DateTime date,
    required String dirPath,
    required String path,
    required String address,
    bool? showIntroCakePayCard,
    String yatEid = '',
    String yatLastUsedAddressRaw = '',
    int? derivationInfoId,
    HardwareWalletType? hardwareWalletType,
    String? parentAddress,
    String? hashedWalletIdentifier,
    bool? isNonSeedWallet,
    int? sortOrder,
  }) {
    return WalletInfo(
      0,
      id,
      name,
      type,
      isRecovery,
      restoreHeight,
      date.millisecondsSinceEpoch,
      dirPath,
      path,
      address,
      yatEid,
      yatLastUsedAddressRaw,
      showIntroCakePayCard,
      derivationInfoId ?? -1,
      hardwareWalletType,
      parentAddress,
      hashedWalletIdentifier,
      isNonSeedWallet ?? false,
      sortOrder ?? 0,
    );
  }

  static String get tableName => 'walletInfo'; 
  static String get selfIdColumn => "${tableName}Id";

  int internalId;

  String id;
  String name;
  WalletType type;
  bool isRecovery;
  int restoreHeight;
  int timestamp;
  String dirPath;
  String path;
  String address;
  Future<Map<String, String>> getAddresses() async {
    final list = await WalletInfoAddressMap.selectList(internalId);
    return Map.fromEntries(list.map((e) => MapEntry(e.addressKey, e.addressValue)));
  }

  Future<void> setAddresses(Map<String, String> addresses) async {
    await WalletInfoAddressMap.deleteByWalletInfoId(internalId);
    final keys = addresses.keys.toList();
    for (final address in keys) {
      await WalletInfoAddressMap.insert(internalId, address, addresses[address]!);
    }
  }

  String? yatEid;
  String? yatLastUsedAddressRaw;
  bool? showIntroCakePayCard;
  Future<Map<int, List<WalletInfoAddressInfo>>> getAddressInfos() async {
    final list = await WalletInfoAddressInfo.selectList(internalId);
    final ret = <int, List<WalletInfoAddressInfo>>{};
    for (final e in list) {
      ret[e.mapKey] ??= [];
      ret[e.mapKey]!.add(e);
    }
    return ret;
  }

  Future<void> setAddressInfos(Map<int, List<WalletInfoAddressInfo>> addressInfos) async {
    await WalletInfoAddressInfo.deleteByWalletInfoId(internalId);
    final entries = addressInfos.entries.toList();
    for (final addressInfo in entries) {
      for (final info in addressInfo.value) {
        await WalletInfoAddressInfo.insert(
          walletInfoId: internalId,
          mapKey: addressInfo.key,
          accountIndex: info.accountIndex,
          address: info.address,
          label: info.label,
        );
      }
    }
  }

  Future<Set<String>> getUsedAddresses() async {
    final list = await WalletInfoAddress.selectList(internalId, WalletInfoAddressType.used);
    return list.map((e) => e.address).toSet();
  }
  Future<void> setUsedAddresses(List<String> addresses) async {
    await WalletInfoAddress.deleteByType(internalId, WalletInfoAddressType.used);
    for (final address in addresses) {
      await WalletInfoAddress.insert(internalId, WalletInfoAddressType.used, address);
    }
  }

  Future<Set<String>> getHiddenAddresses() async {
    final list = await WalletInfoAddress.selectList(internalId, WalletInfoAddressType.hidden);
    return list.map((e) => e.address).toSet();
  }
  Future<void> setHiddenAddresses(List<String> addresses) async {
    await WalletInfoAddress.deleteByType(internalId, WalletInfoAddressType.hidden);
    for (final address in addresses) {
      await WalletInfoAddress.insert(internalId, WalletInfoAddressType.hidden, address);
    }
  }

  Future<Set<String>> getManualAddresses() async {
    final list = await WalletInfoAddress.selectList(internalId, WalletInfoAddressType.manual);
    return list.map((e) => e.address).toSet();
  }
  Future<void> setManualAddresses(List<String> addresses) async {
    await WalletInfoAddress.deleteByType(internalId, WalletInfoAddressType.manual);
    for (final address in addresses) {
      await WalletInfoAddress.insert(internalId, WalletInfoAddressType.manual, address);
    }
  }

  Future<void> addAddress(String address, WalletInfoAddressType type) async {
    await WalletInfoAddress.insert(internalId, type, address);
  }

  String? addressPageType;
  String? network;
  int derivationInfoId;
  DerivationInfo? _derivationInfo;
  Future<DerivationInfo> getDerivationInfo() async {
    if (_derivationInfo != null) {
      return _derivationInfo!;
    }
    final list = await DerivationInfo.selectList('walletInfoDerivationInfoId = ?', [derivationInfoId]);
    if (list.isEmpty) {
      final di = DerivationInfo(
        id: 0,
        derivationType: DerivationType.unknown,
      );
      derivationInfoId = await di.save();
      _derivationInfo = di;
      return di;
    }
    _derivationInfo = list[0];
    return _derivationInfo!;
  }
  HardwareWalletType? hardwareWalletType;
  String? parentAddress;
  String? hashedWalletIdentifier;
  bool isNonSeedWallet;
 
  int sortOrder;

  String get yatLastUsedAddress => yatLastUsedAddressRaw ?? '';

  set yatLastUsedAddress(String address) {
    yatLastUsedAddressRaw = address;
    _yatLastUsedAddressController.add(address);
  }

  String get yatEmojiId => yatEid ?? '';

  bool get isShowIntroCakePayCard {
    if (showIntroCakePayCard == null) {
      return type != WalletType.haven;
    }
    return showIntroCakePayCard!;
  }

  bool get isHardwareWallet => [
        HardwareWalletType.bitbox,
        HardwareWalletType.ledger,
        HardwareWalletType.trezor
      ].contains(hardwareWalletType);

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(timestamp);

  Stream<String> get yatLastUsedAddressStream => _yatLastUsedAddressController.stream;

  StreamController<String> _yatLastUsedAddressController;

  Map<String, dynamic> toJson() => {
    selfIdColumn: internalId,
    "id": id,
    "name": name,
    "type": type.index,
    "isRecovery": isRecovery ? 1 : 0,
    "restoreHeight": restoreHeight,
    "timestamp": timestamp,
    "dirPath": dirPath,
    "path": path,
    "address": address,
    "yatEid": yatEid,
    "yatLastUsedAddressRaw": yatLastUsedAddressRaw,
    "showIntroCakePayCard": showIntroCakePayCard == true ? 1 : 0, // SQL regression: null -> false
    "walletInfoDerivationInfoId": derivationInfoId,
    "hardwareWalletType": hardwareWalletType?.index,
    "parentAddress": parentAddress,
    "hashedWalletIdentifier": hashedWalletIdentifier,
    "isNonSeedWallet": isNonSeedWallet ? 1 : 0,
    "sortOrder": sortOrder,
  };

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      json[selfIdColumn] as int,
      json['id'] as String,
      json['name'] as String,
      WalletType.values[json['type'] as int],
      (json['isRecovery'] as int) == 1,
      json['restoreHeight'] as int,
      json['timestamp'] as int,
      json['dirPath'] as String,
      json['path'] as String,
      json['address'] as String,
      json['yatEid'] as String?,
      json['yatLastUsedAddressRaw'] as String?,
      (json['showIntroCakePayCard'] as int) == 1,
      json['walletInfoDerivationInfoId'] as int,
      json['hardwareWalletType'] == null ? null : HardwareWalletType.values[json['hardwareWalletType'] as int],
      json['parentAddress'] as String?,
      json['hashedWalletIdentifier'] as String?,
      (json['isNonSeedWallet'] as int) == 1,
      json['sortOrder'] as int? ?? 0,
    );
  }

  Future<int> save() async {
    final json = toJson();
    if (json[selfIdColumn] == 0) {
      json[selfIdColumn] = null;
    }
    if (_derivationInfo != null) {
      derivationInfoId = await _derivationInfo!.save();
    }
    internalId = await db.insert(tableName, json, conflictAlgorithm: ConflictAlgorithm.replace);
    return internalId;
  }

  static Future<int> delete(WalletInfo walletInfo) async {
    return await db.delete(tableName, where: 'id = ?', whereArgs: [walletInfo.id]);
  }

  static Future<List<WalletInfo>> selectList(String where, List<dynamic> whereArgs, {String orderBy = 'sortOrder'}) async {
    final list = await db.query(
      tableName,
      where: where.isNotEmpty ? where : "1 = 1",
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );
    return List.generate(list.length, (index) => WalletInfo.fromJson(list[index]));
  }

  static Future<List<WalletInfo>> getAll() async {
    return selectList('', []);
  }

  static Future<WalletInfo?> get(String name, WalletType type) async {
    final list = await selectList('name = ? AND type = ?', [name, type.index]);
    if (list.isEmpty) {
      return null;
    }
    return list[0];
  }

  Future<void> updateRestoreHeight(int height) async {
    restoreHeight = height;
    await save();
  }
}
