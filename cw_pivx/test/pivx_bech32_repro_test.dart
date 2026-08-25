import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_pivx/src/pivx_network.dart';
import 'package:flutter_test/flutter_test.dart';

/// PIVX transparent addresses (base58, 'D' prefix, pubkey version byte 30) are
/// byte-identical to Dogecoin and have NO segwit form. Parsing one against a
/// segwit-capable network sends it down the segwit branch, which bech32-decodes
/// it and throws "Invalid bech32 format (string is mixed case)" — the error a
/// tester hit on a t->t send. Every PIVX address parse must use PivxNetwork.
void main() {
  final hd =
      Bip32Slip10Secp256k1.fromSeed(Uint8List(64)).childKey(Bip32KeyIndex(0));
  final pivxAddr =
      generateP2PKHAddress(hd: hd, index: 0, network: PivxNetwork.mainnet);

  test('PivxNetwork classifies a D... address as P2PKH (no bech32 decode)', () {
    expect(RegexUtils.addressTypeFromStr(pivxAddr, PivxNetwork.mainnet),
        isA<P2pkhAddress>());
  });

  test('a segwit-capable network wrongly bech32-decodes the same address', () {
    // Documents the failure mode: this is why PIVX must never be parsed with a
    // segwit network (e.g. BitcoinNetwork) — the app must keep it legacy-only.
    expect(
      () => RegexUtils.addressTypeFromStr(pivxAddr, BitcoinNetwork.mainnet),
      throwsA(predicate((e) => e.toString().contains('bech32'))),
    );
  });
}
