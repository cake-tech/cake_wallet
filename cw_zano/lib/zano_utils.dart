import 'dart:convert';

import 'package:cw_zano/api/model/get_address_info_result.dart';
import 'package:cw_zano/get_height_by_date.dart';
import 'package:monero/zano.dart' as zano;

class ZanoUtils {
  static int heightByDate(DateTime date) =>
      ZanoHeight.getBlockHeightByTime(date.toUtc().subtract(const Duration(days: 1)));

  static int creationTimestampFromHeight(int height) {
    if (height <= 0) return 0;
    return ZanoHeight.getTimeByBlockHeight(height).millisecondsSinceEpoch ~/ 1000;
  }

  static bool validateAddress(String address) {
    try {
      final result = GetAddressInfoResult.fromJson(
        jsonDecode(zano.PlainWallet_getAddressInfo(address)) as Map<String, dynamic>,
      );
      return result.valid;
    } catch (err) {
      return false;
    }
  }
}
