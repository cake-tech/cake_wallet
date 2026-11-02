import 'dart:typed_data';

import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:cw_tron/hardware/tron_ledger_app.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';

class TronLedgerService extends HardwareWalletService {
  TronLedgerService(LedgerConnection connection) : app = TronLedgerApp(connection);
  final TronLedgerApp app;

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    if (index < 0 || limit < 0 || index + limit > 0x80000000) {
      throw ArgumentError('Invalid TRON account range');
    }
    await app.getAppConfiguration();
    final accounts = <HardwareAccountData>[];
    for (var i = index; i < index + limit; i++) {
      final path = "m/44'/195'/$i'/0/0";
      final address = await app.getAddress(path);
      accounts.add(
        HardwareAccountData(address: address.address, accountIndex: i, derivationPath: path),
      );
    }
    return accounts;
  }

  Future<void> verifyAddress(String path, String expectedAddress) async {
    final result = await app.getAddress(path, display: true);
    if (result.address != expectedAddress) {
      throw TronLedgerException('The device address does not match this wallet');
    }
  }

  Future<Uint8List> signPreparedTransaction(
    String path,
    Uint8List rawData, {
    bool requireClearUsdt = false,
  }) =>
      app.signTransaction(path, rawData, requireClearUsdt: requireClearUsdt);
}
