import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/ata_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/memo_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/sol_instruction_bytes.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_account_fetcher.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_lookup_budget.dart";
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

  final resolver = SplTokenResolver(null, SolanaLookupBudget());
  final noWalletFetcher = SolanaAccountFetcher(null, SolanaLookupBudget());
  const source = "96FHuHDcv9FL55qhoBoUGAmxZg9XM47fBM3t2vdefGW2";
  const dest = "23XoPQqGw9WMsLoqTu8HMzJLD6RnXsufbKyWPLJywsCT";
  const mint = "AsotAq6Hb5KW6bAExHq2hJctDNuErLEjaVSaR4yJ5WEj";
  const authority = "EWXF1h46ahk9i4c768wRCxxWjR7eEDs3PAvFwms95hqf";
  const wallet = "4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t";
  const attacker = "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU";
  const attackerMint = "6nMF76wKdFZaE78eRRDcNikVw1jMKMC4zoj7ibq1N25f";
  const newOwnerProgram = "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1";
  const seedBase = "GThUX1Atko4tqhN2NaiTazWSeFWMuiUvfFnyJyUghFMJ";
  const nonceAccount = "5Q544fKrFoe6tsEbD7S8EmxGTJYAKtTVhAW5Q5pge4j1";
  const recentBlockhashesSysvar = "SysvarRecentB1ockHashes11111111111111111111";

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
    const decoder = SystemProgramDecoder();

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

    test("create account shows the funding, the new account and the program that owns it", () {
      final created = decoder.decode(
        data: [
          ...u32Le(0),
          ...u64Le(BigInt.from(2039280)),
          ...u64Le(BigInt.from(165)),
          ...SolAddress(newOwnerProgram).toBytes(),
        ],
        accounts: [wallet, dest],
      );
      expect(created!.title, S.current.wc_action_create_account);
      expect(rowValue(created.rows, S.current.wc_amount), "0.00203928 SOL");
      expect(rowValue(created.rows, S.current.wc_new_account), dest);
      expect(rowValue(created.rows, S.current.wc_owner), newOwnerProgram);
      expect(decoder.decode(data: u32Le(9), accounts: [source, dest]), isNull);
    });

    test("create account with seed reads the lamports and the owner from after the seed", () {
      const seed = "vault";
      final created = decoder.decode(
        data: [
          ...u32Le(3),
          ...SolAddress(seedBase).toBytes(),
          ...u64Le(BigInt.from(seed.length)),
          ...seed.codeUnits,
          ...u64Le(BigInt.from(2039280)),
          ...u64Le(BigInt.from(165)),
          ...SolAddress(newOwnerProgram).toBytes(),
        ],
        accounts: [wallet, dest, wallet],
      );
      expect(rowValue(created!.rows, S.current.wc_amount), "0.00203928 SOL");
      expect(rowValue(created.rows, S.current.wc_new_account), dest);
      expect(rowValue(created.rows, S.current.wc_owner), newOwnerProgram);
    });

    test("create account cut short of its owner is not decoded", () {
      final created = decoder.decode(
        data: [...u32Le(0), ...u64Le(BigInt.from(2039280)), ...u64Le(BigInt.from(165))],
        accounts: [wallet, dest],
      );
      expect(created, isNull);
    });

    test("a transfer keeps its roles when the recipient is not resolved", () {
      final decoded = decoder.decode(
        data: [...u32Le(2), ...u64Le(BigInt.from(50000000000))],
        accounts: [wallet, null, wallet],
      );
      expect(rowValue(decoded!.rows, S.current.from), wallet);
      expect(rowValue(decoded.rows, S.current.to), S.current.wc_unresolved_account);
    });

    test("Assign names the program taking the account over and warns", () {
      final decoded = decoder.decode(
        data: [...u32Le(1), ...SolAddress(newOwnerProgram).toBytes()],
        accounts: [wallet],
      );
      expect(decoded!.title, S.current.wc_action_assign);
      expect(rowValue(decoded.rows, S.current.account), wallet);
      expect(rowValue(decoded.rows, S.current.wc_owner), newOwnerProgram);
      expect(decoded.warnings, [S.current.wc_warning_authority_change]);
    });

    test("AssignWithSeed reads the new owner from after the seed", () {
      const seed = "vault";
      final decoded = decoder.decode(
        data: [
          ...u32Le(10),
          ...SolAddress(seedBase).toBytes(),
          ...u64Le(BigInt.from(seed.length)),
          ...seed.codeUnits,
          ...SolAddress(newOwnerProgram).toBytes(),
        ],
        accounts: [source, wallet],
      );
      expect(decoded!.title, S.current.wc_action_assign);
      expect(rowValue(decoded.rows, S.current.account), source);
      expect(rowValue(decoded.rows, S.current.wc_owner), newOwnerProgram);
      expect(decoded.warnings, [S.current.wc_warning_authority_change]);
    });

    test("AssignWithSeed whose seed length runs past the data is not decoded", () {
      List<int> assignWithSeedLength(BigInt seedLength) => [
        ...u32Le(10),
        ...SolAddress(seedBase).toBytes(),
        ...u64Le(seedLength),
        ...SolAddress(newOwnerProgram).toBytes(),
      ];

      final beyondData = decoder.decode(
        data: assignWithSeedLength(BigInt.from(32)),
        accounts: [source, wallet],
      );
      expect(beyondData, isNull);

      final beyondInt = decoder.decode(
        data: assignWithSeedLength((BigInt.one << 64) - BigInt.one),
        accounts: [source, wallet],
      );
      expect(beyondInt, isNull);
    });

    test("TransferWithSeed is a send from the seeded account to the recipient", () {
      const seed = "vault";
      final decoded = decoder.decode(
        data: [
          ...u32Le(11),
          ...u64Le(BigInt.from(50000000000)),
          ...u64Le(BigInt.from(seed.length)),
          ...seed.codeUnits,
          ...SolAddress(newOwnerProgram).toBytes(),
        ],
        accounts: [source, wallet, attacker],
      );
      expect(decoded!.title, "${S.current.wc_action_send} 50 SOL");
      expect(rowValue(decoded.rows, S.current.wc_amount), "50 SOL");
      expect(rowValue(decoded.rows, S.current.from), source);
      expect(rowValue(decoded.rows, S.current.to), attacker);
    });

    test("WithdrawNonceAccount is a send from the nonce account to the recipient", () {
      final decoded = decoder.decode(
        data: [...u32Le(5), ...u64Le(BigInt.from(50000000000))],
        accounts: [nonceAccount, attacker, source, dest, wallet],
      );
      expect(decoded!.title, "${S.current.wc_action_send} 50 SOL");
      expect(rowValue(decoded.rows, S.current.from), nonceAccount);
      expect(rowValue(decoded.rows, S.current.to), attacker);
    });

    test("a send that stops short of its recipient account is not decoded", () {
      final transfer = [...u32Le(2), ...u64Le(BigInt.from(1000000000))];
      expect(decoder.decode(data: transfer, accounts: [wallet]), isNull);
      expect(decoder.decode(data: transfer, accounts: const []), isNull);

      final transferWithSeed = [...u32Le(11), ...u64Le(BigInt.from(1000000000))];
      expect(decoder.decode(data: transferWithSeed, accounts: [source, wallet]), isNull);
    });

    test("AdvanceNonceAccount names the nonce account and its authority", () {
      final decoded = decoder.decode(
        data: u32Le(4),
        accounts: [nonceAccount, recentBlockhashesSysvar, authority],
      );
      expect(decoded!.title, S.current.wc_action_advance_nonce);
      expect(rowValue(decoded.rows, S.current.wc_nonce_account), nonceAccount);
      expect(rowValue(decoded.rows, S.current.wc_nonce_authority), authority);
      expect(decoded.rows, hasLength(2));
    });

    test("AdvanceNonceAccount that stops short of its authority account is not decoded", () {
      final decoded = decoder.decode(
        data: u32Le(4),
        accounts: [nonceAccount, recentBlockhashesSysvar],
      );
      expect(decoded, isNull);
    });
  });

  group("SplTokenDecoder", () {
    final decoder = SplTokenDecoder(resolver, noWalletFetcher);

    test("transferChecked uses the carried decimals", () async {
      final decoded = await decoder.decode(
        data: [12, ...u64Le(BigInt.from(5000000)), 6],
        accounts: [source, mint, dest, authority],
        wallet: wallet,
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
        wallet: wallet,
      );
      expect(decoded!.rows.any((r) => r.value == "123456"), isTrue);
      expect(decoded.warnings, contains(S.current.wc_warning_raw_token_amount));
    });

    test("burn and close decode their accounts", () async {
      final burn = await decoder.decode(
        data: [8, ...u64Le(BigInt.from(9))],
        accounts: [source, mint, authority],
        wallet: wallet,
      );
      expect(burn!.title, S.current.wc_action_burn);

      final close = await decoder.decode(
        data: [9],
        accounts: [source, wallet, authority],
        wallet: wallet,
      );
      expect(close!.title, S.current.wc_action_close_token_account);
      expect(close.warnings, isEmpty);
    });

    test("closing an account to someone else warns that the funds leave the wallet", () async {
      final close = await decoder.decode(
        data: [9],
        accounts: [source, attacker, wallet],
        wallet: wallet,
      );
      expect(rowValue(close!.rows, S.current.to), attacker);
      expect(close.warnings, [S.current.wc_warning_recipient_not_you]);
    });

    test("SyncNative is shown as wrapping SOL into the token account", () async {
      final decoded = await decoder.decode(data: [17], accounts: [source], wallet: wallet);
      expect(decoded!.title, S.current.wc_action_wrap("SOL"));
      expect(rowValue(decoded.rows, S.current.wc_token_account), source);
      expect(decoded.warnings, isEmpty);
    });

    test("SetAuthority shows the account, the authority handed over and who gets it", () async {
      final decoded = await decoder.decode(
        data: [6, 2, 1, ...SolAddress(attacker).toBytes()],
        accounts: [source, wallet],
        wallet: wallet,
      );
      expect(decoded!.title, S.current.wc_action_set_authority);
      expect(rowValue(decoded.rows, S.current.account), source);
      expect(rowValue(decoded.rows, S.current.type), "AccountOwner");
      expect(rowValue(decoded.rows, S.current.wc_new_authority), attacker);
      expect(decoded.warnings, [S.current.wc_warning_authority_change]);
    });

    test("SetAuthority that removes an authority shows none", () async {
      final decoded = await decoder.decode(
        data: [6, 0, 0],
        accounts: [mint, wallet],
        wallet: wallet,
      );
      expect(rowValue(decoded!.rows, S.current.type), "MintTokens");
      expect(rowValue(decoded.rows, S.current.wc_new_authority), S.current.settings_none);
    });

    test("SetAuthority cut short of its new authority is not decoded", () async {
      final decoded = await decoder.decode(
        data: [6, 2, 1, ...SolAddress(attacker).toBytes().sublist(0, 31)],
        accounts: [source, wallet],
        wallet: wallet,
      );
      expect(decoded, isNull);
    });

    test("an SPL transfer keeps its roles when the source is not resolved", () async {
      final decoded = await decoder.decode(
        data: [3, ...u64Le(BigInt.from(1000000))],
        accounts: [null, attacker, wallet],
        wallet: wallet,
      );
      expect(rowValue(decoded!.rows, S.current.from), S.current.wc_unresolved_account);
      expect(rowValue(decoded.rows, S.current.to), attacker);
    });

    test("an approval keeps its roles when the delegate is not resolved", () async {
      final decoded = await decoder.decode(
        data: [4, ...u64Le((BigInt.one << 64) - BigInt.one)],
        accounts: [source, null, wallet],
        wallet: wallet,
      );
      expect(
        rowValue(decoded!.rows, S.current.wc_approved_spender),
        S.current.wc_unresolved_account,
      );
      expect(decoded.warnings, contains(S.current.wc_warning_unlimited_approval));
    });

    test("a checked transfer of an unresolved mint says so in the token row", () async {
      final decoded = await decoder.decode(
        data: [12, ...u64Le(BigInt.from(5000000)), 6],
        accounts: [source, null, dest, authority],
        wallet: wallet,
      );
      expect(rowValue(decoded!.rows, S.current.wc_token), S.current.wc_unresolved_account);
      expect(rowValue(decoded.rows, S.current.wc_amount), "5");
    });
  });

  group("mints the wallet does not know", () {
    const spoofed = CryptoCurrency(title: "USDT", name: "usdt", decimals: 6);
    final spoofedResolver = StubSplResolver(byMint: {attackerMint: spoofed}, known: const {});

    test("a checked transfer shows the mint address and warns despite resolved metadata", () async {
      final decoded = await SplTokenDecoder(spoofedResolver, noWalletFetcher).decode(
        data: [12, ...u64Le(BigInt.from(1000000000)), 6],
        accounts: [source, attackerMint, dest, authority],
        wallet: wallet,
      );
      expect(rowValue(decoded!.rows, S.current.wc_token), attackerMint);
      expect(rowValue(decoded.rows, S.current.wc_amount), "1000 6nMF…N25f");
      expect(decoded.warnings, [S.current.wc_warning_unknown_token]);
    });

    test("an untagged transfer shows the mint address read from the source account", () async {
      final fetcher = StubAccountFetcher({
        source: [...SolAddress(attackerMint).toBytes(), ...List.filled(133, 0)],
      });
      final decoded = await SplTokenDecoder(spoofedResolver, fetcher).decode(
        data: [3, ...u64Le(BigInt.from(1000000000))],
        accounts: [source, dest, authority],
        wallet: wallet,
      );
      expect(rowValue(decoded!.rows, S.current.wc_token), attackerMint);
      expect(rowValue(decoded.rows, S.current.wc_amount), "1000 6nMF…N25f");
      expect(decoded.warnings, [S.current.wc_warning_unknown_token]);
    });

    test("a checked transfer of a mint the wallet does not know skips the token lookup", () async {
      final counting = CountingSplResolver(byMint: {attackerMint: spoofed}, known: const {});
      final decoded = await SplTokenDecoder(counting, noWalletFetcher).decode(
        data: [13, ...u64Le(BigInt.from(1000000000)), 6],
        accounts: [source, attackerMint, dest, authority],
        wallet: wallet,
      );
      expect(rowValue(decoded!.rows, S.current.wc_amount), "1000 6nMF…N25f");
      expect(counting.lookedUp, isEmpty);
    });

    test("an untagged transfer of such a mint still needs the lookup for its decimals", () async {
      final counting = CountingSplResolver(byMint: {attackerMint: spoofed}, known: const {});
      final fetcher = StubAccountFetcher({
        source: [...SolAddress(attackerMint).toBytes(), ...List.filled(133, 0)],
      });
      final decoded = await SplTokenDecoder(counting, fetcher).decode(
        data: [3, ...u64Le(BigInt.from(1000000000))],
        accounts: [source, dest, authority],
        wallet: wallet,
      );
      expect(rowValue(decoded!.rows, S.current.wc_amount), "1000 6nMF…N25f");
      expect(counting.lookedUp, [attackerMint]);
    });

    test("creating a token account shows the mint address instead of the symbol", () async {
      final decoded = await AtaDecoder(
        spoofedResolver,
      ).decode(data: const [1], accounts: [wallet, dest, wallet, attackerMint], wallet: wallet);
      expect(rowValue(decoded!.rows, S.current.wc_token), attackerMint);
    });
  });

  group("SPL approvals and supply", () {
    final decoder = SplTokenDecoder(
      StubSplResolver(
        byMint: {mint: const CryptoCurrency(title: "JUP", name: "jup", decimals: 6)},
      ),
      noWalletFetcher,
    );

    test("approveChecked names the token, amount and delegate", () async {
      final decoded = await decoder.decode(
        data: [13, ...u64Le(BigInt.from(1500000)), 6],
        accounts: [source, mint, dest, authority],
        wallet: wallet,
      );
      expect(decoded!.title, S.current.wc_action_approve);
      expect(rowValue(decoded.rows, S.current.wc_amount), "1.5 JUP");
      expect(rowValue(decoded.rows, S.current.wc_token_account), source);
      expect(rowValue(decoded.rows, S.current.wc_approved_spender), dest);
      expect(decoded.warnings, isEmpty);
    });

    test("checked amounts use the decimals the instruction carries, not the token's", () async {
      final transfer = await decoder.decode(
        data: [12, ...u64Le(BigInt.from(5000000000)), 9],
        accounts: [source, mint, dest, authority],
        wallet: wallet,
      );
      expect(rowValue(transfer!.rows, S.current.wc_amount), "5 JUP");

      final approval = await decoder.decode(
        data: [13, ...u64Le(BigInt.from(5000000000)), 9],
        accounts: [source, mint, dest, authority],
        wallet: wallet,
      );
      expect(rowValue(approval!.rows, S.current.wc_amount), "5 JUP");
    });

    test("burn names the token and amount from the mint in its second account", () async {
      final decoded = await decoder.decode(
        data: [8, ...u64Le(BigInt.from(2500000))],
        accounts: [source, mint, authority],
        wallet: wallet,
      );
      expect(decoded!.title, S.current.wc_action_burn);
      expect(rowValue(decoded.rows, S.current.wc_token), "JUP");
      expect(rowValue(decoded.rows, S.current.wc_amount), "2.5 JUP");
      expect(decoded.warnings, isEmpty);
    });

    test("revoke names the account losing its delegate", () async {
      final decoded = await decoder.decode(
        data: [5],
        accounts: [source, authority],
        wallet: wallet,
      );
      expect(decoded!.title, S.current.wc_action_revoke_approval);
      expect(decoded.rows.single.value, source);
    });

    test("mintTo shows the minted amount and destination", () async {
      final decoded = await decoder.decode(
        data: [7, ...u64Le(BigInt.from(2000000))],
        accounts: [mint, dest, authority],
        wallet: wallet,
      );
      expect(decoded!.title, S.current.wc_action_mint);
      expect(decoded.rows.any((r) => r.value == "2 JUP"), isTrue);
      expect(decoded.rows.any((r) => r.value == dest), isTrue);
    });

    test("an untagged approve without account data stays raw and warns", () async {
      final decoded = await decoder.decode(
        data: [4, ...u64Le(BigInt.from(777))],
        accounts: [source, dest, authority],
        wallet: wallet,
      );
      expect(decoded!.rows.any((r) => r.value == "777"), isTrue);
      expect(rowValue(decoded.rows, S.current.wc_token_account), source);
      expect(rowValue(decoded.rows, S.current.wc_approved_spender), dest);
      expect(decoded.warnings, contains(S.current.wc_warning_raw_token_amount));
    });

    test("an untagged transfer resolves its mint from the source account", () async {
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
        wallet: wallet,
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
        wallet: wallet,
      );
      expect(fetcher.fetchCalls, 1, reason: "one lookup, not one per account");
    });

    test("an account shorter than a mint is treated as unresolvable", () async {
      final fetcher = StubAccountFetcher({source: List.filled(8, 0)});
      final withFetcher = SplTokenDecoder(StubSplResolver(), fetcher);
      final decoded = await withFetcher.decode(
        data: [3, ...u64Le(BigInt.from(64))],
        accounts: [source, dest, authority],
        wallet: wallet,
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
        wallet: wallet,
      );
      expect(decoded!.rows.any((r) => r.value == "12"), isTrue);
      expect(decoded.warnings, contains(S.current.wc_warning_raw_token_amount));
    });
  });

  test("AtaDecoder titles a plain create", () async {
    final decoded = await AtaDecoder(
      resolver,
    ).decode(data: const [], accounts: [source, dest, authority, mint], wallet: wallet);
    expect(decoded!.title, S.current.wc_action_create_token_account);
  });

  test("AtaDecoder does not read RecoverNested as a create", () async {
    final decoded = await AtaDecoder(resolver).decode(
      data: const [2],
      accounts: [source, dest, authority, mint, source, dest, authority],
      wallet: wallet,
    );
    expect(decoded, isNull);
  });

  test("AtaDecoder rejects a truncated account list", () async {
    final decoded = await AtaDecoder(
      resolver,
    ).decode(data: const [1], accounts: [source, dest], wallet: wallet);
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
      wallet: wallet,
    );
    expect(decoded!.title, S.current.wc_action_create_token_account_idempotent);
    expect(decoded.rows.any((r) => r.value == authority), isTrue);
  });

  group("who pays for a new token account", () {
    final decoder = AtaDecoder(resolver);

    test("the wallet paying for someone else's account warns that SOL leaves it", () async {
      final decoded = await decoder.decode(
        data: const [1],
        accounts: [wallet, dest, attacker, mint],
        wallet: wallet,
      );
      expect(rowValue(decoded!.rows, S.current.wc_owner), attacker);
      expect(decoded.warnings, [S.current.wc_warning_recipient_not_you]);
    });

    test("the wallet paying for its own account does not warn", () async {
      final decoded = await decoder.decode(
        data: const [1],
        accounts: [wallet, dest, wallet, mint],
        wallet: wallet,
      );
      expect(decoded!.warnings, isEmpty);
    });

    test("someone else paying for their own account does not warn", () async {
      final decoded = await decoder.decode(
        data: const [1],
        accounts: [attacker, dest, attacker, mint],
        wallet: wallet,
      );
      expect(decoded!.warnings, isEmpty);
    });
  });

  group("SplTokenResolver.isKnown", () {
    const enabledMint = "5ipEofiHQt2z9EXBZZMbMLcgeD6SFRFGKfQgfo65PKCc";
    const disabledMint = "8vdCZ5Ks2TcgAfJjE7q9RKdBt1A9dWPM7fKQPFaC3Z3E";
    const flaggedMint = "45HT9JFxtNEEKAQ9abyCSf663eZfMAzxUtq2ppsnkKBo";
    const usdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v";
    const wsolMint = "So11111111111111111111111111111111111111112";

    final walletList = WalletListResolver(const {
      enabledMint: CryptoCurrency(title: "GOOD", name: "good", decimals: 6, enabled: true),
      disabledMint: CryptoCurrency(title: "OFF", name: "off", decimals: 6),
      flaggedMint: CryptoCurrency(
        title: "USDT",
        name: "usdt",
        decimals: 6,
        enabled: true,
        isPotentialScam: true,
      ),
    });

    test("an enabled wallet token that is not flagged is known", () {
      expect(walletList.isKnown(enabledMint), isTrue);
    });

    test("a wallet token the user has not enabled is not known", () {
      expect(walletList.isKnown(disabledMint), isFalse);
    });

    test("a wallet token flagged as a potential scam is not known", () {
      expect(walletList.isKnown(flaggedMint), isFalse);
    });

    test("a mint in neither list is not known", () {
      expect(walletList.isKnown(attackerMint), isFalse);
    });

    test("a default token and wrapped SOL are known without being in the wallet list", () {
      expect(walletList.isKnown(usdcMint), isTrue);
      expect(walletList.isKnown(wsolMint), isTrue);
    });
  });
}

class CountingSplResolver extends StubSplResolver {
  CountingSplResolver({super.byMint, super.known});

  final lookedUp = <String>[];

  @override
  Future<CryptoCurrency?> resolve(String mintAddress) {
    lookedUp.add(mintAddress);
    return super.resolve(mintAddress);
  }
}

class WalletListResolver extends SplTokenResolver {
  WalletListResolver(this.walletTokens) : super(null, SolanaLookupBudget());

  final Map<String, CryptoCurrency> walletTokens;

  @override
  Iterable<CryptoCurrency> walletKnownTokens() => walletTokens.values;

  @override
  String? mintAddressFor(CryptoCurrency token) {
    for (final entry in walletTokens.entries) {
      if (identical(entry.value, token)) {
        return entry.key;
      }
    }
    return super.mintAddressFor(token);
  }
}
