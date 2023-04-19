import 'package:cake_wallet/utils/device_info.dart';
import 'package:flutter/services.dart';

const channel = MethodChannel('com.cake_wallet/native_utils');

Future<String> fetchUnstoppableDomainAddress(String domain, String ticker) async {
  var address = '';

  try {
    if (DeviceInfo.instance.isMobile) {
      address = await channel.invokeMethod<String>(
          'getUnstoppableDomainAddress',
          <String, String> {
            'domain' : domain,
            'ticker' : ticker
          }
      ) ?? '';
    } else {
      // TODO: Integrate with Unstoppable domains resolution API
      return address;
    }
  } catch (e) {
    print('Unstoppable domain error: ${e.toString()}');
    address = '';
  }

  return address;
}