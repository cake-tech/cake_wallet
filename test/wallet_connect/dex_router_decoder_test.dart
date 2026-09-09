import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/dex_router_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:flutter_test/flutter_test.dart";

import "abi_hex.dart";

void main() {
  setUpAll(() {
    S.current = const S();
  });

  final decoder = DexRouterDecoder(Erc20TokenResolver(null));
  const weth = "0x1111111111111111111111111111111111111111";
  const tokenOut = "0x2222222222222222222222222222222222222222";
  const recipient = "0x3333333333333333333333333333333333333333";
  const router = "0x4444444444444444444444444444444444444444";
  final halfEth = BigInt.from(5) * BigInt.from(10).pow(17);

  test("swapExactETHForTokens shows the paid transaction value", () async {
    final body = wordInt(90) +
        wordInt(0x80) +
        wordAddr(recipient) +
        wordInt(1700000000) +
        addressArrayBody([weth, tokenOut]);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse("0x7ff36ab5$body")!,
      nativeSymbol: "ETH",
      routerAddress: router,
      walletAddress: recipient,
      valueWei: halfEth,
    );
    expect(decoded!.actionTitle, S.current.wc_action_swap);
    expect(decoded.rows.first.label, S.current.wc_swap_from);
    expect(decoded.rows.first.value, "0.5 ETH");
    expect(decoded.hideValue, isTrue);
  });

  test("swapExactTokensForTokens reads amounts from calldata", () async {
    final body = wordInt(1000) +
        wordInt(900) +
        wordInt(0xa0) +
        wordAddr(recipient) +
        wordInt(1700000000) +
        addressArrayBody([weth, tokenOut]);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse("0x38ed1739$body")!,
      nativeSymbol: "ETH",
      routerAddress: router,
      walletAddress: recipient,
      valueWei: BigInt.zero,
    );
    expect(decoded!.rows.first.value.startsWith("1000"), isTrue);
    expect(decoded.rows[1].value.startsWith("900"), isTrue);
    expect(decoded.hideValue, isFalse);
  });

  test("exactInputSingle decodes the V3 struct words", () async {
    final body = wordAddr(weth) +
        wordAddr(tokenOut) +
        wordInt(3000) +
        wordAddr(recipient) +
        wordInt(1700000000) +
        wordInt(5000) +
        wordInt(4900) +
        wordInt(0);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse("0x414bf389$body")!,
      nativeSymbol: "ETH",
      routerAddress: router,
      walletAddress: recipient,
      valueWei: BigInt.zero,
    );
    expect(decoded!.actionTitle, S.current.wc_action_swap);
    expect(decoded.rows.first.value.startsWith("5000"), isTrue);
    expect(decoded.rows[1].value.startsWith("4900"), isTrue);
  });

  test("SwapRouter02 exactInputSingle reads the shifted struct words", () async {
    final body = wordAddr(weth) +
        wordAddr(tokenOut) +
        wordInt(500) +
        wordAddr(recipient) +
        wordInt(7000) +
        wordInt(6900) +
        wordInt(0);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse("0x04e45aaf$body")!,
      nativeSymbol: "ETH",
      routerAddress: router,
      walletAddress: recipient,
      valueWei: BigInt.zero,
    );
    expect(decoded!.actionTitle, S.current.wc_action_swap);
    expect(decoded.rows.first.value.startsWith("7000"), isTrue);
    expect(decoded.rows[1].value.startsWith("6900"), isTrue);
  });

  test("swapTokensForExactTokens shows the max spend and exact output", () async {
    final body = wordInt(900) +
        wordInt(1000) +
        wordInt(0xa0) +
        wordAddr(recipient) +
        wordInt(1700000000) +
        addressArrayBody([weth, tokenOut]);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse("0x8803dbee$body")!,
      nativeSymbol: "ETH",
      routerAddress: router,
      walletAddress: recipient,
      valueWei: BigInt.zero,
    );
    expect(decoded!.rows.first.label, S.current.wc_swap_from_max);
    expect(decoded.rows.first.value.startsWith("1000"), isTrue);
    expect(decoded.rows[1].label, S.current.wc_swap_to);
    expect(decoded.rows[1].value.startsWith("900"), isTrue);
  });

  test("swapETHForExactTokens takes the max spend from the transaction value", () async {
    final body = wordInt(750) +
        wordInt(0x80) +
        wordAddr(recipient) +
        wordInt(1700000000) +
        addressArrayBody([weth, tokenOut]);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse("0xfb3bdb41$body")!,
      nativeSymbol: "ETH",
      routerAddress: router,
      walletAddress: recipient,
      valueWei: halfEth,
    );
    expect(decoded!.rows.first.label, S.current.wc_swap_from_max);
    expect(decoded.rows.first.value, "0.5 ETH");
    expect(decoded.rows[1].value.startsWith("750"), isTrue);
    expect(decoded.hideValue, isTrue);
  });

  test("swapExactTokensForETH renders the output side as native", () async {
    final body = wordInt(1000) +
        wordInt(900) +
        wordInt(0xa0) +
        wordAddr(recipient) +
        wordInt(1700000000) +
        addressArrayBody([tokenOut, weth]);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse("0x18cbafe5$body")!,
      nativeSymbol: "ETH",
      routerAddress: router,
      walletAddress: recipient,
      valueWei: BigInt.zero,
    );
    expect(decoded!.rows[1].value.endsWith("ETH"), isTrue);
  });

  test("exactOutputSingle swaps the specified and limit amounts", () async {
    final body = wordAddr(weth) +
        wordAddr(tokenOut) +
        wordInt(3000) +
        wordAddr(recipient) +
        wordInt(1700000000) +
        wordInt(4000) +
        wordInt(4200) +
        wordInt(0);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse("0xdb3e2198$body")!,
      nativeSymbol: "ETH",
      routerAddress: router,
      walletAddress: recipient,
      valueWei: BigInt.zero,
    );
    expect(decoded!.rows.first.label, S.current.wc_swap_from_max);
    expect(decoded.rows.first.value.startsWith("4200"), isTrue);
    expect(decoded.rows[1].label, S.current.wc_swap_to);
    expect(decoded.rows[1].value.startsWith("4000"), isTrue);
  });

  test("SwapRouter02 exactOutputSingle reads the shifted words", () async {
    final body = wordAddr(weth) +
        wordAddr(tokenOut) +
        wordInt(3000) +
        wordAddr(recipient) +
        wordInt(4000) +
        wordInt(4200) +
        wordInt(0);
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse("0x5023b4df$body")!,
      nativeSymbol: "ETH",
      routerAddress: router,
      walletAddress: recipient,
      valueWei: BigInt.zero,
    );
    expect(decoded!.rows.first.value.startsWith("4200"), isTrue);
    expect(decoded.rows[1].value.startsWith("4000"), isTrue);
  });

  group("opaque routers", () {
    final opaque = <String, String>{
      "c04b8d59": "Uniswap V3",
      "f28c0498": "Uniswap V3",
      "b858183f": "Uniswap V3",
      "09b81346": "Uniswap V3",
      "415565b0": "0x Protocol",
      "f6274f66": "0x Protocol",
      "7c025200": "1inch",
      "0502b1c5": "1inch",
      "b0431182": "1inch",
      "12aa3caf": "1inch",
    };

    for (final entry in opaque.entries) {
      test("${entry.key} names ${entry.value} and admits the amounts are unknown", () async {
        final decoded = await decoder.decode(
          calldata: EvmCalldata.parse("0x${entry.key}${wordInt(1)}")!,
          nativeSymbol: "ETH",
          routerAddress: router,
          walletAddress: recipient,
          valueWei: BigInt.zero,
        );
        expect(decoded, isNotNull);
        expect(decoded!.actionTitle, S.current.wc_action_swap);
        expect(decoded.actionSubtitle, S.current.wc_via(entry.value));
        expect(decoded.rows.single.value, router);
        expect(decoded.warnings, contains(S.current.wc_warning_swap_amounts_unavailable));
      });
    }
  });

  test("a router selector with unreadable arguments degrades to the opaque view", () async {
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse("0x38ed1739${wordInt(1)}")!,
      nativeSymbol: "ETH",
      routerAddress: router,
      walletAddress: recipient,
      valueWei: BigInt.zero,
    );
    expect(decoded!.actionTitle, S.current.wc_action_swap);
    expect(decoded.warnings, contains(S.current.wc_warning_swap_amounts_unavailable));
  });

  test("non-router selector returns null", () async {
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse("0xdeadbeef${wordInt(1)}")!,
      nativeSymbol: "ETH",
      routerAddress: router,
      walletAddress: recipient,
      valueWei: BigInt.zero,
    );
    expect(decoded, isNull);
  });
}
