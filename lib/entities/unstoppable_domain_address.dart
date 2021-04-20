import 'package:flutter/services.dart';

const channel = MethodChannel('com.cakewallet.cake_wallet/unstoppable-domain');

Future<String> fetchUnstoppableDomainAddress(String domain, String ticker) async {
  String address;

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