import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cw_core/utils/print_verbose.dart";

class UniversalRouterDecoder {
  UniversalRouterDecoder(this.tokenResolver);

  final Erc20TokenResolver tokenResolver;

  static const _commandTypeMask = 0x3f;
  static const _v3SwapExactIn = 0x00;
  static const _v3SwapExactOut = 0x01;
  static const _sweep = 0x04;
  static const _v2SwapExactIn = 0x08;
  static const _v2SwapExactOut = 0x09;
  static const _permit2Permit = 0x0a;
  static const _wrapEth = 0x0b;
  static const _unwrapWeth = 0x0c;
  static const _v4Swap = 0x10;

  static const _v4ActionSwapExactInSingle = 0x06;
  static const _v4ActionSwapExactIn = 0x07;
  static const _v4ActionSwapExactOutSingle = 0x08;
  static const _v4ActionSwapExactOut = 0x09;
  static const _v4ActionSettleAll = 0x0c;
  static const _v4ActionTake = 0x0e;
  static const _v4ActionTakeAll = 0x0f;
  static const _v4ActionTakePortion = 0x10;

  static const _sentinelAddressThis = "0x0000000000000000000000000000000000000001";
  static const _sentinelMsgSender = "0x0000000000000000000000000000000000000002";
  static const _zeroAddress = "0x0000000000000000000000000000000000000000";

