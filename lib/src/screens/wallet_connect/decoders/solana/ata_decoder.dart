import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/system_program_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";

class AtaDecoder {
  AtaDecoder(this.resolver);

  final SplTokenResolver resolver;

  Future<SolDecodedInstruction?> decode({
    required List<int> data,
    required List<String> accounts,
  }) async {
    if (accounts.length < 4) {
      return null;
    }

    final isIdempotent = data.isNotEmpty && data.first == 1;
    final owner = accounts[2];
    final mint = accounts[3];
    final tokenAccount = accounts[1];

    final token = await resolver.resolve(mint);
    final symbol = resolver.symbolFor(token, mint);

    return SolDecodedInstruction(
      title: isIdempotent
          ? S.current.wc_action_create_token_account_idempotent
          : S.current.wc_action_create_token_account,
      rows: [
        WCDecodedRow(label: S.current.wc_token, value: symbol),
        WCDecodedRow(
          label: S.current.wc_owner,
          value: owner,
          kind: WCDecodedRowKind.address,
        ),
        WCDecodedRow(
          label: S.current.wc_token_account,
          value: tokenAccount,
          kind: WCDecodedRowKind.address,
        ),
      ],
    );
  }
}
