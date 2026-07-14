import 'dart:io';
import 'package:cw_core/keyable.dart';
import 'package:cw_core/node_list.dart';
import 'package:cw_core/utils/proxy_socket/abstract.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:cw_core/wallet_type.dart';
import 'dart:math' as math;
import 'package:convert/convert.dart';

import 'package:crypto/crypto.dart';

import 'cake_hive.dart';
import 'node.dart' as node_new;

part 'node_legacy.part.dart';

Future<void> performNodeHiveMigration() async {
  if (!CakeHive.isAdapterRegistered(Node.typeId)) {
    CakeHive.registerAdapter(NodeAdapter());
  }

  final nodeBox = await CakeHive.openBox<Node>(Node.boxName);
  final powNodeBox = await CakeHive.openBox<Node>(Node.boxName + "pow");
  final builtinNodes = await loadAllDefaultNodes();
  final builtinPowNodes = await loadDefaultNanoPowNodes();
  await Node.migrateAllToSqlite(nodeBox, powNodeBox, builtinNodes, builtinPowNodes);
}

Uri createUriFromElectrumAddress(String address, String path) =>
    Uri.tryParse('tcp://$address$path')!;

@HiveType(typeId: Node.typeId)
class Node extends HiveObject with Keyable {
  Node({
    this.label,
    this.login,
    this.password,
    this.useSSL,
    this.trusted = false,
    this.socksProxyAddress,
    this.path = '',
    this.isEnabledForAutoSwitching = false,
    String? uri,
    WalletType? type,
  }) {
    if (uri != null) {
      uriRaw = uri;
    }
    if (type != null) {
      this.type = type;
    }
  }

  static Future<void> migrateAllToSqlite(Box<Node> nodeBox, Box<Node> powNodeBox,
      List<node_new.Node> defaultNodes, List<node_new.Node> defaultPowNodes) async {
    final list = nodeBox.values.toList();
    final powList = powNodeBox.values.toList();
    for (final node in list) {
      if (defaultNodes.any((item) => item.uri == node.uri)) {
        // default nodes will be added by validateBuiltinNodes(), no need to migrate them.
        await node.delete();
        continue;
      }
      await node.migrateToSqlite(isPow: false, isBuiltin: false, isOfficial: false);
      await node.delete();
    }
    for (final node in powList) {
      if (defaultPowNodes.any((item) => item.uri == node.uri)) {
        await node.delete();
        continue;
      }
      await node.migrateToSqlite(isPow: true, isBuiltin: false, isOfficial: false);
      await node.delete();
    }
  }

  Future<void> migrateToSqlite(
      {required bool isPow, required bool isBuiltin, required bool isOfficial}) async {
    final newNode = node_new.Node(
      id: key as int,
      login: login,
      label: label,
      password: password,
      type: type,
      useSSL: useSSL,
      trusted: trusted,
      socksProxyAddress: socksProxyAddress,
      isPow: isPow,
      path: path,
      uri: uriRaw,
      isEnabledForAutoSwitching: isEnabledForAutoSwitching,
      isOfficial: isOfficial,
      isBuiltin: isBuiltin,
    );
    await newNode.save();
  }

  Node.fromMap(Map<String, Object?> map)
      : uriRaw = map['uri'] as String? ?? '',
        path = map['path'] as String? ?? '',
        login = map['login'] as String?,
        label = map['label'] as String?,
        password = map['password'] as String?,
        useSSL = map['useSSL'] as bool?,
        trusted = map['trusted'] as bool? ?? false,
        socksProxyAddress = map['socksProxyPort'] as String?,
        isEnabledForAutoSwitching = map['isEnabledForAutoSwitching'] as bool? ?? false;

  static const typeId = NODE_TYPE_ID;
  static const boxName = 'Nodes';

  @HiveField(0, defaultValue: '')
  late String uriRaw;

  @HiveField(1)
  String? login;

  @HiveField(2)
  String? password;

  @HiveField(3, defaultValue: 0)
  late int typeRaw;

  @HiveField(4)
  bool? useSSL;

  @HiveField(5, defaultValue: false)
  bool trusted;

  @HiveField(6)
  String? socksProxyAddress;

  @HiveField(7, defaultValue: '')
  String? path;

  @HiveField(8)
  bool? isElectrs;

  @HiveField(9)
  bool? supportsSilentPayments;

  @HiveField(10)
  bool? supportsMweb;

  @HiveField(11, defaultValue: false)
  bool isEnabledForAutoSwitching;

  @HiveField(12, defaultValue: '')
  String? label;

  bool get isSSL => useSSL ?? false;

  bool get useSocksProxy => socksProxyAddress == null ? false : socksProxyAddress!.isNotEmpty;

  Uri get uri {
    try {
      return _uri;
    } catch (e) {
      printV(e);
      return Uri();
    }
  }

  Uri get _uri {
    switch (type) {
      case WalletType.monero:
      case WalletType.zcash:
      case WalletType.haven:
      case WalletType.wownero:
        return Uri.http(uriRaw, '');
      case WalletType.bitcoin:
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
      case WalletType.dogecoin:
        return createUriFromElectrumAddress(uriRaw, path!);
      case WalletType.nano:
      case WalletType.banano:
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.bsc:
      case WalletType.arbitrum:
      case WalletType.solana:
      case WalletType.tron:
      case WalletType.zano:
      case WalletType.decred:
        return Uri.parse(
            "http${isSSL ? "s" : ""}://$uriRaw${path!.startsWith("/") || path!.isEmpty ? path : "/$path"}");
      case WalletType.none:
        throw Exception('Unexpected type ${type.toString()} for Node uri');
    }
  }

  bool get isValidProxyAddress => socksProxyAddress?.contains(':') ?? false;

  @override
  bool operator ==(other) =>
      other is Node &&
      (other.uriRaw == uriRaw &&
          other.login == login &&
          other.label == label &&
          other.password == password &&
          other.typeRaw == typeRaw &&
          other.useSSL == useSSL &&
          other.trusted == trusted &&
          other.socksProxyAddress == socksProxyAddress &&
          other.path == path);

  @override
  int get hashCode =>
      uriRaw.hashCode ^
      login.hashCode ^
      label.hashCode ^
      password.hashCode ^
      typeRaw.hashCode ^
      useSSL.hashCode ^
      trusted.hashCode ^
      socksProxyAddress.hashCode ^
      path.hashCode;

  @override
  dynamic get keyIndex {
    _keyIndex ??= key;
    return _keyIndex;
  }

  WalletType get type => deserializeFromInt(typeRaw);

  set type(WalletType type) => typeRaw = serializeToInt(type);

  dynamic _keyIndex;
}
