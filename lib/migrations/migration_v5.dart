import 'dart:io';

import 'package:cake_wallet/di.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';

class MigrationV5 {
  static Future<void> run() async {
    final walletInfoSource = getIt.get<Box<WalletInfo>>();
    await addAddressesForMoneroWallets(walletInfoSource);
  }

  static Future<void> addAddressesForMoneroWallets(
      Box<WalletInfo> walletInfoSource) async {
    final moneroWalletsInfo =
        walletInfoSource.values.where((info) => info.type == WalletType.monero);
    moneroWalletsInfo.forEach((info) async {
      try {
        final walletPath =
            await pathForWallet(name: info.name, type: WalletType.monero);
        final addressFilePath = '$walletPath.address.txt';
        final addressFile = File(addressFilePath);

        if (!addressFile.existsSync()) {
          return;
        }

        final addressText = await addressFile.readAsString();
        info.address = addressText;
        await info.save();
      } catch (e) {
        print(e.toString());
      }
    });
  }
}
