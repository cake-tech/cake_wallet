import 'dart:convert';
import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:coldcard_protocol/client.dart';
import 'package:cw_bitcoin/hardware/bitcoin_hardware_wallet_service.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';

class ColdcardService extends HardwareWalletService with BitcoinHardwareWalletService {
  ColdcardService(this.device);

  final ColdCardDevice device;

  @override
  Future<Uint8List> getMasterFingerprint() async {
    return Uint8List(4)..buffer.asByteData().setUint32(0, device.masterFingerprint!);
  }

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final accounts = <HardwareAccountData>[];
    final indexRange = List.generate(limit, (i) => i + index);

    for (final i in indexRange) {
      final derivationPath = "m/84'/0'/$i'";
      final xPub = await device.getXpub(derivationPath);
      final hd = Bip32Slip10Secp256k1.fromExtendedKey(xPub).childKey(Bip32KeyIndex(0));
      final address = generateP2WPKHAddress(hd: hd, index: 0, network: BitcoinNetwork.mainnet);

      accounts.add(HardwareAccountData(
        address: address,
        accountIndex: i,
        derivationPath: derivationPath,
        xpub: xPub,
      ));
    }

    return accounts;
  }

  @override
  Future<Uint8List> signTransaction({required String transaction}) async =>
      device.signTransaction(base64Decode(transaction));

  @override
  Future<Uint8List> signMessage({required Uint8List message, String? derivationPath}) async {
    final result = await device.signMessage(message, subpath: derivationPath ?? 'm');
    return result.$2;
  }
}
