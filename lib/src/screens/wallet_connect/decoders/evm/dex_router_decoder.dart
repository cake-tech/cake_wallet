import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/universal_router_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/format_fixed.dart";

class DexRouterDecoder {
  DexRouterDecoder(this.tokenResolver);

  final Erc20TokenResolver tokenResolver;

  static const _universalRouter = UniversalRouterDecoder();
  static const _maxLookedUpTokens = 12;
  static final _allBips = BigInt.from(10000);

  Future<WCDecodedRequest?> decode({
    required EvmCalldata calldata,
    required String nativeSymbol,
    required String? routerAddress,
    required BigInt valueWei,
    required int? chainId,
    String? walletAddress,
  }) async {
    final router = EvmSelectors.routerFor(calldata.selector);
    if (router == null || routerAddress == null) {
      return null;
    }

    final decoded = await _decodeSwap(
      calldata: calldata,
      nativeSymbol: nativeSymbol,
      router: router,
      routerAddress: routerAddress,
      valueWei: valueWei,
      walletAddress: walletAddress,
      chainId: chainId,
    );
    if (decoded == null) {
      return null;
    }
    return _withRouter(decoded, router, routerAddress, chainId);
  }

  Future<WCDecodedRequest?> decodeMulticall({
    required List<EvmCalldata> calls,
    required String nativeSymbol,
    required String? routerAddress,
    required BigInt valueWei,
    required int? chainId,
    String? walletAddress,
  }) async {
    if (routerAddress == null) {
      return null;
    }

    final plan = SwapPlan(
      routerAddress: routerAddress,
      walletAddress: walletAddress,
      chainId: chainId,
      valueWei: valueWei,
      isSwapRouter: true,
    );
    for (final call in calls) {
      if (!_readV3RouterCall(plan, call)) {
        return null;
      }
    }

    final decoded = await _describe(plan, DexRouter.uniswapV3, nativeSymbol);
    return _withRouter(decoded, DexRouter.uniswapV3, routerAddress, chainId);
  }

  WCDecodedRequest _withRouter(
    WCDecodedRequest decoded,
    DexRouter router,
    String routerAddress,
    int? chainId,
  ) {
    final isKnownRouter = EvmSelectors.isKnownRouter(router, chainId, routerAddress);
    return decoded.copyWith(
      actionSubtitle: isKnownRouter
          ? decoded.actionSubtitle
          : S.current.wc_via(shortAddress(routerAddress)),
      rows: [
        ...decoded.rows,
        WCDecodedRow(
          label: S.current.wc_router,
          value: routerAddress,
          kind: WCDecodedRowKind.address,
        ),
      ],
      warnings: [...decoded.warnings, if (!isKnownRouter) S.current.wc_warning_unknown_contract],
    );
  }

  Future<WCDecodedRequest?> _decodeSwap({
    required EvmCalldata calldata,
    required String nativeSymbol,
    required DexRouter router,
    required String routerAddress,
    required BigInt valueWei,
    required String? walletAddress,
    required int? chainId,
  }) async {
    if (router == DexRouter.universalRouter) {
      final plan = _universalRouter.decode(
        calldata: calldata,
        routerAddress: routerAddress,
        walletAddress: walletAddress,
        chainId: chainId,
        valueWei: valueWei,
      );
      return plan == null ? null : _describe(plan, router, nativeSymbol);
    }

    final plan = SwapPlan(
      routerAddress: routerAddress,
      walletAddress: walletAddress,
      chainId: chainId,
      valueWei: valueWei,
      isSwapRouter: true,
    );

    if (!_readV2RouterCall(plan, calldata) && !_readV3RouterCall(plan, calldata)) {
      plan.hasUnexpectedStep = true;
    }
    return _describe(plan, router, nativeSymbol);
  }

