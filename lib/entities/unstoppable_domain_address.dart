import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

const channel = MethodChannel('com.cake_wallet/native_utils');

Future<String> fetchUnstoppableDomainAddress(String domain, String ticker) async {
  var address = '';

  try {
    final uri = Uri.parse("https://api.unstoppabledomains.com/profile/public/${Uri.encodeQueryComponent(domain)}?fields=records");
    final jsonString = await http.read(uri);
    final jsonParsed = json.decode(jsonString) as Map<String, dynamic>;
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
    print('Unstoppable domain error: ${e.toString()}');
    address = '';
  }

  return address;
}