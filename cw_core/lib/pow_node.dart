import 'dart:io';
import 'package:cw_core/keyable.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:http/io_client.dart' as ioc;

part 'pow_node.g.dart';

Uri createUriFromElectrumAddress(String address) => Uri.tryParse('tcp://$address')!;

@HiveType(typeId: PowNode.typeId)
class PowNode extends HiveObject with Keyable {
  PowNode({
    this.login,
    this.password,
    this.useSSL,
    this.trusted = false,
    this.socksProxyAddress,
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

  PowNode.fromMap(Map<String, Object?> map)
      : uriRaw = map['uri'] as String? ?? '',
        login = map['login'] as String?,
        password = map['password'] as String?,
        useSSL = map['useSSL'] as bool?,
        trusted = map['trusted'] as bool? ?? false,
        socksProxyAddress = map['socksProxyPort'] as String?;

  static const typeId = POW_NODE_TYPE_ID;
  static const boxName = 'PowNodes';

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

  bool get isSSL => useSSL ?? false;

  bool get useSocksProxy => socksProxyAddress == null ? false : socksProxyAddress!.isNotEmpty;

  Uri get uri {
    switch (type) {
      case WalletType.monero:
        return Uri.http(uriRaw, '');
      case WalletType.bitcoin:
        return createUriFromElectrumAddress(uriRaw);
      case WalletType.litecoin:
        return createUriFromElectrumAddress(uriRaw);
      case WalletType.haven:
        return Uri.http(uriRaw, '');
      case WalletType.ethereum:
        return Uri.https(uriRaw, '');
      case WalletType.nano:
      case WalletType.banano:
        if (uriRaw.contains("https") || uriRaw.endsWith("443") || isSSL) {
          return Uri.https(uriRaw, '');
        } else {
          return Uri.http(uriRaw, '');
        }
      default:
        throw Exception('Unexpected type ${type.toString()} for Node uri');
    }
  }

  @override
  bool operator ==(other) =>
      other is PowNode &&
      (other.uriRaw == uriRaw &&
          other.login == login &&
          other.password == password &&
          other.typeRaw == typeRaw &&
          other.useSSL == useSSL &&
          other.trusted == trusted &&
          other.socksProxyAddress == socksProxyAddress);

  @override
  int get hashCode =>
      uriRaw.hashCode ^
      login.hashCode ^
      password.hashCode ^
      typeRaw.hashCode ^
      useSSL.hashCode ^
      trusted.hashCode ^
      socksProxyAddress.hashCode;

  @override
  dynamic get keyIndex {
    _keyIndex ??= key;
    return _keyIndex;
  }

  WalletType get type => deserializeFromInt(typeRaw);

  set type(WalletType type) => typeRaw = serializeToInt(type);

  dynamic _keyIndex;

  Future<bool> requestNode() async {
    try {
      switch (type) {
        case WalletType.nano:
          return requestNanoPowNode();
        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestNanoPowNode() async {
    return http
        .post(
      uri,
      headers: {'Content-type': 'application/json'},
      body: json.encode(
        {
          "action": "work_generate",
          "hash": "0000000000000000000000000000000000000000000000000000000000000000",
        },
      ),
    )
        .then((http.Response response) {
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    });
  }
}
