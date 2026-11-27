import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/raw_transaction.dart";
import "package:flutter_test/flutter_test.dart";

import "raw_tx_hex.dart";

/// The txid of a serialized transaction: the double SHA-256 of its bytes with
/// witnesses removed, shown in reverse byte order.
String _txidOfLegacy(String legacyHex) {
  final hash = QuickCrypto.sha256DoubleHash(BytesUtils.fromHexString(legacyHex));
  return BytesUtils.toHexString(hash.reversed.toList());
}

void main() {
  const sig = "11";
  final pubHex = "02${"ab" * 32}";
  final outScript = "0014${"33" * 20}";
  final nestedScriptSig = "16" "0014${"22" * 20}";
  final legacyScriptSig = "47${"11" * 71}21$pubHex";

  List<RawInput> nestedInputs() => [RawInput(txid: "aa" * 32, scriptSig: nestedScriptSig)];
  List<RawOutput> outputs() => [RawOutput(amount: 50000, scriptPubKey: outScript)];

  group("parseRawTransaction txid", () {
    test("a legacy transaction's txid is the double SHA-256 of its bytes", () {
      final legacy = rawTxHex(
        inputs: [RawInput(txid: "aa" * 32, scriptSig: legacyScriptSig)],
        outputs: outputs(),
      );

      expect(parseRawTransaction(legacy)?.txId, _txidOfLegacy(legacy));
    });

    test("a segwit transaction has the same txid as its witness-free form", () {
      final legacy = rawTxHex(inputs: nestedInputs(), outputs: outputs());
      final segwit = rawTxHex(
        inputs: nestedInputs(),
        outputs: outputs(),
        witnesses: [
          [sig, pubHex],
        ],
      );

      expect(segwit, isNot(legacy), reason: "the segwit form carries witness data");
      expect(parseRawTransaction(segwit)?.txId, _txidOfLegacy(legacy));
      expect(parseRawTransaction(segwit)?.txId, parseRawTransaction(legacy)?.txId);
    });

    test("a segwit transaction whose last input is legacy has the right txid", () {
      final legacy = rawTxHex(
        inputs: [
          RawInput(txid: "aa" * 32, scriptSig: nestedScriptSig),
          RawInput(txid: "bb" * 32, scriptSig: legacyScriptSig),
        ],
        outputs: outputs(),
      );
      final segwit = rawTxHex(
        inputs: [
          RawInput(txid: "aa" * 32, scriptSig: nestedScriptSig),
          RawInput(txid: "bb" * 32, scriptSig: legacyScriptSig),
        ],
        outputs: outputs(),
        witnesses: [
          [sig, pubHex],
          [],
        ],
      );

      expect(parseRawTransaction(segwit)?.txId, _txidOfLegacy(legacy));
    });

    test("the txid changes when any byte of the transaction changes", () {
      final original = rawTxHex(inputs: nestedInputs(), outputs: outputs());
      final altered = rawTxHex(
        inputs: nestedInputs(),
        outputs: [RawOutput(amount: 50001, scriptPubKey: outScript)],
      );

      expect(parseRawTransaction(altered)?.txId, isNot(parseRawTransaction(original)?.txId));
    });
  });

  group("parseRawTransaction witnesses", () {
    test("every input gets a witness stack, including nested-segwit inputs", () {
      final parsed = parseRawTransaction(
        rawTxHex(
          inputs: nestedInputs(),
          outputs: outputs(),
          witnesses: [
            [sig, pubHex],
          ],
        ),
      );

      expect(parsed, isNotNull);
      expect(parsed!.witnesses, hasLength(1));
      expect(parsed.witnesses.single, [
        BytesUtils.fromHexString(sig),
        BytesUtils.fromHexString(pubHex),
      ]);
    });

    test("a trailing legacy input contributes an empty witness stack", () {
      final parsed = parseRawTransaction(
        rawTxHex(
          inputs: [
            RawInput(txid: "aa" * 32, scriptSig: nestedScriptSig),
            RawInput(txid: "bb" * 32, scriptSig: legacyScriptSig),
          ],
          outputs: outputs(),
          witnesses: [
            [sig, pubHex],
            [],
          ],
        ),
      );

      expect(parsed, isNotNull);
      expect(parsed!.witnesses, hasLength(2));
      expect(parsed.witnesses.last, isEmpty);
    });
  });

  group("parseRawTransaction refuses what it can't read", () {
    test("an MWEB-flagged transaction returns null, so it is never cached", () {
      // Flag 0x09 is segwit plus MWEB. This parser only reads the plain segwit
      // flag, and it has no MWEB extension parsing, so it must not guess.
      final mweb = rawTxHex(
        inputs: nestedInputs(),
        outputs: outputs(),
        witnesses: [
          [sig, pubHex],
        ],
        mweb: "abcdef0123",
      );

      expect(parseRawTransaction(mweb), isNull);
    });

    test("a truncated transaction returns null", () {
      final full = rawTxHex(
        inputs: nestedInputs(),
        outputs: outputs(),
        witnesses: [
          [sig, pubHex],
        ],
      );

      expect(parseRawTransaction(full.substring(0, full.length - 8)), isNull);
    });

    test("a null or empty hex returns null", () {
      expect(parseRawTransaction(null), isNull);
      expect(parseRawTransaction(""), isNull);
    });
  });
}
