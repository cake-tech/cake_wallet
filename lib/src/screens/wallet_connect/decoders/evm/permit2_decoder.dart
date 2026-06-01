import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart';

class Permit2Decoder {
  Permit2Decoder(this.tokenResolver);

  final Erc20TokenResolver tokenResolver;

  WCDecodedRequest? decode({required EvmCalldata calldata}) {
    switch (calldata.selector) {
      case EvmSelectors.permit2Permit:
      case EvmSelectors.permit2PermitBatch:
      case EvmSelectors.permit2PermitTransferFrom:
        return _opaque(S.current.wc_action_permit2);
      case EvmSelectors.permit2TransferFrom:
        return _decodePermit2TransferFrom(calldata);
      case EvmSelectors.erc2612Permit:
        return _opaque(S.current.wc_action_permit);
    }
    return null;
  }

  WCDecodedRequest? _decodePermit2TransferFrom(EvmCalldata calldata) {
    final fromAddr = calldata.addressAt(0);
    final toAddr = calldata.addressAt(1);
    final amount = calldata.uintAt(2);
    final token = calldata.addressAt(3);
    if (fromAddr == null || toAddr == null || amount == null || token == null) {
      return _opaque(S.current.wc_action_permit2);
    }
    return WCDecodedRequest(
      actionTitle: S.current.wc_action_permit2,
      rows: [
        WCDecodedRow(
          label: S.current.wc_token,
          value: tokenResolver.shortAddress(token),
          kind: WCDecodedRowKind.address,
        ),
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

  WCDecodedRequest _opaque(String title) {
    return WCDecodedRequest(
      actionTitle: title,
      warnings: [S.current.wc_warning_permit_review],
      hideTo: true,
      hideZeroValue: true,
    );
  }
}
