import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:cake_wallet/src/domain/common/digest_request.dart';

part 'node.g.dart';

@HiveType()
class Node extends HiveObject {
  Node({@required this.uri, this.login, this.password});

  Node.fromMap(Map map)
      : uri = (map['uri'] ?? '') as String,
        login = map['login'] as String,
        password = map['password'] as String;

  static const boxName = 'Nodes';

  @HiveField(0)
  String uri;

  @HiveField(1)
  String login;

  @HiveField(2)
  String password;

  Future<bool> requestNode(String uri, {String login, String password}) async {
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
          json.encode({"jsonrpc": "2.0", "id": "0", "method": "get_info"});
      final response =
          await http.post(url.toString(), headers: headers, body: body);
      resBody = json.decode(response.body) as Map<String, dynamic>;
    }

    return !(resBody["result"]["offline"] as bool);
  }
}
