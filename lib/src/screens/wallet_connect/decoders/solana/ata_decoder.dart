import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/system_program_decoder.dart";

class AtaDecoder {
  AtaDecoder(this.resolver);

  final SplTokenResolver resolver;

  static const _createTags = {0, 1};

  Future<SolDecodedInstruction?> decode({
    required List<int> data,
    required List<String?> accounts,
    required String wallet,
  }) async {
    if (accounts.length < 4 || (data.isNotEmpty && !_createTags.contains(data.first))) {
      return null;
    }

    final isIdempotent = data.isNotEmpty && data.first == 1;
    final mint = accounts[3];
    final token = mint != null && resolver.isKnown(mint) ? await resolver.resolve(mint) : null;

    return SolDecodedInstruction(
      title: isIdempotent
          ? S.current.wc_action_create_token_account_idempotent
          : S.current.wc_action_create_token_account,
      rows: [
        SolDecodedInstruction.tokenRow(resolver, token, mint),
        SolDecodedInstruction.accountRow(S.current.wc_owner, accounts[2]),
        SolDecodedInstruction.accountRow(S.current.wc_token_account, accounts[1]),
      ],
      warnings: [
        if (accounts[0] == wallet && accounts[2] != wallet) S.current.wc_warning_recipient_not_you,
      ],
    );
  }
}
