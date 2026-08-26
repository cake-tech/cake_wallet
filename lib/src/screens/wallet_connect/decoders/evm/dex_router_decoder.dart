import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/universal_router_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";

class DexRouterDecoder {
  DexRouterDecoder(this.tokenResolver) : _universalRouter = UniversalRouterDecoder(tokenResolver);

  final Erc20TokenResolver tokenResolver;
  final UniversalRouterDecoder _universalRouter;

  Future<WCDecodedRequest?> decode({
    required EvmCalldata calldata,
    required String nativeSymbol,
    required String? routerAddress,
    required BigInt valueWei,
    String? walletAddress,
  }) async {
    final routerName = EvmSelectors.routerNameFor(calldata.selector);
    if (routerName == null) {
      return null;
    }

    switch (calldata.selector) {
      case EvmSelectors.uniV2SwapExactTokensForTokens:
      case EvmSelectors.uniV2SwapExactTokensForTokensSupportingFeeOnTransferTokens:
        return _decodeUniV2ExactIn(calldata, nativeSymbol, routerName, routerAddress);
      case EvmSelectors.uniV2SwapTokensForExactTokens:
        return _decodeUniV2ExactOut(
          calldata,
          nativeSymbol,
          routerName,
          routerAddress,
          ethOut: false,
        );
      case EvmSelectors.uniV2SwapExactETHForTokens:
      case EvmSelectors.uniV2SwapExactETHForTokensSupportingFeeOnTransferTokens:
        return _decodeUniV2ExactInEth(calldata, nativeSymbol, routerName, routerAddress, valueWei);
      case EvmSelectors.uniV2SwapETHForExactTokens:
        return _decodeUniV2ExactOutEth(calldata, nativeSymbol, routerName, routerAddress, valueWei);
      case EvmSelectors.uniV2SwapExactTokensForETH:
      case EvmSelectors.uniV2SwapExactTokensForETHSupportingFeeOnTransferTokens:
        return _decodeUniV2ExactIn(calldata, nativeSymbol, routerName, routerAddress, ethOut: true);
      case EvmSelectors.uniV2SwapTokensForExactETH:
        return _decodeUniV2ExactOut(
          calldata,
          nativeSymbol,
          routerName,
          routerAddress,
          ethOut: true,
        );
      case EvmSelectors.uniV3ExactInputSingle:
        return _decodeUniV3Single(
          calldata,
          nativeSymbol,
          routerName,
          routerAddress,
          isExactIn: true,
        );
      case EvmSelectors.uniV3ExactOutputSingle:
        return _decodeUniV3Single(
          calldata,
          nativeSymbol,
          routerName,
          routerAddress,
          isExactIn: false,
        );
      case EvmSelectors.uniV3Router02ExactInputSingle:
        return _decodeUniV3Single(
          calldata,
          nativeSymbol,
          routerName,
          routerAddress,
          isExactIn: true,
          hasDeadlineWord: false,
        );
      case EvmSelectors.uniV3Router02ExactOutputSingle:
        return _decodeUniV3Single(
          calldata,
          nativeSymbol,
          routerName,
          routerAddress,
          isExactIn: false,
          hasDeadlineWord: false,
        );
      case EvmSelectors.uniV3UniversalRouterExecute:
      case EvmSelectors.uniV3UniversalRouterExecuteWithDeadline:
        final decoded = await _universalRouter.decode(
          calldata: calldata,
          nativeSymbol: nativeSymbol,
          routerName: routerName,
          walletAddress: walletAddress,
        );
        return decoded ?? _decodeOpaqueSwap(routerName, routerAddress);
      case EvmSelectors.uniV3ExactInput:
      case EvmSelectors.uniV3ExactOutput:
      case EvmSelectors.uniV3Router02ExactInput:
      case EvmSelectors.uniV3Router02ExactOutput:
      case EvmSelectors.zeroXTransformErc20:
      case EvmSelectors.zeroXFillLimitOrder:
      case EvmSelectors.oneInchSwap:
      case EvmSelectors.oneInchUnoswap:
      case EvmSelectors.oneInchClipperSwap:
      case EvmSelectors.oneInchAggregationSwap:
        return _decodeOpaqueSwap(routerName, routerAddress);
    }
    return null;
  }

