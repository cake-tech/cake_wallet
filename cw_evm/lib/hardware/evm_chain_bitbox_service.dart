import "dart:async";

import "package:bitbox_flutter/bitbox_flutter.dart";
import "package:cw_core/hardware/hardware_account_data.dart";
import "package:cw_core/hardware/hardware_wallet_service.dart";

class EVMChainBitboxService extends HardwareWalletService {
  EVMChainBitboxService(this.manager, {this.chainId = 1});

  final BitboxConnection manager;
  final int chainId;

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final accounts = <HardwareAccountData>[];
    final indexRange = List.generate(limit, (i) => i + index);

    for (final i in indexRange) {
      final derivationPath = "m/44'/60'/0'/0/$i";
      final address =
          await BitboxEthereum(manager.ffi, chainId: chainId).getAddress(derivationPath);

      accounts.add(
        HardwareAccountData(
          address: address,
          accountIndex: i,
          derivationPath: derivationPath,
        ),
      );
    }

    return accounts;
  }
}
