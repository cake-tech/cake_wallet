import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart";

class SwapPlan {
  SwapPlan({
    required this.routerAddress,
    required this.walletAddress,
    required this.chainId,
    required this.valueWei,
    this.isSwapRouter = false,
  });

  static const wallet = "wallet";
  static const router = "router";
  static const nativeToken = "0x0000000000000000000000000000000000000000";
  static const _msgSender = "0x0000000000000000000000000000000000000001";
  static const _addressThis = "0x0000000000000000000000000000000000000002";

  static final contractBalance = BigInt.one << 255;

  final String routerAddress;
  final String? walletAddress;
  final int? chainId;
  final BigInt valueWei;

  final bool isSwapRouter;

  final steps = <SwapStep>[];

  bool hasUnexpectedStep = false;

  String? get wrappedNative => EvmSelectors.wrappedNativeAddresses[chainId];

  static List<String>? v3PathTokens(List<int>? path) {
    if (path == null || path.length < 43 || (path.length - 20) % 23 != 0) {
      return null;
    }
    return [
      for (var offset = 0; offset < path.length; offset += 23)
        EvmCalldata.addressFromBytes(path, offset),
    ];
  }

  String party(String address, {bool mapsSentinels = false, bool zeroIsRouter = false}) {
    final lower = address.toLowerCase();
    if (lower == walletAddress?.toLowerCase() || (mapsSentinels && lower == _msgSender)) {
      return wallet;
    }
    if (lower == routerAddress.toLowerCase() ||
        (mapsSentinels && lower == _addressThis) ||
        (zeroIsRouter && lower == nativeToken)) {
      return router;
    }
    return lower;
  }

  List<SwapStep>? asSingleSwap() {
    if (hasUnexpectedStep) {
      return null;
    }

    final cursor = _StepCursor(steps);
    final permit = cursor.take<SwapPermit>((permit) => party(permit.spender) == router);
    final funding = _takeFunding(cursor);
    final routes = _takeRoutes(cursor, isRouterPaid: funding != null);
    final trade = routes == null ? null : _sumRoutes(routes, funding);
    if (trade == null) {
      return null;
    }

    final fee = _takeFee(cursor, trade);
    final delivered = _takeDelivery(cursor, trade, fee);
    if (delivered == null || !_takeLeftovers(cursor, trade, funding)) {
      return null;
    }

    if (!cursor.isAtEnd || (permit != null && permit.token != trade.tokenIn)) {
      return null;
    }

    return [delivered, ?fee, ?permit];
  }

  _SwapFunding? _takeFunding(_StepCursor cursor) {
    if (valueWei > BigInt.zero) {
      final isWrapped = cursor.takeWrap(router, valueWei) || isSwapRouter;
      return _SwapFunding(
        paidToken: nativeToken,
        heldToken: isWrapped ? wrappedNative : nativeToken,
        amount: valueWei,
      );
    }

    final pull = cursor.take<SwapTransfer>((pull) => pull.isFromWallet && pull.recipient == router);
    if (pull == null) {
      return null;
    }

    return _SwapFunding(
      paidToken: pull.token,
      heldToken: _rewrapped(cursor, pull.token),
      amount: pull.amount,
    );
  }

  String _rewrapped(_StepCursor cursor, String held) {
    final wrapped = wrappedNative;
    if (held == nativeToken && wrapped != null && cursor.takeWrap(router, contractBalance)) {
      return wrapped;
    }

    final isUnwrapped =
        held == wrapped &&
        cursor.take<SwapPayout>((unwrap) => unwrap.isUnwrap && unwrap.recipient == router) != null;
    return isUnwrapped ? nativeToken : held;
  }