  bool _readV2RouterCall(SwapPlan plan, EvmCalldata calldata) {
    switch (calldata.selector) {
      case EvmSelectors.uniV2SwapExactTokensForTokens:
      case EvmSelectors.uniV2SwapExactTokensForTokensSupportingFeeOnTransferTokens:
        return _readV2Swap(plan, calldata, isExactIn: true);
      case EvmSelectors.uniV2SwapTokensForExactTokens:
        return _readV2Swap(plan, calldata, isExactIn: false);
      case EvmSelectors.uniV2SwapExactETHForTokens:
      case EvmSelectors.uniV2SwapExactETHForTokensSupportingFeeOnTransferTokens:
        return _readV2Swap(plan, calldata, isExactIn: true, isEthIn: true);
      case EvmSelectors.uniV2SwapETHForExactTokens:
        return _readV2Swap(plan, calldata, isExactIn: false, isEthIn: true);
      case EvmSelectors.uniV2SwapExactTokensForETH:
      case EvmSelectors.uniV2SwapExactTokensForETHSupportingFeeOnTransferTokens:
        return _readV2Swap(plan, calldata, isExactIn: true, unwrapsOutput: true);
      case EvmSelectors.uniV2SwapTokensForExactETH:
        return _readV2Swap(plan, calldata, isExactIn: false, unwrapsOutput: true);
    }
    return false;
  }

  bool _readV2Swap(
    SwapPlan plan,
    EvmCalldata calldata, {
    required bool isExactIn,
    bool isEthIn = false,
    bool unwrapsOutput = false,
    bool isOnRouter02 = false,
  }) {
    final fromAmount = isEthIn ? plan.valueWei : calldata.uintAt(isExactIn ? 0 : 1);
    final toAmount = calldata.uintAt(isExactIn && !isEthIn ? 1 : 0);
    final path = calldata.addressArrayAt(isEthIn ? 1 : 2);
    final recipient = calldata.addressAt(isEthIn ? 2 : 3);
    if (fromAmount == null ||
        toAmount == null ||
        path == null ||
        path.length < 2 ||
        recipient == null) {
      return false;
    }

    final party = plan.party(recipient, mapsSentinels: isOnRouter02);
    final spendsBalance = isOnRouter02 && isExactIn && fromAmount == BigInt.zero;
    plan.steps.add(
      SwapLeg(
        tokenIn: path.first,
        tokenOut: path.last,
        fromAmount: spendsBalance ? SwapPlan.contractBalance : fromAmount,
        toAmount: toAmount,
        isExactIn: isExactIn,
        recipient: unwrapsOutput ? SwapPlan.router : party,
        isPaidByRouter: isEthIn || spendsBalance || (isOnRouter02 && plan.valueWei > BigInt.zero),
        isOutputChecked: isExactIn || !isOnRouter02,
      ),
    );
    if (unwrapsOutput) {
      plan.steps.add(
        SwapPayout(
          token: path.last,
          recipient: party,
          amountMinimum: toAmount,
          isUnwrap: path.last == plan.wrappedNative,
        ),
      );
    }

    if (isEthIn && !isExactIn) {
      plan.steps.add(
        SwapPayout(
          token: SwapPlan.nativeToken,
          recipient: SwapPlan.wallet,
          amountMinimum: BigInt.zero,
        ),
      );
    }
    return true;
  }

