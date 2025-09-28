import 'dart:convert';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';

class FioAddressProvider {
  static const apiAuthority = 'fio.blockpane.com';
  static const availCheck = '/v1/chain/avail_check';
  static const getAddress = '/v1/chain/get_pub_address';

  static Future<bool> checkAvail(String fioAddress) async {
    bool isFioRegistered = false;
    final headers = {'Content-Type': 'application/json'};
    final body = <String, String>{"fio_name": fioAddress};

    final uri = Uri.https(apiAuthority, availCheck);
    final response = await ProxyWrapper().post(
      clearnetUri: uri,
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      return isFioRegistered;
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    isFioRegistered = responseJSON['is_registered'] as int == 1;

    return isFioRegistered;
  }

  static Future<String?> getPubAddress(String fioAddress, String token) async {
    final headers = {'Content-Type': 'application/json'};
    final body = <String, String>{
      "fio_address": fioAddress,
      "chain_code": token.toUpperCase(),
      "token_code": token.toUpperCase(),
    };

    final uri = Uri.https(apiAuthority, getAddress);
    final response = await ProxyWrapper().post(
      clearnetUri: uri,
      headers: headers,
      body: json.encode(body),
    );

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 400) {
      final error = responseJSON['error'] as String;
      final message = responseJSON['message'] as String;
      printV('${error}\n$message');
      return null;
    }

    if (response.statusCode != 200) {
      final String message = responseJSON['message'] as String? ?? 'Unknown error';

      printV('Error fetching public address for token $token: $message');
      return null;
    }

    final String pubAddress = responseJSON['public_address'] as String? ?? '';

    if (pubAddress.isNotEmpty) {
      return pubAddress;
    }

    return null;
  }
}
