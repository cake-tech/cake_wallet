import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_pivx/src/pivx_network.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the transparent send build path (cw_bitcoin/electrum_wallet.dart calls
/// RegexUtils.addressTypeFromStr). PIVX D... addresses are base58, not bech32;
/// before the bitcoin_base fork fix, this threw "Invalid bech32 format (string
/// is mixed case)" and blocked every t->t send.
void main() {
  test('classifies a PIVX D... address as P2PKH without bech32-decoding it', () {
    final hd = Bip32Slip10Secp256k1.fromSeed(Uint8List(64))
        .childKey(Bip32KeyIndex(0));
    final address = generateP2PKHAddress(
      hd: hd,
      index: 0,
      network: PivxNetwork.mainnet,
    );

    final classified =
        RegexUtils.addressTypeFromStr(address, PivxNetwork.mainnet);
    expect(classified, isA<P2pkhAddress>());
  });
}
