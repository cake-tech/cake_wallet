import 'dart:async';
import 'dart:typed_data';

import 'package:cw_core/hardware/hardware_account_data.dart';

abstract class HardwareWalletService {
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5});

  Future<Uint8List> signTransaction({required String transaction}) => throw UnimplementedError();

  Future<Uint8List> signMessage({required Uint8List message, String? derivationPath}) =>
      throw UnimplementedError();
}
