import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/dex_router_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc1155_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc721_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/permit2_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cake_wallet/store/app_store.dart";

class EvmRequestDecoder {
  EvmRequestDecoder(AppStore? appStore) : _resolver = Erc20TokenResolver(appStore) {
    _erc20 = Erc20Decoder(_resolver);
    _erc721 = Erc721Decoder(_resolver);
    _erc1155 = Erc1155Decoder(_resolver);
    _router = DexRouterDecoder(_resolver);
    _permit2 = Permit2Decoder(_resolver);
  }

  final Erc20TokenResolver _resolver;
  late final Erc20Decoder _erc20;
  late final Erc721Decoder _erc721;
  late final Erc1155Decoder _erc1155;
  late final DexRouterDecoder _router;
  late final Permit2Decoder _permit2;

  Erc20TokenResolver get tokenResolver => _resolver;

  static const _multicallSelectors = {
    EvmSelectors.multicall,
    EvmSelectors.multicallWithDeadline,
    EvmSelectors.multicallWithPreviousBlockhash,
  };

  Future<WCDecodedRequest> decodeTransaction({
    required String? rawData,
    required String? toAddress,
    required String? fromAddress,
    required String nativeSymbol,
    required BigInt valueWei,
  }) async {
    final calldata = EvmCalldata.parse(rawData);
    if (calldata == null) {
      return _decodeNativeTransfer(toAddress, nativeSymbol, valueWei);
    }

    final known = await _decodeKnownCall(calldata, toAddress, fromAddress, nativeSymbol, valueWei);
    if (known != null) {
      return known;
    }

    final multicall =
        await _decodeMulticall(calldata, toAddress, fromAddress, nativeSymbol, valueWei);
    if (multicall != null) {
      return multicall;
    }

    return _unknownCall(calldata, toAddress, nativeSymbol, valueWei);
  }

  Future<WCDecodedRequest?> _decodeKnownCall(
    EvmCalldata calldata,
    String? toAddress,
    String? fromAddress,
    String nativeSymbol,
    BigInt valueWei,
  ) async {
    final erc20Result = await _erc20.decode(
      calldata: calldata,
      contractAddress: toAddress,
      nativeSymbol: nativeSymbol,
    );
    if (erc20Result != null) {
      return erc20Result;
    }

    final erc721Result = _erc721.decode(calldata: calldata, contractAddress: toAddress);
    if (erc721Result != null) {
      return erc721Result;
    }

    final erc1155Result = _erc1155.decode(calldata: calldata, contractAddress: toAddress);
    if (erc1155Result != null) {
      return erc1155Result;
    }

    final routerResult = await _router.decode(
      calldata: calldata,
      nativeSymbol: nativeSymbol,
      routerAddress: toAddress,
      walletAddress: fromAddress,
      valueWei: valueWei,
    );
    if (routerResult != null) {
      return routerResult;
    }

    return _permit2.decode(calldata: calldata, contractAddress: toAddress);
  }

  Future<WCDecodedRequest?> _decodeMulticall(
    EvmCalldata calldata,
    String? toAddress,
    String? fromAddress,
    String nativeSymbol,
    BigInt valueWei,
  ) async {
    if (!_multicallSelectors.contains(calldata.selector)) {
      return null;
    }

    final hasPrefixWord = calldata.selector != EvmSelectors.multicall;
    final deadline =
        calldata.selector == EvmSelectors.multicallWithDeadline ? calldata.uintAt(0) : null;
    final inners = calldata.bytesArrayAt(hasPrefixWord ? 1 : 0);
    if (inners == null || inners.isEmpty) {
      return null;
    }

    final decodedInners = <WCDecodedRequest?>[];
    for (final innerHex in inners) {
      final innerCalldata = EvmCalldata.parse(innerHex);
      if (innerCalldata == null) {
        decodedInners.add(null);
        continue;
      }
      decodedInners.add(
        await _decodeKnownCall(innerCalldata, toAddress, fromAddress, nativeSymbol, valueWei),
      );
    }

    final primary = decodedInners.firstWhere((d) => d != null, orElse: () => null);
    final deadlineRow = deadline == null
        ? null
        : WCDecodedRow(label: S.current.wc_deadline, value: _resolver.formatTimestamp(deadline));

    if (inners.length == 1 && primary != null) {
      return primary.copyWith(rows: [...primary.rows, if (deadlineRow != null) deadlineRow]);
    }

    final detailRows = <WCDecodedRow>[];
    final innerWarnings = <String>{};
    bool anyUnknown = false;
    for (var i = 0; i < inners.length; i++) {
      final decoded = decodedInners[i];
      if (decoded == null) {
        final innerCalldata = EvmCalldata.parse(inners[i]);
        detailRows.add(
          WCDecodedRow(
            label: S.current.wc_step_n((i + 1).toString()),
            value: innerCalldata == null
                ? S.current.wc_decode_failed
                : EvmSelectors.humanNameFor(innerCalldata.selector),
          ),
        );
        anyUnknown = true;
        continue;
      }
      detailRows.add(
        WCDecodedRow(
          label: S.current.wc_step_n((i + 1).toString()),
          value: decoded.actionTitle,
        ),
      );
      detailRows.addAll(decoded.rows);
      innerWarnings.addAll(decoded.warnings);
    }

    if (primary == null) {
      final unknown = _unknownCall(calldata, toAddress, nativeSymbol, valueWei);
      return unknown.copyWith(
        rows: [...unknown.rows, if (deadlineRow != null) deadlineRow],
        detailRows: detailRows,
      );
    }

    return primary.copyWith(
      rows: [...primary.rows, if (deadlineRow != null) deadlineRow],
      detailRows: [...primary.detailRows, ...detailRows],
      warnings: {
        ...primary.warnings,
        if (anyUnknown) S.current.wc_warning_unknown_contract,
        ...innerWarnings,
      }.toList(),
    );
  }

  WCDecodedRequest _decodeNativeTransfer(
    String? toAddress,
    String nativeSymbol,
    BigInt valueWei,
  ) {
    final amountStr = _resolver.formatNativeAmount(valueWei);
    return WCDecodedRequest(
      actionTitle: S.current.wc_action_send,
      rows: [
        WCDecodedRow(
          label: S.current.wc_amount,
          value: "$amountStr $nativeSymbol",
          kind: WCDecodedRowKind.amount,
        ),
        if (toAddress != null)
          WCDecodedRow(
            label: S.current.to,
            value: toAddress,
            kind: WCDecodedRowKind.address,
          ),
      ],
      hideTo: true,
      hideValue: true,
    );
  }

  WCDecodedRequest _unknownCall(
    EvmCalldata calldata,
    String? toAddress,
    String nativeSymbol,
    BigInt valueWei,
  ) {
    final humanName = EvmSelectors.humanNameFor(calldata.selector);
    final amountStr = _resolver.formatNativeAmount(valueWei);

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
            value: "$amountStr $nativeSymbol",
            kind: WCDecodedRowKind.amount,
          ),
      ],
      warnings: [S.current.wc_warning_unknown_contract],
      hideTo: true,
      hideValue: true,
    );
  }
}
