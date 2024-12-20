import 'dart:convert';

import 'package:cw_zano/api/api_calls.dart';
import 'package:cw_zano/api/model/get_address_info_result.dart';

class ZanoUtils {
  static bool validateAddress(String address) {
    try {
      final result = GetAddressInfoResult.fromJson(
        jsonDecode(ApiCalls.getAddressInfo(address: address)) as Map<String, dynamic>,
      );
      return result.valid;
    } catch (err) {
      return false;
    }
  }
}
