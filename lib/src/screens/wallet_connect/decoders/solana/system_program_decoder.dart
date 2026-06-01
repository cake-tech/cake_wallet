import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/solana/sol_instruction_bytes.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_resolver.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart';

class SolDecodedInstruction {
  const SolDecodedInstruction({
    required this.title,
    this.rows = const [],
    this.warnings = const [],
  });

  final String title;
  final List<WCDecodedRow> rows;
  final List<String> warnings;
}

class SystemProgramDecoder {
  SystemProgramDecoder(this.resolver);

  final SplTokenResolver resolver;

  SolDecodedInstruction? decode({
    required List<int> data,
    required List<String> accounts,
  }) {
    final bytes = SolInstructionBytes(data);
    final instructionTag = bytes.u32Le(0);
    if (instructionTag == null) return null;

    if (instructionTag == 2) {
      final lamports = bytes.u64Le(4);
      if (lamports == null || accounts.length < 2) return null;
      final from = accounts[0];
      final to = accounts[1];
      return SolDecodedInstruction(
        title: '${S.current.wc_action_send} ${resolver.formatSol(lamports)} SOL',
        rows: [
          WCDecodedRow(
            label: S.current.wc_amount,
            value: '${resolver.formatSol(lamports)} SOL',
            kind: WCDecodedRowKind.amount,
          ),
          WCDecodedRow(
            label: S.current.from,
            value: from,
            kind: WCDecodedRowKind.address,
          ),
          WCDecodedRow(
            label: S.current.to,
            value: to,
            kind: WCDecodedRowKind.address,
          ),
        ],
      );
    }

    if (instructionTag == 0) {
      if (accounts.length < 2) return null;
      return SolDecodedInstruction(
        title: S.current.wc_action_create_account,
        rows: [
          WCDecodedRow(
            label: S.current.wc_new_account,
            value: accounts[1],
            kind: WCDecodedRowKind.address,
          ),
        ],
      );
    }

    return null;
  }
}
