import 'dart:convert';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';

Future<String> fetchUnstoppableDomainAddress(String domain, String ticker) async {
  var address = '';

  try {
    final uri = Uri.parse("https://api.unstoppabledomains.com/profile/public/${Uri.encodeQueryComponent(domain)}?fields=records");
    final response = await ProxyWrapper().get(clearnetUri: uri);
    
    final jsonParsed = json.decode(response.body) as Map<String, dynamic>;
    if (jsonParsed["records"] == null) {
      throw Exception(".records response from $uri is empty");
    };
    final records = jsonParsed["records"] as Map<String, dynamic>;
    final key = "crypto.${ticker.toUpperCase()}.address";
    if (records[key] == null) {
      throw Exception(".records.${key} response from $uri is empty");
    }

    return records[key] as String? ?? '';
  } catch (e) {
    printV('Unstoppable domain error: ${e.toString()}');
    address = '';
  }

  return address;
}