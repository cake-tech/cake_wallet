import "dart:convert";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/system_program_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";

class MemoDecoder {
  SolDecodedInstruction decode(List<int> data) {
    String memo;
    try {
      memo = utf8.decode(data);
    } catch (_) {
      memo = data.toString();
    }
    return SolDecodedInstruction(
      title: S.current.wc_action_memo,
      rows: [WCDecodedRow(label: S.current.wc_memo, value: memo)],
    );
  }
}
