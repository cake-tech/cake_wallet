import 'package:flutter/services.dart';

const channel = MethodChannel('com.cake_wallet/native_utils');

Future<String> fetchUnstoppableDomainAddress(String domain, String ticker) async {
  var address = '';

  try {
    address = await channel.invokeMethod(
        'getUnstoppableDomainAddress',
        <String, String> {
          'domain' : domain,
          'ticker' : ticker
        }
    );
  } catch (e) {
    print('Unstoppable domain error: ${e.toString()}');
    address = '';
  }

  return address;
}