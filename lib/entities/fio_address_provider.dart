import 'dart:convert';

import 'package:http/http.dart' as http;

class FioAddressProvider {
  static const apiAuthority = 'fio.blockpane.com';
  static const availCheck = '/v1/chain/avail_check';
  static const getAddress = '/v1/chain/get_pub_address';

  static Future<bool> checkAvail(String fioAddress) async {
    bool isFioRegistered = false;
    final headers = {'Content-Type': 'application/json'};
    final body = <String, String>{"fio_name": fioAddress};

    final uri = Uri.https(apiAuthority, availCheck);
    final response =
        await http.post(uri, headers: headers, body: json.encode(body));

    if (response.statusCode != 200) {
      return isFioRegistered;
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    isFioRegistered = responseJSON['is_registered'] as int == 1;

    return isFioRegistered;
  }

  static Future<String> getPubAddress(String fioAddress, String token) async {
    final headers = {'Content-Type': 'application/json'};
    final body = <String, String>{
      "fio_address": fioAddress,
      "chain_code": token.toUpperCase(),
      "token_code": token.toUpperCase(),
    };

    final uri = Uri.https(apiAuthority, getAddress);
    final response =
        await http.post(uri, headers: headers, body: json.encode(body));

    if (response.statusCode == 400) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON['error'] as String;
      final message = responseJSON['message'] as String;
      throw Exception('${error}\n$message');
    }

    if (response.statusCode != 200) {
      throw Exception('Unexpected response http status: ${response.statusCode}');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final String pubAddress = responseJSON['public_address'] as String;

    return pubAddress;
  }
}