  Future<WCDecodedRequest?> decode({
    required EvmCalldata calldata,
    required String nativeSymbol,
    required String routerName,
    String? walletAddress,
  }) async {
    final commands = calldata.dynamicBytesAt(0);
    final inputs = calldata.bytesArrayAt(1);
    if (commands == null || inputs == null) {
      return null;
    }
    if (commands.isEmpty || commands.length != inputs.length) {
      return null;
    }

    var hasWrap = false;
    var sawV4Swap = false;
    final legs = <_SwapLeg>[];
    _UrPermit? permit;
    _DeliverStep? deliver;

    for (var i = 0; i < commands.length; i++) {
      final cmd = commands[i] & _commandTypeMask;

      if (cmd == _wrapEth) {
        hasWrap = true;
        continue;
      }

      if (cmd == _permit2Permit) {
        permit ??= _decodePermitCommand(EvmCalldata.fromBody(inputs[i]));
        continue;
      }

      if (cmd == _unwrapWeth || cmd == _sweep) {
        deliver ??= _decodeDeliver(EvmCalldata.fromBody(inputs[i]), isSweep: cmd == _sweep);
        continue;
      }

      final input = EvmCalldata.fromBody(inputs[i]);
      _SwapLeg? parsed;
      switch (cmd) {
        case _v3SwapExactIn:
          parsed = _decodeV3(input, exactIn: true);
          break;
        case _v3SwapExactOut:
          parsed = _decodeV3(input, exactIn: false);
          break;
        case _v2SwapExactIn:
          parsed = _decodeV2(input, exactIn: true);
          break;
        case _v2SwapExactOut:
          parsed = _decodeV2(input, exactIn: false);
          break;
        case _v4Swap:
          sawV4Swap = true;
          parsed = _decodeV4(input);
          break;
      }
      if (parsed != null) {
        legs.add(parsed);
      }
    }

    final permitRows = await _permitRows(permit);
    final permitDetailRows = _permitDetailRows(permit);
    final permitUnlimited = permit != null && tokenResolver.isUnlimitedAmount(permit.amount);

    final mergedLegs = _mergeLegs(legs);

    if (mergedLegs.isEmpty && sawV4Swap) {
      return WCDecodedRequest(
        actionTitle: S.current.wc_action_swap,
        actionSubtitle: S.current.wc_via("Uniswap V4 (Universal Router)"),
        rows: permitRows,
        detailRows: permitDetailRows,
        warnings: [
          S.current.wc_warning_v4_undecoded,
          if (permitUnlimited) S.current.wc_warning_unlimited_approval,
        ],
        hideTo: true,
      );
    }

    if (mergedLegs.isEmpty) {
      return null;
    }

    if (mergedLegs.length > 1) {
      return _multiRouteRequest(
        legs: mergedLegs,
        nativeSymbol: nativeSymbol,
        routerName: routerName,
        walletAddress: walletAddress,
        hasWrap: hasWrap,
        permitRows: permitRows,
        permitDetailRows: permitDetailRows,
        permitUnlimited: permitUnlimited,
      );
    }

    final leg = mergedLegs.first;

    final deliversSwapOutput = deliver != null &&
        (deliver.token == null || deliver.token!.toLowerCase() == leg.tokenOut.toLowerCase());

    final effectiveToAmount =
        (leg.exactIn && deliversSwapOutput && deliver.amountMinimum > BigInt.zero)
            ? deliver.amountMinimum
            : leg.toAmount;
    final effectiveRecipient = deliversSwapOutput ? deliver.recipient : leg.recipient;
    final isUnwrapToNative = (deliver?.isUnwrap == true && deliversSwapOutput) ||
        (deliver == null && leg.toAmount == BigInt.zero);

    final descs = await Future.wait([
      _describe(leg.tokenIn, leg.fromAmount, nativeSymbol, preferNative: hasWrap),
      _describe(leg.tokenOut, effectiveToAmount, nativeSymbol, preferNative: isUnwrapToNative),
    ]);

    final noMinProtection = leg.exactIn && effectiveToAmount == BigInt.zero;
    final noMaxProtection = !leg.exactIn && leg.fromAmount == BigInt.zero;

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_swap,
      actionSubtitle: S.current.wc_via(routerName),
      rows: [
        WCDecodedRow(
          label: leg.exactIn ? S.current.wc_swap_from : S.current.wc_swap_from_max,
          value: descs[0],
        ),
        WCDecodedRow(
          label: leg.exactIn ? S.current.wc_swap_to_min : S.current.wc_swap_to,
          value: descs[1],
        ),
        if (effectiveRecipient != null) _recipientRow(effectiveRecipient, walletAddress),
        ...permitRows,
      ],
      detailRows: permitDetailRows,
      warnings: [
        S.current.wc_warning_swap_amounts_estimated,
        if (noMinProtection || noMaxProtection) S.current.wc_warning_zero_slippage,
        if (permitUnlimited) S.current.wc_warning_unlimited_approval,
      ],
      hideTo: true,
      hideValue: hasWrap || leg.tokenIn.toLowerCase() == _zeroAddress,
    );
  }

  Future<WCDecodedRequest> _multiRouteRequest({
    required List<_SwapLeg> legs,
    required String nativeSymbol,
    required String routerName,
    required String? walletAddress,
    required bool hasWrap,
    required List<WCDecodedRow> permitRows,
    required List<WCDecodedRow> permitDetailRows,
    required bool permitUnlimited,
  }) async {
    final rows = <WCDecodedRow>[];
    for (final leg in legs) {
      final descs = await Future.wait([
        _describe(leg.tokenIn, leg.fromAmount, nativeSymbol, preferNative: hasWrap),
        _describe(leg.tokenOut, leg.toAmount, nativeSymbol, preferNative: false),
      ]);
      rows.add(
        WCDecodedRow(
          label: leg.exactIn ? S.current.wc_swap_from : S.current.wc_swap_from_max,
          value: descs[0],
        ),
      );
      rows.add(
        WCDecodedRow(
          label: leg.exactIn ? S.current.wc_swap_to_min : S.current.wc_swap_to,
          value: descs[1],
        ),
      );
    }

    final recipient = legs.map((l) => l.recipient).firstWhere((r) => r != null, orElse: () => null);
    if (recipient != null) {
      rows.add(_recipientRow(recipient, walletAddress));
    }
    rows.addAll(permitRows);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_swap,
      actionSubtitle: S.current.wc_via(routerName),
      rows: rows,
      detailRows: permitDetailRows,
      warnings: [
        S.current.wc_warning_swap_amounts_estimated,
        if (permitUnlimited) S.current.wc_warning_unlimited_approval,
      ],
      hideTo: true,
      hideValue: hasWrap || legs.any((l) => l.tokenIn.toLowerCase() == _zeroAddress),
    );
  }

  List<_SwapLeg> _mergeLegs(List<_SwapLeg> legs) {
    if (legs.length < 2) {
      return legs;
    }
    final first = legs.first;

    final samePair = legs.every(
      (l) =>
          l.exactIn == first.exactIn &&
          l.tokenIn.toLowerCase() == first.tokenIn.toLowerCase() &&
          l.tokenOut.toLowerCase() == first.tokenOut.toLowerCase(),
    );
    if (!samePair) {
      return legs;
    }

    var fromTotal = BigInt.zero;
    var toTotal = BigInt.zero;
    for (final l in legs) {
      fromTotal += l.fromAmount;
      toTotal += l.toAmount;
    }
    return [
      _SwapLeg(
        tokenIn: first.tokenIn,
        tokenOut: first.tokenOut,
        fromAmount: fromTotal,
        toAmount: toTotal,
        exactIn: first.exactIn,
        recipient: legs.map((l) => l.recipient).firstWhere((r) => r != null, orElse: () => null),
      ),
    ];
  }

  _UrPermit? _decodePermitCommand(EvmCalldata input) {
    final token = input.addressAt(0);
    final amount = input.uintAt(1);
    final expiration = input.uintAt(2);
    final spender = input.addressAt(4);
    if (token == null || amount == null) {
      return null;
    }
    return _UrPermit(token: token, amount: amount, expiration: expiration, spender: spender);
  }

  Future<List<WCDecodedRow>> _permitRows(_UrPermit? permit) async {
    if (permit == null) {
      return const [];
    }
    final token = await tokenResolver.resolve(permit.token);
    final symbol = tokenResolver.symbolOrShort(token, permit.token);
    return [
      WCDecodedRow(
        label: S.current.wc_action_approve,
        value: "${tokenResolver.formatAmount(permit.amount, token)} $symbol",
        kind: WCDecodedRowKind.amount,
      ),
    ];
  }

  List<WCDecodedRow> _permitDetailRows(_UrPermit? permit) {
    if (permit == null) {
      return const [];
    }
    return [
      if (permit.spender != null)
        WCDecodedRow(
          label: S.current.wc_approved_spender,
          value: permit.spender!,
          kind: WCDecodedRowKind.address,
        ),
      if (permit.expiration != null)
        WCDecodedRow(
          label: S.current.wc_expiration,
          value: tokenResolver.formatTimestamp(permit.expiration),
        ),
    ];
  }

  WCDecodedRow _recipientRow(String recipient, String? walletAddress) {
    final lower = recipient.toLowerCase();
    final isOwnWallet = walletAddress != null && lower == walletAddress.toLowerCase();
    if (lower == _sentinelMsgSender || isOwnWallet) {
      return WCDecodedRow(
        label: S.current.wc_recipient,
        value: S.current.wc_recipient_you,
      );
    }
    if (lower == _sentinelAddressThis) {
      return WCDecodedRow(
        label: S.current.wc_recipient,
        value: S.current.wc_recipient_router_hold,
      );
    }
    return WCDecodedRow(
      label: S.current.wc_recipient,
      value: recipient,
      kind: WCDecodedRowKind.address,
    );
  }

  _DeliverStep? _decodeDeliver(EvmCalldata input, {required bool isSweep}) {
    if (isSweep) {
      final token = input.addressAt(0);
      final recipient = input.addressAt(1);
      final min = input.uintAt(2);
      if (recipient == null || min == null) {
        return null;
      }
      return _DeliverStep(
        recipient: recipient,
        amountMinimum: min,
        isUnwrap: false,
        token: token,
      );
    }
    final recipient = input.addressAt(0);
    final min = input.uintAt(1);
    if (recipient == null || min == null) {
      return null;
    }
    return _DeliverStep(recipient: recipient, amountMinimum: min, isUnwrap: true);
  }

  _SwapLeg? _decodeV3(EvmCalldata input, {required bool exactIn}) {
    final recipient = input.addressAt(0);
    final amount = input.uintAt(1);
    final amountLimit = input.uintAt(2);
    final path = input.dynamicBytesAt(3);
    if (amount == null || amountLimit == null || path == null || path.length < 40) {
      return null;
    }

    final firstToken = _addressFromBytes(path, 0);
    final lastToken = _addressFromBytes(path, path.length - 20);

    if (exactIn) {
      return _SwapLeg(
        tokenIn: firstToken,
        tokenOut: lastToken,
        fromAmount: amount,
        toAmount: amountLimit,
        exactIn: true,
        recipient: recipient,
      );
    }

    return _SwapLeg(
      tokenIn: lastToken,
      tokenOut: firstToken,
      fromAmount: amountLimit,
      toAmount: amount,
      exactIn: false,
      recipient: recipient,
    );
  }

  _SwapLeg? _decodeV2(EvmCalldata input, {required bool exactIn}) {
    final recipient = input.addressAt(0);
    final amount = input.uintAt(1);
    final amountLimit = input.uintAt(2);
    final path = input.addressArrayAt(3);
    if (amount == null || amountLimit == null || path == null || path.length < 2) {
      return null;
    }

    final tokenIn = path.first;
    final tokenOut = path.last;
    if (exactIn) {
      return _SwapLeg(
        tokenIn: tokenIn,
        tokenOut: tokenOut,
        fromAmount: amount,
        toAmount: amountLimit,
        exactIn: true,
        recipient: recipient,
      );
    }
    return _SwapLeg(
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      fromAmount: amountLimit,
      toAmount: amount,
      exactIn: false,
      recipient: recipient,
    );
  }

  Future<String> _describe(
    String tokenAddress,
    BigInt amount,
    String nativeSymbol, {
    required bool preferNative,
  }) async {
    if (tokenAddress.toLowerCase() == _zeroAddress) {
      return "${tokenResolver.formatNativeAmount(amount)} $nativeSymbol";
    }

    final token = await tokenResolver.resolve(tokenAddress);
    final symbol = tokenResolver.symbolOrShort(token, tokenAddress);
    final native = nativeSymbol.toUpperCase();
    final isWrappedNative = token != null && (symbol == "W$native" || symbol == native);

    if (preferNative && isWrappedNative) {
      return "${tokenResolver.formatNativeAmount(amount)} $nativeSymbol";
    }

    final amountStr = tokenResolver.formatAmount(amount, token);
    return "$amountStr $symbol";
  }

  _SwapLeg? _decodeV4(EvmCalldata input) {
    try {
      final actionBytes = input.dynamicBytesAt(0);
      final paramsList = input.bytesArrayAt(1);
      if (actionBytes == null || paramsList == null) {
        return null;
      }
      if (actionBytes.length != paramsList.length) {
        return null;
      }
      if (actionBytes.isEmpty) {
        return null;
      }

      _V4SwapInfo? swap;
      BigInt? takeMin;
      BigInt? settleMax;
      String? finalRecipient;

      for (var i = 0; i < actionBytes.length; i++) {
        final action = actionBytes[i];
        final param = EvmCalldata.fromBody(paramsList[i]);

        switch (action) {
          case _v4ActionSwapExactInSingle:
            swap ??= _parseV4Single(param, exactIn: true);
            break;
          case _v4ActionSwapExactOutSingle:
            swap ??= _parseV4Single(param, exactIn: false);
            break;
          case _v4ActionSwapExactIn:
            swap ??= _parseV4MultiHop(param, exactIn: true);
            break;
          case _v4ActionSwapExactOut:
            swap ??= _parseV4MultiHop(param, exactIn: false);
            break;
          case _v4ActionTakeAll:
            takeMin ??= param.uintAt(1);
            break;
          case _v4ActionTake:
          case _v4ActionTakePortion:
            finalRecipient ??= param.addressAt(1);
            break;
          case _v4ActionSettleAll:
            settleMax ??= param.uintAt(1);
            break;
        }
      }

      if (swap == null) {
        return null;
      }

      final fromAmount = (!swap.exactIn && settleMax != null && settleMax > BigInt.zero)
          ? settleMax
          : swap.fromAmount;
      final toAmount =
          (swap.exactIn && takeMin != null && takeMin > BigInt.zero) ? takeMin : swap.toAmount;

      return _SwapLeg(
        tokenIn: swap.tokenIn,
        tokenOut: swap.tokenOut,
        fromAmount: fromAmount,
        toAmount: toAmount,
        exactIn: swap.exactIn,
        recipient: finalRecipient,
      );
    } catch (e) {
      printV("UniversalRouterDecoder: V4 action decode failed: $e");
      return null;
    }
  }

  _V4SwapInfo? _parseV4Single(EvmCalldata raw, {required bool exactIn}) {
    final p = _unwrapV4Param(raw);
    final currency0 = p.addressAt(0);
    final currency1 = p.addressAt(1);
    final zeroForOne = p.boolAt(5);
    final specifiedAmount = p.uintAt(6);
    final limitAmount = p.uintAt(7);
    if (currency0 == null ||
        currency1 == null ||
        zeroForOne == null ||
        specifiedAmount == null ||
        limitAmount == null) {
      return null;
    }
    final tokenIn = zeroForOne ? currency0 : currency1;
    final tokenOut = zeroForOne ? currency1 : currency0;
    if (exactIn) {
      return _V4SwapInfo(
        tokenIn: tokenIn,
        tokenOut: tokenOut,
        fromAmount: specifiedAmount,
        toAmount: limitAmount,
        exactIn: true,
      );
    }
    return _V4SwapInfo(
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      fromAmount: limitAmount,
      toAmount: specifiedAmount,
      exactIn: false,
    );
  }

  _V4SwapInfo? _parseV4MultiHop(EvmCalldata raw, {required bool exactIn}) {
    final p = _unwrapV4Param(raw);
    final currencyIn = p.addressAt(0);
    if (currencyIn == null) {
      return null;
    }

    final s2 = p.uintAt(2);
    final s3 = p.uintAt(3);
    final s4 = p.uintAt(4);

    BigInt? specified;
    BigInt? limit;
    final looksShifted =
        s2 != null && s3 != null && s2 < BigInt.from(0x10000) && s3 > s2 * BigInt.from(1000);
    if (looksShifted && s4 != null) {
      specified = s3;
      limit = s4;
    } else {
      specified = s2;
      limit = s3;
    }
    if (specified == null || limit == null) {
      return null;
    }

    final pathOffsetBytes = p.uintAt(1)?.toInt();
    String tokenOut = currencyIn;
    if (pathOffsetBytes != null) {
      final lastHop = _readV4LastHopCurrency(p, pathOffsetBytes);
      if (lastHop != null) {
        tokenOut = lastHop;
      }
    }

    if (exactIn) {
      return _V4SwapInfo(
        tokenIn: currencyIn,
        tokenOut: tokenOut,
        fromAmount: specified,
        toAmount: limit,
        exactIn: true,
      );
    }
    return _V4SwapInfo(
      tokenIn: currencyIn,
      tokenOut: tokenOut,
      fromAmount: limit,
      toAmount: specified,
      exactIn: false,
    );
  }

  String? _readV4LastHopCurrency(EvmCalldata struct, int byteOffset) {
    final pathLengthWord = byteOffset ~/ 32;
    final count = struct.uintAt(pathLengthWord)?.toInt();
    if (count == null || count <= 0) {
      return null;
    }
    final lastOffsetWord = pathLengthWord + count;
    final lastOffsetBytes = struct.uintAt(lastOffsetWord)?.toInt();
    if (lastOffsetBytes == null) {
      return null;
    }
    final pathBodyStartBytes = (pathLengthWord + 1) * 32;
    final pathKeyStartWord = (pathBodyStartBytes + lastOffsetBytes) ~/ 32;
    return struct.addressAt(pathKeyStartWord);
  }

  EvmCalldata _unwrapV4Param(EvmCalldata raw) {
    if (raw.body.length < 64) {
      return raw;
    }
    final first = raw.uintAt(0)?.toInt();
    if (first == 0x20) {
      return EvmCalldata.fromBody(raw.body.substring(64));
    }
    return raw;
  }

  String _addressFromBytes(List<int> bytes, int offset) {
    final slice = bytes.sublist(offset, offset + 20);
    final hex = slice.map((b) => b.toRadixString(16).padLeft(2, "0")).join();
    return "0x$hex";
  }
}

class _SwapLeg {
  const _SwapLeg({
    required this.tokenIn,
    required this.tokenOut,
    required this.fromAmount,
    required this.toAmount,
    required this.exactIn,
    required this.recipient,
  });

  final String tokenIn;
  final String tokenOut;
  final BigInt fromAmount;
  final BigInt toAmount;
  final bool exactIn;
  final String? recipient;
}

class _UrPermit {
  const _UrPermit({
    required this.token,
    required this.amount,
    this.expiration,
    this.spender,
  });

  final String token;
  final BigInt amount;
  final BigInt? expiration;
  final String? spender;
}

class _V4SwapInfo {
  const _V4SwapInfo({
    required this.tokenIn,
    required this.tokenOut,
    required this.fromAmount,
    required this.toAmount,
    required this.exactIn,
  });

  final String tokenIn;
  final String tokenOut;
  final BigInt fromAmount;
  final BigInt toAmount;
  final bool exactIn;
}

class _DeliverStep {
  const _DeliverStep({
    required this.recipient,
    required this.amountMinimum,
    required this.isUnwrap,
    this.token,
  });

  final String recipient;
  final BigInt amountMinimum;
  final bool isUnwrap;
  final String? token;
}
