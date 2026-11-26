import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";

class Erc721Decoder {
  const Erc721Decoder();

  static const _argumentWords = {
    EvmSelectors.erc721SafeTransferFrom: 3,
    EvmSelectors.erc721SafeTransferFromData: 3,
    EvmSelectors.erc721SetApprovalForAll: 2,
  };

  WCDecodedRequest? decode({required EvmCalldata calldata, required String contractAddress}) {
    final padded = calldata.zeroPaddedTo(_argumentWords[calldata.selector] ?? 0);
    final decoded = _decodeCall(padded ?? calldata, contractAddress);
    if (decoded == null || padded == null) {
      return decoded;
    }
    return decoded.copyWith(warnings: [...decoded.warnings, S.current.wc_warning_decode_failed]);
  }

  WCDecodedRequest? _decodeCall(EvmCalldata calldata, String contractAddress) {
    switch (calldata.selector) {
      case EvmSelectors.erc721SafeTransferFrom:
      case EvmSelectors.erc721SafeTransferFromData:
        return _decodeNftTransfer(calldata, contractAddress);
      case EvmSelectors.erc721SetApprovalForAll:
        return _decodeSetApprovalForAll(calldata, contractAddress);
    }
    return null;
  }

  WCDecodedRequest? _decodeNftTransfer(EvmCalldata calldata, String contractAddress) {
    final sender = calldata.addressAt(0);
    final recipient = calldata.addressAt(1);
    final tokenId = calldata.uintAt(2);
    if (sender == null || recipient == null || tokenId == null) {
      return null;
    }

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_nft_transfer,
      actionSubtitle: shortAddress(contractAddress),
      rows: [
        WCDecodedRow(label: S.current.wc_token_id, value: "#$tokenId"),
        WCDecodedRow(label: S.current.from, value: sender, kind: WCDecodedRowKind.address),
        WCDecodedRow(label: S.current.to, value: recipient, kind: WCDecodedRowKind.address),
      ],
    );
  }

  WCDecodedRequest? _decodeSetApprovalForAll(EvmCalldata calldata, String contractAddress) {
    final operator = calldata.addressAt(0);
    final approval = calldata.uintAt(1);
    if (operator == null || approval == null) {
      return null;
    }
    final isApproved = approval != BigInt.zero;

    return WCDecodedRequest(
      actionTitle: isApproved
          ? S.current.wc_action_set_approval_for_all
          : S.current.wc_action_revoke_approval_for_all,
      actionSubtitle: shortAddress(contractAddress),
      rows: [
        WCDecodedRow(label: S.current.wc_operator, value: operator, kind: WCDecodedRowKind.address),
      ],
      warnings: isApproved ? [S.current.wc_warning_set_approval_for_all] : const [],
    );
  }
}
