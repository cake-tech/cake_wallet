import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/dex_router_decoder.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc1155_decoder.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_decoder.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc721_decoder.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/permit2_decoder.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart';
import 'package:cake_wallet/store/app_store.dart';

class EvmRequestDecoder {
  EvmRequestDecoder(AppStore appStore)
      : _resolver = Erc20TokenResolver(appStore),
        _appStore = appStore {
    _erc20 = Erc20Decoder(_resolver);
    _erc721 = Erc721Decoder(_resolver);
    _erc1155 = Erc1155Decoder(_resolver);
    _router = DexRouterDecoder(_resolver);
    _permit2 = Permit2Decoder(_resolver);
  }

  final Erc20TokenResolver _resolver;
  // ignore: unused_field
  final AppStore _appStore;
  late final Erc20Decoder _erc20;
  late final Erc721Decoder _erc721;
  late final Erc1155Decoder _erc1155;
  late final DexRouterDecoder _router;
  late final Permit2Decoder _permit2;

  Erc20TokenResolver get tokenResolver => _resolver;

  Future<WCDecodedRequest> decodeTransaction({
    required String? rawData,
    required String? toAddress,
    required String? fromAddress,
    required String nativeSymbol,
    required BigInt valueWei,
  }) async {
    final calldata = EvmCalldata.parse(rawData);
    if (calldata == null) {
      return _decodeNativeTransfer(toAddress, fromAddress, nativeSymbol, valueWei);
    }

    final erc20Result = await _erc20.decode(
        calldata: calldata, contractAddress: toAddress, nativeSymbol: nativeSymbol);
    if (erc20Result != null) return erc20Result;

    final erc721Result = _erc721.decode(calldata: calldata, contractAddress: toAddress);
    if (erc721Result != null) return erc721Result;

    final erc1155Result = _erc1155.decode(calldata: calldata, contractAddress: toAddress);
    if (erc1155Result != null) return erc1155Result;

    final routerResult = await _router.decode(
      calldata: calldata,
      nativeSymbol: nativeSymbol,
      routerAddress: toAddress,
    );
    if (routerResult != null) return routerResult;

    final permitResult = _permit2.decode(calldata: calldata);
    if (permitResult != null) return permitResult;

    return _unknownCall(calldata, toAddress, nativeSymbol, valueWei);
  }

  WCDecodedRequest _decodeNativeTransfer(
    String? toAddress,
    String? fromAddress,
    String nativeSymbol,
    BigInt valueWei,
  ) {
    final amount = valueWei.toDouble() / 1e18;
    final amountStr = _resolver.formatNative(amount);
    return WCDecodedRequest(
      actionTitle: S.current.wc_action_send,
      rows: [
        WCDecodedRow(
          label: S.current.wc_amount,
          value: '$amountStr $nativeSymbol',
          kind: WCDecodedRowKind.amount,
        ),
        if (toAddress != null)
          WCDecodedRow(
            label: S.current.to,
            value: toAddress,
            kind: WCDecodedRowKind.address,
          ),
        if (fromAddress != null)
          WCDecodedRow(
            label: S.current.from,
            value: fromAddress,
            kind: WCDecodedRowKind.address,
          ),
      ],
      hideTo: true,
      hideZeroValue: false,
    );
  }

  WCDecodedRequest _unknownCall(
    EvmCalldata calldata,
    String? toAddress,
    String nativeSymbol,
    BigInt valueWei,
  ) {
    final humanName = EvmSelectors.humanNameFor(calldata.selector);
    final amount = valueWei.toDouble() / 1e18;
    final amountStr = _resolver.formatNative(amount);

    return WCDecodedRequest(
      actionTitle: S.current.wc_contract_call,
      actionSubtitle: humanName,
      rows: [
        if (toAddress != null)
          WCDecodedRow(
            label: S.current.wc_contract,
            value: toAddress,
            kind: WCDecodedRowKind.address,
          ),
        if (valueWei > BigInt.zero)
          WCDecodedRow(
            label: S.current.wc_value,
            value: '$amountStr $nativeSymbol',
            kind: WCDecodedRowKind.amount,
          ),
      ],
      warnings: [S.current.wc_warning_unknown_contract],
      hideTo: true,
      hideZeroValue: valueWei == BigInt.zero,
    );
  }
}