  List<SwapLeg>? _takeRoutes(_StepCursor cursor, {required bool isRouterPaid}) {
    SwapLeg? takeRouteStart() => cursor.take<SwapLeg>(
      (leg) =>
          leg.fromAmount > BigInt.zero &&
          leg.fromAmount != contractBalance &&
          leg.isPaidByRouter == isRouterPaid,
    );
    final routes = <SwapLeg>[];
    final chainedTokens = <String>{};
    for (var start = takeRouteStart(); start != null; start = takeRouteStart()) {
      var route = start;
      while (route.isExactIn) {
        final sectionEnd = cursor.index;
        final held = route.recipient == router
            ? _rewrapped(cursor, route.tokenOut)
            : route.tokenOut;
        final next = cursor.take<SwapLeg>(
          (next) =>
              next.isExactIn &&
              next.isPaidByRouter &&
              next.fromAmount == contractBalance &&
              next.tokenIn == held &&
              (route.recipient == router || route.recipient == next.inputPair),
        );
        if (next == null) {
          cursor.index = sectionEnd;
          break;
        }
        chainedTokens.addAll([route.tokenOut, held]);
        route = SwapLeg(
          tokenIn: route.tokenIn,
          tokenOut: next.tokenOut,
          fromAmount: route.fromAmount,
          toAmount: next.toAmount,
          isExactIn: true,
          recipient: next.recipient,
        );
      }
      routes.add(route);
    }
    if (routes.isEmpty) {
      return null;
    }

    final first = routes.first;
    if (chainedTokens.contains(first.tokenIn) || chainedTokens.contains(first.tokenOut)) {
      return null;
    }
    return routes;
  }

  SwapLeg? _sumRoutes(List<SwapLeg> routes, _SwapFunding? funding) {
    final first = routes.first;
    var paid = BigInt.zero;
    var received = BigInt.zero;
    for (final route in routes) {
      final isSameTrade =
          route.tokenIn == first.tokenIn &&
          route.tokenOut == first.tokenOut &&
          route.isExactIn == first.isExactIn &&
          route.recipient == first.recipient;
      if (!isSameTrade) {
        return null;
      }
      paid += route.fromAmount;
      received += route.toAmount;
    }

    if (funding != null) {
      final isCovered = first.isExactIn ? paid == funding.amount : paid <= funding.amount;
      if (first.tokenIn != funding.heldToken || !isCovered) {
        return null;
      }
      paid = funding.amount;
    }

    return SwapLeg(
      tokenIn: funding?.paidToken ?? first.tokenIn,
      tokenOut: first.tokenOut,
      fromAmount: paid,
      toAmount: received,
      isExactIn: first.isExactIn,
      recipient: first.recipient,
      isOutputChecked: routes.every((route) => route.isOutputChecked),
    );
  }

  SwapStep? _takeFee(_StepCursor cursor, SwapLeg trade) {
    if (trade.recipient != router) {
      return null;
    }

    bool isOutput(String token) =>
        token == trade.tokenOut || (isSwapRouter && token == nativeToken);
    return cursor.take<SwapPortion>(
          (portion) => portion.fraction <= SwapPortion.largestFee && isOutput(portion.token),
        ) ??
        cursor.take<SwapTransfer>(
          (flatFee) => !flatFee.isFromWallet && !flatFee.isWrap && flatFee.token == trade.tokenOut,
        );
  }

  SwapLeg? _takeDelivery(_StepCursor cursor, SwapLeg trade, SwapStep? fee) {
    if (trade.recipient != router) {
      return trade.recipient == wallet && trade.isOutputChecked ? trade : null;
    }

    final held = _rewrapped(cursor, trade.tokenOut);
    final delivery = cursor.take<SwapPayout>(
      (payout) => payout.recipient == wallet && payout.token == held,
    );
    if (delivery == null) {
      return null;
    }

    final isNetOfFee = trade.isExactIn && delivery.amountMinimum > BigInt.zero;
    var received = isNetOfFee ? delivery.amountMinimum : trade.toAmount;
    final flatFee = fee is SwapTransfer ? fee.amount : BigInt.zero;
    if (flatFee * BigInt.from(100) > received) {
      return null;
    }
    if (!isNetOfFee) {
      received -= fee is SwapPortion ? received * fee.fraction ~/ SwapPortion.whole : flatFee;
    }
    if (!trade.isOutputChecked && delivery.amountMinimum < received) {
      return null;
    }

    return SwapLeg(
      tokenIn: trade.tokenIn,
      tokenOut: delivery.isUnwrap ? nativeToken : held,
      fromAmount: trade.fromAmount,
      toAmount: received,
      isExactIn: trade.isExactIn,
      recipient: wallet,
    );
  }

