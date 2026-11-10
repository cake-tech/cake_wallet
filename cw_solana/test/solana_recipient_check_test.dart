import "dart:convert";

import "package:cw_solana/solana_recipient_check.dart";
import "package:flutter_test/flutter_test.dart";
import "package:on_chain/solana/solana.dart";

final usdc = SolAddress("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v");
final usdt = SolAddress("Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB");
final tokenProgram = SPLTokenProgramConst.tokenProgramId;
final token2022 = SPLTokenProgramConst.token2022ProgramId;
final squadsV4 = SolAddress("SQDS4ep65T869zMMBKyuUq6aD6EgTu8psMjkvj52pCf");
final stakeProgram = SolAddress("Stake11111111111111111111111111111111111111");
final bpfLoaderUpgradeable = SolAddress("BPFLoaderUpgradeab1e11111111111111111111111");

/// An RPC `getAccountInfo` result, with data sliced the way `_classifyRecipient` requests it.
SolanaAccountInfo account({
  required SolAddress owner,
  required int space,
  List<int> data = const [],
  bool executable = false,
}) =>
    SolanaAccountInfo(
      executable: executable,
      lamports: BigInt.from(2039280),
      owner: owner,
      rentEpoch: 0,
      space: space,
      data: [
        base64.encode(data.take(SolanaRecipientCheck.dataSliceLength).toList()),
        "base64",
      ],
    );

/// SPL token account bytes: mint (0-31) | owner (32-63) | ... ; Token-2022 extensions append
/// the account type at byte 165.
List<int> tokenAccountData(SolAddress mint, {int extraBytes = 0, int? accountType}) {
  final data = List<int>.filled(SolanaRecipientCheck.tokenAccountSize + extraBytes, 0);
  data.setRange(0, 32, mint.toBytes());
  if (accountType != null) data[165] = accountType;
  return data;
}

SolanaRecipientKind classify(SolanaAccountInfo? info, {SolAddress? program}) =>
    SolanaRecipientCheck.classify(info: info, mint: usdc, tokenProgramId: program ?? tokenProgram);

void main() {
  group("sends to the ATA (wallet)", () {
    test("no account yet: new wallet without SOL, or an unfunded vault PDA", () {
      expect(classify(null), SolanaRecipientKind.wallet);
    });

    test("System-owned: a normal wallet, or a funded vault PDA", () {
      final info = account(owner: SystemProgramConst.programId, space: 0);
      expect(classify(info), SolanaRecipientKind.wallet);
    });
  });

  group("sends directly to the pasted token account", () {
    test("SPL token account of the mint being sent", () {
      final info = account(owner: tokenProgram, space: 165, data: tokenAccountData(usdc));
      expect(classify(info), SolanaRecipientKind.tokenAccountForMint);
    });

    test("Token-2022 account with extensions (account type 2 at byte 165)", () {
      final data = tokenAccountData(usdc, extraBytes: 5, accountType: 2);
      final info = account(owner: token2022, space: 170, data: data);
      expect(classify(info, program: token2022), SolanaRecipientKind.tokenAccountForMint);
    });
  });

  group("refuses (not a wallet)", () {
    test("token account of a different mint", () {
      final info = account(owner: tokenProgram, space: 165, data: tokenAccountData(usdt));
      expect(classify(info), SolanaRecipientKind.notAWallet);
    });

    test("right mint, but under the other token program", () {
      final info = account(owner: tokenProgram, space: 165, data: tokenAccountData(usdc));
      expect(classify(info, program: token2022), SolanaRecipientKind.notAWallet);
    });

    test("a mint (82 bytes), even if its first 32 bytes matched", () {
      final data = List<int>.filled(82, 0)..setRange(0, 32, usdc.toBytes());
      final info = account(owner: tokenProgram, space: 82, data: data);
      expect(classify(info), SolanaRecipientKind.notAWallet);
    });

    test("Token-2022 mint with extensions (account type 1 at byte 165)", () {
      final data = tokenAccountData(usdc, extraBytes: 69, accountType: 1);
      final info = account(owner: token2022, space: 234, data: data);
      expect(classify(info, program: token2022), SolanaRecipientKind.notAWallet);
    });

    test("multisig settings account (owned by the Squads program)", () {
      final info = account(owner: squadsV4, space: 1000, data: List<int>.filled(1000, 7));
      expect(classify(info), SolanaRecipientKind.notAWallet);
    });

    test("stake account", () {
      expect(classify(account(owner: stakeProgram, space: 200)), SolanaRecipientKind.notAWallet);
    });

    test("a program", () {
      final info = account(owner: bpfLoaderUpgradeable, space: 36, executable: true);
      expect(classify(info), SolanaRecipientKind.notAWallet);
    });

    test("token-program account whose data can't be decoded", () {
      final info = SolanaAccountInfo(
        executable: false,
        lamports: BigInt.one,
        owner: tokenProgram,
        rentEpoch: 0,
        space: 165,
        data: ["not base64!", "base64"],
      );
      expect(classify(info), SolanaRecipientKind.notAWallet);
    });
  });
}
