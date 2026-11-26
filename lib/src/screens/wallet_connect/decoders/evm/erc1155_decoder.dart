import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";

class Erc1155Decoder {
  const Erc1155Decoder();

  WCDecodedRequest? decode({required EvmCalldata calldata, required String contractAddress}) {
    switch (calldata.selector) {
      case EvmSelectors.erc1155SafeTransferFrom:
        return _decodeSingle(calldata, contractAddress);
      case EvmSelectors.erc1155SafeBatchTransferFrom:
        return _decodeBatch(calldata, contractAddress);
    }
    return null;
  }

  WCDecodedRequest? _decodeSingle(EvmCalldata calldata, String contractAddress) {
    final padded = calldata.zeroPaddedTo(4);
    final arguments = padded ?? calldata;
    final sender = arguments.addressAt(0);
    final recipient = arguments.addressAt(1);
    final tokenId = arguments.uintAt(2);
    final amount = arguments.uintAt(3);
    if (sender == null || recipient == null || tokenId == null || amount == null) {
      return null;
    }

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_nft_transfer,
      actionSubtitle: shortAddress(contractAddress),
      rows: [
        WCDecodedRow(label: S.current.wc_token_id, value: "#$tokenId"),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: amount.toString(),
          kind: WCDecodedRowKind.amount,
        ),
        WCDecodedRow(label: S.current.from, value: sender, kind: WCDecodedRowKind.address),
        WCDecodedRow(label: S.current.to, value: recipient, kind: WCDecodedRowKind.address),
      ],
      warnings: [if (padded != null) S.current.wc_warning_decode_failed],
    );
  }

  WCDecodedRequest? _decodeBatch(EvmCalldata calldata, String contractAddress) {
    final sender = calldata.addressAt(0);
    final recipient = calldata.addressAt(1);
    if (sender == null || recipient == null) {
      return null;
    }

    final ids = calldata.uintArrayAt(2);
    final amounts = calldata.uintArrayAt(3);
    final isRead = ids != null && amounts != null && ids.length == amounts.length;

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_nft_batch_transfer,
      actionSubtitle: shortAddress(contractAddress),
      rows: [
        if (isRead)
          for (final (index, id) in ids.indexed)
            WCDecodedRow(label: S.current.wc_token_id, value: "#$id ×${amounts[index]}"),
        WCDecodedRow(label: S.current.from, value: sender, kind: WCDecodedRowKind.address),
        WCDecodedRow(label: S.current.to, value: recipient, kind: WCDecodedRowKind.address),
      ],
      warnings: [if (!isRead) S.current.wc_warning_decode_failed],
    );
  }
}
