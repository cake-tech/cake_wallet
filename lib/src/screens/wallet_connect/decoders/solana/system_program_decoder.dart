import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/sol_instruction_bytes.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/format_fixed.dart";

class SolDecodedInstruction {
  const SolDecodedInstruction({
    required this.title,
    this.rows = const [],
    this.warnings = const [],
  });

  final String title;
  final List<WCDecodedRow> rows;
  final List<String> warnings;

  static WCDecodedRow accountRow(String label, String? account) => WCDecodedRow(
    label: label,
    value: account ?? S.current.wc_unresolved_account,
    kind: WCDecodedRowKind.address,
  );

  static WCDecodedRow tokenRow(SplTokenResolver resolver, CryptoCurrency? token, String? mint) =>
      mint != null && token != null && resolver.isKnown(mint)
      ? WCDecodedRow(label: S.current.wc_token, value: resolver.symbolFor(token, mint))
      : accountRow(S.current.wc_token, mint);
}

class SystemProgramDecoder {
  const SystemProgramDecoder();

  static const advanceNonceAccountTag = 4;
  static const nonceAuthorityPosition = 2;

  static const _recipientPositions = {2: 1, 5: 1, 11: 2};

  static String formatSol(BigInt lamports) => formatFixed(lamports, 9);

  SolDecodedInstruction? decode({required List<int> data, required List<String?> accounts}) {
    final bytes = SolInstructionBytes(data);
    final instructionTag = bytes.u32Le(0);
    if (instructionTag == null) {
      return null;
    }

    final recipientPosition = _recipientPositions[instructionTag];
    if (recipientPosition != null) {
      final lamports = bytes.u64Le(4);
      if (lamports == null || accounts.length <= recipientPosition) {
        return null;
      }
      return SolDecodedInstruction(
        title: "${S.current.wc_action_send} ${formatSol(lamports)} SOL",
        rows: [
          _solAmountRow(lamports),
          SolDecodedInstruction.accountRow(S.current.from, accounts[0]),
          SolDecodedInstruction.accountRow(S.current.to, accounts[recipientPosition]),
        ],
      );
    }

    if (instructionTag == advanceNonceAccountTag) {
      if (accounts.length <= nonceAuthorityPosition) {
        return null;
      }
      return SolDecodedInstruction(
        title: S.current.wc_action_advance_nonce,
        rows: [
          SolDecodedInstruction.accountRow(S.current.wc_nonce_account, accounts[0]),
          SolDecodedInstruction.accountRow(
            S.current.wc_nonce_authority,
            accounts[nonceAuthorityPosition],
          ),
        ],
      );
    }

    if (instructionTag == 0 || instructionTag == 3) {
      final lamportsOffset = instructionTag == 0 ? 4 : _offsetAfterSeed(bytes);
      final lamports = lamportsOffset == null ? null : bytes.u64Le(lamportsOffset);
      final owner = lamportsOffset == null ? null : bytes.address(lamportsOffset + 16);
      if (lamports == null || owner == null || accounts.length < 2) {
        return null;
      }
      return SolDecodedInstruction(
        title: S.current.wc_action_create_account,
        rows: [
          _solAmountRow(lamports),
          SolDecodedInstruction.accountRow(S.current.wc_new_account, accounts[1]),
          SolDecodedInstruction.accountRow(S.current.wc_owner, owner),
        ],
      );
    }

    if (instructionTag == 1 || instructionTag == 10) {
      final ownerOffset = instructionTag == 1 ? 4 : _offsetAfterSeed(bytes);
      final owner = ownerOffset == null ? null : bytes.address(ownerOffset);
      if (owner == null || accounts.isEmpty) {
        return null;
      }
      return SolDecodedInstruction(
        title: S.current.wc_action_assign,
        rows: [
          SolDecodedInstruction.accountRow(S.current.account, accounts[0]),
          SolDecodedInstruction.accountRow(S.current.wc_owner, owner),
        ],
        warnings: [S.current.wc_warning_authority_change],
      );
    }

    return null;
  }

  int? _offsetAfterSeed(SolInstructionBytes bytes) {
    final seedLength = bytes.u64Le(36);
    if (seedLength == null || seedLength > BigInt.from(_maxSeedLength)) {
      return null;
    }
    return 44 + seedLength.toInt();
  }

  static const _maxSeedLength = 32;

  WCDecodedRow _solAmountRow(BigInt lamports) => WCDecodedRow(
    label: S.current.wc_amount,
    value: "${formatSol(lamports)} SOL",
    kind: WCDecodedRowKind.amount,
  );
}
