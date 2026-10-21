import "package:blockchain_utils/base58/base58.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/alt_lookup.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_program_ids.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_request_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
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
    final decoded = await decoder.decodeTransaction(transferParams(), walletAddress: payer);
    expect(decoded.actionTitle, contains("1 SOL"));
    expect(decoded.rows.any((r) => r.value == dest), isTrue);
    expect(decoded.rawFallback, isNotNull);

    final feeRow = decoded.rows.last;
    expect(feeRow.label, S.current.wc_network_fee);
    expect(feeRow.value, "~ 0.000005 SOL");
  });

  test("ComputeBudget instructions add the priority fee", () async {
    final decoded = await decoder.decodeTransaction(
      transferParams(withPriorityFee: true),
      walletAddress: payer,
    );
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
    final decoded = await decoder.decodeTransaction(
      {"transaction": tx.serializeString(encoding: TransactionSerializeEncoding.base64)},
      walletAddress: payer,
    );

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
    final decoded = await decoder.decodeTransaction(
      {"transaction": "not-base64"},
      walletAddress: payer,
    );
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

    final decoded = await decoder.decodeAllTransactions(
      {
        "transactions": [encoded, encoded],
      },
      walletAddress: payer,
    );
    expect(decoded.actionTitle, S.current.wc_action_sign_all_transactions);
    expect(decoded.actionSubtitle, S.current.wc_transactions_count("2"));
    expect(decoded.rows.any((r) => r.label == S.current.wc_transaction_n("1")), isTrue);
    expect(decoded.rows.any((r) => r.label == S.current.wc_transaction_n("2")), isTrue);
  });

  test("empty transactions list falls back with a warning", () async {
    final decoded = await decoder.decodeAllTransactions(
      <String, dynamic>{},
      walletAddress: payer,
    );
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
      final decoded = await decoder.decodeTransaction(
        {"transaction": encoded},
        walletAddress: payer,
      );
      expect(decoded.warnings, contains(S.current.wc_warning_unresolved_accounts));
    });
  });

  group("swap with instructions outside it", () {
    const signer = "4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t";
    const usdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v";
    const usdtMint = "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB";
    const tokenProgram = SolanaProgramIds.tokenProgram;
    const poolUsdc = "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM";
    const poolUsdt = "5Q544fKrFoe6tsEbD7S8EmxGTJYAKtTVhAW5Q5pge4j1";
    const poolAuthority = "GThUX1Atko4tqhN2NaiTazWSeFWMuiUvfFnyJyUghFMJ";
    const stranger = "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU";

    String ataFor(String owner, String mint) =>
        AssociatedTokenAccountProgramUtils.associatedTokenAccount(
          mint: SolAddress(mint),
          owner: SolAddress(owner),
        ).address.address;

    AccountMeta meta(String address, {bool signer = false, bool writable = false}) =>
        AccountMeta(publicKey: SolAddress(address), isSigner: signer, isWritable: writable);

    TransactionInstruction transferChecked(
      String source,
      String mint,
      String destination,
      String owner,
      int amount,
    ) =>
        TransactionInstruction.fromBytes(
          programId: SolAddress(tokenProgram),
          instructionBytes: [12, ...u64Le(BigInt.from(amount)), 6],
          keys: [
            meta(source, writable: true),
            meta(mint),
            meta(destination, writable: true),
            meta(owner, signer: owner == signer),
          ],
        );

    TransactionInstruction solTransfer(String destination, BigInt lamports) =>
        TransactionInstruction.fromBytes(
          programId: SolAddress(systemProgram),
          instructionBytes: [...u32Le(2), ...u64Le(lamports)],
          keys: [meta(signer, signer: true, writable: true), meta(destination, writable: true)],
        );

    Future<WCDecodedRequest> decodeSwapWith(List<TransactionInstruction> extra) {
      final tx = SolanaTransaction(
        payerKey: SolAddress(signer),
        recentBlockhash: SolAddress(blockhash),
        instructions: [
          transferChecked(ataFor(signer, usdcMint), usdcMint, poolUsdc, signer, 2000000),
          transferChecked(poolUsdt, usdtMint, ataFor(signer, usdtMint), poolAuthority, 1900000),
          ...extra,
        ],
      );
      return decoder.decodeTransaction(
        {"transaction": tx.serializeString(encoding: TransactionSerializeEncoding.base64)},
        walletAddress: signer,
      );
    }

    TransactionInstruction unlimitedApprove(String delegate) => TransactionInstruction.fromBytes(
          programId: SolAddress(tokenProgram),
          instructionBytes: [4, ...u64Le((BigInt.one << 64) - BigInt.one)],
          keys: [
            meta(ataFor(signer, usdcMint), writable: true),
            meta(delegate),
            meta(signer, signer: true),
          ],
        );

    test("a plain swap keeps its legs off the main card and does not warn", () async {
      final decoded = await decodeSwapWith(const []);
      expect(decoded.actionTitle, S.current.wc_action_swap);
      expect(decoded.warnings, isNot(contains(S.current.wc_warning_swap_extra_transfers)));
      expect(decoded.rows.any((r) => r.label == S.current.wc_instruction_n("1")), isFalse);
    });

    test("each warning shows once even when the swap and its legs raise the same one", () async {
      final decoded = await decodeSwapWith(const []);
      expect(decoded.warnings.toSet().length, decoded.warnings.length);
      expect(decoded.warnings, contains(S.current.wc_warning_unknown_token));
    });

    test("SOL sent to a third party shows on the main card with a warning", () async {
      final decoded = await decodeSwapWith([solTransfer(stranger, BigInt.from(5000000000))]);
      expect(decoded.actionTitle, S.current.wc_action_swap);
      expect(decoded.rows.any((r) => r.value == stranger), isTrue);
      expect(decoded.rows.any((r) => r.value == "5 SOL"), isTrue);
      expect(decoded.warnings, contains(S.current.wc_warning_swap_extra_transfers));
    });

    test("wrapping SOL into the signer's own account is not flagged", () async {
      final wrap = solTransfer(ataFor(signer, SolanaProgramIds.wrappedSolMint), BigInt.from(1000));
      final decoded = await decodeSwapWith([wrap]);
      expect(decoded.warnings, isNot(contains(S.current.wc_warning_swap_extra_transfers)));
    });

    test("an unlimited token approval shows on the main card with both warnings", () async {
      final decoded = await decodeSwapWith([unlimitedApprove(stranger)]);
      final spenderRow = decoded.rows.firstWhere((r) => r.label == S.current.wc_spender);
      expect(spenderRow.value, stranger);
      expect(decoded.warnings, contains(S.current.wc_warning_swap_extra_transfers));
      expect(decoded.warnings, contains(S.current.wc_warning_unlimited_approval));
    });

    TransactionInstruction closeAccount(String account, String destination) =>
        TransactionInstruction.fromBytes(
          programId: SolAddress(tokenProgram),
          instructionBytes: const [9],
          keys: [
            meta(account, writable: true),
            meta(destination, writable: true),
            meta(signer, signer: true),
          ],
        );

    test("unwrapping SOL to someone else surfaces the close and the SOL it carries", () async {
      final wsolAta = ataFor(signer, SolanaProgramIds.wrappedSolMint);
      final decoded = await decodeSwapWith([
        solTransfer(wsolAta, BigInt.from(10000000000)),
        closeAccount(wsolAta, stranger),
      ]);
      expect(decoded.rows.any((r) => r.label == S.current.to && r.value == stranger), isTrue);
      expect(decoded.rows.any((r) => r.value == "10 SOL"), isTrue);
      expect(decoded.warnings, contains(S.current.wc_warning_swap_extra_transfers));
    });

    test("handing the wrapped SOL account to someone else surfaces the SOL put into it", () async {
      final wsolAta = ataFor(signer, SolanaProgramIds.wrappedSolMint);
      final handOver = TransactionInstruction.fromBytes(
        programId: SolAddress(tokenProgram),
        instructionBytes: [6, 2, 1, ...SolAddress(stranger).toBytes()],
        keys: [meta(wsolAta, writable: true), meta(signer, signer: true)],
      );
      final decoded = await decodeSwapWith([
        solTransfer(wsolAta, BigInt.from(10000000000)),
        handOver,
      ]);
      expect(decoded.rows.any((r) => r.value == "10 SOL"), isTrue);
      expect(decoded.warnings, contains(S.current.wc_warning_swap_extra_transfers));
    });

    test("wrapping and unwrapping back to the signer stays a plain swap", () async {
      final wsolAta = ataFor(signer, SolanaProgramIds.wrappedSolMint);
      final decoded = await decodeSwapWith([
        solTransfer(wsolAta, BigInt.from(1000)),
        closeAccount(wsolAta, signer),
      ]);
      expect(decoded.warnings, isNot(contains(S.current.wc_warning_swap_extra_transfers)));
    });

    test("funding a new account shows the amount on the main card", () async {
      final decoded = await decodeSwapWith([
        TransactionInstruction.fromBytes(
          programId: SolAddress(systemProgram),
          instructionBytes: [
            ...u32Le(0),
            ...u64Le(BigInt.from(10000000000)),
            ...u64Le(BigInt.zero),
            ...SolAddress(stranger).toBytes(),
          ],
          keys: [
            meta(signer, signer: true, writable: true),
            meta(stranger, signer: true, writable: true),
          ],
        ),
      ]);
      expect(decoded.rows.any((r) => r.value == "10 SOL"), isTrue);
      expect(decoded.warnings, contains(S.current.wc_warning_swap_extra_transfers));
    });

    test("an instruction we cannot read is lifted rather than hidden", () async {
      final setAuthority = TransactionInstruction.fromBytes(
        programId: SolAddress(tokenProgram),
        instructionBytes: [6, 2, 1, ...SolAddress(stranger).toBytes()],
        keys: [meta(ataFor(signer, usdcMint), writable: true), meta(signer, signer: true)],
      );
      final decoded = await decodeSwapWith([setAuthority]);
      expect(decoded.rows.any((r) => r.label == S.current.wc_instruction_n("3")), isTrue);
      expect(decoded.warnings, contains(S.current.wc_warning_swap_extra_transfers));
    });

    test("a second debit of the pay token is not read as a swap", () async {
      final skim = transferChecked(ataFor(signer, usdcMint), usdcMint, stranger, signer, 500000);
      final decoded = await decodeSwapWith([skim]);
      expect(decoded.actionTitle, isNot(S.current.wc_action_swap));
      expect(decoded.rows.any((r) => r.label == S.current.to && r.value == stranger), isTrue);
    });

    test("a fee payer's own accounts are not treated as the wallet's", () async {
      final tx = SolanaTransaction(
        payerKey: SolAddress(stranger),
        recentBlockhash: SolAddress(blockhash),
        instructions: [
          transferChecked(ataFor(stranger, usdcMint), usdcMint, poolUsdc, stranger, 2000000),
          transferChecked(poolUsdt, usdtMint, ataFor(stranger, usdtMint), poolAuthority, 1900000),
          solTransfer(stranger, BigInt.from(10000000000)),
        ],
      );
      final decoded = await decoder.decodeTransaction(
        {"transaction": tx.serializeString(encoding: TransactionSerializeEncoding.base64)},
        walletAddress: signer,
      );
      expect(decoded.actionTitle, isNot(S.current.wc_action_swap));
      expect(decoded.rows.any((r) => r.value == "10 SOL"), isTrue);
    });
  });
}