  bool _readV3RouterCall(SwapPlan plan, EvmCalldata calldata) {
    switch (calldata.selector) {
      case EvmSelectors.uniV3ExactInputSingle:
        return _readV3Single(plan, calldata, isExactIn: true, hasDeadlineWord: true);
      case EvmSelectors.uniV3ExactOutputSingle:
        return _readV3Single(plan, calldata, isExactIn: false, hasDeadlineWord: true);
      case EvmSelectors.uniV3Router02ExactInputSingle:
        return _readV3Single(plan, calldata, isExactIn: true, hasDeadlineWord: false);
      case EvmSelectors.uniV3Router02ExactOutputSingle:
        return _readV3Single(plan, calldata, isExactIn: false, hasDeadlineWord: false);
      case EvmSelectors.uniV3ExactInput:
        return _readV3Path(plan, calldata, isExactIn: true, hasDeadlineWord: true);
      case EvmSelectors.uniV3ExactOutput:
        return _readV3Path(plan, calldata, isExactIn: false, hasDeadlineWord: true);
      case EvmSelectors.uniV3Router02ExactInput:
        return _readV3Path(plan, calldata, isExactIn: true, hasDeadlineWord: false);
      case EvmSelectors.uniV3Router02ExactOutput:
        return _readV3Path(plan, calldata, isExactIn: false, hasDeadlineWord: false);
      case EvmSelectors.uniV2Router02SwapExactTokensForTokens:
        return _readV2Swap(plan, calldata, isExactIn: true, isOnRouter02: true);
      case EvmSelectors.uniV2Router02SwapTokensForExactTokens:
        return _readV2Swap(plan, calldata, isExactIn: false, isOnRouter02: true);
      case EvmSelectors.routerUnwrapWeth9:
        return _readPayout(plan, calldata, isUnwrap: true, recipientWord: 1);
      case EvmSelectors.routerUnwrapWeth9ToSender:
        return _readPayout(plan, calldata, isUnwrap: true);
      case EvmSelectors.routerUnwrapWeth9WithFee:
        return _readPayout(plan, calldata, isUnwrap: true, recipientWord: 1, feeWord: 2);
      case EvmSelectors.routerUnwrapWeth9WithFeeToSender:
        return _readPayout(plan, calldata, isUnwrap: true, feeWord: 1);
      case EvmSelectors.routerSweepToken:
        return _readPayout(plan, calldata, isUnwrap: false, recipientWord: 2);
      case EvmSelectors.routerSweepTokenToSender:
        return _readPayout(plan, calldata, isUnwrap: false);
      case EvmSelectors.routerSweepTokenWithFee:
        return _readPayout(plan, calldata, isUnwrap: false, recipientWord: 2, feeWord: 3);
      case EvmSelectors.routerSweepTokenWithFeeToSender:
        return _readPayout(plan, calldata, isUnwrap: false, feeWord: 2);
      case EvmSelectors.routerRefundEth:
        plan.steps.add(
          SwapPayout(
            token: SwapPlan.nativeToken,
            recipient: SwapPlan.wallet,
            amountMinimum: BigInt.zero,
          ),
        );
        return true;
      case EvmSelectors.routerSelfPermit:
      case EvmSelectors.routerSelfPermitIfNecessary:
        return _readSelfPermit(plan, calldata, amount: calldata.uintAt(1));
      case EvmSelectors.routerSelfPermitAllowed:
      case EvmSelectors.routerSelfPermitAllowedIfNecessary:
        return _readSelfPermit(plan, calldata, amount: EvmCalldata.uint256Max);
    }
    return false;
  }

  bool _readSelfPermit(SwapPlan plan, EvmCalldata calldata, {required BigInt? amount}) {
    final token = calldata.addressAt(0);
    if (token == null || amount == null) {
      return false;
    }

    plan.steps.add(SwapPermit(token: token, amount: amount, spender: plan.routerAddress));
    return true;
  }

  bool _readV3Single(
    SwapPlan plan,
    EvmCalldata calldata, {
    required bool isExactIn,
    required bool hasDeadlineWord,
  }) {
    final tokenIn = calldata.addressAt(0);
    final tokenOut = calldata.addressAt(1);
    final recipient = calldata.addressAt(3);
    final specifiedAmount = calldata.uintAt(hasDeadlineWord ? 5 : 4);
    final limitAmount = calldata.uintAt(hasDeadlineWord ? 6 : 5);
    final priceLimit = calldata.uintAt(hasDeadlineWord ? 7 : 6);
    if (tokenIn == null ||
        tokenOut == null ||
        recipient == null ||
        specifiedAmount == null ||
        limitAmount == null ||
        priceLimit == null) {
      return false;
    }

    if (priceLimit != BigInt.zero) {
      plan.hasUnexpectedStep = true;
    }

    _addV3Leg(
      plan,
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      recipient: recipient,
      specifiedAmount: specifiedAmount,
      limitAmount: limitAmount,
      isExactIn: isExactIn,
      hasDeadlineWord: hasDeadlineWord,
    );
    return true;
  }

  bool _readV3Path(
    SwapPlan plan,
    EvmCalldata calldata, {
    required bool isExactIn,
    required bool hasDeadlineWord,
  }) {
    final params = calldata.structAt(0);
    final path = SwapPlan.v3PathTokens(params?.dynamicBytesAt(0));
    final recipient = params?.addressAt(1);
    final specifiedAmount = params?.uintAt(hasDeadlineWord ? 3 : 2);
    final limitAmount = params?.uintAt(hasDeadlineWord ? 4 : 3);
    if (path == null || recipient == null || specifiedAmount == null || limitAmount == null) {
      return false;
    }

    final midPath = path.sublist(1, path.length - 1);
    if (plan.valueWei > BigInt.zero && midPath.contains(plan.wrappedNative)) {
      plan.hasUnexpectedStep = true;
    }

    _addV3Leg(
      plan,
      tokenIn: isExactIn ? path.first : path.last,
      tokenOut: isExactIn ? path.last : path.first,
      recipient: recipient,
      specifiedAmount: specifiedAmount,
      limitAmount: limitAmount,
      isExactIn: isExactIn,
      hasDeadlineWord: hasDeadlineWord,
    );
    return true;
  }