  bool _takeLeftovers(_StepCursor cursor, SwapLeg trade, _SwapFunding? funding) {
    final firstRefund = cursor.index;
    bool isRefund(SwapPayout refund) =>
        refund.recipient == wallet && refund.amountMinimum == BigInt.zero;
    while (cursor.take<SwapPayout>(isRefund) != null || cursor.takeWrap(wallet, contractBalance)) {}
    if (funding == null || trade.isExactIn) {
      return true;
    }

    final unspentToken = isSwapRouter && valueWei > BigInt.zero ? nativeToken : funding.heldToken;
    return steps
        .sublist(firstRefund, cursor.index)
        .any((refund) => (refund is SwapPayout ? refund.token : nativeToken) == unspentToken);
  }
}

class _StepCursor {
  _StepCursor(this.steps);

  final List<SwapStep> steps;
  int index = 0;

  bool get isAtEnd => index == steps.length;

  T? take<T extends SwapStep>(bool Function(T step) fits) {
    final step = isAtEnd ? null : steps[index];
    if (step is! T || !fits(step)) {
      return null;
    }
    index++;
    return step;
  }

  bool takeWrap(String recipient, BigInt amount) =>
      take<SwapTransfer>(
        (wrap) => wrap.isWrap && wrap.recipient == recipient && wrap.amount == amount,
      ) !=
      null;
}

class _SwapFunding {
  const _SwapFunding({required this.paidToken, required this.heldToken, required this.amount});

  final String paidToken;
  final String? heldToken;
  final BigInt amount;
}

sealed class SwapStep {
  const SwapStep();
}

class SwapLeg extends SwapStep {
  const SwapLeg({
    required this.tokenIn,
    required this.tokenOut,
    required this.fromAmount,
    required this.toAmount,
    required this.isExactIn,
    required this.recipient,
    this.isPaidByRouter = false,
    this.isOutputChecked = true,
    this.inputPair,
  });

  final String tokenIn;
  final String tokenOut;
  final BigInt fromAmount;
  final BigInt toAmount;
  final bool isExactIn;
  final String recipient;
  final bool isPaidByRouter;

  final bool isOutputChecked;

  final String? inputPair;
}

class SwapPayout extends SwapStep {
  const SwapPayout({
    required this.token,
    required this.recipient,
    required this.amountMinimum,
    this.isUnwrap = false,
  });

  final String token;
  final String recipient;
  final BigInt amountMinimum;
  final bool isUnwrap;
}

class SwapTransfer extends SwapStep {
  const SwapTransfer({
    required this.token,
    required this.recipient,
    required this.amount,
    this.isFromWallet = false,
    this.isWrap = false,
  });

  final String token;
  final String recipient;
  final BigInt amount;
  final bool isFromWallet;

  final bool isWrap;
}

class SwapPortion extends SwapStep {
  const SwapPortion({required this.token, required this.recipient, required this.fraction});

  static final whole = BigInt.from(10).pow(18);
  static final bip = BigInt.from(10).pow(14);

  static final largestFee = BigInt.from(10).pow(16);

  final String token;
  final String recipient;
  final BigInt fraction;
}

class SwapPermit extends SwapStep {
  const SwapPermit({
    required this.token,
    required this.amount,
    required this.spender,
    this.expiration,
  });

  final String token;
  final BigInt amount;
  final String spender;
  final BigInt? expiration;
}

class UniversalRouterDecoder {
  const UniversalRouterDecoder();

  static const _v3SwapExactIn = 0x00;
  static const _v3SwapExactOut = 0x01;
  static const _permit2TransferFrom = 0x02;
  static const _permit2PermitBatch = 0x03;
  static const _sweep = 0x04;
  static const _transfer = 0x05;
  static const _payPortion = 0x06;
  static const _payPortionFullPrecision = 0x07;
  static const _v2SwapExactIn = 0x08;
  static const _v2SwapExactOut = 0x09;
  static const _permit2Permit = 0x0a;
  static const _wrapEth = 0x0b;
  static const _unwrapWeth = 0x0c;
  static const _permit2TransferFromBatch = 0x0d;
  static const _v4Swap = 0x10;
  static const _executeSubPlan = 0x21;
  static const _allowRevertFlag = 0x80;

