import "package:blockchain_utils/base58/base58.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/alt_lookup.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_request_decoder.dart";
import "package:flutter_test/flutter_test.dart";
import "package:on_chain/solana/solana.dart";

import "abi_hex.dart";
import "stubs.dart";

void main() {
  setUpAll(() {
    S.current = const S();
  });

  final decoder = SolanaRequestDecoder(null);
  const payer = "So11111111111111111111111111111111111111112";
  const dest = "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr";
  const blockhash = "JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4";
  const systemProgram = "11111111111111111111111111111111";
  const computeBudget = "ComputeBudget111111111111111111111111111111";

  Map<String, dynamic> key(String pubkey, {bool signer = false, bool writable = false}) =>
      {"pubkey": pubkey, "isSigner": signer, "isWritable": writable};

  Map<String, dynamic> transferParams({bool withPriorityFee = false}) => {
        "feePayer": payer,
        "recentBlockhash": blockhash,
        "instructions": [
          {
            "programId": systemProgram,
            "data": [...u32Le(2), ...u64Le(BigInt.from(1000000000))],
            "keys": [key(payer, signer: true, writable: true), key(dest, writable: true)],
          },
          if (withPriorityFee) ...[
            {
              "programId": computeBudget,
              "data": [2, ...u32Le(200000)],
              "keys": <Map<String, dynamic>>[],
            },
            {
              "programId": computeBudget,
              "data": [3, ...u64Le(BigInt.from(1000))],
              "keys": <Map<String, dynamic>>[],
            },
          ],
        ],
      };

  test("system transfer decodes with title, rows and base fee", () async {
    final decoded = await decoder.decodeTransaction(transferParams());
    expect(decoded.actionTitle, contains("1 SOL"));
    expect(decoded.rows.any((r) => r.value == dest), isTrue);
    expect(decoded.rawFallback, isNotNull);

    final feeRow = decoded.rows.last;
    expect(feeRow.label, S.current.wc_network_fee);
    expect(feeRow.value, "~ 0.000005 SOL");
  });

  test("ComputeBudget instructions add the priority fee", () async {
    final decoded = await decoder.decodeTransaction(transferParams(withPriorityFee: true));
    final feeRow = decoded.rows.last;
    expect(feeRow.value, "~ 0.0000052 SOL");
  });

  test("a recognised router with no readable amounts says so plainly", () async {
    final tx = SolanaTransaction(
      payerKey: SolAddress(payer),
      recentBlockhash: SolAddress(blockhash),
      instructions: [
        TransactionInstruction.fromBytes(
          programId: SolAddress("CAMMCzo5YL8w4VFF8KVHrK22GGUsp5VTaW7grrKgrWqK"),
          instructionBytes: const [9, 9, 9, 9],
          keys: [
            AccountMeta(publicKey: SolAddress(payer), isSigner: true, isWritable: true),
          ],
        ),
      ],
    );
    final decoded = await decoder.decodeTransaction({
      "transaction": tx.serializeString(encoding: TransactionSerializeEncoding.base64),
    });

    expect(decoded.actionSubtitle, S.current.wc_via("Raydium"));
    expect(decoded.warnings, contains(S.current.wc_warning_swap_amounts_unavailable));
    expect(
      decoded.warnings,
      isNot(contains(S.current.wc_warning_swap_amounts_estimated)),
      reason: "nothing is estimated when nothing is shown",
    );
    expect(decoded.rawFallback, isNotNull);
  });

  test("undeserializable params fall back to the raw view", () async {
    final decoded = await decoder.decodeTransaction({"transaction": "not-base64"});
    expect(decoded.warnings, contains(S.current.wc_warning_decode_failed));
    expect(decoded.rawFallback, isNotNull);
  });

  test("decodeSignMessage renders the utf8 content", () async {
    final message = Base58Encoder.encode("hello world".codeUnits);
    final decoded = await decoder.decodeSignMessage(message);
    expect(decoded.rows.single.value, "hello world");
  });

  test("decodeAllTransactions labels every transaction and keeps the count", () async {
    final tx = SolanaTransaction(
      payerKey: SolAddress(payer),
      recentBlockhash: SolAddress(blockhash),
      instructions: [
        TransactionInstruction.fromBytes(
          programId: SolAddress(systemProgram),
          instructionBytes: [...u32Le(2), ...u64Le(BigInt.from(500000000))],
          keys: [
            AccountMeta(publicKey: SolAddress(payer), isSigner: true, isWritable: true),
            AccountMeta(publicKey: SolAddress(dest), isSigner: false, isWritable: true),
          ],
        ),
      ],
    );
    final encoded = tx.serializeString(encoding: TransactionSerializeEncoding.base64);

    final decoded = await decoder.decodeAllTransactions({
      "transactions": [encoded, encoded],
    });
    expect(decoded.actionTitle, S.current.wc_action_sign_all_transactions);
    expect(decoded.actionSubtitle, S.current.wc_transactions_count("2"));
    expect(decoded.rows.any((r) => r.label == S.current.wc_transaction_n("1")), isTrue);
    expect(decoded.rows.any((r) => r.label == S.current.wc_transaction_n("2")), isTrue);
  });

  test("empty transactions list falls back with a warning", () async {
    final decoded = await decoder.decodeAllTransactions(<String, dynamic>{});
    expect(decoded.warnings, contains(S.current.wc_warning_decode_failed));
  });

  group("AltLookup", () {
    const loadedA = "LBUZKhRxPF3XUpBCjp4YzTKgLccjZhTSDM9YuVaPwxo";
    const loadedB = "PhoeNiXZ8ByJGLkxNfZRnkUfjvmuYqLR89jjFHGqdXY";
    const tableKey = "CAMMCzo5YL8w4VFF8KVHrK22GGUsp5VTaW7grrKgrWqK";

    AddressLookupTableAccount table() => AddressLookupTableAccount(
          key: SolAddress(tableKey),
          deactivationSlot: BigInt.parse("ffffffffffffffff", radix: 16),
          lastExtendedSlot: BigInt.zero,
          lastExtendedStartIndex: 0,
          authority: null,
          addresses: [SolAddress(loadedA), SolAddress(loadedB)],
        );

    SolanaTransaction v0Tx() => SolanaTransaction(
          payerKey: SolAddress(payer),
          recentBlockhash: SolAddress(blockhash),
          addressLookupTableAccounts: [table()],
          instructions: [
            TransactionInstruction.fromBytes(
              programId: SolAddress(systemProgram),
              instructionBytes: u32Le(0),
              keys: [
                AccountMeta(publicKey: SolAddress(loadedA), isSigner: false, isWritable: true),
                AccountMeta(publicKey: SolAddress(loadedB), isSigner: false, isWritable: false),
              ],
            ),
          ],
        );

    test("combinedKeys appends looked-up writables before readonlies", () {
      final message = v0Tx().message as MessageV0;
      expect(message.addressTableLookups, isNotEmpty);

      final combined = AltLookup.combinedKeys(message, [table()]);
      expect(combined, isNotNull);
      expect(combined!.first, payer);
      expect(combined.sublist(combined.length - 2), [loadedA, loadedB]);
    });

    test("resolveAccountKeys appends the looked-up addresses", () async {
      final tx = v0Tx();
      final message = tx.message as MessageV0;
      final tableKey = message.addressTableLookups.first.accountKey.address;

      // A lookup table account is a fixed meta header followed by packed keys.
      final data = <int>[
        ...List.filled(56, 0),
        ...SolAddress(loadedA).toBytes(),
        ...SolAddress(loadedB).toBytes(),
      ];
      data[0] = 1; // typeIndex: an initialised lookup table
      for (var i = 4; i < 12; i++) {
        data[i] = 0xff; // deactivationSlot = u64 max, i.e. still active
      }

      final fetcher = StubAccountFetcher({tableKey: data});
      final resolved = await AltLookup(fetcher).resolveAccountKeys(tx);

      expect(fetcher.fetchCalls, 1);
      expect(resolved.length, greaterThan(message.accountKeys.length));
      expect(resolved, contains(loadedA));
      expect(resolved, contains(loadedB));
      expect(resolved.first, payer);
    });

    test("resolveAccountKeys returns static keys when the table is unreadable", () async {
      final tx = v0Tx();
      final fetcher = StubAccountFetcher(const {});
      final resolved = await AltLookup(fetcher).resolveAccountKeys(tx);
      expect(resolved.length, (tx.message as MessageV0).accountKeys.length);
    });

    test("resolveAccountKeys leaves a legacy transaction untouched", () async {
      final tx = SolanaTransaction(
        payerKey: SolAddress(payer),
        recentBlockhash: SolAddress(blockhash),
        instructions: [
          TransactionInstruction.fromBytes(
            programId: SolAddress(systemProgram),
            instructionBytes: u32Le(0),
            keys: [
              AccountMeta(publicKey: SolAddress(dest), isSigner: false, isWritable: true),
            ],
          ),
        ],
      );
      final fetcher = StubAccountFetcher(const {});
      final resolved = await AltLookup(fetcher).resolveAccountKeys(tx);
      expect(fetcher.fetchCalls, 0, reason: "no lookups means no RPC call");
      expect(resolved, contains(payer));
    });

    test("decode falls back to static keys when tables cannot be fetched", () async {
      final encoded = v0Tx().serializeString(encoding: TransactionSerializeEncoding.base64);
      final decoded = await decoder.decodeTransaction({"transaction": encoded});
      expect(decoded.warnings, contains(S.current.wc_warning_unresolved_accounts));
    });
  });
}