  void _addV3Leg(
    SwapPlan plan, {
    required String tokenIn,
    required String tokenOut,
    required String recipient,
    required BigInt specifiedAmount,
    required BigInt limitAmount,
    required bool isExactIn,
    required bool hasDeadlineWord,
  }) {
    final spendsBalance = isExactIn && !hasDeadlineWord && specifiedAmount == BigInt.zero;
    final amountIn = spendsBalance ? SwapPlan.contractBalance : specifiedAmount;
    plan.steps.add(
      SwapLeg(
        tokenIn: tokenIn,
        tokenOut: tokenOut,
        fromAmount: isExactIn ? amountIn : limitAmount,
        toAmount: isExactIn ? limitAmount : specifiedAmount,
        isExactIn: isExactIn,
        recipient: plan.party(
          recipient,
          mapsSentinels: !hasDeadlineWord,
          zeroIsRouter: hasDeadlineWord,
        ),
        isPaidByRouter: spendsBalance || plan.valueWei > BigInt.zero,
      ),
    );
  }

  bool _readPayout(
    SwapPlan plan,
    EvmCalldata calldata, {
    required bool isUnwrap,
    int? recipientWord,
    int? feeWord,
  }) {
    final token = isUnwrap ? plan.wrappedNative : calldata.addressAt(0);
    final amountMinimum = calldata.uintAt(isUnwrap ? 0 : 1);
    final recipient = recipientWord == null ? null : calldata.addressAt(recipientWord);
    if (token == null || amountMinimum == null || (recipientWord != null && recipient == null)) {
      return false;
    }

    var floor = amountMinimum;
    if (feeWord != null) {
      final feeBips = calldata.uintAt(feeWord);
      final feeRecipient = calldata.addressAt(feeWord + 1);
      if (feeBips == null || feeBips > _allBips || feeRecipient == null) {
        return false;
      }
      floor -= amountMinimum * feeBips ~/ _allBips;
      plan.steps.add(
        SwapPortion(
          token: isUnwrap ? SwapPlan.nativeToken : token,
          recipient: plan.party(feeRecipient),
          fraction: feeBips * SwapPortion.bip,
        ),
      );
    }

    plan.steps.add(
      SwapPayout(
        token: token,
        recipient: recipient == null ? SwapPlan.wallet : plan.party(recipient),
        amountMinimum: floor,
        isUnwrap: isUnwrap,
      ),
    );
    return true;
  }

  Future<WCDecodedRequest> _describe(SwapPlan plan, DexRouter router, String nativeSymbol) async {
    final isListed = EvmSelectors.isKnownRouter(router, plan.chainId, plan.routerAddress);
    final swap = isListed ? plan.asSingleSwap() : null;
    final isSwap = swap != null;
    final steps = swap ?? plan.steps;
    final draft = _StepRows(tokenResolver, plan.chainId, nativeSymbol, const {}, isSwap: isSwap)
      ..addAll(steps);
    final shown = draft.shownTokens.take(_maxLookedUpTokens).toList();
    final tokens = Map.fromIterables(shown, await Future.wait(shown.map(tokenResolver.resolve)));
    final card = _StepRows(tokenResolver, plan.chainId, nativeSymbol, tokens, isSwap: isSwap)
      ..addAll(steps);

    return WCDecodedRequest(
      actionTitle: isSwap ? S.current.wc_action_swap : S.current.wc_contract_call,
      actionSubtitle: S.current.wc_via(router.displayName),
      rows: card.rows,
      detailRows: card.detailRows,
      warnings: [
        if (isSwap && router == DexRouter.universalRouter)
          S.current.wc_warning_swap_amounts_estimated,
        if (!isSwap) S.current.wc_warning_decode_failed,
        if (card.hasUnprotectedLeg) S.current.wc_warning_zero_slippage,
        if (card.hasUnlimitedApproval) S.current.wc_warning_unlimited_approval,
        if (card.hasUnknownToken) S.current.wc_warning_unknown_token,
        if (card.hasOtherPayee) S.current.wc_warning_recipient_not_you,
      ],
      isValueShown: isSwap && plan.valueWei > BigInt.zero,
    );
  }
}

class _StepRows {
  _StepRows(
    this.tokenResolver,
    this.chainId,
    this.nativeSymbol,
    this.tokens, {
    required this.isSwap,
  });