  static const _v4SwapExactInSingle = 0x06;
  static const _v4SwapExactIn = 0x07;
  static const _v4SwapExactOutSingle = 0x08;
  static const _v4SwapExactOut = 0x09;
  static const _v4Settle = 0x0b;
  static const _v4SettleAll = 0x0c;
  static const _v4Take = 0x0e;
  static const _v4TakeAll = 0x0f;
  static const _v4TakePortion = 0x10;

  static const _maxSubPlanDepth = 4;

  SwapPlan? decode({
    required EvmCalldata calldata,
    required String routerAddress,
    required String? walletAddress,
    required int? chainId,
    required BigInt valueWei,
  }) {
    final version = EvmSelectors.universalRouterVersion(chainId, routerAddress);
    final commands = <int>[];
    final inputs = <EvmCalldata>[];
    if (!_flatten(calldata, version, commands, inputs, 0) || commands.isEmpty) {
      return null;
    }

    final plan = SwapPlan(
      routerAddress: routerAddress,
      walletAddress: walletAddress,
      chainId: chainId,
      valueWei: valueWei,
    );
    for (var index = 0; index < commands.length; index++) {
      final isRead = _readCommand(
        plan,
        version,
        commands[index] & version.commandMask,
        inputs[index],
      );
      if (!isRead || commands[index] & _allowRevertFlag != 0) {
        plan.hasUnexpectedStep = true;
      }
    }
    return plan;
  }

  bool _flatten(
    EvmCalldata plan,
    UniversalRouterVersion version,
    List<int> commands,
    List<EvmCalldata> inputs,
    int depth,
  ) {
    final ownCommands = plan.dynamicBytesAt(0);
    final ownInputs = plan.bytesArrayAt(1);
    if (ownCommands == null || ownInputs == null || ownCommands.length != ownInputs.length) {
      return false;
    }

    for (var index = 0; index < ownCommands.length; index++) {
      final input = EvmCalldata.fromBody(ownInputs[index]);
      commands.add(ownCommands[index]);
      inputs.add(input);
      final isSubPlan =
          ownCommands[index] & version.commandMask == _executeSubPlan &&
          version.hasV12Commands &&
          depth < _maxSubPlanDepth;
      if (isSubPlan) {
        _flatten(input, version, commands, inputs, depth + 1);
      }
    }
    return true;
  }

  bool _readCommand(SwapPlan plan, UniversalRouterVersion version, int command, EvmCalldata input) {
    switch (command) {
      case _v3SwapExactIn:
        return _readSwap(plan, input, SwapPlan.v3PathTokens(input.dynamicBytesAt(3)));
      case _v3SwapExactOut:
        final path = SwapPlan.v3PathTokens(input.dynamicBytesAt(3))?.reversed.toList();
        return _readSwap(plan, input, path, isExactIn: false);
      case _v2SwapExactIn:
      case _v2SwapExactOut:
        return _readSwap(
          plan,
          input,
          input.addressArrayAt(3),
          isExactIn: command == _v2SwapExactIn,
          isV2: true,
        );
      case _v4Swap:
        final headWords = version.v4MultiHopHeadWords;
        return headWords != null && _readV4Swap(plan, input, headWords);
      case _sweep:
        return _readPayout(plan, input, isUnwrap: false);
      case _unwrapWeth:
        return _readPayout(plan, input, isUnwrap: true);
      case _wrapEth:
        return _readWrap(plan, input);
      case _transfer:
        return _readTransfer(plan, input, isFromWallet: false);
      case _permit2TransferFrom:
        final mapsSentinels = version != UniversalRouterVersion.v1;
        return _readTransfer(plan, input, isFromWallet: true, mapsSentinels: mapsSentinels);
      case _permit2TransferFromBatch:
        return _readTransferBatch(plan, input);
      case _payPortion:
        return _readPortion(plan, input, unit: SwapPortion.bip);
      case _payPortionFullPrecision:
        return version.hasFullPrecisionPortion && _readPortion(plan, input, unit: BigInt.one);
      case _permit2Permit:
        return _readPermit(plan, input, 0, spender: input.addressAt(4));
      case _permit2PermitBatch:
        return _readPermitBatch(plan, input);
    }
    return false;
  }

