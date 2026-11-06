import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";

class Erc721Decoder {
  Erc721Decoder(this.tokenResolver);

  final Erc20TokenResolver tokenResolver;

  WCDecodedRequest? decode({
    required EvmCalldata calldata,
    required String? contractAddress,
  }) {
    switch (calldata.selector) {
      case EvmSelectors.erc721SafeTransferFrom:
      case EvmSelectors.erc721SafeTransferFromData:
        return _decodeNftTransfer(calldata, contractAddress);
      case EvmSelectors.erc721SetApprovalForAll:
        return _decodeSetApprovalForAll(calldata, contractAddress);
    }
    return null;
  }

  WCDecodedRequest? _decodeNftTransfer(EvmCalldata calldata, String? contractAddress) {
    final fromAddr = calldata.addressAt(0);
    final toAddr = calldata.addressAt(1);
    final tokenId = calldata.uintAt(2);
    if (fromAddr == null || toAddr == null || tokenId == null) {
      return null;
    }

    final collection = contractAddress == null ? "?" : tokenResolver.shortAddress(contractAddress);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_nft_transfer,
      actionSubtitle: collection,
      rows: [
        WCDecodedRow(label: S.current.wc_token_id, value: "#$tokenId"),
        WCDecodedRow(
          label: S.current.from,
          value: fromAddr,
          kind: WCDecodedRowKind.address,
        ),
        WCDecodedRow(
          label: S.current.to,
          value: toAddr,
          kind: WCDecodedRowKind.address,
        ),
      ],
      hideTo: true,
    );
  }

  WCDecodedRequest? _decodeSetApprovalForAll(EvmCalldata calldata, String? contractAddress) {
    final operator = calldata.addressAt(0);
    final approved = calldata.boolAt(1);
    if (operator == null || approved == null) {
      return null;
    }

    final collection = contractAddress == null ? "?" : tokenResolver.shortAddress(contractAddress);

    return WCDecodedRequest(
      actionTitle: approved
          ? S.current.wc_action_set_approval_for_all
          : S.current.wc_action_revoke_approval_for_all,
      actionSubtitle: collection,
      rows: [
        WCDecodedRow(
          label: S.current.wc_operator,
          value: operator,
          kind: WCDecodedRowKind.address,
        ),
      ],
      warnings: approved ? [S.current.wc_warning_set_approval_for_all] : const [],
      hideTo: true,
    );
  }
}
