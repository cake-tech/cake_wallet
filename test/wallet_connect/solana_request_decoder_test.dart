import "dart:async";
import "dart:convert";

import "package:blockchain_utils/blockchain_utils.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/alt_lookup.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_account_fetcher.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_lookup_budget.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_program_ids.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_request_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/spl_token.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:flutter_test/flutter_test.dart";
import "package:on_chain/solana/solana.dart";

import "abi_hex.dart";
import "stubs.dart";

void main() {
  setUpAll(() {
    S.current = const S();
  });

  final decoder = SolanaRequestDecoder(null);
  const payer = "96FHuHDcv9FL55qhoBoUGAmxZg9XM47fBM3t2vdefGW2";
  const dest = "23XoPQqGw9WMsLoqTu8HMzJLD6RnXsufbKyWPLJywsCT";
  const blockhash = "GHtXQBsoZHVnNFa9YevAzFr17DJjgHXk3ycTKD5xD3Zi";
  const systemProgram = "11111111111111111111111111111111";
  const computeBudget = "ComputeBudget111111111111111111111111111111";
  const tokenProgram = SolanaProgramIds.tokenProgram;
  const wsolMint = SolanaProgramIds.wrappedSolMint;
  const jupiter = SolanaProgramIds.jupiterV6;
  const raydium = SolanaProgramIds.raydiumClmm;

  const wallet = "4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t";
  const attacker = "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU";
  const usdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v";
  const usdtMint = "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB";
  const attackerMint = "6nMF76wKdFZaE78eRRDcNikVw1jMKMC4zoj7ibq1N25f";
  const attackerUsdcAccount = "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM";
  const attackerMintAccount = "5Q544fKrFoe6tsEbD7S8EmxGTJYAKtTVhAW5Q5pge4j1";
  const unknownProgram = "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1";
  const nonceAccount = "GThUX1Atko4tqhN2NaiTazWSeFWMuiUvfFnyJyUghFMJ";
  const recentBlockhashesSysvar = "SysvarRecentB1ockHashes11111111111111111111";
  const lookupTable = "AsotAq6Hb5KW6bAExHq2hJctDNuErLEjaVSaR4yJ5WEj";
  const jupiterEventAuthority = "D8cy77BBepLMngZx6ZukaTff5hCt1HrWyKk3Hnd9oitf";

  Map<String, dynamic> key(String pubkey, {bool signer = false, bool writable = false}) => {
    "pubkey": pubkey,
    "isSigner": signer,
    "isWritable": writable,
  };

  String programRow(int instruction, String program) =>
      "${S.current.wc_instruction_n("$instruction")}: ${S.current.wc_program}: $program";

  String jupiterRow(int instruction) => programRow(instruction, "Jupiter ($jupiter)");

  AccountMeta meta(String address, {bool signer = false, bool writable = false}) =>
      AccountMeta(publicKey: SolAddress(address), isSigner: signer, isWritable: writable);

  TransactionInstruction instruction(String programId, List<int> data, List<AccountMeta> keys) =>
      TransactionInstruction.fromBytes(
        programId: SolAddress(programId),
        instructionBytes: data,
        keys: keys,
      );

  TransactionInstruction solTransfer(String destination, int lamports, {String from = wallet}) =>
      instruction(
        systemProgram,
        [...u32Le(2), ...u64Le(BigInt.from(lamports))],
        [meta(from, signer: true, writable: true), meta(destination, writable: true)],
      );

  TransactionInstruction transferChecked(
    String source,
    String mint,
    String destination,
    String owner,
    int amount, {
    int decimals = 6,
  }) => instruction(
    tokenProgram,
    [12, ...u64Le(BigInt.from(amount)), decimals],
    [
      meta(source, writable: true),
      meta(mint),
      meta(destination, writable: true),
      meta(owner, signer: true),
    ],
  );

  TransactionInstruction setAuthority(String account, String newAuthority) => instruction(
    tokenProgram,
    [6, 2, 1, ...SolAddress(newAuthority).toBytes()],
    [meta(account, writable: true), meta(wallet, signer: true)],
  );

  TransactionInstruction closeAccount(String account, String destination) => instruction(
    tokenProgram,
    const [9],
    [meta(account, writable: true), meta(destination, writable: true), meta(wallet, signer: true)],
  );

  TransactionInstruction computeUnitPrice(int microLamports) =>
      instruction(computeBudget, [3, ...u64Le(BigInt.from(microLamports))], const []);

  TransactionInstruction computeUnitLimit(int units) =>
      instruction(computeBudget, [2, ...u32Le(units)], const []);

  String encoded(
    List<TransactionInstruction> instructions, {
    List<AddressLookupTableAccount> lookupTables = const [],
  }) => SolanaTransaction(
    payerKey: SolAddress(wallet),
    recentBlockhash: SolAddress(blockhash),
    instructions: instructions,
    addressLookupTableAccounts: lookupTables,
  ).serializeString(encoding: TransactionSerializeEncoding.base64);

  Future<WCDecodedRequest> decode(
    List<TransactionInstruction> instructions, {
    List<AddressLookupTableAccount> lookupTables = const [],
  }) => decoder.decodeTransaction({
    "transaction": encoded(instructions, lookupTables: lookupTables),
  }, walletAddress: wallet);

  final realSolana = solana;
  tearDown(() => solana = realSolana);

  String account(int seed) => SolAddress.uncheckBytes(List.filled(32, seed)).address;
  String sourceOfTransfer(int transfer) => account(10 + transfer);
  String mintOfTransfer(int transfer) => account(20 + transfer);

  TransactionInstruction tokenTransfer(int transfer) => instruction(
    tokenProgram,
    [3, ...u64Le(BigInt.from(1500000))],
    [
      meta(sourceOfTransfer(transfer), writable: true),
      meta(dest, writable: true),
      meta(wallet, signer: true),
    ],
  );

  FakeSolanaNode nodeAnsweringIn(Duration latency) {
    final node = FakeSolanaNode(
      latency: latency,
      accounts: {
        for (var transfer = 0; transfer < 8; transfer++)
          sourceOfTransfer(transfer): [
            ...SolAddress(mintOfTransfer(transfer)).toBytes(),
            ...List.filled(133, 0),
          ],
      },
    );
    solana = node;
    return node;
  }

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
    final title = "${S.current.wc_action_send} 1 SOL";
    expect(decoded.actionTitle, title);
    expect(rowLines(decoded.rows), [
      row(S.current.wc_instruction_n("1"), title),
      row(S.current.wc_amount, "1 SOL"),
      row(S.current.from, payer),
      row(S.current.to, dest),
      row(S.current.wc_network_fee, "~ 0.000005 SOL"),
    ]);
    expect(decoded.rawFallback, const JsonEncoder.withIndent("  ").convert(transferParams()));
  });

  test("ComputeBudget instructions add the priority fee", () async {
    final decoded = await decoder.decodeTransaction(
      transferParams(withPriorityFee: true),
      walletAddress: payer,
    );
    final feeRow = decoded.rows.last;
    expect(feeRow.value, "~ 0.0000052 SOL");
    expect(decoded.actionTitle, contains("1 SOL"), reason: "compute budget does not change it");
  });

  group("network fee", () {
    test("a price with no limit is charged on Agave's default limit", () async {
      final decoded = await decode([
        computeUnitPrice(1000000000000),
        solTransfer(attacker, 1000000),
      ]);
      expect(rowValue(decoded.rows, S.current.wc_network_fee), "~ 6.000005 SOL");
      expect(decoded.warnings, contains(S.current.wc_warning_high_network_fee));
    });

    test("an instruction for another program counts for 200,000 units", () async {
      final decoded = await decode([
        computeUnitPrice(1000000),
        instruction(unknownProgram, const [1], [meta(wallet, signer: true)]),
      ]);
      expect(rowValue(decoded.rows, S.current.wc_network_fee), "~ 0.000208 SOL");
      expect(decoded.warnings, isNot(contains(S.current.wc_warning_high_network_fee)));
    });

    test("the default limit stops at the transaction maximum", () async {
      final decoded = await decode([
        computeUnitPrice(1000000),
        for (var i = 0; i < 8; i++) instruction(unknownProgram, [i], [meta(wallet, signer: true)]),
      ]);
      expect(rowValue(decoded.rows, S.current.wc_network_fee), "~ 0.001405 SOL");
    });

    test("a limit above the transaction maximum is charged at the maximum", () async {
      final decoded = await decode([
        computeUnitLimit(4000000000),
        computeUnitPrice(1000000),
        solTransfer(attacker, 1000000),
      ]);
      expect(rowValue(decoded.rows, S.current.wc_network_fee), "~ 0.001405 SOL");
      expect(decoded.warnings, isNot(contains(S.current.wc_warning_high_network_fee)));
    });

    test("a price cut short of its value is not charged", () async {
      final decoded = await decode([
        instruction(computeBudget, const [3, 255, 255, 255], const []),
        solTransfer(attacker, 1000000),
      ]);
      expect(rowValue(decoded.rows, S.current.wc_network_fee), "~ 0.000005 SOL");
    });

    test(
      "signatures a precompile instruction declares are charged like the transaction's",
      () async {
        const verifiers = [
          "Ed25519SigVerify111111111111111111111111111",
          "KeccakSecp256k11111111111111111111111111111",
          "Secp256r1SigVerify1111111111111111111111111",
        ];
        for (final verifier in verifiers) {
          final decoded = await decode([
            instruction(verifier, const [3, 0], const []),
            solTransfer(attacker, 1000000),
          ]);
          expect(
            rowValue(decoded.rows, S.current.wc_network_fee),
            "~ 0.00002 SOL",
            reason: verifier,
          );
        }
      },
    );

    test("a precompile instruction with no data declares no signatures", () async {
      final decoded = await decode([
        instruction("Ed25519SigVerify111111111111111111111111111", const [], const []),
        solTransfer(attacker, 1000000),
      ]);
      expect(rowValue(decoded.rows, S.current.wc_network_fee), "~ 0.000005 SOL");
    });

    test("a fee just over 0.05 SOL warns and one at it does not", () async {
      final over = await decode([
        computeUnitLimit(1000000),
        computeUnitPrice(49996000),
        solTransfer(attacker, 1000000),
      ]);
      expect(rowValue(over.rows, S.current.wc_network_fee), "~ 0.050001 SOL");
      expect(over.warnings, contains(S.current.wc_warning_high_network_fee));

      final at = await decode([
        computeUnitLimit(1000000),
        computeUnitPrice(49995000),
        solTransfer(attacker, 1000000),
      ]);
      expect(rowValue(at.rows, S.current.wc_network_fee), "~ 0.05 SOL");
      expect(at.warnings, isNot(contains(S.current.wc_warning_high_network_fee)));
    });

    test("signAll judges each transaction's fee on its own, not the total", () async {
      String priced(int microLamports) => encoded([
        computeUnitLimit(1000000),
        computeUnitPrice(microLamports),
        solTransfer(attacker, 1000000),
      ]);

      final twoAtTheLine = await decoder.decodeAllTransactions({
        "transactions": [priced(49995000), priced(49995000)],
      }, walletAddress: wallet);
      expect(twoAtTheLine.warnings, isEmpty, reason: "0.05 SOL each, 0.1 SOL together");

      final oneOver = await decoder.decodeAllTransactions({
        "transactions": [priced(1000), priced(49996000)],
      }, walletAddress: wallet);
      expect(oneOver.warnings, [S.current.wc_warning_high_network_fee]);
    });
  });

  test("a known router is named next to its id and its instruction is not read", () async {
    final decoded = await decode([
      instruction(raydium, const [9, 9, 9, 9], [meta(wallet, signer: true, writable: true)]),
    ]);

    expect(decoded.actionTitle, S.current.wc_action_sign_transaction);
    expect(rowLines(decoded.rows), [
      programRow(1, "Raydium ($raydium)"),
      "${S.current.wc_network_fee}: ~ 0.000005 SOL",
    ]);
    expect(decoded.warnings, [S.current.wc_warning_unknown_instruction]);
  });

  test("undeserializable params fall back to the raw view", () async {
    const params = {"transaction": "not-base64"};
    final decoded = await decoder.decodeTransaction(params, walletAddress: payer);
    expect(decoded.actionTitle, S.current.wc_action_sign_transaction);
    expect(decoded.rows, isEmpty);
    expect(decoded.warnings, [S.current.wc_warning_decode_failed]);
    expect(decoded.rawFallback, const JsonEncoder.withIndent("  ").convert(params));
  });

  group("solana_signMessage", () {
    final refusedAsTransaction = throwsA(
      isA<FormatException>().having((e) => e.message, "message", contains("transaction message")),
    );
    final refusedAsNotText = throwsA(
      isA<FormatException>().having(
        (e) => e.message,
        "message",
        isNot(contains("transaction message")),
      ),
    );

    SolanaTransaction drain({List<AddressLookupTableAccount> lookupTables = const []}) =>
        SolanaTransaction(
          payerKey: SolAddress(wallet),
          recentBlockhash: SolAddress(blockhash),
          instructions: [solTransfer(attacker, 50000000000)],
          addressLookupTableAccounts: lookupTables,
        );

    List<int> asciiOnlyMessage() => SolanaTransaction(
      payerKey: SolAddress.uncheckBytes(List.filled(32, 0x41)),
      recentBlockhash: SolAddress.uncheckBytes(List.filled(32, 0x43)),
      instructions: [
        TransactionInstruction.fromBytes(
          programId: SolAddress(systemProgram),
          instructionBytes: [...u32Le(2), ...u64Le(BigInt.from(0x7f7f7f7f))],
          keys: [
            AccountMeta(
              publicKey: SolAddress.uncheckBytes(List.filled(32, 0x41)),
              isSigner: true,
              isWritable: true,
            ),
            AccountMeta(
              publicKey: SolAddress.uncheckBytes(List.filled(32, 0x42)),
              isSigner: false,
              isWritable: true,
            ),
          ],
        ),
      ],
    ).serializeMessage();

    test("text is shown as written", () {
      final decoded = decoder.decodeSignMessage(utf8.encode("hello world"));
      expect(decoded.rows.single.value, "hello world");
    });

    test("a multi-line sign-in message is shown as written", () {
      const signIn =
          "example.org wants you to sign in with your Solana account:\n"
          "$wallet\n\nNonce: 8f3b2c1d\nIssued At: 2026-11-23T10:00:00Z";
      final decoded = decoder.decodeSignMessage(utf8.encode(signIn));
      expect(decoded.rows.single.value, signIn);
    });

    test("a serialized legacy transaction message is refused", () {
      final message = drain().serializeMessage();
      expect(message.first, lessThan(0x80), reason: "legacy messages have no version prefix");
      expect(() => decoder.decodeSignMessage(message), refusedAsTransaction);
    });

    test("a serialized v0 transaction message is refused", () {
      final table = AddressLookupTableAccount(
        key: SolAddress(lookupTable),
        deactivationSlot: BigInt.parse("ffffffffffffffff", radix: 16),
        lastExtendedSlot: BigInt.zero,
        lastExtendedStartIndex: 0,
        authority: null,
        addresses: [SolAddress(attacker)],
      );
      final message = drain(lookupTables: [table]).serializeMessage();
      expect(message.first, 0x80, reason: "v0 messages start with the version prefix");
      expect(() => decoder.decodeSignMessage(message), refusedAsTransaction);
    });

    test("a transaction message made only of valid UTF-8 bytes is still refused", () {
      final message = asciiOnlyMessage();
      expect(utf8.decode(message), isNotEmpty, reason: "strict UTF-8 alone would let it through");
      expect(() => decoder.decodeSignMessage(message), refusedAsTransaction);
    });

    test("text that only starts like a transaction message is shown", () {
      final message = [...asciiOnlyMessage(), ..." thanks".codeUnits];
      final decoded = decoder.decodeSignMessage(message);
      expect(decoded.rows.single.value, endsWith(" thanks"));
    });

    test("text behind a byte order mark is refused, the mark would be signed and not shown", () {
      final marked = [0xef, 0xbb, 0xbf, ...utf8.encode("hello world")];
      expect(() => decoder.decodeSignMessage(marked), refusedAsNotText);
    });

    test("bytes that are not UTF-8 are refused", () {
      final offchainPreamble = [
        0xff,
        ..."solana offchain".codeUnits,
        0,
        0,
        5,
        0,
        ..."hello".codeUnits,
      ];
      expect(() => decoder.decodeSignMessage(offchainPreamble), refusedAsNotText);
    });
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
    }, walletAddress: payer);
    final title = "${S.current.wc_action_send} 0.5 SOL";
    final transactionRows = [
      row(S.current.wc_instruction_n("1"), title),
      row(S.current.wc_amount, "0.5 SOL"),
      row(S.current.from, payer),
      row(S.current.to, dest),
      row(S.current.wc_network_fee, "~ 0.000005 SOL"),
    ];
    expect(decoded.actionTitle, S.current.wc_action_sign_all_transactions);
    expect(decoded.actionSubtitle, S.current.wc_transactions_count("2"));
    expect(rowLines(decoded.rows), [
      row(S.current.wc_transaction_n("1"), title),
      ...transactionRows,
      row(S.current.wc_transaction_n("2"), title),
      ...transactionRows,
    ]);
  });

  test("decodeAllTransactions decodes a batch of a hundred transactions", () async {
    final decoded = await decoder.decodeAllTransactions({
      "transactions": [
        for (var i = 1; i <= 100; i++) encoded([solTransfer(attacker, i * 1000000000)]),
      ],
    }, walletAddress: wallet);

    expect(decoded.actionSubtitle, S.current.wc_transactions_count("100"));
    expect(
      rowValue(decoded.rows, S.current.wc_transaction_n("1")),
      "${S.current.wc_action_send} 1 SOL",
    );
    expect(
      rowValue(decoded.rows, S.current.wc_transaction_n("100")),
      "${S.current.wc_action_send} 100 SOL",
    );
    expect(decoded.warnings, isEmpty);
  });

  group("decodeAllTransactions with an entry that does not parse", () {
    final refusedAsUnparsable = throwsA(
      isA<FormatException>().having((e) => e.message, "message", contains("does not parse")),
    );
    const unparsable = "AAAA";

    test("the whole request is refused, wherever the entry sits", () async {
      final parsable = encoded([solTransfer(attacker, 1000000000)]);
      for (final transactions in [
        [parsable, unparsable],
        [unparsable, parsable],
      ]) {
        await expectLater(
          decoder.decodeAllTransactions({"transactions": transactions}, walletAddress: wallet),
          refusedAsUnparsable,
        );
      }
    });

    test("nothing is looked up for the entries before it", () async {
      final node = nodeAnsweringIn(Duration.zero);
      await expectLater(
        SolanaRequestDecoder(WalletOnlyAppStore()).decodeAllTransactions({
          "transactions": [
            encoded([tokenTransfer(0)]),
            unparsable,
          ],
        }, walletAddress: wallet),
        refusedAsUnparsable,
      );
      expect(node.accountLookups, isEmpty);
    });
  });

  group("transaction size", () {
    String withEmptyInstructions(int count) =>
        encoded([for (var i = 0; i < count; i++) instruction(systemProgram, const [], const [])]);

    test("a transaction that fills the 1232 byte packet is parsed", () {
      final full = withEmptyInstructions(355);
      expect(base64.decode(full), hasLength(1232));
      expect(decoder.transactionFromParams({"transaction": full}), isNotNull);
    });

    test("a transaction over the packet size is refused, on its own and inside signAll", () async {
      final tooLong = withEmptyInstructions(356);
      expect(base64.decode(tooLong), hasLength(1235));
      expect(decoder.transactionFromParams({"transaction": tooLong}), isNull);

      await expectLater(
        decoder.decodeAllTransactions({
          "transactions": [tooLong],
        }, walletAddress: wallet),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group("a transaction in another encoding than the one the wallet signs", () {
    final canonical = base64.decode(encoded([solTransfer(attacker, 1000000000)]));
    const keyCountOffset = 1 + 64 + 3;
    final signedMessage = SolanaTransaction.deserialize(canonical).serializeMessage();

    final variants = <String, List<int>>{
      "bytes after the message": [...canonical, 0],
      "a key count padded to two bytes": [
        ...canonical.sublist(0, keyCountOffset),
        canonical[keyCountOffset] | 0x80,
        0,
        ...canonical.sublist(keyCountOffset + 1),
      ],
      "a signature count padded to two bytes": [0x81, 0, ...canonical.sublist(1)],
    };

    test("the canonical bytes are parsed", () {
      expect(decoder.transactionFromParams({"transaction": base64.encode(canonical)}), isNotNull);
    });

    for (final variant in variants.entries) {
      test("${variant.key} get it refused", () {
        expect(
          SolanaTransaction.deserialize(variant.value).serializeMessage(),
          signedMessage,
          reason: "the library reads it as the same message",
        );
        expect(
          decoder.transactionFromParams({"transaction": base64.encode(variant.value)}),
          isNull,
        );
      });
    }
  });

  group("AltLookup", () {
    const readonlyInTable = "EWXF1h46ahk9i4c768wRCxxWjR7eEDs3PAvFwms95hqf";
    const writableInTable = "5ipEofiHQt2z9EXBZZMbMLcgeD6SFRFGKfQgfo65PKCc";
    const tableAddresses = [readonlyInTable, writableInTable];

    AddressLookupTableAccount table() => AddressLookupTableAccount(
      key: SolAddress(lookupTable),
      deactivationSlot: BigInt.parse("ffffffffffffffff", radix: 16),
      lastExtendedSlot: BigInt.zero,
      lastExtendedStartIndex: 0,
      authority: null,
      addresses: tableAddresses.map(SolAddress.new).toList(),
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
            AccountMeta(publicKey: SolAddress(writableInTable), isSigner: false, isWritable: true),
            AccountMeta(publicKey: SolAddress(readonlyInTable), isSigner: false, isWritable: false),
          ],
        ),
      ],
    );

    List<int> tableDataOf(int addressCount) {
      final tableData = <int>[
        ...List.filled(56, 0),
        for (final address in tableAddresses) ...SolAddress(address).toBytes(),
        ...List.filled((addressCount - tableAddresses.length) * 32, 7),
      ];
      tableData[0] = 1;
      tableData.fillRange(4, 12, 0xff);
      return tableData;
    }

    test("the looked-up addresses follow the static keys, writable ones first", () async {
      final tx = v0Tx();
      final staticKeys = tx.message.accountKeys.map((key) => key.address).toList();
      expect(staticKeys, [payer, systemProgram]);

      final fetcher = StubAccountFetcher({lookupTable: tableDataOf(tableAddresses.length)});
      final resolved = await AltLookup(fetcher).resolveAccountKeys(tx);

      expect(fetcher.fetchCalls, 1);
      expect(resolved, [...staticKeys, writableInTable, readonlyInTable]);
    });

    test("a table is read up to the 256 addresses a lookup table can hold", () async {
      final tx = v0Tx();
      final staticKeys = tx.message.accountKeys.map((key) => key.address).toList();

      final full = tableDataOf(256);
      expect(full, hasLength(8248));
      expect(await AltLookup(StubAccountFetcher({lookupTable: full})).resolveAccountKeys(tx), [
        ...staticKeys,
        writableInTable,
        readonlyInTable,
      ]);
    });

    test("an account longer than a full lookup table is not read as one", () async {
      final tx = v0Tx();
      final staticKeys = tx.message.accountKeys.map((key) => key.address).toList();

      final tooLong = tableDataOf(257);
      expect(
        await AltLookup(StubAccountFetcher({lookupTable: tooLong})).resolveAccountKeys(tx),
        staticKeys,
      );
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
            keys: [AccountMeta(publicKey: SolAddress(dest), isSigner: false, isWritable: true)],
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
      final decoded = await decoder.decodeTransaction({
        "transaction": encoded,
      }, walletAddress: payer);
      expect(decoded.warnings, contains(S.current.wc_warning_unresolved_accounts));
    });
  });

  group("accounts behind a lookup table that cannot be loaded", () {
    AddressLookupTableAccount tableHolding(String address) => AddressLookupTableAccount(
      key: SolAddress(lookupTable),
      deactivationSlot: BigInt.parse("ffffffffffffffff", radix: 16),
      lastExtendedSlot: BigInt.zero,
      lastExtendedStartIndex: 0,
      authority: null,
      addresses: [SolAddress(address)],
    );

    test("a SOL transfer does not show the wallet as its own recipient", () async {
      final decoded = await decode(
        [
          instruction(
            systemProgram,
            [...u32Le(2), ...u64Le(BigInt.from(50000000000))],
            [
              meta(wallet, signer: true, writable: true),
              meta(attacker, writable: true),
              meta(wallet, signer: true, writable: true),
            ],
          ),
        ],
        lookupTables: [tableHolding(attacker)],
      );

      expect(rowValue(decoded.rows, S.current.wc_amount), "50 SOL");
      expect(rowValue(decoded.rows, S.current.from), wallet);
      expect(rowValue(decoded.rows, S.current.to), S.current.wc_unresolved_account);
      expect(decoded.warnings, contains(S.current.wc_warning_unresolved_accounts));
    });

    test("an SPL transfer out of the wallet does not read as incoming", () async {
      final walletUsdc = ataFor(wallet, usdcMint);
      final decoded = await decode(
        [
          instruction(
            tokenProgram,
            [3, ...u64Le(BigInt.from(1000000000))],
            [
              meta(walletUsdc, writable: true),
              meta(attackerUsdcAccount, writable: true),
              meta(wallet, signer: true),
              meta(recentBlockhashesSysvar),
            ],
          ),
        ],
        lookupTables: [tableHolding(walletUsdc)],
      );

      expect(rowValue(decoded.rows, S.current.from), S.current.wc_unresolved_account);
      expect(rowValue(decoded.rows, S.current.to), attackerUsdcAccount);
    });

    test("an unlimited approval does not show the wallet as its own spender", () async {
      final decoded = await decode(
        [
          instruction(
            tokenProgram,
            [4, ...u64Le((BigInt.one << 64) - BigInt.one)],
            [
              meta(ataFor(wallet, usdcMint), writable: true),
              meta(attacker),
              meta(wallet, signer: true),
              meta(recentBlockhashesSysvar),
            ],
          ),
        ],
        lookupTables: [tableHolding(attacker)],
      );

      expect(
        rowValue(decoded.rows, S.current.wc_approved_spender),
        S.current.wc_unresolved_account,
      );
      expect(decoded.warnings, contains(S.current.wc_warning_unlimited_approval));
    });
  });

  group("title", () {
    test("a leading memo does not become the title", () async {
      final decoded = await decode([
        instruction(SolanaProgramIds.memoV2, "Claim your airdrop".codeUnits, const []),
        solTransfer(attacker, 50000000000),
      ]);
      expect(decoded.actionTitle, S.current.wc_action_sign_transaction);
      expect(rowValue(decoded.rows, S.current.to), attacker);
    });

    test("several decoded instructions get the generic title", () async {
      final walletUsdc = ataFor(wallet, usdcMint);
      final decoded = await decode([
        instruction(
          tokenProgram,
          const [5],
          [meta(walletUsdc, writable: true), meta(wallet, signer: true)],
        ),
        solTransfer(attacker, 50000000000),
        setAuthority(walletUsdc, attacker),
      ]);
      expect(decoded.actionTitle, S.current.wc_action_sign_transaction);
      expect(rowValue(decoded.rows, S.current.wc_new_authority), attacker);
      expect(decoded.warnings, contains(S.current.wc_warning_authority_change));
    });

    test("a decoded transfer next to an unknown program gets the generic title", () async {
      final decoded = await decode([
        solTransfer(attacker, 50000000000),
        instruction(unknownProgram, const [1], [meta(wallet, signer: true)]),
      ]);
      expect(decoded.actionTitle, S.current.wc_action_sign_transaction);
      expect(rowValue(decoded.rows, S.current.wc_amount), "50 SOL");
    });

    test("a router next to a transfer gets the generic title", () async {
      final decoded = await decode([
        instruction(raydium, const [9, 9, 9, 9], [meta(wallet, signer: true, writable: true)]),
        solTransfer(attacker, 50000000000),
      ]);
      expect(decoded.actionTitle, S.current.wc_action_sign_transaction);
      expect(rowValue(decoded.rows, S.current.wc_amount), "50 SOL");
      expect(decoded.warnings, [S.current.wc_warning_unknown_instruction]);
    });

    test("an unknown program is shown by its full id under the generic title", () async {
      final decoded = await decode([
        instruction(unknownProgram, const [1], [meta(wallet, signer: true, writable: true)]),
      ]);
      expect(decoded.actionTitle, S.current.wc_action_sign_transaction);
      expect(
        rowValue(decoded.rows, S.current.wc_instruction_n("1")),
        "${S.current.wc_program}: $unknownProgram",
      );
      expect(decoded.warnings, contains(S.current.wc_warning_unknown_instruction));
    });
  });

  group("signers and expiry", () {
    TransactionInstruction advanceNonce({String authority = wallet}) =>
        instruction(systemProgram, u32Le(4), [
          meta(nonceAccount, writable: true),
          meta(recentBlockhashesSysvar),
          meta(authority, signer: true),
        ]);

    test("a leading AdvanceNonceAccount is decoded and warns that nothing expires", () async {
      final decoded = await decode([advanceNonce(), solTransfer(attacker, 50000000000)]);
      expect(
        rowValue(decoded.rows, S.current.wc_instruction_n("1")),
        S.current.wc_action_advance_nonce,
      );
      expect(rowValue(decoded.rows, S.current.wc_nonce_account), nonceAccount);
      expect(rowValue(decoded.rows, S.current.wc_nonce_authority), wallet);
      expect(decoded.warnings, [S.current.wc_warning_durable_nonce]);
    });

    test("a durable nonce someone else controls warns that the wallet cannot cancel", () async {
      final decoded = await decode([
        advanceNonce(authority: attacker),
        solTransfer(dest, 50000000000),
      ]);
      expect(rowValue(decoded.rows, S.current.wc_nonce_authority), attacker);
      expect(decoded.warnings, [
        S.current.wc_warning_durable_nonce,
        S.current.wc_warning_nonce_authority_not_you,
      ]);
    });

    test("AdvanceNonceAccount later in the transaction does not make it durable", () async {
      final decoded = await decode([
        solTransfer(dest, 50000000000),
        advanceNonce(authority: attacker),
      ]);
      expect(rowValue(decoded.rows, S.current.wc_nonce_authority), attacker);
      expect(decoded.warnings, isEmpty);
    });

    test("a second required signer is listed", () async {
      final decoded = await decode([
        solTransfer(attacker, 1000000),
        solTransfer(wallet, 2000000, from: attacker),
      ]);
      expect(rowValue(decoded.rows, S.current.wc_other_signers), attacker);
      expect(rowValue(decoded.rows, S.current.wc_network_fee), "~ 0.00001 SOL");
    });

    test("a transaction only the wallet signs lists no other signers", () async {
      final decoded = await decode([solTransfer(attacker, 1000000)]);
      expect(rowValue(decoded.rows, S.current.wc_other_signers), isNull);
    });
  });

  test("a System transfer that names no recipient is shown as an unknown instruction", () async {
    final decoded = await decode([
      instruction(
        systemProgram,
        [...u32Le(2), ...u64Le(BigInt.from(1000000000))],
        [meta(wallet, signer: true, writable: true)],
      ),
    ]);
    expect(rowLines(decoded.rows), [
      programRow(1, systemProgram),
      "${S.current.wc_network_fee}: ~ 0.000005 SOL",
    ]);
    expect(decoded.warnings, [S.current.wc_warning_unknown_instruction]);
  });

  group("lookup budget", () {
    List<String> amountsOn(WCDecodedRequest decoded) => [
      for (final row in decoded.rows)
        if (row.label == S.current.wc_amount) row.value,
    ];

    testWidgets("lookups stop ten seconds into a request and the rows left stay raw", (
      tester,
    ) async {
      final node = nodeAnsweringIn(const Duration(seconds: 4));
      WCDecodedRequest? decoded;
      unawaited(
        SolanaRequestDecoder(WalletOnlyAppStore())
            .decodeTransaction({
              "transaction": encoded([for (var i = 0; i < 4; i++) tokenTransfer(i)]),
            }, walletAddress: wallet)
            .then((request) => decoded = request),
      );

      await tester.pump(const Duration(milliseconds: 9999));
      expect(decoded, isNull);
      await tester.pump(const Duration(milliseconds: 1));
      expect(decoded, isNotNull, reason: "the third lookup was only due back at 12 s");

      expect(node.accountLookups, [for (var i = 0; i < 3; i++) sourceOfTransfer(i)]);
      expect(node.tokenLookups, [mintOfTransfer(0), mintOfTransfer(1)]);
      expect(amountsOn(decoded!), [startsWith("1.5 "), startsWith("1.5 "), "1500000", "1500000"]);
      expect(decoded!.warnings, contains(S.current.wc_warning_raw_token_amount));

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets("signAll has one budget for all of its transactions", (tester) async {
      final node = nodeAnsweringIn(const Duration(seconds: 4));
      WCDecodedRequest? decoded;
      unawaited(
        SolanaRequestDecoder(WalletOnlyAppStore())
            .decodeAllTransactions({
              "transactions": [
                encoded([tokenTransfer(0), tokenTransfer(1)]),
                encoded([tokenTransfer(2), tokenTransfer(3)]),
              ],
            }, walletAddress: wallet)
            .then((request) => decoded = request),
      );

      await tester.pump(const Duration(milliseconds: 9999));
      expect(decoded, isNull);
      await tester.pump(const Duration(milliseconds: 1));
      expect(decoded, isNotNull);
      expect(node.accountLookups, [for (var i = 0; i < 3; i++) sourceOfTransfer(i)]);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets("a second request leaves the first one's budget as it was", (tester) async {
      final node = nodeAnsweringIn(const Duration(seconds: 4));
      final shared = SolanaRequestDecoder(WalletOnlyAppStore());
      WCDecodedRequest? first;
      WCDecodedRequest? second;

      unawaited(
        shared
            .decodeTransaction({
              "transaction": encoded([for (var i = 0; i < 4; i++) tokenTransfer(i)]),
            }, walletAddress: wallet)
            .then((request) => first = request),
      );
      await tester.pump(const Duration(seconds: 6));
      unawaited(
        shared
            .decodeTransaction({
              "transaction": encoded([for (var i = 4; i < 8; i++) tokenTransfer(i)]),
            }, walletAddress: wallet)
            .then((request) => second = request),
      );

      await tester.pump(const Duration(milliseconds: 3999));
      expect(first, isNull);
      await tester.pump(const Duration(milliseconds: 1));
      expect(first, isNotNull, reason: "ten seconds after the first request began");
      expect(second, isNull);

      await tester.pump(const Duration(milliseconds: 5999));
      expect(second, isNull);
      await tester.pump(const Duration(milliseconds: 1));
      expect(second, isNotNull, reason: "ten seconds after the second request began");

      expect(
        node.accountLookups,
        unorderedEquals([
          for (final transfer in [0, 1, 2, 4, 5, 6]) sourceOfTransfer(transfer),
        ]),
      );

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets("a decode that finishes inside its budget leaves no timer behind", (tester) async {
      final node = nodeAnsweringIn(const Duration(milliseconds: 100));
      WCDecodedRequest? decoded;
      unawaited(
        SolanaRequestDecoder(WalletOnlyAppStore())
            .decodeTransaction({
              "transaction": encoded([tokenTransfer(0)]),
            }, walletAddress: wallet)
            .then((request) => decoded = request),
      );

      await tester.pump(const Duration(seconds: 1));
      expect(amountsOn(decoded!), [startsWith("1.5 ")]);
      expect(node.accountLookups, [sourceOfTransfer(0)]);
    });

    test("the node is asked only while the budget lasts", () async {
      final node = nodeAnsweringIn(Duration.zero);
      final store = WalletOnlyAppStore();

      final running = SolanaLookupBudget();
      await SolanaAccountFetcher(store, running).fetchAccountsData([sourceOfTransfer(0)]);
      await SplTokenResolver(store, running).resolve(mintOfTransfer(0));
      expect(node.accountLookups, [sourceOfTransfer(0)]);
      expect(node.tokenLookups, [mintOfTransfer(0)]);

      final spent = SolanaLookupBudget()..markSpent();
      expect(
        await SolanaAccountFetcher(store, spent).fetchAccountsData([sourceOfTransfer(1)]),
        isNull,
      );
      expect(await SplTokenResolver(store, spent).resolve(mintOfTransfer(1)), isNull);
      expect(node.accountLookups, [sourceOfTransfer(0)]);
      expect(node.tokenLookups, [mintOfTransfer(0)]);
    });

    test("a lookup that outlasts its own timeout answers null", () async {
      final unanswered = Completer<String?>();
      final answer = await SolanaLookupBudget().run(
        () => unanswered.future,
        timeout: const Duration(milliseconds: 1),
      );
      expect(answer, isNull);
    });
  });

  test("closing a token account to someone else warns outside a swap too", () async {
    final decoded = await decode([closeAccount(ataFor(wallet, wsolMint), attacker)]);
    expect(decoded.actionTitle, S.current.wc_action_close_token_account);
    expect(rowValue(decoded.rows, S.current.to), attacker);
    expect(decoded.warnings, contains(S.current.wc_warning_recipient_not_you));
  });

  test("paying to create a token account for someone else warns", () async {
    final decoded = await decode([
      instruction(
        SolanaProgramIds.associatedTokenProgram,
        const [1],
        [
          meta(wallet, signer: true, writable: true),
          meta(ataFor(attacker, usdcMint), writable: true),
          meta(attacker),
          meta(usdcMint),
          meta(systemProgram),
          meta(tokenProgram),
        ],
      ),
    ]);
    expect(rowValue(decoded.rows, S.current.wc_owner), attacker);
    expect(decoded.warnings, [S.current.wc_warning_recipient_not_you]);
  });

  group("token transfers without a router", () {
    test("a payment out and a look-alike token in are shown as two transfers", () async {
      final decoded = await decode([
        transferChecked(
          ataFor(wallet, usdcMint),
          usdcMint,
          attackerUsdcAccount,
          wallet,
          1000000000,
        ),
        transferChecked(
          attackerMintAccount,
          attackerMint,
          ataFor(wallet, attackerMint),
          attacker,
          1000000000,
        ),
      ]);

      expect(decoded.actionTitle, S.current.wc_action_sign_transaction);
      expect(decoded.rows.where((r) => r.label == S.current.to).map((r) => r.value), [
        attackerUsdcAccount,
        ataFor(wallet, attackerMint),
      ]);
      expect(decoded.rows.where((r) => r.label == S.current.wc_token).last.value, attackerMint);
      expect(decoded.warnings, contains(S.current.wc_warning_unknown_token));
      expect(rowValue(decoded.rows, S.current.wc_other_signers), attacker);
    });
  });

  group("Jupiter route instructions are not read", () {
    final walletUsdc = ataFor(wallet, usdcMint);
    final walletUsdt = ataFor(wallet, usdtMint);
    final walletWsol = ataFor(wallet, wsolMint);
    const attackerUsdtAccount = "J9WJF4NbJwio4DiKiTGsb7uDnxbruWjEVkj7M6bLhCRa";

    final routeData = BytesUtils.fromHexString(
      "bb64facc31c4af14404b4c00000000005f624c0000000000320000000000010000009c10270001",
    );

    TransactionInstruction route({
      String program = jupiter,
      String destinationOverride = jupiter,
    }) => instruction(program, routeData, [
      meta(wallet, signer: true),
      meta(walletUsdc, writable: true),
      meta(walletUsdt, writable: true),
      meta(usdcMint),
      meta(usdtMint),
      meta(tokenProgram),
      meta(tokenProgram),
      meta(destinationOverride, writable: destinationOverride != jupiter),
      meta(jupiterEventAuthority),
      meta(jupiter),
    ]);

    TransactionInstruction defaultRoute() => instruction(
      jupiter,
      BytesUtils.fromHexString(
        "e517cb977ae3ad2a01000000cd0164000180b2e60e00000000715a140100000000320000",
      ),
      [
        meta(tokenProgram),
        meta(wallet, signer: true),
        meta(walletUsdc, writable: true),
        meta(walletUsdt, writable: true),
        meta(attackerUsdtAccount, writable: true),
        meta(usdtMint),
        meta(jupiter),
        meta(jupiterEventAuthority),
        meta(jupiter),
      ],
    );

    void expectUnreadRouteOnly(WCDecodedRequest decoded, String program) {
      expect(decoded.actionTitle, S.current.wc_action_sign_transaction);
      expect(rowLines(decoded.rows), [
        programRow(1, program),
        "${S.current.wc_network_fee}: ~ 0.000005 SOL",
      ]);
      expect(decoded.warnings, [S.current.wc_warning_unknown_instruction]);
    }

    test("a route_v2 into the wallet's own account shows no amounts", () async {
      expectUnreadRouteOnly(await decode([route()]), "Jupiter ($jupiter)");
    });

    test("a route_v2 with destination_token_account set shows no recipient", () async {
      final decoded = await decode([route(destinationOverride: attackerUsdtAccount)]);
      expectUnreadRouteOnly(decoded, "Jupiter ($jupiter)");
    });

    test("the default route instruction paying someone else shows no recipient", () async {
      expectUnreadRouteOnly(await decode([defaultRoute()]), "Jupiter ($jupiter)");
    });

    test("an unknown program shaped like a Jupiter route is shown by its id", () async {
      expectUnreadRouteOnly(await decode([route(program: unknownProgram)]), unknownProgram);
    });

    test("SOL sent to someone else next to a route is on the card", () async {
      final decoded = await decode([route(), solTransfer(attacker, 5000000000)]);
      expect(decoded.actionTitle, S.current.wc_action_sign_transaction);
      expect(rowLines(decoded.rows), [
        jupiterRow(1),
        "${S.current.wc_instruction_n("2")}: ${S.current.wc_action_send} 5 SOL",
        "${S.current.wc_amount}: 5 SOL",
        "${S.current.from}: $wallet",
        "${S.current.to}: $attacker",
        "${S.current.wc_network_fee}: ~ 0.000005 SOL",
      ]);
      expect(decoded.warnings, [S.current.wc_warning_unknown_instruction]);
    });

    test("SOL wrapped next to a route is on the card whatever the route pays", () async {
      final decoded = await decode([solTransfer(walletWsol, 100000000000), route()]);
      expect(rowValue(decoded.rows, S.current.wc_amount), "100 SOL");
      expect(rowValue(decoded.rows, S.current.to), walletWsol);
    });

    test("an unlimited approval next to a route is on the card with its warning", () async {
      final decoded = await decode([
        route(),
        instruction(
          tokenProgram,
          [4, ...u64Le((BigInt.one << 64) - BigInt.one)],
          [meta(walletUsdc, writable: true), meta(attacker), meta(wallet, signer: true)],
        ),
      ]);
      expect(rowValue(decoded.rows, S.current.wc_approved_spender), attacker);
      expect(decoded.warnings, contains(S.current.wc_warning_unlimited_approval));
    });

    test("closing the wrapped SOL account to someone else next to a route warns", () async {
      final decoded = await decode([
        solTransfer(walletWsol, 10000000000),
        route(),
        closeAccount(walletWsol, attacker),
      ]);
      expect(rowValue(decoded.rows, S.current.wc_amount), "10 SOL");
      expect(decoded.rows.any((r) => r.label == S.current.to && r.value == attacker), isTrue);
      expect(decoded.warnings, contains(S.current.wc_warning_recipient_not_you));
    });

    test("a Batch next to a route is shown by the token program's id", () async {
      final batch = instruction(
        tokenProgram,
        const [255, 2, 1, 5, 3, 1, 9],
        [
          meta(walletUsdc, writable: true),
          meta(wallet, signer: true),
          meta(walletWsol, writable: true),
          meta(attacker, writable: true),
          meta(wallet, signer: true),
        ],
      );
      final decoded = await decode([route(), batch]);
      expect(rowLines(decoded.rows), [
        jupiterRow(1),
        programRow(2, tokenProgram),
        "${S.current.wc_network_fee}: ~ 0.000005 SOL",
      ]);
      expect(decoded.warnings, [S.current.wc_warning_unknown_instruction]);
    });
  });

  group("transfers next to a router", () {
    const poolUsdc = "23XoPQqGw9WMsLoqTu8HMzJLD6RnXsufbKyWPLJywsCT";
    const poolUsdt = "J9WJF4NbJwio4DiKiTGsb7uDnxbruWjEVkj7M6bLhCRa";
    const poolAuthority = "REALQqNEomY6cQGZJUGwywTBD2UmDT32rZcNnfxQ5N2";

    test("a payment out and one in are shown as two transfers, not as a swap", () async {
      final walletUsdc = ataFor(wallet, usdcMint);
      final walletUsdt = ataFor(wallet, usdtMint);
      final decoded = await decode([
        transferChecked(walletUsdc, usdcMint, poolUsdc, wallet, 2000000),
        transferChecked(poolUsdt, usdtMint, walletUsdt, poolAuthority, 1900000),
        instruction(raydium, const [9], [meta(wallet, signer: true)]),
      ]);

      expect(decoded.actionTitle, S.current.wc_action_sign_transaction);
      expect(rowLines(decoded.rows), [
        "${S.current.wc_instruction_n("1")}: ${S.current.wc_action_transfer}",
        "${S.current.wc_token}: $usdcMint",
        "${S.current.wc_amount}: 2 EPjF…Dt1v",
        "${S.current.from}: $walletUsdc",
        "${S.current.to}: $poolUsdc",
        "${S.current.wc_instruction_n("2")}: ${S.current.wc_action_transfer}",
        "${S.current.wc_token}: $usdtMint",
        "${S.current.wc_amount}: 1.9 Es9v…wNYB",
        "${S.current.from}: $poolUsdt",
        "${S.current.to}: $walletUsdt",
        programRow(3, "Raydium ($raydium)"),
        "${S.current.wc_other_signers}: $poolAuthority",
        "${S.current.wc_network_fee}: ~ 0.00001 SOL",
      ]);
      expect(decoded.warnings, [S.current.wc_warning_unknown_instruction]);
    });
  });

  group("transactions captured from lite-api.jup.ag", () {
    Map<String, dynamic> captured(String programId, String dataHex, [String keys = ""]) => {
      "programId": programId,
      "data": BytesUtils.fromHexString(dataHex),
      "keys": [
        for (final match in RegExp(r"(\w+)(?::(s?)(w?))?").allMatches(keys))
          key(match[1]!, signer: match[2] == "s", writable: match[3] == "w"),
      ],
    };

    Future<WCDecodedRequest> decodeCaptured(List<Map<String, dynamic>> instructions) =>
        decoder.decodeTransaction({
          "feePayer": wallet,
          "recentBlockhash": blockhash,
          "instructions": instructions,
        }, walletAddress: wallet);

    const capturedWsolAccount = "2484ax8f261sDW3YmAkeK1ggEDkN7aSrUNCnnz9FxRup";
    const capturedUsd1Account = "474qb3Fap63qvjdBWLEpuecL3wiwL4QbUbKoDhqPmmJy";
    const usd1Mint = "USD1ttGY1N17NEEHLmELoaybftRBUSErhqYiQzvEmuB";

    List<String> createAccountRows(int instruction, String mint, String tokenAccount) => [
      "${S.current.wc_instruction_n("$instruction")}: "
          "${S.current.wc_action_create_token_account_idempotent}",
      "${S.current.wc_token}: $mint",
      "${S.current.wc_owner}: $wallet",
      "${S.current.wc_token_account}: $tokenAccount",
    ];

    List<String> wrapRows(int instruction) => [
      "${S.current.wc_instruction_n("$instruction")}: ${S.current.wc_action_send} 0.25 SOL",
      "${S.current.wc_amount}: 0.25 SOL",
      "${S.current.from}: $wallet",
      "${S.current.to}: $capturedWsolAccount",
      "${S.current.wc_instruction_n("${instruction + 1}")}: ${S.current.wc_action_wrap("SOL")}",
      "${S.current.wc_token_account}: $capturedWsolAccount",
    ];

    List<String> closeWsolRows(int instruction) => [
      "${S.current.wc_instruction_n("$instruction")}: ${S.current.wc_action_close_token_account}",
      "${S.current.wc_token_account}: $capturedWsolAccount",
      "${S.current.to}: $wallet",
    ];

    void expectPlainCard(WCDecodedRequest decoded, List<String> rows) {
      expect(decoded.actionTitle, S.current.wc_action_sign_transaction);
      expect(rowLines(decoded.rows), rows);
      expect(decoded.warnings, [S.current.wc_warning_unknown_instruction]);
    }

    final computeLimit = captured(computeBudget, "02c05c1500");
    final computePrice = captured(computeBudget, "030417010000000000");
    final createWsolAccount = captured(SolanaProgramIds.associatedTokenProgram, "01", """
      4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t:sw
      2484ax8f261sDW3YmAkeK1ggEDkN7aSrUNCnnz9FxRup:w 4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t
      So11111111111111111111111111111111111111112 11111111111111111111111111111111
      TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
    """);
    final createUsd1Account = captured(SolanaProgramIds.associatedTokenProgram, "01", """
      4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t:sw
      474qb3Fap63qvjdBWLEpuecL3wiwL4QbUbKoDhqPmmJy:w 4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t
      USD1ttGY1N17NEEHLmELoaybftRBUSErhqYiQzvEmuB 11111111111111111111111111111111
      TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
    """);
    final fundWsolAccount = captured(systemProgram, "0200000080b2e60e00000000", """
      4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t:sw
      2484ax8f261sDW3YmAkeK1ggEDkN7aSrUNCnnz9FxRup:w
    """);
    final syncWsolAccount = captured(tokenProgram, "11", """
      2484ax8f261sDW3YmAkeK1ggEDkN7aSrUNCnnz9FxRup:w
    """);
    final closeWsolAccount = captured(tokenProgram, "09", """
      2484ax8f261sDW3YmAkeK1ggEDkN7aSrUNCnnz9FxRup:w
      4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t:w
      4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t:s
    """);

    test("USDT to AAPLx through USDC shows the account it creates and the route unread", () async {
      final decoded = await decodeCaptured([
        computeLimit,
        captured(SolanaProgramIds.associatedTokenProgram, "01", """
          4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t:sw
          Dzf2Q5eVcYnnWEBYQx5vTMcZ1VC3XWsoKHcQ1rK9gWBt:w
          4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t
          XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp 11111111111111111111111111111111
          TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
        """),
        captured(
          jupiter,
          "bb64facc31c4af14404b4c000000000013d0150000000000320000000000020000009c102700012f0000"
              "10270102",
          """
          4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t:s
          ATSVbA98Ur5dzoVX4whLLm5kSfUS3cQr65EyTULUtmnU:w
          Dzf2Q5eVcYnnWEBYQx5vTMcZ1VC3XWsoKHcQ1rK9gWBt:w
          Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB
          XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
          TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4
          D8cy77BBepLMngZx6ZukaTff5hCt1HrWyKk3Hnd9oitf JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4
          REALQqNEomY6cQGZJUGwywTBD2UmDT32rZcNnfxQ5N2 4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t
          96FHuHDcv9FL55qhoBoUGAmxZg9XM47fBM3t2vdefGW2
          23XoPQqGw9WMsLoqTu8HMzJLD6RnXsufbKyWPLJywsCT:w
          ATSVbA98Ur5dzoVX4whLLm5kSfUS3cQr65EyTULUtmnU:w
          3hxeFuNcMTKQmzvUMFyc8fEdsi4vd7za4FURD3Ra1gU3:w
          J9WJF4NbJwio4DiKiTGsb7uDnxbruWjEVkj7M6bLhCRa:w
          6nMF76wKdFZaE78eRRDcNikVw1jMKMC4zoj7ibq1N25f:w
          EWXF1h46ahk9i4c768wRCxxWjR7eEDs3PAvFwms95hqf:w
          TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
          TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr
          Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
          AsotAq6Hb5KW6bAExHq2hJctDNuErLEjaVSaR4yJ5WEj
          5ipEofiHQt2z9EXBZZMbMLcgeD6SFRFGKfQgfo65PKCc:w
          8vdCZ5Ks2TcgAfJjE7q9RKdBt1A9dWPM7fKQPFaC3Z3E:w
          45HT9JFxtNEEKAQ9abyCSf663eZfMAzxUtq2ppsnkKBo:w
          Dpw1EAVrSB1ibxiDQyTAW6Zip3J4Btk2x4SgApQCeFbX
          HT2PLQBcG5EiCcNSaMHAjSgd9F98ecpATbk4Sk5oYuM JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4
          whirLbMiicVdio4qvUfM5KAg6Ct8VwpYzGff3uctyCc TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
          TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr
          4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t
          Djdm88bGU5NLHvMEWCZqsbLGd28vL8KeS2mxejTnPzoW:w
          XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
          Dzf2Q5eVcYnnWEBYQx5vTMcZ1VC3XWsoKHcQ1rK9gWBt:w
          HgEdPsXdbi15x94DUVsbrvdf6Fc8Wdp5PbaDT9JTo8bN:w
          3hxeFuNcMTKQmzvUMFyc8fEdsi4vd7za4FURD3Ra1gU3:w
          EnwJjGQZyKjVqWbqYKHGFrmuS7DpowTrAyDzYNn6asdU:w
          93fdYBXJp7prjgnEZzbeEVmyMYXqftNSH9dGiumDXDXS:w
          FENYsp2iavnkWGwRZE1ms4TFtakgL6KwcsivyaJkoYbm:w
          5NNpdxRf2ifC1AAbJbNc1viAsg5pzZcL1k1BGRtiCVCG:w
          7V5Jzq3vUQ1r34G9V5JeMpmbtixuhfeFb8XspGZxqCQQ:w
          """,
        ),
      ]);

      expectPlainCard(decoded, [
        ...createAccountRows(
          2,
          "XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp",
          "Dzf2Q5eVcYnnWEBYQx5vTMcZ1VC3XWsoKHcQ1rK9gWBt",
        ),
        jupiterRow(3),
        "${S.current.wc_network_fee}: ~ 0.000005 SOL",
      ]);
    });

    test("USDC to USDT sent to another account says nothing about who is paid", () async {
      final decoded = await decodeCaptured([
        computeLimit,
        createWsolAccount,
        createUsd1Account,
        captured(
          jupiter,
          "bb64facc31c4af14404b4c0000000000a7624c0000000000320000000000030000007400102700019c10"
              "2701021a10270203",
          """
          4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t:s
          3hxeFuNcMTKQmzvUMFyc8fEdsi4vd7za4FURD3Ra1gU3:w
          ATSVbA98Ur5dzoVX4whLLm5kSfUS3cQr65EyTULUtmnU:w
          EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
          Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
          TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
          9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM:w
          D8cy77BBepLMngZx6ZukaTff5hCt1HrWyKk3Hnd9oitf JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4
          MNFSTqtC93rEfYHB6hF82sKdZpUDFWkViLByLd1k1Ms
          4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t:w
          4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t
          4ba9bguTo7HbXFopJHaNMh8iAyApFpyQPgoufj3cSnyt:w
          11111111111111111111111111111111 474qb3Fap63qvjdBWLEpuecL3wiwL4QbUbKoDhqPmmJy:w
          3hxeFuNcMTKQmzvUMFyc8fEdsi4vd7za4FURD3Ra1gU3:w
          BkmQoLwdoseDsHZxSFo76XSGnyMixy6iUtMEHVzMuNP9:w
          BDVsoFu2GrvXG8HRjfp8aCyphSmEhb9Sm92siVSb6VES:w
          TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
          USD1ttGY1N17NEEHLmELoaybftRBUSErhqYiQzvEmuB TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
          EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
          HPzBNXsVT2yWMTS1kUJz5KygFDErWdYa7V871Qq2V23r:w
          F5diL6uf7eacLcEJJP3oh3HevstzFV5821pLHtvNywQi:w
          REALQqNEomY6cQGZJUGwywTBD2UmDT32rZcNnfxQ5N2
          4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t Cgc2VcAefVLKgfueBUAKYNgyiYs4YCHQMeTLJ4DccrTt
          DyzGYEhdgSn5EEUt4XXviavZ7v7SV2YGrYV8HX3Aw5XT:w
          474qb3Fap63qvjdBWLEpuecL3wiwL4QbUbKoDhqPmmJy:w
          2484ax8f261sDW3YmAkeK1ggEDkN7aSrUNCnnz9FxRup:w
          yCeSRFxf5zn4nTMV4wjsBswhKD1ac6bz1FsTPSqWeG7:w
          2woLM63wQWnNtQoWhtUfQCUE4fTqyyJN9t3WdtFoF9sN:w
          9gmyvoNDMpCKn9MQYUc8q23TS7Q2mhkrqiksD8F3RsBS:w
          TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
          TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr
          USD1ttGY1N17NEEHLmELoaybftRBUSErhqYiQzvEmuB So11111111111111111111111111111111111111112
          AnXYymu5kNhvtsHtaVF2XNkAKA6P9WRyzUFPvgK8k97j
          BFfUG4Ej9XRvBNupt4F68yxjdDSj9TUvsGadh9dwBUia:w
          ExhjMVywDhjjhm5DWKbn5ELiVqeV77WbymoBJSSNj8NS:w
          4kAM7TGmkpaoCVdBRRsKJFfAnZspwijZRC5bJV5jYrLs:w
          JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4
          CAMMCzo5YL8w4VFF8KVHrK22GGUsp5VTaW7grrKgrWqK 4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t
          9iFER3bpjf1PTTCQCfTRu17EJgvsxo9pVyA9QWwEuX4x
          3nMFwZXwY1s1M5s8vYAHqd4wGs4iSxXE4LRoUMMYqEgF:w
          2484ax8f261sDW3YmAkeK1ggEDkN7aSrUNCnnz9FxRup:w
          ATSVbA98Ur5dzoVX4whLLm5kSfUS3cQr65EyTULUtmnU:w
          AbcuyoPeYnddzFoFQudsiFka8qd6tTwvLgxwtpTKTpKC:w
          2n6fxuD6PA5NYgEnXXYMh2iWD1JBJ1LGf76kFJAayZmX:w
          Cqb16WaM7dDDP8koxYASDJLWgan4STDB1R3LiSH8r3GR:w
          TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
          FT455QZEK7eXdMQwrQaPFSf6EHr6PD1xFhkdqyZwDNwJ:w
          2ncinnTcJxbZ1nUHavBVJ3Ap3R4CE7p2LJ6Jtpd1vLzd:w
          HL1bNJr7u5EAFpDtMsvcZBbEjqnuE3eRxtTzufztEwrb:w
          9RFBYoWP2VsjfnEyspc26w1vPFuV8gFpFGEncxnTmxZb:w
          JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4
          """,
        ),
        closeWsolAccount,
      ]);

      expectPlainCard(decoded, [
        ...createAccountRows(2, wsolMint, capturedWsolAccount),
        ...createAccountRows(3, usd1Mint, capturedUsd1Account),
        jupiterRow(4),
        ...closeWsolRows(5),
        "${S.current.wc_network_fee}: ~ 0.000005 SOL",
      ]);
    });

    test("SOL to USDC shows the wrap, the route unread and the unwrap", () async {
      final decoded = await decodeCaptured([
        computeLimit,
        computePrice,
        createWsolAccount,
        fundWsolAccount,
        syncWsolAccount,
        captured(
          jupiter,
          "d19853937cfed8e90180b2e60e00000000d25614010000000032000000000002000000cfd055d230f3e8"
              "d6da8a0c00000c00050010270001a1010100000010270102",
          """
          2MFoS3MPtvyQ4Wh4M9pdfPjz6UhVoNbFbGJAskCPCj3h
          4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t:s
          2484ax8f261sDW3YmAkeK1ggEDkN7aSrUNCnnz9FxRup:w
          H1qQ6Hent1C5wa4Hc3GK2V1sgg4grvDBbmKd5H8dsTmo:w
          JSvtokJbtGsYhneKomFBjnJh4djEQLdHV2kAeS43bBZ:w
          3hxeFuNcMTKQmzvUMFyc8fEdsi4vd7za4FURD3Ra1gU3:w
          So11111111111111111111111111111111111111112 EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
          TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
          D8cy77BBepLMngZx6ZukaTff5hCt1HrWyKk3Hnd9oitf JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4
          SCoRcH8c2dpjvcJD6FiPbCSQyQgu3PcUAWj2Xxx3mqn EHcege7dok1iYs7SxL2XzDPvhg6XzMVcx2V5SkMUurJP
          2MFoS3MPtvyQ4Wh4M9pdfPjz6UhVoNbFbGJAskCPCj3h
          H1qQ6Hent1C5wa4Hc3GK2V1sgg4grvDBbmKd5H8dsTmo:w
          F3Hej7eXZMWTr141APvCiNM7ZUn22cD9b1p8EcfFH8vn:w
          44GW6aFire4Fd72h4QqjenNKrQLjfnApHhWYXo3S1gvp:w
          qZGfSMBqqCK7jFUdBDCVk7uHHgP67WDRD6kTt84gGK2:w
          So11111111111111111111111111111111111111112 Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB
          TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
          MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr ojh19ojaKduoJZuaJADhcVGp4xt1TcdAvZmpVsCorch
          HLixVmXdBqzP1sXT9au4BHcvUjDgx5ev16cEJdd9tUSM
          85Etk23kFtyt265MQjyUgzJYZ7u5o2EVNdjDmuNySbGi:w
          9UmAmvtBZrS1Er85MC2DzTyHR522XJqA1EpHQNPLhX5F:w
          GUoa6mRgTyoE8NgXEyLnYXMWdS71KrcXG2nnx9u41Fmd:w
          Sysvar1nstructions1111111111111111111111111 9mYEd71VzXZoa8a3B3Zw5TG6C3N7qLRGnw2JdtocsrrS
          DRVSpZ2YUYYKgZP8XtLhAGtT1zYSCKzeHfb4DgRnrgqD
          2MFoS3MPtvyQ4Wh4M9pdfPjz6UhVoNbFbGJAskCPCj3h
          Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB
          EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
          UUUXQdoC85FmgUgDMfYj3UsBWMLSjU7gVj4QmYGdMRx:w
          EPUHjseXG3izk3MVUJ1PcyWT9xeBhtAnq8gUpq3j8Uni:w
          H7o7KCr5n3whqcPsPkeCPWrzivKrarqzidD3kt8fijvB:w
          42Xtwh4LeVX7yHtn77wXSXsDMKFqggcafgdHWKvsguxu:w
          6PMK33AGG7qCyMn2uMYdWBMqdESW3VNUQHbqUFUqSgwP:w
          H6mmDwnQHBq68tqEhBConeRBBDUobqHrQbDUcBVNTW9M:w
          5DMkwX1edkbAywTecSjP2nyPjzmi8dCKvWfQXybVLvCw:w
          FCgtbMQPyLVNnvd7mpxc3SCE8Ne8qEL9xkU2gwf7xceA:w
          F3Hej7eXZMWTr141APvCiNM7ZUn22cD9b1p8EcfFH8vn:w
          JSvtokJbtGsYhneKomFBjnJh4djEQLdHV2kAeS43bBZ:w
          TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
          """,
        ),
        closeWsolAccount,
      ]);

      expectPlainCard(decoded, [
        ...createAccountRows(3, wsolMint, capturedWsolAccount),
        ...wrapRows(4),
        jupiterRow(6),
        ...closeWsolRows(7),
        "${S.current.wc_network_fee}: ~ 0.000105 SOL",
      ]);
    });

    test("the default route instruction sent to another account is shown unread", () async {
      final decoded = await decodeCaptured([
        computeLimit,
        computePrice,
        createWsolAccount,
        createUsd1Account,
        captured(
          jupiter,
          "e517cb977ae3ad2a0300000074006400019c640102cd01640203404b4c000000000029624c0000000000"
              "320000",
          """
          TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
          4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t:s
          3hxeFuNcMTKQmzvUMFyc8fEdsi4vd7za4FURD3Ra1gU3:w
          ATSVbA98Ur5dzoVX4whLLm5kSfUS3cQr65EyTULUtmnU:w
          9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM:w
          Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4
          D8cy77BBepLMngZx6ZukaTff5hCt1HrWyKk3Hnd9oitf JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4
          MNFSTqtC93rEfYHB6hF82sKdZpUDFWkViLByLd1k1Ms 4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t:w
          4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t
          4ba9bguTo7HbXFopJHaNMh8iAyApFpyQPgoufj3cSnyt:w 11111111111111111111111111111111
          474qb3Fap63qvjdBWLEpuecL3wiwL4QbUbKoDhqPmmJy:w
          3hxeFuNcMTKQmzvUMFyc8fEdsi4vd7za4FURD3Ra1gU3:w
          BkmQoLwdoseDsHZxSFo76XSGnyMixy6iUtMEHVzMuNP9:w
          BDVsoFu2GrvXG8HRjfp8aCyphSmEhb9Sm92siVSb6VES:w
          TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA USD1ttGY1N17NEEHLmELoaybftRBUSErhqYiQzvEmuB
          TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
          HPzBNXsVT2yWMTS1kUJz5KygFDErWdYa7V871Qq2V23r:w
          F5diL6uf7eacLcEJJP3oh3HevstzFV5821pLHtvNywQi:w
          REALQqNEomY6cQGZJUGwywTBD2UmDT32rZcNnfxQ5N2 4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t
          Cgc2VcAefVLKgfueBUAKYNgyiYs4YCHQMeTLJ4DccrTt
          DyzGYEhdgSn5EEUt4XXviavZ7v7SV2YGrYV8HX3Aw5XT:w
          474qb3Fap63qvjdBWLEpuecL3wiwL4QbUbKoDhqPmmJy:w
          2484ax8f261sDW3YmAkeK1ggEDkN7aSrUNCnnz9FxRup:w
          yCeSRFxf5zn4nTMV4wjsBswhKD1ac6bz1FsTPSqWeG7:w
          2woLM63wQWnNtQoWhtUfQCUE4fTqyyJN9t3WdtFoF9sN:w
          9gmyvoNDMpCKn9MQYUc8q23TS7Q2mhkrqiksD8F3RsBS:w
          TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
          MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr USD1ttGY1N17NEEHLmELoaybftRBUSErhqYiQzvEmuB
          So11111111111111111111111111111111111111112 AnXYymu5kNhvtsHtaVF2XNkAKA6P9WRyzUFPvgK8k97j
          BFfUG4Ej9XRvBNupt4F68yxjdDSj9TUvsGadh9dwBUia:w
          ExhjMVywDhjjhm5DWKbn5ELiVqeV77WbymoBJSSNj8NS:w
          4kAM7TGmkpaoCVdBRRsKJFfAnZspwijZRC5bJV5jYrLs:w
          JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4 BiSoNHVpsVZW2F7rx2eQ59yQwKxzU5NvBcmKshCSUypi
          4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t
          FJnaiidSLXFweWkgbinxEHRykVHsnkzDcYbNDR3RF5LN:w
          C9jjhzojE16zJ296tEPinA35rB1okyMVspE7FnR4idMf:w
          F2zDmA4GLsHtSDtEAFo9wWr5VBHLXtZjYzhRoGybWsFM:w
          2484ax8f261sDW3YmAkeK1ggEDkN7aSrUNCnnz9FxRup:w
          ATSVbA98Ur5dzoVX4whLLm5kSfUS3cQr65EyTULUtmnU:w
          TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
          So11111111111111111111111111111111111111112 Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB
          Sysvar1nstructions1111111111111111111111111 J1to1yufRnoWn81KYg1XkTWzmKjnYSnmE2VY8DGUJ9Qv
          JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4 4cG31VNF9TzFinNc7BmnjhFvGjxkY3sCETVMtMgbrhPs
          9mYEd71VzXZoa8a3B3Zw5TG6C3N7qLRGnw2JdtocsrrS
          """,
        ),
        closeWsolAccount,
      ]);

      expectPlainCard(decoded, [
        ...createAccountRows(3, wsolMint, capturedWsolAccount),
        ...createAccountRows(4, usd1Mint, capturedUsd1Account),
        jupiterRow(5),
        ...closeWsolRows(6),
        "${S.current.wc_network_fee}: ~ 0.000105 SOL",
      ]);
    });

    test("SOL to USDC through the default route shows the same wrap and unwrap", () async {
      final decoded = await decodeCaptured([
        computeLimit,
        computePrice,
        createWsolAccount,
        fundWsolAccount,
        syncWsolAccount,
        captured(
          jupiter,
          "e517cb977ae3ad2a01000000cd0164000180b2e60e00000000715a140100000000320000",
          """
          TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
          4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t:s
          2484ax8f261sDW3YmAkeK1ggEDkN7aSrUNCnnz9FxRup:w
          3hxeFuNcMTKQmzvUMFyc8fEdsi4vd7za4FURD3Ra1gU3:w
          JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4 EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
          JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4 D8cy77BBepLMngZx6ZukaTff5hCt1HrWyKk3Hnd9oitf
          JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4 BiSoNHVpsVZW2F7rx2eQ59yQwKxzU5NvBcmKshCSUypi
          4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t
          8FnX3xo2yYw3EUE6w3nQA4GfXGS9wpK6oj3veJpbFzLo:w
          ATRsNGv2nDw7hSMfkUTBoVUDsFDwN7po7KbecyiGWNB4:w
          2Y7HATmn9aJBcxCskE5V2U2epmjvkZmB51zTJBbhj4cU:w
          2484ax8f261sDW3YmAkeK1ggEDkN7aSrUNCnnz9FxRup:w
          3hxeFuNcMTKQmzvUMFyc8fEdsi4vd7za4FURD3Ra1gU3:w
          TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
          So11111111111111111111111111111111111111112 EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
          Sysvar1nstructions1111111111111111111111111 J1to1yufRnoWn81KYg1XkTWzmKjnYSnmE2VY8DGUJ9Qv
          JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4 4cG31VNF9TzFinNc7BmnjhFvGjxkY3sCETVMtMgbrhPs
          9mYEd71VzXZoa8a3B3Zw5TG6C3N7qLRGnw2JdtocsrrS
          """,
        ),
        closeWsolAccount,
      ]);

      expectPlainCard(decoded, [
        ...createAccountRows(3, wsolMint, capturedWsolAccount),
        ...wrapRows(4),
        jupiterRow(6),
        ...closeWsolRows(7),
        "${S.current.wc_network_fee}: ~ 0.000105 SOL",
      ]);
    });
  });
}

typedef AnyWallet = WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>;

class FakeSolanaNode extends Fake implements Solana {
  FakeSolanaNode({required this.latency, required this.accounts});

  final Duration latency;
  final Map<String, List<int>> accounts;
  final accountLookups = <String>[];
  final tokenLookups = <String>[];

  @override
  Future<List<List<int>?>?> getAccountsData(AnyWallet wallet, List<String> addresses) async {
    accountLookups.addAll(addresses);
    await Future<void>.delayed(latency);
    return [for (final address in addresses) accounts[address]];
  }

  @override
  Future<CryptoCurrency?> getSPLToken(AnyWallet wallet, String contractAddress) async {
    tokenLookups.add(contractAddress);
    return const CryptoCurrency(title: "TKN", name: "tkn", decimals: 6);
  }

  @override
  List<CryptoCurrency> getSPLTokenCurrencies(AnyWallet wallet) => const [];

  @override
  List<SPLToken> getDefaultSPLTokens() => const [];
}

class WalletOnlyAppStore extends Fake implements AppStore {
  @override
  AnyWallet? wallet = FakeWallet();
}

class FakeWallet extends Fake implements AnyWallet {}