  bool _readSwap(
    SwapPlan plan,
    EvmCalldata input,
    List<String>? path, {
    bool isExactIn = true,
    bool isV2 = false,
  }) {
    final recipient = input.addressAt(0);
    final amount = input.uintAt(1);
    final amountLimit = input.uintAt(2);
    final payerWord = input.uintAt(4);
    if (recipient == null || amount == null || amountLimit == null || payerWord == null) {
      return false;
    }
    if (path == null || path.length < 2) {
      return false;
    }

    plan.steps.add(
      SwapLeg(
        tokenIn: path.first,
        tokenOut: path.last,
        fromAmount: isExactIn ? amount : amountLimit,
        toAmount: isExactIn ? amountLimit : amount,
        isExactIn: isExactIn,
        recipient: plan.party(recipient, mapsSentinels: true),
        isPaidByRouter: payerWord == BigInt.zero,
        isOutputChecked: isExactIn || !isV2,
        inputPair: isV2 ? EvmSelectors.uniswapV2Pair(plan.chainId, path[0], path[1]) : null,
      ),
    );
    return true;
  }

  bool _readPayout(SwapPlan plan, EvmCalldata input, {required bool isUnwrap}) {
    final token = isUnwrap ? plan.wrappedNative : input.addressAt(0);
    final recipient = input.addressAt(isUnwrap ? 0 : 1);
    final amountMinimum = input.uintAt(isUnwrap ? 1 : 2);
    if (token == null || recipient == null || amountMinimum == null) {
      return false;
    }

    plan.steps.add(
      SwapPayout(
        token: token,
        recipient: plan.party(recipient, mapsSentinels: true),
        amountMinimum: isUnwrap ? amountMinimum : amountMinimum & EvmCalldata.uint160Max,
        isUnwrap: isUnwrap,
      ),
    );
    return true;
  }

  bool _readWrap(SwapPlan plan, EvmCalldata input) {
    final recipient = input.addressAt(0);
    final amount = input.uintAt(1);
    if (recipient == null || amount == null) {
      return false;
    }

    plan.steps.add(
      SwapTransfer(
        token: SwapPlan.nativeToken,
        recipient: plan.party(recipient, mapsSentinels: true),
        amount: amount,
        isWrap: true,
      ),
    );
    return true;
  }

  bool _readTransfer(
    SwapPlan plan,
    EvmCalldata input, {
    required bool isFromWallet,
    bool mapsSentinels = true,
  }) {
    final token = input.addressAt(0);
    final recipient = input.addressAt(1);
    final amount = input.uintAt(2);
    if (token == null || recipient == null || amount == null) {
      return false;
    }

    plan.steps.add(
      SwapTransfer(
        token: token,
        recipient: plan.party(recipient, mapsSentinels: mapsSentinels),
        amount: isFromWallet ? amount & EvmCalldata.uint160Max : amount,
        isFromWallet: isFromWallet,
      ),
    );
    return true;
  }

  bool _readTransferBatch(SwapPlan plan, EvmCalldata input) {
    final details = input.structAt(0);
    final count = details?.boundedUintAt(0);
    if (details == null || count == null) {
      return false;
    }

    for (var index = 0; index < count; index++) {
      final recipient = details.addressAt(2 + index * 4);
      final amount = details.uintAt(3 + index * 4);
      final token = details.addressAt(4 + index * 4);
      if (recipient == null || amount == null || token == null) {
        return false;
      }
      plan.steps.add(
        SwapTransfer(
          token: token,
          recipient: plan.party(recipient),
          amount: amount & EvmCalldata.uint160Max,
          isFromWallet: true,
        ),
      );
    }
    return true;
  }

