import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/ata_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/memo_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/sol_instruction_bytes.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_account_fetcher.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/system_program_decoder.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";
import "package:on_chain/solana/solana.dart";

import "abi_hex.dart";
import "stubs.dart";

void main() {
  setUpAll(() {
    S.current = const S();
  });

  final resolver = SplTokenResolver(null);
  const source = "So11111111111111111111111111111111111111112";
  const dest = "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr";
  const mint = "JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4";
  const authority = "ComputeBudget111111111111111111111111111111";

  group("SolInstructionBytes", () {
    test("reads little-endian values and nulls past the end", () {
      final bytes = SolInstructionBytes([2, 0, 0, 0, ...u64Le(BigInt.from(77))]);
      expect(bytes.u8(0), 2);
      expect(bytes.u32Le(0), 2);
      expect(bytes.u64Le(4), BigInt.from(77));
      expect(bytes.u64Le(5), isNull);
    });
  });

  group("SystemProgramDecoder", () {
    final decoder = SystemProgramDecoder(resolver);

    test("decodes a transfer with formatted SOL amount", () {
      final lamports = BigInt.from(1000000000);
      final decoded = decoder.decode(
        data: [...u32Le(2), ...u64Le(lamports)],
        accounts: [source, dest],
      );
      expect(decoded, isNotNull);
      expect(decoded!.title, contains("1 SOL"));
      expect(decoded.rows.any((r) => r.value == dest), isTrue);
    });

    test("decodes create account and ignores unknown tags", () {
      final created = decoder.decode(data: u32Le(0), accounts: [source, dest]);
      expect(created!.title, S.current.wc_action_create_account);
      expect(decoder.decode(data: u32Le(9), accounts: [source, dest]), isNull);
    });
  });

  group("SplTokenDecoder", () {
    final decoder = SplTokenDecoder(resolver, SolanaAccountFetcher(null));

    test("transferChecked uses the carried decimals", () async {
      final decoded = await decoder.decode(
        data: [12, ...u64Le(BigInt.from(5000000)), 6],
        accounts: [source, mint, dest, authority],
      );
      expect(decoded, isNotNull);
      expect(decoded!.title, S.current.wc_action_transfer);
      expect(decoded.rows.any((r) => r.value.startsWith("5 ")), isTrue);
      expect(decoded.warnings, contains(S.current.wc_warning_unknown_token));
    });

    test("untagged transfer without account data stays raw and warns", () async {
      final decoded = await decoder.decode(
        data: [3, ...u64Le(BigInt.from(123456))],
        accounts: [source, dest, authority],
      );
      expect(decoded!.rows.any((r) => r.value == "123456"), isTrue);
      expect(decoded.warnings, contains(S.current.wc_warning_raw_token_amount));
    });

    test("burn and close decode their accounts", () async {
      final burn = await decoder.decode(
        data: [8, ...u64Le(BigInt.from(9))],
        accounts: [source, mint, authority],
      );
      expect(burn!.title, S.current.wc_action_burn);

      final close = await decoder.decode(data: [9], accounts: [source, dest, authority]);
      expect(close!.title, S.current.wc_action_close_token_account);
    });
  });

  group("SPL approvals and supply", () {
    final decoder = SplTokenDecoder(
      StubSplResolver(byMint: {mint: const CryptoCurrency(title: "JUP", name: "jup", decimals: 6)}),
      SolanaAccountFetcher(null),
    );

    test("approveChecked names the token, amount and delegate", () async {
      final decoded = await decoder.decode(
        data: [13, ...u64Le(BigInt.from(1500000)), 6],
        accounts: [source, mint, dest, authority],
      );
      expect(decoded!.title, S.current.wc_action_approve);
      expect(decoded.rows.any((r) => r.value == "1.5 JUP"), isTrue);
      expect(decoded.rows.any((r) => r.value == dest), isTrue);
      expect(decoded.warnings, isEmpty);
    });

    test("revoke names the account losing its delegate", () async {
      final decoded = await decoder.decode(data: [5], accounts: [source, authority]);
      expect(decoded!.title, S.current.wc_action_revoke_approval);
      expect(decoded.rows.single.value, source);
    });

    test("mintTo shows the minted amount and destination", () async {
      final decoded = await decoder.decode(
        data: [7, ...u64Le(BigInt.from(2000000))],
        accounts: [mint, dest, authority],
      );
      expect(decoded!.title, S.current.wc_action_mint);
      expect(decoded.rows.any((r) => r.value == "2 JUP"), isTrue);
      expect(decoded.rows.any((r) => r.value == dest), isTrue);
    });

    test("an untagged approve without account data stays raw and warns", () async {
      final decoded = await decoder.decode(
        data: [4, ...u64Le(BigInt.from(777))],
        accounts: [source, dest, authority],
      );
      expect(decoded!.rows.any((r) => r.value == "777"), isTrue);
      expect(decoded.warnings, contains(S.current.wc_warning_raw_token_amount));
    });

    test("an untagged transfer resolves its mint from the source account", () async {
      // The first 32 bytes of an SPL token account are its mint.
      final mintBytes = SolAddress(mint).toBytes();
      final fetcher = StubAccountFetcher({
        source: [...mintBytes, ...List.filled(133, 0)],
      });
      final withFetcher = SplTokenDecoder(
        StubSplResolver(
          byMint: {mint: const CryptoCurrency(title: "JUP", name: "jup", decimals: 6)},
        ),
        fetcher,
      );
      final decoded = await withFetcher.decode(
        data: [3, ...u64Le(BigInt.from(4500000))],
        accounts: [source, dest, authority],
      );
      expect(fetcher.fetchCalls, 1);
      expect(decoded!.rows.any((r) => r.value == "4.5 JUP"), isTrue);
      expect(decoded.warnings, isEmpty, reason: "a resolved mint removes the raw-amount caveat");
    });

    test("only the source account is fetched, once, per untagged instruction", () async {
      final mintBytes = SolAddress(mint).toBytes();
      final fetcher = StubAccountFetcher({
        source: [...mintBytes, ...List.filled(133, 0)],
      });
      final withFetcher = SplTokenDecoder(
        StubSplResolver(
          byMint: {mint: const CryptoCurrency(title: "JUP", name: "jup", decimals: 6)},
        ),
        fetcher,
      );
      await withFetcher.decode(
        data: [3, ...u64Le(BigInt.from(1))],
        accounts: [source, dest, authority],
      );
      expect(fetcher.fetchCalls, 1, reason: "one lookup, not one per account");
    });

    test("an account shorter than a mint is treated as unresolvable", () async {
      final fetcher = StubAccountFetcher({source: List.filled(8, 0)});
      final withFetcher = SplTokenDecoder(StubSplResolver(), fetcher);
      final decoded = await withFetcher.decode(
        data: [3, ...u64Le(BigInt.from(64))],
        accounts: [source, dest, authority],
      );
      expect(decoded!.rows.any((r) => r.value == "64"), isTrue);
      expect(decoded.warnings, contains(S.current.wc_warning_raw_token_amount));
    });

    test("an unreadable source account keeps the raw amount", () async {
      final fetcher = StubAccountFetcher(const {});
      final withFetcher = SplTokenDecoder(StubSplResolver(), fetcher);
      final decoded = await withFetcher.decode(
        data: [3, ...u64Le(BigInt.from(12))],
        accounts: [source, dest, authority],
      );
      expect(decoded!.rows.any((r) => r.value == "12"), isTrue);
      expect(decoded.warnings, contains(S.current.wc_warning_raw_token_amount));
    });
  });

  test("AtaDecoder titles a plain create", () async {
    final decoded = await AtaDecoder(resolver).decode(
      data: const [],
      accounts: [source, dest, authority, mint],
    );
    expect(decoded!.title, S.current.wc_action_create_token_account);
  });

  test("AtaDecoder rejects a truncated account list", () async {
    final decoded = await AtaDecoder(resolver).decode(data: const [1], accounts: [source, dest]);
    expect(decoded, isNull);
  });

  test("MemoDecoder decodes utf8", () {
    final decoded = MemoDecoder().decode("hello memo".codeUnits);
    expect(decoded.rows.single.value, "hello memo");
  });

  test("AtaDecoder titles idempotent creates", () async {
    final decoder = AtaDecoder(resolver);
    final decoded = await decoder.decode(
      data: [1],
      accounts: [source, dest, authority, mint],
    );
    expect(decoded!.title, S.current.wc_action_create_token_account_idempotent);
    expect(decoded.rows.any((r) => r.value == authority), isTrue);
  });
}