  final Erc20TokenResolver tokenResolver;
  final int? chainId;
  final String nativeSymbol;
  final Map<String, Erc20Token?> tokens;
  final bool isSwap;

  final rows = <WCDecodedRow>[];
  final detailRows = <WCDecodedRow>[];
  final shownTokens = <String>{};
  bool hasUnprotectedLeg = false;
  bool hasUnlimitedApproval = false;
  bool hasUnknownToken = false;
  bool hasOtherPayee = false;

  void addAll(List<SwapStep> steps) => steps.forEach(_add);

  void _add(SwapStep step) {
    final paymentLabel = isSwap ? S.current.fee : S.current.wc_action_transfer;
    switch (step) {
      case SwapLeg():
        _addAmount(
          step.isExactIn ? S.current.wc_swap_from : S.current.wc_swap_from_max,
          step.tokenIn,
          step.fromAmount,
        );
        _addAmount(
          step.isExactIn ? S.current.wc_swap_to_min : S.current.wc_swap_to,
          step.tokenOut,
          step.toAmount,
        );
        _addParty(S.current.wc_recipient, step.recipient);
        final isUnprotected = step.isExactIn
            ? step.toAmount == BigInt.zero
            : tokenResolver.isUnlimitedAmount(step.fromAmount);
        hasUnprotectedLeg = hasUnprotectedLeg || (isSwap && isUnprotected);
      case SwapPayout():
        _addAmount(
          S.current.wc_swap_to_min,
          step.isUnwrap ? SwapPlan.nativeToken : step.token,
          step.amountMinimum,
        );
        _addParty(S.current.wc_recipient, step.recipient);
      case SwapTransfer():
        _addAmount(paymentLabel, step.token, step.amount, kind: WCDecodedRowKind.amount);
        _addParty(S.current.to, step.recipient);
      case SwapPortion():
        final symbol = step.token == SwapPlan.nativeToken
            ? nativeSymbol
            : tokenResolver.symbolOrShort(tokens[step.token], step.token);
        final percent = formatFixed(step.fraction, 16);
        rows.add(WCDecodedRow(label: paymentLabel, value: "$percent% $symbol"));
        _addTokenAddress(step.token);
        _addParty(S.current.to, step.recipient);
      case SwapPermit():
        _addAmount(
          S.current.wc_action_approve,
          step.token,
          step.amount,
          kind: WCDecodedRowKind.amount,
        );
        rows.add(
          WCDecodedRow(
            label: S.current.wc_approved_spender,
            value: step.spender,
            kind: WCDecodedRowKind.address,
          ),
        );
        final expiration = step.expiration;
        if (expiration != null) {
          detailRows.add(
            WCDecodedRow(
              label: S.current.wc_expiration,
              value: tokenResolver.formatExpiry(expiration),
            ),
          );
        }
        hasUnlimitedApproval = hasUnlimitedApproval || tokenResolver.isUnlimitedAmount(step.amount);
    }
  }

  void _addAmount(
    String label,
    String token,
    BigInt amount, {
    WCDecodedRowKind kind = WCDecodedRowKind.text,
  }) {
    final isNative = token == SwapPlan.nativeToken;
    final resolved = tokens[token];
    final symbol = isNative ? nativeSymbol : tokenResolver.symbolOrShort(resolved, token);
    final shown = isNative && !tokenResolver.isUnlimitedAmount(amount)
        ? tokenResolver.formatNativeAmount(amount)
        : tokenResolver.formatAmount(amount, resolved);
    rows.add(WCDecodedRow(label: label, value: "$shown $symbol", kind: kind));
    _addTokenAddress(token);
  }

  void _addTokenAddress(String token) {
    if (token == SwapPlan.nativeToken || !shownTokens.add(token)) {
      return;
    }
    rows.add(WCDecodedRow(label: S.current.wc_token, value: token, kind: WCDecodedRowKind.address));
    if (!tokenResolver.isKnown(token, chainId: chainId)) {
      hasUnknownToken = true;
    }
  }

  void _addParty(String label, String party) {
    if (party == SwapPlan.wallet) {
      rows.add(WCDecodedRow(label: label, value: S.current.wc_recipient_you));
      return;
    }
    hasOtherPayee = hasOtherPayee || !isSwap;
    if (party == SwapPlan.router) {
      rows.add(WCDecodedRow(label: label, value: S.current.wc_recipient_router_hold));
      return;
    }
    rows.add(WCDecodedRow(label: label, value: party, kind: WCDecodedRowKind.address));
  }
}