  bool _readPortion(SwapPlan plan, EvmCalldata input, {required BigInt unit}) {
    final token = input.addressAt(0);
    final recipient = input.addressAt(1);
    final portion = input.uintAt(2);
    if (token == null || recipient == null || portion == null) {
      return false;
    }

    plan.steps.add(
      SwapPortion(
        token: token,
        recipient: plan.party(recipient, mapsSentinels: true),
        fraction: portion * unit,
      ),
    );
    return true;
  }

  bool _readPermit(SwapPlan plan, EvmCalldata details, int firstWord, {required String? spender}) {
    final token = details.addressAt(firstWord);
    final amount = details.uintAt(firstWord + 1);
    if (token == null || amount == null || spender == null) {
      return false;
    }

    plan.steps.add(
      SwapPermit(
        token: token,
        amount: amount,
        spender: spender,
        expiration: details.uintAt(firstWord + 2),
      ),
    );
    return true;
  }

  bool _readPermitBatch(SwapPlan plan, EvmCalldata input) {
    final permitBatch = input.structAt(0);
    final details = permitBatch?.structAt(0);
    final count = details?.boundedUintAt(0);
    if (permitBatch == null || details == null || count == null) {
      return false;
    }

    for (var index = 0; index < count; index++) {
      if (!_readPermit(plan, details, 1 + index * 4, spender: permitBatch.addressAt(1))) {
        return false;
      }
    }
    return true;
  }

  bool _readV4Swap(SwapPlan plan, EvmCalldata input, int multiHopHeadWords) {
    final actions = input.dynamicBytesAt(0, lengthBits: 32);
    final params = input.bytesArrayAt(1, lengthBits: 32);
    if (actions == null || params == null || actions.length != params.length) {
      return false;
    }

    _V4Swap? swap;
    _V4Settle? settle;
    final takes = <SwapStep>[];
    for (var index = 0; index < actions.length; index++) {
      final action = actions[index];
      final param = EvmCalldata.fromBody(params[index]);
      switch (action) {
        case _v4SwapExactInSingle || _v4SwapExactIn || _v4SwapExactOutSingle || _v4SwapExactOut:
          swap = _parseV4Swap(param, action, multiHopHeadWords);
        case _v4Settle || _v4SettleAll:
          settle = _parseV4Settle(param, isAll: action == _v4SettleAll);
        case _v4Take || _v4TakeAll || _v4TakePortion:
          final take = _parseV4Take(plan, param, action);
          if (take != null) {
            takes.add(take);
          }
      }
    }

    final take = takes.singleOrNull;
    if (actions.length != 3 ||
        swap == null ||
        settle == null ||
        take is! SwapPayout ||
        settle.currency != swap.tokenIn ||
        take.token != swap.tokenOut ||
        settle.isOpenDebtPaid == swap.spendsOpenCredit ||
        (!swap.isExactIn && take.amountMinimum < swap.toAmount)) {
      plan.steps.addAll(takes);
      return false;
    }

    plan.steps.add(
      SwapLeg(
        tokenIn: swap.tokenIn,
        tokenOut: swap.tokenOut,
        fromAmount: swap.spendsOpenCredit ? settle.amount : swap.fromAmount,
        toAmount: take.amountMinimum > swap.toAmount ? take.amountMinimum : swap.toAmount,
        isExactIn: swap.isExactIn,
        recipient: take.recipient,
        isPaidByRouter: settle.isPaidByRouter || swap.tokenIn == SwapPlan.nativeToken,
      ),
    );
    return true;
  }

  _V4Settle? _parseV4Settle(EvmCalldata param, {required bool isAll}) {
    final currency = param.addressAt(0);
    final amount = param.uintAt(1);
    final payerWord = isAll ? BigInt.one : param.uintAt(2);
    if (currency == null || amount == null || payerWord == null) {
      return null;
    }

    return _V4Settle(
      currency: currency,
      amount: amount,
      isPaidByRouter: payerWord == BigInt.zero,
      isOpenDebtPaid: isAll || amount == BigInt.zero,
    );
  }