  Future<WCDecodedRequest?> _decodeUniV2ExactIn(
    EvmCalldata calldata,
    String nativeSymbol,
    String routerName,
    String? routerAddress, {
    bool ethOut = false,
  }) async {
    final amountIn = calldata.uintAt(0);
    final amountOutMin = calldata.uintAt(1);
    final path = calldata.addressArrayAt(2);
    final recipient = calldata.addressAt(3);
    if (amountIn == null || amountOutMin == null || path == null || path.length < 2) {
      return _decodeOpaqueSwap(routerName, routerAddress);
    }
    final tokenIn = path.first;
    final tokenOut = path.last;
    final descs = await Future.wait([
      _formatAmount(tokenIn, amountIn, nativeSymbol, asNative: false),
      _formatAmount(tokenOut, amountOutMin, nativeSymbol, asNative: ethOut),
    ]);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_swap,
      actionSubtitle: S.current.wc_via(routerName),
      rows: [
        WCDecodedRow(label: S.current.wc_swap_from, value: descs[0]),
        WCDecodedRow(label: S.current.wc_swap_to_min, value: descs[1]),
        if (recipient != null)
          WCDecodedRow(
            label: S.current.wc_recipient,
            value: recipient,
            kind: WCDecodedRowKind.address,
          ),
      ],
      hideTo: true,
    );
  }

  Future<WCDecodedRequest?> _decodeUniV2ExactOut(
    EvmCalldata calldata,
    String nativeSymbol,
    String routerName,
    String? routerAddress, {
    required bool ethOut,
  }) async {
    final amountOut = calldata.uintAt(0);
    final amountInMax = calldata.uintAt(1);
    final path = calldata.addressArrayAt(2);
    final recipient = calldata.addressAt(3);
    if (amountOut == null || amountInMax == null || path == null || path.length < 2) {
      return _decodeOpaqueSwap(routerName, routerAddress);
    }
    final tokenIn = path.first;
    final tokenOut = path.last;
    final descs = await Future.wait([
      _formatAmount(tokenIn, amountInMax, nativeSymbol, asNative: false),
      _formatAmount(tokenOut, amountOut, nativeSymbol, asNative: ethOut),
    ]);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_swap,
      actionSubtitle: S.current.wc_via(routerName),
      rows: [
        WCDecodedRow(label: S.current.wc_swap_from_max, value: descs[0]),
        WCDecodedRow(label: S.current.wc_swap_to, value: descs[1]),
        if (recipient != null)
          WCDecodedRow(
            label: S.current.wc_recipient,
            value: recipient,
            kind: WCDecodedRowKind.address,
          ),
      ],
      hideTo: true,
    );
  }

  Future<WCDecodedRequest?> _decodeUniV2ExactInEth(
    EvmCalldata calldata,
    String nativeSymbol,
    String routerName,
    String? routerAddress,
    BigInt valueWei,
  ) async {
    final amountOutMin = calldata.uintAt(0);
    final path = calldata.addressArrayAt(1);
    final recipient = calldata.addressAt(2);
    if (amountOutMin == null || path == null || path.length < 2) {
      return _decodeOpaqueSwap(routerName, routerAddress);
    }
    final tokenOut = path.last;
    final outDesc = await _formatAmount(tokenOut, amountOutMin, nativeSymbol, asNative: false);
    final inDesc = "${tokenResolver.formatNativeAmount(valueWei)} $nativeSymbol";

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_swap,
      actionSubtitle: S.current.wc_via(routerName),
      rows: [
        WCDecodedRow(label: S.current.wc_swap_from, value: inDesc),
        WCDecodedRow(label: S.current.wc_swap_to_min, value: outDesc),
        if (recipient != null)
          WCDecodedRow(
            label: S.current.wc_recipient,
            value: recipient,
            kind: WCDecodedRowKind.address,
          ),
      ],
      hideTo: true,
      hideValue: true,
    );
  }

  Future<WCDecodedRequest?> _decodeUniV2ExactOutEth(
    EvmCalldata calldata,
    String nativeSymbol,
    String routerName,
    String? routerAddress,
    BigInt valueWei,
  ) async {
    final amountOut = calldata.uintAt(0);
    final path = calldata.addressArrayAt(1);
    final recipient = calldata.addressAt(2);
    if (amountOut == null || path == null || path.length < 2) {
      return _decodeOpaqueSwap(routerName, routerAddress);
    }
    final tokenOut = path.last;
    final outDesc = await _formatAmount(tokenOut, amountOut, nativeSymbol, asNative: false);

    // The max spend is the transaction value, the router refunds the surplus.
    final inDesc = "${tokenResolver.formatNativeAmount(valueWei)} $nativeSymbol";

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_swap,
      actionSubtitle: S.current.wc_via(routerName),
      rows: [
        WCDecodedRow(label: S.current.wc_swap_from_max, value: inDesc),
        WCDecodedRow(label: S.current.wc_swap_to, value: outDesc),
        if (recipient != null)
          WCDecodedRow(
            label: S.current.wc_recipient,
            value: recipient,
            kind: WCDecodedRowKind.address,
          ),
      ],
      hideTo: true,
      hideValue: true,
    );
  }

  Future<WCDecodedRequest?> _decodeUniV3Single(
    EvmCalldata calldata,
    String nativeSymbol,
    String routerName,
    String? routerAddress, {
    required bool isExactIn,
    bool hasDeadlineWord = true,
  }) async {
    final tokenIn = calldata.addressAt(0);
    final tokenOut = calldata.addressAt(1);
    final recipient = calldata.addressAt(3);
    final amountSpecified = calldata.uintAt(hasDeadlineWord ? 5 : 4);
    final amountLimit = calldata.uintAt(hasDeadlineWord ? 6 : 5);

    if (tokenIn == null || tokenOut == null || amountSpecified == null || amountLimit == null) {
      return _decodeOpaqueSwap(routerName, routerAddress);
    }

    final fromAmount = isExactIn ? amountSpecified : amountLimit;
    final toAmount = isExactIn ? amountLimit : amountSpecified;

    final descs = await Future.wait([
      _formatAmount(tokenIn, fromAmount, nativeSymbol, asNative: false),
      _formatAmount(tokenOut, toAmount, nativeSymbol, asNative: false),
    ]);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_swap,
      actionSubtitle: S.current.wc_via(routerName),
      rows: [
        WCDecodedRow(
          label: isExactIn ? S.current.wc_swap_from : S.current.wc_swap_from_max,
          value: descs[0],
        ),
        WCDecodedRow(
          label: isExactIn ? S.current.wc_swap_to_min : S.current.wc_swap_to,
          value: descs[1],
        ),
        if (recipient != null)
          WCDecodedRow(
            label: S.current.wc_recipient,
            value: recipient,
            kind: WCDecodedRowKind.address,
          ),
      ],
      hideTo: true,
    );
  }

  // Nothing here carries an amount, so say the amounts could not be read
  // rather than describing absent numbers as estimates.
  WCDecodedRequest _decodeOpaqueSwap(String routerName, String? routerAddress) => WCDecodedRequest(
        actionTitle: S.current.wc_action_swap,
        actionSubtitle: S.current.wc_via(routerName),
        rows: [
          if (routerAddress != null)
            WCDecodedRow(
              label: S.current.wc_router,
              value: routerAddress,
              kind: WCDecodedRowKind.address,
            ),
        ],
        warnings: [S.current.wc_warning_swap_amounts_unavailable],
        hideTo: true,
      );

  Future<String> _formatAmount(
    String tokenAddress,
    BigInt rawAmount,
    String nativeSymbol, {
    required bool asNative,
  }) async {
    if (asNative || _isNativeSentinel(tokenAddress)) {
      return "${tokenResolver.formatNativeAmount(rawAmount)} $nativeSymbol";
    }
    final token = await tokenResolver.resolve(tokenAddress);
    final symbol = tokenResolver.symbolOrShort(token, tokenAddress);
    final amount = tokenResolver.formatAmount(rawAmount, token);
    return "$amount $symbol";
  }

  bool _isNativeSentinel(String address) {
    final lower = address.toLowerCase();
    return lower == "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee" ||
        lower == "0x0000000000000000000000000000000000000000";
  }
}
