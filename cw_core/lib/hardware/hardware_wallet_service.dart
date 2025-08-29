import 'dart:async';

import 'package:cw_core/hardware/hardware_account_data.dart';

abstract class HardwareWalletService {
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5});
}
