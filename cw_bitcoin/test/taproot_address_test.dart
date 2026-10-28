import 'dart:math';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("generateP2TRAddress matches ECPublic.toTaprootAddress", () {
    final random = Random.secure();
    for (var i = 0; i < 20; i++) {
      final hd = Bip32Slip10Secp256k1.fromSeed(List.generate(64, (_) => random.nextInt(256)));
      for (var index = 0; index < 10; index++) {
        for (final network in [BitcoinNetwork.mainnet, BitcoinNetwork.testnet]) {
          expect(
            generateP2TRAddress(hd: hd, network: network, index: index),
            ECPublic.fromBip32(hd.childKey(Bip32KeyIndex(index)).publicKey)
                .toTaprootAddress()
                .toAddress(network),
          );
        }
      }
    }
  });
}
