import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as ioc;

class DigestAuth{
  Future<http.Response>request({
        String uri, 
        String login = "", 
        String password = "",
      }) async {
    final path = '/json_rpc';
    final rpcUri = Uri.http(uri, path);
    final realm = 'monero-rpc';
    final postMap = {
    'jsonrpc': '2.0', 
    'id': '0', 
    'method': 'get_info'
    };
    final authenticatingClient = HttpClient();
   
    authenticatingClient.addCredentials(
      rpcUri,
      realm, 
      HttpClientDigestCredentials(login ?? "", password ?? ""),
    );
   
    final http.Client client = ioc.IOClient(authenticatingClient);
   
    final response = await client.post(
      rpcUri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(postMap),
    );
   
    client.close();

    return response;
 }
}