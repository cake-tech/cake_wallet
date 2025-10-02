import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/hardware/bitcoin_hardware_wallet_service.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:trezor_connect/trezor_connect.dart';

class BitcoinTrezorService extends HardwareWalletService with BitcoinHardwareWalletService {
  BitcoinTrezorService(this.connect);

  final TrezorConnect connect;

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final indexRange = List.generate(limit, (i) => i + index);
    final requestParams = <TrezorGetPublicKeyParams>[];

    for (final i in indexRange) {
      requestParams.add(TrezorGetPublicKeyParams(path: "m/84'/0'/$i'"));
    }

    final accounts = await connect.getPublicKeyBundle(requestParams);

    return accounts?.map((account) {
          final hd = Bip32Slip10Secp256k1.fromExtendedKey(account.xpub).childKey(Bip32KeyIndex(0));
          final address = generateP2WPKHAddress(hd: hd, index: 0, network: BitcoinNetwork.mainnet);
          return HardwareAccountData(
            address: address,
            xpub: account.xpub,
            accountIndex: account.path[2] - 0x80000000, // unharden the path to get the index
            derivationPath: account.serializedPath,
          );
        }).toList() ??
        [];
  }

  @override
  Future<Uint8List> signTransaction({required String transaction}) =>
      throw UnimplementedError(); // ToDo (Konsti)

  @override
  Future<Uint8List> signMessage({required Uint8List message, String? derivationPath}) async {
    final sig = await connect.signMessage(derivationPath ?? "m/84'/0'/0'/0/0",
        message: hex.encode(message), hex: true);
    return base64Decode(sig!.signature);
  }

  @override
  Future<Uint8List> getMasterFingerprint() => throw UnimplementedError(); // ToDo (Konsti)
}
