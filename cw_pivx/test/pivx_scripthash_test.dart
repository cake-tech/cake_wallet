import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_pivx/src/pivx_network.dart';
import 'package:cw_pivx/src/pivx_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

// Electrum scripthash: sha256(scriptPubKey), byte-reversed.
String _electrumScriptHash(List<int> script) =>
    BytesUtils.toHexString(QuickCrypto.sha256Hash(script).reversed.toList());

String _baseScriptHash(String address) => BitcoinAddressRecord(
      address,
      index: 0,
      type: P2pkhAddressType.p2pkh,
      network: PivxNetwork.mainnet,
    ).getScriptHash(PivxNetwork.mainnet);

void main() {
  final hd = Bip32Slip10Secp256k1.fromSeed(Uint8List(64));
  final dAddresses = [
    for (final i in [0, 1, 7, 42, 1000])
      generateP2PKHAddress(hd: hd, index: i, network: PivxNetwork.mainnet),
  ];

  test('base getScriptHash matches the P2PKH scripthash for D addresses', () {
    for (final address in [
      ...dAddresses,
      'DNmHG2VuQc54GRa3Hu4QgZ7RLGm1Ly9o3S'
    ]) {
      expect(address, startsWith('D'));
      final hash160 = Base58Decoder.checkDecode(address).sublist(1);
      final script = [0x76, 0xa9, 0x14, ...hash160, 0x88, 0xac];
      expect(_baseScriptHash(address), _electrumScriptHash(script),
          reason: address);
    }
  });

  test('matches the scripthash electrum02.chainster.org indexes', () {
    // get_history on this hash returned the mainnet deshield 06e3a5a8...
    expect(_baseScriptHash('DNmHG2VuQc54GRa3Hu4QgZ7RLGm1Ly9o3S'),
        '85e3b90ccaf7758ed96d355ad0db5c31163c772b6ae828e06f647a5cdb85b2f6');
  });

  group('verboseReceivedSats', () {
    const owned = 'DNmHG2VuQc54GRa3Hu4QgZ7RLGm1Ly9o3S';
    BitcoinAddressRecord record({required bool hidden}) => BitcoinAddressRecord(
          owned,
          index: 3,
          isHidden: hidden,
          type: P2pkhAddressType.p2pkh,
          network: PivxNetwork.mainnet,
        );
    // Trimmed verbose of mainnet deshield 06e3a5a8... at 5597595: no
    // transparent vin, one 0.5 PIVX P2PKH output.
    Map<String, dynamic> deshield({List<dynamic> vin = const []}) => {
          'txid':
              '06e3a5a829ca6526987ebb8fdbff1f6fdaef1a5ad7bacbe8eb0e1f2dd0258bd4',
          'vin': vin,
          'vout': [
            {
              'value': 0.5,
              'n': 0,
              'scriptPubKey': {
                'hex': '76a914c1520fc9bf0f779edc56b6fccd196ca96cf408db88ac',
                'type': 'pubkeyhash',
                'addresses': [owned],
              },
            },
          ],
        };

    test('counts a deshield landing on a change-branch address', () {
      expect(
          PivxWalletBase.verboseReceivedSats(
              deshield(), [record(hidden: true)]),
          50000000);
    });

    test('ignores change of an own t->z shield (transparent vin)', () {
      final shield = deshield(vin: [
        {'txid': 'aa' * 32, 'vout': 1}
      ]);
      expect(PivxWalletBase.verboseReceivedSats(shield, [record(hidden: true)]),
          0);
      expect(
          PivxWalletBase.verboseReceivedSats(shield, [record(hidden: false)]),
          50000000);
    });
  });


  // Restored own sends: fee = transparent in + valueBalance - transparent out.
  test('ownSendFromVerbose rebuilds z->t and t->z amount and fee', () {
    const own = 'DNmHG2VuQc54GRa3Hu4QgZ7RLGm1Ly9o3S';
    const external = 'DEEprWtZfUGBMah9FFLuxouapE6LtxcnEU';
    Map<String, dynamic> out(String address, double piv) => {
          'value': piv,
          'scriptPubKey': {
            'addresses': [address]
          },
        };
    final zToT = PivxWalletBase.ownSendFromVerbose(
        {'vout': [out(external, 0.5)], 'valueBalanceSat': 52400000},
        ownAddresses: {own}, spentNotes: 100000000, changeNotes: 47600000)!;
    expect([zToT.amount, zToT.fee, zToT.to], [50000000, 2400000, external]);
    final tToZ = PivxWalletBase.ownSendFromVerbose(
        {'vout': [out(own, 0.47)], 'valueBalanceSat': -50000000},
        ownAddresses: {own}, transparentIn: 100000000)!;
    expect([tToZ.amount, tToZ.fee], [50000000, 3000000]);
  });
}
