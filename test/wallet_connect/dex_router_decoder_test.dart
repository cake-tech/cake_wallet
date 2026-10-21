import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/dex_router_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cw_core/erc20_token.dart";
import "package:flutter_test/flutter_test.dart";

import "abi_hex.dart";
import "stubs.dart";

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
      chainId: 1,
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
      chainId: 1,
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
      chainId: 1,
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
      chainId: 1,
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
      chainId: 1,
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
      chainId: 1,
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
      chainId: 1,
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
      chainId: 1,
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
      chainId: 1,
    );
    expect(decoded!.rows.first.value.startsWith("4200"), isTrue);
    expect(decoded.rows[1].value.startsWith("4000"), isTrue);
  });

  group("opaque routers", () {
    const uniswapV3Router = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
    const zeroXExchangeProxy = "0xDef1C0ded9bec7F1a1670819833240f027b25EfF";
    const oneInchV5Router = "0x1111111254EEB25477B68fb85Ed929f73A960582";
    final opaque = <String, (String, String)>{
      "c04b8d59": ("Uniswap V3", uniswapV3Router),
      "f28c0498": ("Uniswap V3", uniswapV3Router),
      "b858183f": ("Uniswap V3", uniswapV3Router),
      "09b81346": ("Uniswap V3", uniswapV3Router),
      "415565b0": ("0x Protocol", zeroXExchangeProxy),
      "f6274f66": ("0x Protocol", zeroXExchangeProxy),
      "7c025200": ("1inch", oneInchV5Router),
      "0502b1c5": ("1inch", oneInchV5Router),
      "b0431182": ("1inch", oneInchV5Router),
      "12aa3caf": ("1inch", oneInchV5Router),
    };

    for (final entry in opaque.entries) {
      final (protocol, deployment) = entry.value;
      test("${entry.key} on $protocol's own router names it and admits the amounts are unknown",
          () async {
        final decoded = await decoder.decode(
          calldata: EvmCalldata.parse("0x${entry.key}${wordInt(1)}")!,
          nativeSymbol: "ETH",
          routerAddress: deployment,
          walletAddress: recipient,
          valueWei: BigInt.zero,
          chainId: 1,
        );
        expect(decoded, isNotNull);
        expect(decoded!.actionTitle, S.current.wc_action_swap);
        expect(decoded.actionSubtitle, S.current.wc_via(protocol));
        expect(decoded.rows.single.value, deployment);
        expect(decoded.warnings, contains(S.current.wc_warning_swap_amounts_unavailable));
        expect(decoded.warnings, isNot(contains(S.current.wc_warning_unknown_contract)));
      });
    }
  });

  group("router identity", () {
    String swapExactEthForTokens() =>
        "0x7ff36ab5${wordInt(90)}${wordInt(0x80)}${wordAddr(recipient)}${wordInt(1700000000)}"
        "${addressArrayBody([weth, tokenOut])}";

    test("an unlisted contract using a Uniswap selector is not called Uniswap", () async {
      const impostor = "0x9999999999999999999999999999999999999999";
      final decoded = await decoder.decode(
        calldata: EvmCalldata.parse(swapExactEthForTokens())!,
        nativeSymbol: "ETH",
        routerAddress: impostor,
        walletAddress: recipient,
        valueWei: halfEth,
        chainId: 1,
      );
      expect(decoded!.actionSubtitle, S.current.wc_via("0x9999…9999"));
      expect(decoded.rows.firstWhere((r) => r.label == S.current.wc_router).value, impostor);
      expect(decoded.warnings, contains(S.current.wc_warning_unknown_contract));
    });

    test("a Uniswap router on another chain is not trusted by address alone", () async {
      const mainnetV2Router = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
      final decoded = await decoder.decode(
        calldata: EvmCalldata.parse(swapExactEthForTokens())!,
        nativeSymbol: "ETH",
        routerAddress: mainnetV2Router,
        walletAddress: recipient,
        valueWei: halfEth,
        chainId: 8453,
      );
      expect(decoded!.actionSubtitle, isNot(S.current.wc_via("Uniswap V2")));
      expect(decoded.warnings, contains(S.current.wc_warning_unknown_contract));
    });

    test("a V2 swap to the signing wallet names it as you, a stranger stays an address", () async {
      const mainnetV2Router = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
      const stranger = "0x7777777777777777777777777777777777777777";
      Future<String> recipientShownFor(String walletAddress) async {
        final decoded = await decoder.decode(
          calldata: EvmCalldata.parse(swapExactEthForTokens())!,
          nativeSymbol: "ETH",
          routerAddress: mainnetV2Router,
          walletAddress: walletAddress,
          valueWei: halfEth,
          chainId: 1,
        );
        return decoded!.rows.firstWhere((r) => r.label == S.current.wc_recipient).value;
      }

      expect(await recipientShownFor(recipient), S.current.wc_recipient_you);
      expect(await recipientShownFor(stranger), recipient);
    });

    test("the listed router keeps its name and still shows its address", () async {
      const mainnetV2Router = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
      final decoded = await decoder.decode(
        calldata: EvmCalldata.parse(swapExactEthForTokens())!,
        nativeSymbol: "ETH",
        routerAddress: mainnetV2Router,
        walletAddress: recipient,
        valueWei: halfEth,
        chainId: 1,
      );
      expect(decoded!.actionSubtitle, S.current.wc_via("Uniswap V2"));
      expect(
        decoded.rows.firstWhere((r) => r.label == S.current.wc_router).value,
        mainnetV2Router,
      );
      expect(decoded.warnings, isNot(contains(S.current.wc_warning_unknown_contract)));
    });
  });

  test("a router selector with unreadable arguments degrades to the opaque view", () async {
    final decoded = await decoder.decode(
      calldata: EvmCalldata.parse("0x38ed1739${wordInt(1)}")!,
      nativeSymbol: "ETH",
      routerAddress: router,
      walletAddress: recipient,
      valueWei: BigInt.zero,
      chainId: 1,
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
      chainId: 1,
    );
    expect(decoded, isNull);
  });

  group("V3 swap paid with ETH", () {
    const mainnetWeth = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
    const dai = "0x6b175474e89094c44da98b954eedeac495271d0f";
    final twoTenthsEth = BigInt.parse("2c68af0bb140000", radix: 16);
    final resolvingDecoder = DexRouterDecoder(
      StubErc20Resolver({
        mainnetWeth: Erc20Token(
          name: "Wrapped Ether",
          symbol: "WETH",
          contractAddress: mainnetWeth,
          decimal: 18,
        ),
        dai: Erc20Token(name: "Dai", symbol: "DAI", contractAddress: dai, decimal: 18),
      }),
    );

    String exactInputSingle(String payToken) => "0x414bf389${wordAddr(payToken)}"
        "000000000000000000000000c552b5706baa14c1f0104e95380ea3dc102a481f"
        "0000000000000000000000000000000000000000000000000000000000000064"
        "000000000000000000000000364cc1be5a6f9f2f743815ebde7e82b5952747b3"
        "000000000000000000000000000000000000000000000000000000006ac78487"
        "00000000000000000000000000000000000000000000000002c68af0bb140000"
        "0000000000000000000000000000000000000000000000000000000000000000"
        "0000000000000000000000000000000000000000000000000000000000000000";

    test("golden vector: mainnet WETH-in swap with equal value shows ETH once", () async {
      final decoded = await resolvingDecoder.decode(
        calldata: EvmCalldata.parse(exactInputSingle(mainnetWeth))!,
        nativeSymbol: "ETH",
        routerAddress: "0xE592427A0AEce92De3Edee1F18E0157C05861564",
        valueWei: twoTenthsEth,
        chainId: 1,
      );
      expect(decoded!.rows.first.value, "0.2 ETH");
      expect(decoded.hideValue, isTrue);
    });

    test("a non-wrapped token with the same value keeps the value row", () async {
      final decoded = await resolvingDecoder.decode(
        calldata: EvmCalldata.parse(exactInputSingle(dai))!,
        nativeSymbol: "ETH",
        routerAddress: "0xE592427A0AEce92De3Edee1F18E0157C05861564",
        valueWei: twoTenthsEth,
        chainId: 1,
      );
      expect(decoded!.rows.first.value, "0.2 DAI");
      expect(decoded.hideValue, isFalse);
    });
  });
}
