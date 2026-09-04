import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/universal_router_decoder.dart";
import "package:cw_core/erc20_token.dart";
import "package:flutter_test/flutter_test.dart";

import "abi_hex.dart";
import "stubs.dart";

void main() {
  setUpAll(() {
    S.current = const S();
  });

  final resolver = StubErc20Resolver({
    "0x1111111111111111111111111111111111111111": Erc20Token(
      name: "Wrapped Ether",
      symbol: "WETH",
      contractAddress: "0x1111111111111111111111111111111111111111",
      decimal: 18,
    ),
    "0x2222222222222222222222222222222222222222": Erc20Token(
      name: "USD Coin",
      symbol: "USDC",
      contractAddress: "0x2222222222222222222222222222222222222222",
      decimal: 6,
    ),
  });
  final decoder = UniversalRouterDecoder(resolver);
  const weth = "0x1111111111111111111111111111111111111111";
  const tokenOut = "0x2222222222222222222222222222222222222222";
  const spender = "0x4444444444444444444444444444444444444444";
  const msgSender = "0x0000000000000000000000000000000000000002";
  final uint160Max = (BigInt.one << 160) - BigInt.one;

  // execute(bytes commands, bytes[] inputs, uint256 deadline): the commands
  // blob sits at 0x60 and, being at most one word here, the inputs follow
  // at 0xa0.
  String executeCalldata(String commandsHex, List<String> inputs) =>
      "0x3593564c${wordInt(0x60)}${wordInt(0xa0)}${wordInt(1700000000)}"
      "${bytesBlob(commandsHex)}${bytesArrayBody(inputs)}";

  String v3ExactInInput({required BigInt amountIn, required BigInt amountOutMin}) {
    final path = "${wordAddr(weth).substring(24)}000bb8${wordAddr(tokenOut).substring(24)}";
    return wordAddr(msgSender) +
        word(amountIn) +
        word(amountOutMin) +
        wordInt(0xa0) +
        wordInt(1) +
        bytesBlob(path);
  }

  String v2ExactInInput({required int amountIn, required int amountOutMin}) =>
      wordAddr(msgSender) +
      wordInt(amountIn) +
      wordInt(amountOutMin) +
      wordInt(0xa0) +
      wordInt(1) +
      addressArrayBody([weth, tokenOut]);

  test("V3 exact-in leg takes the receive floor from UNWRAP_WETH", () async {
    final unwrapInput = wordAddr(msgSender) + wordInt(990);
    final calldata = executeCalldata("000c", [
      v3ExactInInput(amountIn: BigInt.from(10).pow(18), amountOutMin: BigInt.zero),
      unwrapInput,
    ]);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse(calldata)!,
      nativeSymbol: "ETH",
      routerName: "Uniswap Universal Router",
    );
    expect(decoded, isNotNull);
    expect(decoded!.rows.first.label, S.current.wc_swap_from);
    expect(decoded.rows[1].label, S.current.wc_swap_to_min);
    expect(decoded.rows[1].value, "0.00099 USDC");
    expect(decoded.rows[2].value, S.current.wc_recipient_you);
    expect(decoded.warnings, isNot(contains(S.current.wc_warning_zero_slippage)));
    expect(
      decoded.hideValue,
      isFalse,
      reason: "the pay leg is WETH the wallet already holds, so attached ETH is unaccounted for",
    );
  });

  test("split routes over the same pair sum their legs", () async {
    final calldata = executeCalldata("0808", [
      v2ExactInInput(amountIn: 100, amountOutMin: 90),
      v2ExactInInput(amountIn: 50, amountOutMin: 40),
    ]);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse(calldata)!,
      nativeSymbol: "ETH",
      routerName: "Uniswap Universal Router",
    );
    expect(decoded!.rows.first.value, "0.00000000000000015 WETH");
    expect(decoded.rows[1].value, "0.00013 USDC");
  });

  test("PERMIT2_PERMIT surfaces the approval beside the swap", () async {
    final permitInput = wordAddr(tokenOut) +
        word(uint160Max) +
        wordInt(1700000000) +
        wordInt(1) +
        wordAddr(spender) +
        wordInt(1700003600);
    final calldata = executeCalldata("0a08", [
      permitInput,
      v2ExactInInput(amountIn: 100, amountOutMin: 90),
    ]);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse(calldata)!,
      nativeSymbol: "ETH",
      routerName: "Uniswap Universal Router",
    );
    expect(
      decoded!.rows.any(
        (r) => r.label == S.current.wc_action_approve && r.value.startsWith(S.current.wc_unlimited),
      ),
      isTrue,
    );
    expect(decoded.warnings, contains(S.current.wc_warning_unlimited_approval));
    expect(decoded.detailRows.any((r) => r.value == spender), isTrue);
  });

  test("a sweep of a different token does not override the receive floor", () async {
    // SWEEP(tokenOther, recipient, 990) must not become the USDC-side floor.
    const other = "0x9999999999999999999999999999999999999999";
    final sweepInput = wordAddr(other) + wordAddr(msgSender) + wordInt(990);
    final calldata = executeCalldata("0804", [
      v2ExactInInput(amountIn: 100, amountOutMin: 90),
      sweepInput,
    ]);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse(calldata)!,
      nativeSymbol: "ETH",
      routerName: "Uniswap Universal Router",
    );
    expect(decoded!.rows[1].value, "0.00009 USDC");
    expect(decoded.rows[1].value, isNot("0.00099 USDC"));
  });

  test("a sweep of a different token does not rename the swap recipient", () async {
    const attacker = "0x9999999999999999999999999999999999999999";
    const otherToken = "0x3333333333333333333333333333333333333333";
    final swapToAttacker = wordAddr(attacker) +
        wordInt(100) +
        wordInt(90) +
        wordInt(0xa0) +
        wordInt(1) +
        addressArrayBody([weth, tokenOut]);
    final sweepToSelf = wordAddr(otherToken) + wordAddr(msgSender) + wordInt(0);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse(executeCalldata("0804", [swapToAttacker, sweepToSelf]))!,
      nativeSymbol: "ETH",
      routerName: "Uniswap Universal Router",
    );
    final recipientRow = decoded!.rows.firstWhere((r) => r.label == S.current.wc_recipient);
    expect(recipientRow.value, attacker);
    expect(recipientRow.value, isNot(S.current.wc_recipient_you));
  });

  test("swaps of different pairs in one execute are all shown", () async {
    const third = "0x5555555555555555555555555555555555555555";
    String v2Input(List<String> path, int amountIn, int amountOutMin) =>
        wordAddr(msgSender) +
        wordInt(amountIn) +
        wordInt(amountOutMin) +
        wordInt(0xa0) +
        wordInt(1) +
        addressArrayBody(path);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse(
        executeCalldata("0808", [
          v2Input([weth, tokenOut], 100, 90),
          v2Input([tokenOut, third], 200, 180),
        ]),
      )!,
      nativeSymbol: "ETH",
      routerName: "Uniswap Universal Router",
    );
    final payRows = decoded!.rows.where((r) => r.label == S.current.wc_swap_from).toList();
    expect(payRows.length, 2, reason: "a second pair is a second swap, not a split route");
    expect(payRows.first.value, "0.0000000000000001 WETH");
    expect(payRows[1].value, "0.0002 USDC");
  });

  test("a V4 swap that pays in native ETH keeps the value row hidden", () async {
    const zero = "0x0000000000000000000000000000000000000000";
    final struct = wordAddr(zero) +
        wordAddr(tokenOut) +
        wordInt(3000) +
        wordInt(60) +
        wordAddr(zero) +
        wordInt(1) +
        word(BigInt.from(10).pow(15)) +
        wordInt(1500) +
        wordInt(0x120) +
        wordInt(0);
    final input =
        wordInt(0x40) + wordInt(0x80) + bytesBlob("06") + bytesArrayBody([wordInt(0x20) + struct]);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse(executeCalldata("10", [input]))!,
      nativeSymbol: "ETH",
      routerName: "Uniswap Universal Router",
    );
    expect(decoded!.rows.first.value, "0.001 ETH");
    expect(
      decoded.hideValue,
      isTrue,
      reason: "the attached ETH is the pay leg, showing it twice would double count",
    );
  });

  test("V3 exact-out reverses the encoded path and labels the max spend", () async {
    // exact-out V3 paths are encoded tokenOut -> ... -> tokenIn.
    final path = "${wordAddr(tokenOut).substring(24)}000bb8${wordAddr(weth).substring(24)}";
    final input = wordAddr(msgSender) +
        wordInt(500) +
        wordInt(700) +
        wordInt(0xa0) +
        wordInt(1) +
        bytesBlob(path);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse(executeCalldata("01", [input]))!,
      nativeSymbol: "ETH",
      routerName: "Uniswap Universal Router",
    );
    expect(decoded!.rows.first.label, S.current.wc_swap_from_max);
    expect(decoded.rows.first.value, "0.0000000000000007 WETH");
    expect(decoded.rows[1].label, S.current.wc_swap_to);
    expect(decoded.rows[1].value, "0.0005 USDC");
  });

  test("V2 exact-out labels the max spend and exact receive", () async {
    final input = wordAddr(msgSender) +
        wordInt(400) +
        wordInt(600) +
        wordInt(0xa0) +
        wordInt(1) +
        addressArrayBody([weth, tokenOut]);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse(executeCalldata("09", [input]))!,
      nativeSymbol: "ETH",
      routerName: "Uniswap Universal Router",
    );
    expect(decoded!.rows.first.label, S.current.wc_swap_from_max);
    expect(decoded.rows.first.value.startsWith("0.0000000000000006"), isTrue);
    expect(decoded.rows[1].value, "0.0004 USDC");
  });

  test("WRAP_ETH before a swap renders the input side as native", () async {
    final wrapInput = wordAddr(msgSender) + word(BigInt.from(10).pow(18));
    final swapInput = v2ExactInInput(amountIn: 1000000000000000000, amountOutMin: 250000);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse(executeCalldata("0b08", [wrapInput, swapInput]))!,
      nativeSymbol: "ETH",
      routerName: "Uniswap Universal Router",
    );
    expect(decoded!.rows.first.value, "1 ETH");
    expect(decoded.rows[1].value, "0.25 USDC");
  });

  group("V4", () {
    // SWAP_EXACT_IN_SINGLE params: PoolKey(currency0, currency1, fee,
    // tickSpacing, hooks), zeroForOne, amountIn, amountOutMinimum, hookData.
    String v4SingleParam({
      required bool zeroForOne,
      required BigInt specified,
      required BigInt limit,
    }) {
      final struct = wordAddr(weth) +
          wordAddr(tokenOut) +
          wordInt(3000) +
          wordInt(60) +
          wordAddr("0x0000000000000000000000000000000000000000") +
          wordInt(zeroForOne ? 1 : 0) +
          word(specified) +
          word(limit) +
          wordInt(0x120) +
          wordInt(0);
      return wordInt(0x20) + struct;
    }

    String v4Body(String actions, List<String> params) =>
        wordInt(0x40) + wordInt(0x40 + 0x40) + bytesBlob(actions) + bytesArrayBody(params);

    test("exact-in single decodes the pool direction and amounts", () async {
      final input = v4Body(
        "06",
        [
          v4SingleParam(
            zeroForOne: true,
            specified: BigInt.from(2000000),
            limit: BigInt.from(1500),
          ),
        ],
      );
      final decoded = await decoder.decode(
        calldata: EvmCalldata.parse(executeCalldata("10", [input]))!,
        nativeSymbol: "ETH",
        routerName: "Uniswap Universal Router",
      );
      expect(decoded, isNotNull);
      expect(decoded!.warnings, isNot(contains(S.current.wc_warning_v4_undecoded)));
      expect(decoded.rows.first.label, S.current.wc_swap_from);
      expect(decoded.rows.first.value, "0.000000000002 WETH");
      expect(decoded.rows[1].value, "0.0015 USDC");
    });

    test("zeroForOne false flips which pool currency is paid", () async {
      final input = v4Body(
        "06",
        [v4SingleParam(zeroForOne: false, specified: BigInt.from(3000), limit: BigInt.from(40))],
      );
      final decoded = await decoder.decode(
        calldata: EvmCalldata.parse(executeCalldata("10", [input]))!,
        nativeSymbol: "ETH",
        routerName: "Uniswap Universal Router",
      );
      expect(decoded!.rows.first.value, "0.003 USDC");
      expect(decoded.rows[1].value.endsWith("WETH"), isTrue);
    });

    test("TAKE_ALL supplies the receive floor when the swap leaves it zero", () async {
      final input = v4Body("060f", [
        v4SingleParam(zeroForOne: true, specified: BigInt.from(1000000), limit: BigInt.zero),
        wordAddr(tokenOut) + wordInt(900000),
      ]);
      final decoded = await decoder.decode(
        calldata: EvmCalldata.parse(executeCalldata("10", [input]))!,
        nativeSymbol: "ETH",
        routerName: "Uniswap Universal Router",
      );
      expect(decoded!.rows[1].value, "0.9 USDC");
      expect(decoded.warnings, isNot(contains(S.current.wc_warning_zero_slippage)));
    });

    test("SETTLE_ALL supplies the pay ceiling for an exact-out swap", () async {
      final input = v4Body("080c", [
        v4SingleParam(zeroForOne: true, specified: BigInt.from(500000), limit: BigInt.zero),
        wordAddr(weth) + wordInt(1200000),
      ]);
      final decoded = await decoder.decode(
        calldata: EvmCalldata.parse(executeCalldata("10", [input]))!,
        nativeSymbol: "ETH",
        routerName: "Uniswap Universal Router",
      );
      expect(decoded!.rows.first.label, S.current.wc_swap_from_max);
      expect(decoded.rows.first.value, "0.0000000000012 WETH");
    });

    test("TAKE names the final recipient", () async {
      const other = "0x7777777777777777777777777777777777777777";
      final input = v4Body("060e", [
        v4SingleParam(zeroForOne: true, specified: BigInt.from(10), limit: BigInt.from(9)),
        wordAddr(tokenOut) + wordAddr(other) + wordInt(0),
      ]);
      final decoded = await decoder.decode(
        calldata: EvmCalldata.parse(executeCalldata("10", [input]))!,
        nativeSymbol: "ETH",
        routerName: "Uniswap Universal Router",
      );
      expect(decoded!.rows.any((r) => r.value == other), isTrue);
    });
  });

  test("V4 swap that cannot be parsed warns instead of guessing", () async {
    final calldata = executeCalldata("10", [wordInt(1)]);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse(calldata)!,
      nativeSymbol: "ETH",
      routerName: "Uniswap Universal Router",
    );
    expect(decoded!.warnings, contains(S.current.wc_warning_v4_undecoded));
  });

  test("no swap command returns null", () async {
    final calldata = executeCalldata("04", [wordAddr(tokenOut) + wordAddr(msgSender) + wordInt(1)]);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse(calldata)!,
      nativeSymbol: "ETH",
      routerName: "Uniswap Universal Router",
    );
    expect(decoded, isNull);
  });
}
