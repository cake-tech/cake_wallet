import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart';

/// Decodes a Uniswap Universal Router `execute(bytes commands, bytes[] inputs
/// [, uint256 deadline])` payload into a readable swap. The router batches a
/// sequence of one-byte command opcodes, each with an ABI-encoded input tuple;
/// we surface the first swap leg plus any WRAP/UNWRAP so a USDT→ETH swap reads
/// as "3 USDT → ETH" rather than an opaque "Value: 0 ETH".
class UniversalRouterDecoder {
  UniversalRouterDecoder(this.tokenResolver);

  final Erc20TokenResolver tokenResolver;

  // Universal Router command opcodes (low 6 bits; high bits are flags).
  static const _commandTypeMask = 0x3f;
  static const _v3SwapExactIn = 0x00;
  static const _v3SwapExactOut = 0x01;
  static const _v2SwapExactIn = 0x08;
  static const _v2SwapExactOut = 0x09;
  static const _wrapEth = 0x0b;
  static const _unwrapWeth = 0x0c;

  Future<WCDecodedRequest?> decode({
    required EvmCalldata calldata,
    required String nativeSymbol,
    required String routerName,
  }) async {
    final commands = calldata.dynamicBytesAt(0);
    final inputs = calldata.bytesArrayAt(1);
    if (commands == null || inputs == null) return null;
    if (commands.isEmpty || commands.length != inputs.length) return null;

    var hasWrap = false;
    var hasUnwrap = false;
    _SwapLeg? leg;

    for (var i = 0; i < commands.length; i++) {
      final cmd = commands[i] & _commandTypeMask;
      if (cmd == _wrapEth) {
        hasWrap = true;
        continue;
      }
      if (cmd == _unwrapWeth) {
        hasUnwrap = true;
        continue;
      }
      if (leg != null) continue;

      final input = EvmCalldata.fromBody(inputs[i]);
      switch (cmd) {
        case _v3SwapExactIn:
          leg = _decodeV3(input, exactIn: true);
          break;
        case _v3SwapExactOut:
          leg = _decodeV3(input, exactIn: false);
          break;
        case _v2SwapExactIn:
          leg = _decodeV2(input, exactIn: true);
          break;
        case _v2SwapExactOut:
          leg = _decodeV2(input, exactIn: false);
          break;
      }
    }

    if (leg == null) return null;

    final fromDesc =
        await _describe(leg.tokenIn, leg.fromAmount, nativeSymbol, preferNative: hasWrap);
    final toDesc =
        await _describe(leg.tokenOut, leg.toAmount, nativeSymbol, preferNative: hasUnwrap);

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_swap,
      actionSubtitle: S.current.wc_via(routerName),
      rows: [
        WCDecodedRow(
          label: leg.exactIn ? S.current.wc_swap_from : S.current.wc_swap_from_max,
          value: fromDesc,
        ),
        WCDecodedRow(
          label: leg.exactIn ? S.current.wc_swap_to_min : S.current.wc_swap_to,
          value: toDesc,
        ),
      ],
      warnings: [S.current.wc_warning_swap_amounts_estimated],
      hideTo: true,
      hideZeroValue: true,
    );
  }

  _SwapLeg? _decodeV3(EvmCalldata input, {required bool exactIn}) {
    // (address recipient, uint256 amount, uint256 amountLimit, bytes path, bool payerIsUser)
    final amount = input.uintAt(1);
    final amountLimit = input.uintAt(2);
    final path = input.dynamicBytesAt(3);
    if (amount == null || amountLimit == null || path == null || path.length < 40) {
      return null;
    }

    final firstToken = _addressFromBytes(path, 0);
    final lastToken = _addressFromBytes(path, path.length - 20);

    if (exactIn) {
      // path is tokenIn -> ... -> tokenOut
      return _SwapLeg(
        tokenIn: firstToken,
        tokenOut: lastToken,
        fromAmount: amount,
        toAmount: amountLimit,
        exactIn: true,
      );
    }
    // exact-out path is encoded reversed: tokenOut -> ... -> tokenIn
    return _SwapLeg(
      tokenIn: lastToken,
      tokenOut: firstToken,
      fromAmount: amountLimit,
      toAmount: amount,
      exactIn: false,
    );
  }

  _SwapLeg? _decodeV2(EvmCalldata input, {required bool exactIn}) {
    // (address recipient, uint256 amount, uint256 amountLimit, address[] path, bool payerIsUser)
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
      );
    }
    return _SwapLeg(
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      fromAmount: amountLimit,
      toAmount: amount,
      exactIn: false,
    );
  }

  Future<String> _describe(
    String tokenAddress,
    BigInt amount,
    String nativeSymbol, {
    required bool preferNative,
  }) async {
    final token = await tokenResolver.resolve(tokenAddress);
    final symbol = tokenResolver.symbolOrShort(token, tokenAddress);
    final native = nativeSymbol.toUpperCase();
    final isWrappedNative = token != null && (symbol == 'W$native' || symbol == native);

    if (preferNative && isWrappedNative) {
      final amountNative = amount.toDouble() / 1e18;
      return '${tokenResolver.formatNative(amountNative)} $nativeSymbol';
    }

    final amountStr = tokenResolver.formatAmount(amount, token);
    return '$amountStr $symbol';
  }

  String _addressFromBytes(List<int> bytes, int offset) {
    final slice = bytes.sublist(offset, offset + 20);
    final hex = slice.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '0x$hex';
  }
}

class _SwapLeg {
  const _SwapLeg({
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
