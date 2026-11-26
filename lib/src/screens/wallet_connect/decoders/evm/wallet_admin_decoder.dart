import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";

class WalletAdminDecoder {
  WCDecodedRequest decodeSwitchChain(ChainInfo chain, {String? reason}) => WCDecodedRequest(
    actionTitle: S.current.wc_action_switch_chain,
    actionSubtitle: reason ?? chain.name,
    rows: [
      WCDecodedRow(label: S.current.wc_target_chain, value: chain.name),
      WCDecodedRow(label: S.current.wc_target_chain_id, value: chain.chainId.toString()),
    ],
  );

  int? extractChainId(dynamic params) {
    final config = params is List && params.isNotEmpty ? params.first : params;
    if (config is! Map) {
      return null;
    }

    return int.tryParse(config["chainId"]?.toString() ?? "");
  }
}
