import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/base58/base58_ex.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/address_from_output.dart';
import 'package:cw_pivx/src/pivx_exchange_address.dart';
import 'package:cw_pivx/src/pivx_network.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // hash160 of DPo9TNvPwy2ZfmVM3CRCxbBvh6NojguWXJ under the exchange prefix;
  // cross-checked with an independent base58check.
  const exm = 'EXMVfkJoGAcaCDzSNqNVurYKgb3BFDEVAkGQ';
  const hash160 = 'cca48133ff2474bf4d9922e0cd8f72057fe47e5a';

  test('decodes, re-encodes and emits the OP_EXCHANGEADDR script', () {
    final address = PivxExchangeAddress.fromAddress(exm);
    expect(address.addressProgram, hash160);
    expect(address.toAddress(), exm);
    expect(BytesUtils.toHexString(address.toScriptPubKey().toBytes()),
        'e076a914${hash160}88ac');
    expect(PivxExchangeAddress.looksLike(exm), isTrue);
  });

  test('rejects a P2PKH address and a corrupted checksum', () {
    expect(PivxExchangeAddress.looksLike('DPo9TNvPwy2ZfmVM3CRCxbBvh6NojguWXJ'),
        isFalse);
    expect(
        () => PivxExchangeAddress.fromAddress(
            'DPo9TNvPwy2ZfmVM3CRCxbBvh6NojguWXJ'),
        throwsA(isA<Exception>()));
    expect(() => PivxExchangeAddress.fromAddress('${exm.substring(0, 35)}R'),
        throwsA(isA<Base58ChecksumError>()));
  });

  test('decodes both script shapes and labels history through the hook', () {
    final built = PivxExchangeAddress.fromAddress(exm).toScriptPubKey();
    // Script.fromRaw reads 0xe0 as a push length: one 25-byte data token.
    final parsed = Script.fromRaw(hexData: 'e076a914${hash160}88ac');
    expect(parsed.script.length, 1);
    expect(PivxExchangeAddress.fromScript(built)!.toAddress(), exm);
    expect(PivxExchangeAddress.fromScript(parsed)!.toAddress(), exm);
    expect(
        PivxExchangeAddress.fromScript(
            Script.fromRaw(hexData: '76a914${hash160}88ac')),
        isNull);

    // PivxNetwork decodes its own exchange scripts; no registration step.
    expect(addressFromOutputScript(parsed, PivxNetwork.mainnet), exm);
    expect(addressFromOutputScript(built, PivxNetwork.mainnet), exm);
    // Other networks never see it.
    expect(addressFromOutputScript(parsed, BitcoinNetwork.mainnet), '');
  });
}
