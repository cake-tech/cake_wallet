import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:cake_wallet/src/domain/common/digest_request.dart';

part 'node.g.dart';

@HiveType()
class Node extends HiveObject {
  static const boxName = 'Nodes';

  @HiveField(0)
  String uri;

  @HiveField(1)
  String login;

  @HiveField(2)
  String password;

  Node({@required this.uri, this.login, this.password});

  Node.fromMap(Map map)
      : uri = map['uri'] ?? '',
        login = map['login'],
        password = map['password'];

  Future<bool> requestNode(String uri, {String login, String password}) async {
    var resBody;

    if (login != null && password != null) {
      final digestRequest = DigestRequest();
      var response = await digestRequest.request(
          uri: uri, login: login, password: password);
      resBody = response.data;
    } else {
      final url = Uri.http(uri, '/json_rpc');
      Map<String, String> headers = {'Content-type': 'application/json'};
      String body =
          json.encode({"jsonrpc": "2.0", "id": "0", "method": "get_info"});
      var response =
          await http.post(url.toString(), headers: headers, body: body);
      resBody = json.decode(response.body);
    }

    return !resBody["result"]["offline"];
  }
}
