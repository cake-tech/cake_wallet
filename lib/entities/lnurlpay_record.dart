import 'dart:convert';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';

class LNUrlPayRecord {
  LNUrlPayRecord({
    required this.address,
    required this.name,
  });

  final String name;
  final String address;

  static Future<String?> checkWellKnownUsername(String username, CryptoCurrency currency) async {
    if (currency != CryptoCurrency.btc) return null;

    // split the string by the @ symbol:
    try {
      final List<String> splitStrs = username.split("@");
      String name = splitStrs.first.toLowerCase();
      final String domain = splitStrs.last;

      if (splitStrs.length == 3) {
        // for username like @alice@domain.org instead of alice@domain.org
        name = splitStrs[1];
      }

      if (name.isEmpty) {
        name = "_";
      }

      // lookup domain/.well-known/nano-currency.json and check if it has a nano address:
      final response = await ProxyWrapper().get(
        clearnetUri: Uri.parse("https://$domain/.well-known/lnurlp/$name"),
        headers: <String, String>{"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        return username;
      }
    } catch (e) {
      printV("error checking well-known username: $e");
    }
    return null;
  }

  static String formatDomainName(String name) {
    String formattedName = name;

    if (name.contains("@")) {
      formattedName = name.replaceAll("@", ".");
    }

    return formattedName;
  }

  static Future<LNUrlPayRecord?> fetchAddressAndName({
    required String formattedName,
    required CryptoCurrency currency,
  }) async {
    String name = formattedName;

    printV("formattedName: $formattedName");

    final address = await checkWellKnownUsername(formattedName, currency);

    if (address == null) {
      return null;
    }

    return LNUrlPayRecord(address: address, name: name);
  }
}
