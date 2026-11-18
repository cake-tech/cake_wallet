import "dart:typed_data";

import "package:bitcoin_base/bitcoin_base.dart";
import "package:cw_bitcoin/payjoin/payjoin_receive_worker.dart";
import "package:flutter_test/flutter_test.dart";
import "package:payjoin/payjoin.dart" as pj;

final ECPublic _pub = ECPrivate.fromBytes(List<int>.generate(32, (i) => i + 1)).getPublic();

UtxoWithAddress _utxo(BitcoinAddressType type, BitcoinBaseAddress address, int vout) =>
    UtxoWithAddress(
      utxo: BitcoinUtxo(
        txHash: "aa" * 32,
        value: BigInt.from(100000),
        vout: vout,
        scriptType: type,
      ),
      ownerDetails: UtxoAddressDetails(publicKey: _pub.toHex(), address: address),
    );

void main() {
  final p2wpkh = _utxo(SegwitAddresType.p2wpkh, _pub.toP2wpkhAddress(), 0);
  final nested = _utxo(P2shAddressType.p2wpkhInP2sh, _pub.toP2wpkhInP2sh(), 1);
  final p2tr = _utxo(SegwitAddresType.p2tr, _pub.toTaprootAddress(), 2);
  final p2pkh = _utxo(P2pkhAddressType.p2pkh, _pub.toP2pkhAddress(), 3);
  final p2wsh = _utxo(SegwitAddresType.p2wsh, _pub.toP2wshAddress(), 4);

  test("contributes P2WPKH inputs", () {
    expect(PayjoinReceiverWorker.buildInputPairs([p2wpkh]), hasLength(1));
  });

  test("contributes nested P2WPKH inputs with their redeem script", () {
    expect(PayjoinReceiverWorker.buildInputPairs([nested]), hasLength(1));
  });

  test("contributes P2TR key-spend inputs with an explicit weight", () {
    expect(PayjoinReceiverWorker.buildInputPairs([p2tr]), hasLength(1));
  });

  test("rust-payjoin rejects an unsigned P2TR input without a weight", () {
    expect(
      () => pj.InputPair(
        txin: pj.TxIn(
          previousOutput: pj.OutPoint(txid: "aa" * 32, vout: 2),
          scriptSig: Uint8List(0),
          sequence: 0,
          witness: [],
        ),
        psbtin: pj.PsbtInput(
          witnessUtxo: pj.TxOut(
            valueSat: 100000,
            scriptPubkey: Uint8List.fromList(_pub.toTaprootAddress().toScriptPubKey().toBytes()),
          ),
          redeemScript: null,
          witnessScript: null,
        ),
        expectedWeight: null,
      ),
      throwsA(anything),
    );
  });

  test("skips unsupported inputs without dropping the supported ones", () {
    expect(
      PayjoinReceiverWorker.buildInputPairs([p2pkh, p2wsh, p2wpkh, p2tr, nested]),
      hasLength(3),
    );
  });
}
