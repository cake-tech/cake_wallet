import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart';

class Erc1155Decoder {
  Erc1155Decoder(this.tokenResolver);

  final Erc20TokenResolver tokenResolver;

  WCDecodedRequest? decode({
    required EvmCalldata calldata,
    required String? contractAddress,
  }) {
    switch (calldata.selector) {
      case EvmSelectors.erc1155SafeTransferFrom:
        return _decodeSingle(calldata, contractAddress);
      case EvmSelectors.erc1155SafeBatchTransferFrom:
        return _decodeBatch(calldata, contractAddress);
    }
    return null;
  }

  WCDecodedRequest? _decodeSingle(EvmCalldata calldata, String? contractAddress) {
    final fromAddr = calldata.addressAt(0);
    final toAddr = calldata.addressAt(1);
    final tokenId = calldata.uintAt(2);
    final amount = calldata.uintAt(3);
    if (fromAddr == null || toAddr == null || tokenId == null || amount == null) {
      return null;
    }

    final collection = contractAddress == null ? '?' : tokenResolver.shortAddress(contractAddress);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_nft_transfer,
      actionSubtitle: collection,
      rows: [
        WCDecodedRow(label: S.current.wc_token_id, value: '#$tokenId'),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: amount.toString(),
          kind: WCDecodedRowKind.amount,
        ),
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
      hideZeroValue: true,
    );
  }

  WCDecodedRequest? _decodeBatch(EvmCalldata calldata, String? contractAddress) {
    final fromAddr = calldata.addressAt(0);
    final toAddr = calldata.addressAt(1);
    if (fromAddr == null || toAddr == null) return null;

    final collection = contractAddress == null ? '?' : tokenResolver.shortAddress(contractAddress);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_nft_batch_transfer,
      actionSubtitle: collection,
      rows: [
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
      hideZeroValue: true,
    );
  }
}