  SwapStep? _parseV4Take(SwapPlan plan, EvmCalldata param, int action) {
    final currency = param.addressAt(0);
    final recipient = action == _v4TakeAll ? null : param.addressAt(1);
    final amount = param.uintAt(action == _v4TakeAll ? 1 : 2);
    if (currency == null || amount == null || (action != _v4TakeAll && recipient == null)) {
      return null;
    }

    final party = recipient == null ? SwapPlan.wallet : plan.party(recipient, mapsSentinels: true);
    return action == _v4TakePortion
        ? SwapPortion(token: currency, recipient: party, fraction: amount * SwapPortion.bip)
        : SwapPayout(token: currency, recipient: party, amountMinimum: amount);
  }

  _V4Swap? _parseV4Swap(EvmCalldata param, int action, int multiHopHeadWords) {
    if (param.uintAt(0) != BigInt.from(0x20)) {
      return null;
    }
    final struct = EvmCalldata.fromBody(param.body.substring(64));
    final isExactIn = action == _v4SwapExactInSingle || action == _v4SwapExactIn;
    if (action == _v4SwapExactInSingle || action == _v4SwapExactOutSingle) {
      return _parseV4Single(struct, isExactIn: isExactIn);
    }
    return _parseV4MultiHop(struct, multiHopHeadWords, isExactIn: isExactIn);
  }

  _V4Swap? _parseV4Single(EvmCalldata struct, {required bool isExactIn}) {
    final currency0 = struct.addressAt(0);
    final currency1 = struct.addressAt(1);
    final zeroForOne = struct.boolAt(5);
    final specifiedAmount = struct.uintAt(6);
    final limitAmount = struct.uintAt(7);
    if (currency0 == null ||
        currency1 == null ||
        zeroForOne == null ||
        specifiedAmount == null ||
        limitAmount == null) {
      return null;
    }

    return _V4Swap(
      tokenIn: zeroForOne ? currency0 : currency1,
      tokenOut: zeroForOne ? currency1 : currency0,
      fromAmount: isExactIn ? specifiedAmount : limitAmount,
      toAmount: isExactIn ? limitAmount : specifiedAmount,
      isExactIn: isExactIn,
    );
  }

  _V4Swap? _parseV4MultiHop(EvmCalldata struct, int headWords, {required bool isExactIn}) {
    final givenCurrency = struct.addressAt(0);
    final specifiedAmount = struct.uintAt(headWords - 2);
    final limitAmount = struct.uintAt(headWords - 1);
    if (givenCurrency == null || specifiedAmount == null || limitAmount == null) {
      return null;
    }
    if (struct.uintAt(1) != BigInt.from(headWords * 32)) {
      return null;
    }

    final hopCount = struct.boundedUintAt(headWords);
    if (hopCount == null || hopCount == 0) {
      return null;
    }
    final firstHopWord = headWords + 1;
    final hopOffset = struct.boundedUintAt(firstHopWord + (isExactIn ? hopCount - 1 : 0));
    if (hopOffset == null || hopOffset % 32 != 0) {
      return null;
    }
    final otherEnd = struct.addressAt(firstHopWord + hopOffset ~/ 32);
    if (otherEnd == null) {
      return null;
    }

    return _V4Swap(
      tokenIn: isExactIn ? givenCurrency : otherEnd,
      tokenOut: isExactIn ? otherEnd : givenCurrency,
      fromAmount: isExactIn ? specifiedAmount : limitAmount,
      toAmount: isExactIn ? limitAmount : specifiedAmount,
      isExactIn: isExactIn,
    );
  }
}

class _V4Swap {
  const _V4Swap({
    required this.tokenIn,
    required this.tokenOut,
    required this.fromAmount,
    required this.toAmount,
    required this.isExactIn,
  });

  final String tokenIn;
  final String tokenOut;
  final BigInt fromAmount;
  final BigInt toAmount;
  final bool isExactIn;

  bool get spendsOpenCredit => isExactIn && fromAmount == BigInt.zero;
}

class _V4Settle {
  const _V4Settle({
    required this.currency,
    required this.amount,
    required this.isPaidByRouter,
    required this.isOpenDebtPaid,
  });

  final String currency;
  final BigInt amount;
  final bool isPaidByRouter;

  final bool isOpenDebtPaid;
}
