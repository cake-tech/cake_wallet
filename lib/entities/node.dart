import 'package:cake_wallet/utils/mobx.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/entities/digest_request.dart';

part 'node.g.dart';

@HiveType(typeId: 1)
class Node extends HiveObject with Keyable {
  Node(
      {@required this.uri,
      @required WalletType type,
      this.login,
      this.password,
      this.useSSL}) {
    this.type = type;
  }

  Node.fromMap(Map map)
      : uri = map['uri'] as String ?? '',
        login = map['login'] as String,
        password = map['password'] as String,
        typeRaw = map['typeRaw'] as int,
        useSSL = map['useSSL'] as bool;

  static const boxName = 'Nodes';

  @HiveField(0)
  String uri;

  @HiveField(1)
  String login;

  @HiveField(2)
  String password;

  @HiveField(3)
  int typeRaw;

  @HiveField(4)
  bool useSSL;

  bool get isSSL => useSSL ?? false;

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
        case WalletType.monero:
          return requestMoneroNode();
        case WalletType.bitcoin:
          return requestBitcoinElectrumServer();
        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestMoneroNode() async {
    try {
      Map<String, dynamic> resBody;

      if (login != null && password != null) {
        final digestRequest = DigestRequest();
        final response = await digestRequest.request(
            uri: uri, login: login, password: password);
        resBody = response.data as Map<String, dynamic>;
      } else {
        final url = Uri.http(uri, '/json_rpc');
        final headers = {'Content-type': 'application/json'};
        final body =
            json.encode({'jsonrpc': '2.0', 'id': '0', 'method': 'get_info'});
        final response =
            await http.post(url.toString(), headers: headers, body: body);
        resBody = json.decode(response.body) as Map<String, dynamic>;
      }

      return !(resBody['result']['offline'] as bool);
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestBitcoinElectrumServer() async {
    // FIXME: IMPLEMENT ME
    return true;
  }
}
