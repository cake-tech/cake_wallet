import 'dart:async';

import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:trezor_connect/trezor_connect.dart';

class EVMChainTrezorService extends HardwareWalletService {
  EVMChainTrezorService(this.connect, {this.chainId = 1});

  final TrezorConnect connect;
  final int chainId;

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final indexRange = List.generate(limit, (i) => i + index);

    final requestParams = <TrezorGetAddressParams>[];
    for (final i in indexRange) {
      final derivationPath = "m/44'/60'/$i'/0/0";
      requestParams.add(TrezorGetAddressParams(path: derivationPath));
    }
    final accounts = await connect.ethereumGetAddressBundle(requestParams);

    return accounts
            ?.map((account) => HardwareAccountData(
                  address: account.address,
                  accountIndex: account.path[2] - 0x80000000, // unharden the path to get the index
                  derivationPath: account.serializedPath,
                ))
            .toList() ??
        [];
  }
}
