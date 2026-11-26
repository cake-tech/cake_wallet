import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/dex_router_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cw_core/erc20_token.dart";
import "package:flutter_test/flutter_test.dart";

import "abi_hex.dart";
import "stubs.dart";

const wallet = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const attacker = "0x9999999999999999999999999999999999999999";
const feeTaker = "0x7777777777777777777777777777777777777777";
const weth = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
const usdc = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
const dai = "0x6b175474e89094c44da98b954eedeac495271d0f";
const unlistedToken = "0x3333333333333333333333333333333333333333";
const zeroAddress = "0x0000000000000000000000000000000000000000";
const addressThis = "0x0000000000000000000000000000000000000002";

const v2Router = "0x7a250d5630b4cf539739df2c5dacb4c659f2488d";
const swapRouter = "0xe592427a0aece92de3edee1f18e0157c05861564";
const swapRouter02 = "0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45";

final oneEth = BigInt.from(10).pow(18);
final halfEth = BigInt.from(5) * BigInt.from(10).pow(17);

BigInt usd(int amount) => BigInt.from(amount) * BigInt.from(10).pow(6);

String v2TokenSwap(String selector, BigInt first, BigInt second, List<String> path, String to) =>
    "0x$selector${word(first)}${word(second)}${wordInt(0xa0)}${wordAddr(to)}"
    "${wordInt(1700000000)}${addressArrayBody(path)}";

String v2EthSwap(String selector, BigInt amountOut, List<String> path, String to) =>
    "0x$selector${word(amountOut)}${wordInt(0x80)}${wordAddr(to)}${wordInt(1700000000)}"
    "${addressArrayBody(path)}";

String router02Single(
  String selector,
  String tokenIn,
  String tokenOut,
  String recipient,
  BigInt specified,
  BigInt limit, {
  BigInt? priceLimit,
}) =>
    "$selector${wordAddr(tokenIn)}${wordAddr(tokenOut)}${wordInt(500)}${wordAddr(recipient)}"
    "${word(specified)}${word(limit)}${word(priceLimit ?? BigInt.zero)}";

String router02ExactInput(List<String> tokens, String recipient, BigInt amountIn, BigInt minimum) {
  final path = [
    for (var i = 0; i < tokens.length; i++) ...[if (i > 0) "0001f4", tokens[i].substring(2)],
  ].join();
  return "b858183f${wordInt(0x20)}${wordInt(0x80)}${wordAddr(recipient)}${word(amountIn)}"
      "${word(minimum)}${bytesBlob(path)}";
}

String router02V2Swap(String selector, BigInt first, BigInt second, List<String> path, String to) =>
    "$selector${word(first)}${word(second)}${wordInt(0x80)}${wordAddr(to)}"
    "${addressArrayBody(path)}";

void main() {
  setUpAll(() {
    S.current = const S();
  });

  final decoder = DexRouterDecoder(
    StubErc20Resolver(
      {
        weth: Erc20Token(name: "Wrapped Ether", symbol: "WETH", contractAddress: weth, decimal: 18),
        usdc: Erc20Token(name: "USD Coin", symbol: "USDC", contractAddress: usdc, decimal: 6),
        dai: Erc20Token(name: "Dai", symbol: "DAI", contractAddress: dai, decimal: 18),
        unlistedToken: Erc20Token(
          name: "USD Coin",
          symbol: "USDC",
          contractAddress: unlistedToken,
          decimal: 6,
        ),
      },
      known: {weth, usdc, dai},
    ),
  );

  Future<WCDecodedRequest?> decode(
    String calldata,
    String router, {
    BigInt? value,
    int chainId = 1,
    String walletAddress = wallet,
  }) => decoder.decode(
    calldata: EvmCalldata.parse(calldata)!,
    nativeSymbol: "ETH",
    routerAddress: router,
    walletAddress: walletAddress,
    valueWei: value ?? BigInt.zero,
    chainId: chainId,
  );

  Future<WCDecodedRequest?> decodeMulticall(
    List<String> calls, {
    String router = swapRouter02,
    BigInt? value,
  }) => decoder.decodeMulticall(
    calls: [for (final call in calls) EvmCalldata.parse(call)!],
    nativeSymbol: "ETH",
    routerAddress: router,
    walletAddress: wallet,
    valueWei: value ?? BigInt.zero,
    chainId: 1,
  );

  String pay(String amount) => row(S.current.wc_swap_from, amount);
  String payMax(String amount) => row(S.current.wc_swap_from_max, amount);
  String receiveMin(String amount) => row(S.current.wc_swap_to_min, amount);
  String receive(String amount) => row(S.current.wc_swap_to, amount);
  String token(String address) => row(S.current.wc_token, address);
  String recipient(String address) => row(S.current.wc_recipient, address);
  String routerRow(String address) => row(S.current.wc_router, address);
  String approve(String amount) => row(S.current.wc_action_approve, amount);
  String spender(String address) => row(S.current.wc_approved_spender, address);
  late final recipientYou = recipient(S.current.wc_recipient_you);
  late final recipientRouter = recipient(S.current.wc_recipient_router_hold);
  late final notYou = S.current.wc_warning_recipient_not_you;
  late final unread = S.current.wc_warning_decode_failed;

  late final wethForUsdc = [pay("1 WETH"), token(weth), receiveMin("3000 USDC"), token(usdc)];

  void expectStepList(
    WCDecodedRequest? decoded,
    List<String> rows,
    String router, {
    List<String> warnings = const [],
  }) {
    expect(decoded!.actionTitle, S.current.wc_contract_call);
    expect(rowLines(decoded.rows), [...rows, routerRow(router)]);
    expect(decoded.warnings, [unread, ...warnings]);
    expect(decoded.isValueShown, isFalse);
  }

  group("Uniswap V2 router", () {
    test("swapExactTokensForTokens reads amounts, tokens and recipient", () async {
      final decoded = await decode(
        v2TokenSwap("38ed1739", oneEth, usd(3000), [weth, dai, usdc], wallet),
        v2Router,
      );
      expect(decoded!.actionTitle, S.current.wc_action_swap);
      expect(decoded.actionSubtitle, S.current.wc_via("Uniswap V2"));
      expect(rowLines(decoded.rows), [...wethForUsdc, recipientYou, routerRow(v2Router)]);
      expect(decoded.warnings, isEmpty);
      expect(decoded.isValueShown, isFalse);
    });

    test("swapTokensForExactTokens shows the max spend and exact output", () async {
      final decoded = await decode(
        v2TokenSwap("8803dbee", usd(3000), oneEth, [weth, usdc], wallet),
        v2Router,
      );
      expect(rowLines(decoded!.rows).take(4), [
        payMax("1 WETH"),
        token(weth),
        receive("3000 USDC"),
        token(usdc),
      ]);
    });

    test("swapExactETHForTokens pays the transaction value", () async {
      final decoded = await decode(
        v2EthSwap("7ff36ab5", usd(1500), [weth, usdc], wallet),
        v2Router,
        value: halfEth,
      );
      expect(rowLines(decoded!.rows), [
        pay("0.5 ETH"),
        receiveMin("1500 USDC"),
        token(usdc),
        recipientYou,
        routerRow(v2Router),
      ]);
      expect(decoded.isValueShown, isTrue);
    });

    test("swapETHForExactTokens takes the max spend from the transaction value", () async {
      final decoded = await decode(
        v2EthSwap("fb3bdb41", usd(1500), [weth, usdc], wallet),
        v2Router,
        value: halfEth,
      );
      expect(rowLines(decoded!.rows).take(2), [payMax("0.5 ETH"), receive("1500 USDC")]);
      expect(decoded.isValueShown, isTrue);
    });

    test("swapETHForExactTokens refunds the unspent value itself and stays one swap", () async {
      final calldata = v2EthSwap("fb3bdb41", usd(1500), [weth, usdc], wallet);
      final listed = await decode(calldata, v2Router, value: halfEth);
      expect(listed!.actionTitle, S.current.wc_action_swap);
      expect(rowLines(listed.rows), [
        payMax("0.5 ETH"),
        receive("1500 USDC"),
        token(usdc),
        recipientYou,
        routerRow(v2Router),
      ]);

      final unlisted = await decode(calldata, attacker, value: halfEth);
      expectStepList(
        unlisted,
        [
          payMax("0.5 WETH"),
          token(weth),
          receive("1500 USDC"),
          token(usdc),
          recipientYou,
          receiveMin("0 ETH"),
          recipientYou,
        ],
        attacker,
        warnings: [S.current.wc_warning_unknown_contract],
      );
    });

    test("an ETH-in swap whose first hop is not the wrapped native is not paid in ETH", () async {
      final decoded = await decode(
        v2EthSwap("7ff36ab5", usd(1500), [dai, usdc], wallet),
        v2Router,
        value: halfEth,
      );
      expectStepList(decoded, [
        pay("0.5 DAI"),
        token(dai),
        receiveMin("1500 USDC"),
        token(usdc),
        recipientYou,
      ], v2Router);
    });

    test("an ETH-in swap with no value attached pays nothing", () async {
      final decoded = await decode(
        v2EthSwap("7ff36ab5", usd(1500), [weth, usdc], wallet),
        v2Router,
      );
      expectStepList(decoded, [
        pay("0 WETH"),
        token(weth),
        receiveMin("1500 USDC"),
        token(usdc),
        recipientYou,
      ], v2Router);
    });

    test("swapExactTokensForETH renders the wrapped native output as ETH", () async {
      final decoded = await decode(
        v2TokenSwap("18cbafe5", usd(3000), oneEth, [usdc, weth], wallet),
        v2Router,
      );
      expect(rowLines(decoded!.rows), [
        pay("3000 USDC"),
        token(usdc),
        receiveMin("1 ETH"),
        recipientYou,
        routerRow(v2Router),
      ]);
      expect(decoded.warnings, isEmpty);
    });

    test("swapTokensForExactETH shows the exact ETH out", () async {
      final decoded = await decode(
        v2TokenSwap("4a25d94a", oneEth, usd(3000), [usdc, weth], wallet),
        v2Router,
      );
      expect(rowLines(decoded!.rows).take(3), [payMax("3000 USDC"), token(usdc), receive("1 ETH")]);
    });

    test("a last hop that is not the wrapped native is never shown as ETH", () async {
      final decoded = await decode(
        v2TokenSwap("18cbafe5", usd(3000), usd(2900), [usdc, unlistedToken], wallet),
        v2Router,
      );
      expect(rowLines(decoded!.rows), containsAll([receiveMin("2900 USDC"), token(unlistedToken)]));
      expect(decoded.warnings, [S.current.wc_warning_unknown_token]);
    });

    test("a swap paid to someone else is a step list that names them", () async {
      final decoded = await decode(
        v2TokenSwap("38ed1739", oneEth, usd(3000), [weth, usdc], attacker),
        v2Router,
      );
      expectStepList(decoded, [...wethForUsdc, recipient(attacker)], v2Router, warnings: [notYou]);
    });

    test("value sent with a token swap is not what pays it, only SwapRouter02 does that", () async {
      final decoded = await decode(
        v2TokenSwap("38ed1739", oneEth, usd(3000), [weth, usdc], wallet),
        v2Router,
        value: oneEth,
      );
      expectStepList(decoded, [...wethForUsdc, recipientYou], v2Router);
    });

    test("swapExactTokensForETH to someone else lists the ETH they are paid", () async {
      final decoded = await decode(
        v2TokenSwap("18cbafe5", usd(3000), oneEth, [usdc, weth], attacker),
        v2Router,
      );
      expectStepList(
        decoded,
        [
          pay("3000 USDC"),
          token(usdc),
          receiveMin("1 WETH"),
          token(weth),
          recipientRouter,
          receiveMin("1 ETH"),
          recipient(attacker),
        ],
        v2Router,
        warnings: [notYou],
      );
    });

    test("a recipient word with junk in its high bytes is the low 160 bits", () async {
      final clean = v2TokenSwap("38ed1739", oneEth, usd(3000), [weth, usdc], wallet);
      final dirty = clean.replaceFirst(
        wordAddr(wallet),
        "ffffffffffffffffffffffff${attacker.substring(2)}",
      );
      final decoded = await decode(dirty, v2Router);
      expectStepList(decoded, [...wethForUsdc, recipient(attacker)], v2Router, warnings: [notYou]);
    });

    test("the router pays the address as written, 0x01 is not the sender here", () async {
      const literalOne = "0x0000000000000000000000000000000000000001";
      final decoded = await decode(
        v2TokenSwap("38ed1739", oneEth, usd(3000), [weth, usdc], literalOne),
        v2Router,
      );
      expectStepList(
        decoded,
        [...wethForUsdc, recipient(literalOne)],
        v2Router,
        warnings: [notYou],
      );
    });
  });

  group("Uniswap V3 routers", () {
    String swapRouterSingle(
      String selector,
      String recipient,
      BigInt specified,
      BigInt limit, {
      BigInt? priceLimit,
    }) =>
        "0x$selector${wordAddr(weth)}${wordAddr(usdc)}${wordInt(3000)}${wordAddr(recipient)}"
        "${wordInt(1700000000)}${word(specified)}${word(limit)}${word(priceLimit ?? BigInt.zero)}";

    test("exactInputSingle decodes the SwapRouter struct words", () async {
      final decoded = await decode(
        swapRouterSingle("414bf389", wallet, oneEth, usd(3000)),
        swapRouter,
      );
      expect(rowLines(decoded!.rows), [
        pay("1 WETH"),
        token(weth),
        receiveMin("3000 USDC"),
        token(usdc),
        recipientYou,
        routerRow(swapRouter),
      ]);
      expect(decoded.warnings, isEmpty);
    });

    test("exactOutputSingle swaps the specified and limit amounts", () async {
      final decoded = await decode(
        swapRouterSingle("db3e2198", wallet, usd(3000), oneEth),
        swapRouter,
      );
      expect(rowLines(decoded!.rows).take(4), [
        payMax("1 WETH"),
        token(weth),
        receive("3000 USDC"),
        token(usdc),
      ]);
    });

    test("exactOutputSingle paid in ETH is not the swap, no refundETH follows it", () async {
      final exactOutRows = [
        payMax("1 WETH"),
        token(weth),
        receive("3000 USDC"),
        token(usdc),
        recipientYou,
      ];

      final onSwapRouter = await decode(
        swapRouterSingle("db3e2198", wallet, usd(3000), oneEth),
        swapRouter,
        value: oneEth + halfEth,
      );
      expectStepList(onSwapRouter, exactOutRows, swapRouter);

      final onSwapRouter02 = await decode(
        "0x${router02Single("5023b4df", weth, usdc, wallet, usd(3000), oneEth)}",
        swapRouter02,
        value: oneEth + halfEth,
      );
      expectStepList(onSwapRouter02, exactOutRows, swapRouter02);
    });

    test("SwapRouter02 exactInputSingle reads the struct without a deadline word", () async {
      final decoded = await decode(
        "0x${router02Single("04e45aaf", weth, usdc, wallet, oneEth, usd(3000))}",
        swapRouter02,
      );
      expect(rowLines(decoded!.rows).take(4), [
        pay("1 WETH"),
        token(weth),
        receiveMin("3000 USDC"),
        token(usdc),
      ]);
    });

    test("SwapRouter02 exactOutputSingle reads the shifted words", () async {
      final decoded = await decode(
        "0x${router02Single("5023b4df", weth, usdc, wallet, usd(3000), oneEth)}",
        swapRouter02,
      );
      expect(rowLines(decoded!.rows).take(3), [
        payMax("1 WETH"),
        token(weth),
        receive("3000 USDC"),
      ]);
    });

    test("exactOutputSingle with a price limit may pay out less than it names", () async {
      final priceLimit = BigInt.one << 96;
      final exactOutRows = [
        payMax("1 WETH"),
        token(weth),
        receive("3000 USDC"),
        token(usdc),
        recipientYou,
      ];

      final onSwapRouter = await decode(
        swapRouterSingle("db3e2198", wallet, usd(3000), oneEth, priceLimit: priceLimit),
        swapRouter,
      );
      expectStepList(onSwapRouter, exactOutRows, swapRouter);

      final onSwapRouter02 = await decode(
        "0x${router02Single("5023b4df", weth, usdc, wallet, usd(3000), oneEth, priceLimit: priceLimit)}",
        swapRouter02,
      );
      expectStepList(onSwapRouter02, exactOutRows, swapRouter02);

      final smallestLimit = await decode(
        "0x${router02Single("5023b4df", weth, usdc, wallet, usd(3000), oneEth, priceLimit: BigInt.one)}",
        swapRouter02,
      );
      expectStepList(smallestLimit, exactOutRows, swapRouter02);
    });

    test("exactInputSingle with a price limit is not the SDK's call either", () async {
      final decoded = await decode(
        swapRouterSingle("414bf389", wallet, oneEth, usd(3000), priceLimit: BigInt.one << 96),
        swapRouter,
      );
      expectStepList(decoded, [...wethForUsdc, recipientYou], swapRouter);
    });

    test("a single-pool call cut short of its price limit word is not read", () async {
      final complete = router02Single("04e45aaf", weth, usdc, wallet, oneEth, usd(3000));
      final decoded = await decode(
        "0x${complete.substring(0, complete.length - 64)}",
        swapRouter02,
      );
      expectStepList(decoded, [], swapRouter02);
    });

    test(
      "exactInput with bytes after its last hop still runs, it is never called a swap",
      () async {
        final paddedPath = "${weth.substring(2)}0001f4${usdc.substring(2)}${dai.substring(2)}";
        final decoded = await decode(
          "0xc04b8d59${wordInt(0x20)}${wordInt(0xa0)}${wordAddr(wallet)}${wordInt(1700000000)}"
          "${word(oneEth)}${word(usd(3000))}${bytesBlob(paddedPath)}",
          swapRouter,
        );
        expectStepList(decoded, [], swapRouter);
      },
    );

    test(
      "an exact-out call with no cap on what it spends warns like a swap with no floor",
      () async {
        final uncapped = (BigInt.one << 256) - BigInt.one;
        final decoded = await decode(
          "0x${router02Single("5023b4df", weth, usdc, wallet, usd(3000), uncapped)}",
          swapRouter02,
        );
        expect(decoded!.actionTitle, S.current.wc_action_swap);
        expect(rowLines(decoded.rows), [
          payMax("${S.current.wc_unlimited} WETH"),
          token(weth),
          receive("3000 USDC"),
          token(usdc),
          recipientYou,
          routerRow(swapRouter02),
        ]);
        expect(decoded.warnings, [S.current.wc_warning_zero_slippage]);
      },
    );

    group("SwapRouter02's V2 swaps", () {
      test("swapExactTokensForTokens reads amounts, path ends and recipient", () async {
        final decoded = await decode(
          "0x${router02V2Swap("472b43f3", oneEth, usd(3000), [weth, dai, usdc], wallet)}",
          swapRouter02,
        );
        expect(decoded!.actionTitle, S.current.wc_action_swap);
        expect(decoded.actionSubtitle, S.current.wc_via("Uniswap V3"));
        expect(rowLines(decoded.rows), [...wethForUsdc, recipientYou, routerRow(swapRouter02)]);
        expect(decoded.warnings, isEmpty);
      });

      test("0x01 as the recipient is the sender", () async {
        const msgSender = "0x0000000000000000000000000000000000000001";
        final decoded = await decode(
          "0x${router02V2Swap("472b43f3", oneEth, usd(3000), [weth, usdc], msgSender)}",
          swapRouter02,
        );
        expect(decoded!.actionTitle, S.current.wc_action_swap);
        expect(rowLines(decoded.rows), [...wethForUsdc, recipientYou, routerRow(swapRouter02)]);
      });

      test(
        "swapTokensForExactTokens only caps what goes in, a sweepToken floor holds the rest",
        () async {
          final exactOutRows = [payMax("1 WETH"), token(weth), receive("3000 USDC"), token(usdc)];

          final straightToWallet = await decode(
            "0x${router02V2Swap("42712a67", usd(3000), oneEth, [weth, usdc], wallet)}",
            swapRouter02,
          );
          expectStepList(straightToWallet, [...exactOutRows, recipientYou], swapRouter02);

          Future<WCDecodedRequest?> sweptWithFloor(BigInt floor) => decodeMulticall([
            router02V2Swap("42712a67", usd(3000), oneEth, [weth, usdc], addressThis),
            "df2ab5bb${wordAddr(usdc)}${word(floor)}${wordAddr(wallet)}",
          ]);

          final floored = await sweptWithFloor(usd(3000));
          expect(floored!.actionTitle, S.current.wc_action_swap);
          expect(rowLines(floored.rows), [...exactOutRows, recipientYou, routerRow(swapRouter02)]);

          expectStepList(
            await sweptWithFloor(usd(3000) - BigInt.one),
            [...exactOutRows, recipientRouter, receiveMin("2999.999999 USDC"), recipientYou],
            swapRouter02,
            warnings: [notYou],
          );
        },
      );

      test("a WETH path with equal value attached is paid in ETH", () async {
        final decoded = await decode(
          "0x${router02V2Swap("472b43f3", halfEth, usd(1500), [weth, usdc], wallet)}",
          swapRouter02,
          value: halfEth,
        );
        expect(decoded!.actionTitle, S.current.wc_action_swap);
        expect(rowLines(decoded.rows).first, pay("0.5 ETH"));
        expect(decoded.isValueShown, isTrue);
      });

      test("a mixed route: a V3 section to the router, a V2 section of all it holds", () async {
        final decoded = await decodeMulticall([
          router02Single("04e45aaf", usdc, dai, addressThis, usd(100), BigInt.zero),
          router02V2Swap("472b43f3", BigInt.zero, oneEth, [dai, weth], wallet),
        ]);
        expect(decoded!.actionTitle, S.current.wc_action_swap);
        expect(rowLines(decoded.rows), [
          pay("100 USDC"),
          token(usdc),
          receiveMin("1 WETH"),
          token(weth),
          recipientYou,
          routerRow(swapRouter02),
        ]);
        expect(decoded.warnings, isEmpty);
      });

      test("paid to someone else it is a step list", () async {
        final decoded = await decode(
          "0x${router02V2Swap("472b43f3", oneEth, usd(3000), [weth, usdc], attacker)}",
          swapRouter02,
        );
        expectStepList(
          decoded,
          [...wethForUsdc, recipient(attacker)],
          swapRouter02,
          warnings: [notYou],
        );
      });
    });

    test("a token outside the wallet and default lists warns and shows its address", () async {
      final decoded = await decode(
        "0x${router02Single("04e45aaf", weth, unlistedToken, wallet, oneEth, usd(3000))}",
        swapRouter02,
      );
      expect(rowLines(decoded!.rows), containsAll([receiveMin("3000 USDC"), token(unlistedToken)]));
      expect(decoded.warnings, [S.current.wc_warning_unknown_token]);
    });

    test("a swap left with the router and never paid out", () async {
      final decoded = await decode(
        "0x${router02Single("04e45aaf", usdc, weth, addressThis, usd(3000), oneEth)}",
        swapRouter02,
      );
      expectStepList(
        decoded,
        [pay("3000 USDC"), token(usdc), receiveMin("1 WETH"), token(weth), recipientRouter],
        swapRouter02,
        warnings: [notYou],
      );
    });

    test("WETH in with equal value shows ETH once", () async {
      final decoded = await decode(
        swapRouterSingle("414bf389", wallet, halfEth, usd(1500)),
        swapRouter,
        value: halfEth,
      );
      expect(rowLines(decoded!.rows).first, pay("0.5 ETH"));
      expect(decoded.isValueShown, isTrue);
    });

    test("WETH in with a value that is not the amount in keeps both", () async {
      for (final value in [halfEth - BigInt.one, halfEth + BigInt.one]) {
        final decoded = await decode(
          swapRouterSingle("414bf389", wallet, halfEth, usd(1500)),
          swapRouter,
          value: value,
        );
        expectStepList(decoded, [
          pay("0.5 WETH"),
          token(weth),
          receiveMin("1500 USDC"),
          token(usdc),
          recipientYou,
        ], swapRouter);
      }
    });

    test("value sent with a swap that does not pay in the wrapped native", () async {
      final decoded = await decode(
        "0x${router02Single("04e45aaf", usdc, weth, wallet, usd(3000), oneEth)}",
        swapRouter02,
        value: halfEth,
      );
      expectStepList(decoded, [
        pay("3000 USDC"),
        token(usdc),
        receiveMin("1 WETH"),
        token(weth),
        recipientYou,
      ], swapRouter02);
    });

    test("golden vector: mainnet WETH-in swap with equal value shows ETH once", () async {
      const mainnetCalldata =
          "0x414bf389"
          "000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
          "000000000000000000000000c552b5706baa14c1f0104e95380ea3dc102a481f"
          "0000000000000000000000000000000000000000000000000000000000000064"
          "000000000000000000000000364cc1be5a6f9f2f743815ebde7e82b5952747b3"
          "000000000000000000000000000000000000000000000000000000006ac78487"
          "00000000000000000000000000000000000000000000000002c68af0bb140000"
          "0000000000000000000000000000000000000000000000000000000000000000"
          "0000000000000000000000000000000000000000000000000000000000000000";
      final decoded = await decode(
        mainnetCalldata,
        swapRouter,
        value: BigInt.parse("2c68af0bb140000", radix: 16),
        walletAddress: "0x364cc1be5a6f9f2f743815ebde7e82b5952747b3",
      );
      expect(rowLines(decoded!.rows), [
        pay("0.2 ETH"),
        receiveMin("0 0xc552…481f"),
        token("0xc552b5706baa14c1f0104e95380ea3dc102a481f"),
        recipientYou,
        routerRow(swapRouter),
      ]);
      expect(decoded.isValueShown, isTrue);
      expect(decoded.warnings, [
        S.current.wc_warning_zero_slippage,
        S.current.wc_warning_unknown_token,
      ]);
    });
  });

  group("SwapRouter02 multicall", () {
    final thirtyThousandthsEth = BigInt.from(3) * BigInt.from(10).pow(16);
    final toRouter = router02Single("04e45aaf", usdc, weth, addressThis, usd(100), BigInt.zero);
    String unwrapWeth9(BigInt minimum, String to) => "49404b7c${word(minimum)}${wordAddr(to)}";

    test("token to ETH takes the recipient and the floor from unwrapWETH9", () async {
      final decoded = await decodeMulticall([toRouter, unwrapWeth9(thirtyThousandthsEth, wallet)]);
      expect(decoded!.actionSubtitle, S.current.wc_via("Uniswap V3"));
      expect(rowLines(decoded.rows), [
        pay("100 USDC"),
        token(usdc),
        receiveMin("0.03 ETH"),
        recipientYou,
        routerRow(swapRouter02),
      ]);
      expect(decoded.warnings, isEmpty);
    });

    test("unwrapWETH9 to someone else is a step list that names them", () async {
      final decoded = await decodeMulticall([
        toRouter,
        unwrapWeth9(thirtyThousandthsEth, attacker),
      ]);
      expectStepList(
        decoded,
        [
          pay("100 USDC"),
          token(usdc),
          receiveMin("0 WETH"),
          token(weth),
          recipientRouter,
          receiveMin("0.03 ETH"),
          recipient(attacker),
        ],
        swapRouter02,
        warnings: [notYou],
      );
    });

    test("unwrapWETH9 without a recipient pays the sender", () async {
      final decoded = await decodeMulticall([toRouter, "49616997${word(thirtyThousandthsEth)}"]);
      expect(rowLines(decoded!.rows), containsAll([receiveMin("0.03 ETH"), recipientYou]));
      expect(decoded.warnings, isEmpty);
    });

    test("unwrapWETH9WithFee lists the fee and its recipient", () async {
      final decoded = await decodeMulticall([
        toRouter,
        "9b2c0a37${word(thirtyThousandthsEth)}${wordAddr(wallet)}${wordInt(25)}"
            "${wordAddr(feeTaker)}",
      ]);
      expect(rowLines(decoded!.rows), [
        pay("100 USDC"),
        token(usdc),
        receiveMin("0.029925 ETH"),
        recipientYou,
        row(S.current.fee, "0.25% ETH"),
        row(S.current.to, feeTaker),
        routerRow(swapRouter02),
      ]);
      expect(decoded.warnings, isEmpty);
    });

    test("unwrapWETH9WithFee without a recipient pays the sender", () async {
      final decoded = await decodeMulticall([
        toRouter,
        "d4ef38de${word(thirtyThousandthsEth)}${wordInt(25)}${wordAddr(feeTaker)}",
      ]);
      expect(rowLines(decoded!.rows), [
        pay("100 USDC"),
        token(usdc),
        receiveMin("0.029925 ETH"),
        recipientYou,
        row(S.current.fee, "0.25% ETH"),
        row(S.current.to, feeTaker),
        routerRow(swapRouter02),
      ]);
      expect(decoded.warnings, isEmpty);
    });

    test("unwrapWETH9WithFee to someone else is a step list that names them", () async {
      final decoded = await decodeMulticall([
        toRouter,
        "9b2c0a37${word(thirtyThousandthsEth)}${wordAddr(attacker)}${wordInt(25)}"
            "${wordAddr(feeTaker)}",
      ]);
      expectStepList(
        decoded,
        [
          pay("100 USDC"),
          token(usdc),
          receiveMin("0 WETH"),
          token(weth),
          recipientRouter,
          row(S.current.wc_action_transfer, "0.25% ETH"),
          row(S.current.to, feeTaker),
          receiveMin("0.029925 ETH"),
          recipient(attacker),
        ],
        swapRouter02,
        warnings: [notYou],
      );
    });

    test("sweepTokenWithFee to someone else is a step list that names them", () async {
      final decoded = await decodeMulticall([
        router02Single("04e45aaf", usdc, dai, addressThis, usd(100), BigInt.zero),
        "e0e189a0${wordAddr(dai)}${word(BigInt.from(99) * oneEth)}${wordAddr(attacker)}"
            "${wordInt(100)}${wordAddr(feeTaker)}",
      ]);
      expectStepList(
        decoded,
        [
          pay("100 USDC"),
          token(usdc),
          receiveMin("0 DAI"),
          token(dai),
          recipientRouter,
          row(S.current.wc_action_transfer, "1% DAI"),
          row(S.current.to, feeTaker),
          receiveMin("98.01 DAI"),
          recipient(attacker),
        ],
        swapRouter02,
        warnings: [notYou],
      );
    });

    test("a fee above 1% is not a fee", () async {
      final decoded = await decodeMulticall([
        toRouter,
        "9b2c0a37${word(thirtyThousandthsEth)}${wordAddr(wallet)}${wordInt(101)}"
            "${wordAddr(feeTaker)}",
      ]);
      expectStepList(
        decoded,
        [
          pay("100 USDC"),
          token(usdc),
          receiveMin("0 WETH"),
          token(weth),
          recipientRouter,
          row(S.current.wc_action_transfer, "1.01% ETH"),
          row(S.current.to, feeTaker),
          receiveMin("0.029697 ETH"),
          recipientYou,
        ],
        swapRouter02,
        warnings: [notYou],
      );
    });

    test("sweepToken delivers a token output, with and without a recipient", () async {
      final daiToRouter = router02Single("04e45aaf", usdc, dai, addressThis, usd(100), BigInt.zero);
      final ninetyNineDai = BigInt.from(99) * oneEth;

      final swapRows = [
        pay("100 USDC"),
        token(usdc),
        receiveMin("99 DAI"),
        token(dai),
        recipientYou,
        routerRow(swapRouter02),
      ];

      final toWallet = await decodeMulticall([
        daiToRouter,
        "df2ab5bb${wordAddr(dai)}${word(ninetyNineDai)}${wordAddr(wallet)}",
      ]);
      expect(toWallet!.actionTitle, S.current.wc_action_swap);
      expect(rowLines(toWallet.rows), swapRows);
      expect(toWallet.warnings, isEmpty);

      final toSender = await decodeMulticall([
        daiToRouter,
        "e90a182f${wordAddr(dai)}${word(ninetyNineDai)}",
      ]);
      expect(toSender!.actionTitle, S.current.wc_action_swap);
      expect(rowLines(toSender.rows), swapRows);
      expect(toSender.warnings, isEmpty);

      final toAttacker = await decodeMulticall([
        daiToRouter,
        "df2ab5bb${wordAddr(dai)}${word(ninetyNineDai)}${wordAddr(attacker)}",
      ]);
      expectStepList(
        toAttacker,
        [
          pay("100 USDC"),
          token(usdc),
          receiveMin("0 DAI"),
          token(dai),
          recipientRouter,
          receiveMin("99 DAI"),
          recipient(attacker),
        ],
        swapRouter02,
        warnings: [notYou],
      );
    });

    test("a fee of more than everything is not a call the router runs", () async {
      expect(
        await decodeMulticall([
          toRouter,
          "9b2c0a37${word(thirtyThousandthsEth)}${wordAddr(wallet)}${wordInt(10001)}"
              "${wordAddr(feeTaker)}",
        ]),
        isNull,
      );
    });

    test("with a fee and no floor on the payout, the swap's own floor is shown net", () async {
      final decoded = await decodeMulticall([
        router02Single("04e45aaf", usdc, dai, addressThis, usd(100), BigInt.from(99) * oneEth),
        "e0e189a0${wordAddr(dai)}${wordInt(0)}${wordAddr(wallet)}${wordInt(100)}"
            "${wordAddr(feeTaker)}",
      ]);
      expect(decoded!.actionTitle, S.current.wc_action_swap);
      expect(rowLines(decoded.rows), [
        pay("100 USDC"),
        token(usdc),
        receiveMin("98.01 DAI"),
        token(dai),
        recipientYou,
        row(S.current.fee, "1% DAI"),
        row(S.current.to, feeTaker),
        routerRow(swapRouter02),
      ]);
    });

    test("sweepTokenWithFee lists the fee, in both overloads", () async {
      final daiToRouter = router02Single("04e45aaf", usdc, dai, addressThis, usd(100), BigInt.zero);
      final feeRows = [row(S.current.fee, "1% DAI"), row(S.current.to, feeTaker)];

      final withRecipient = await decodeMulticall([
        daiToRouter,
        "e0e189a0${wordAddr(dai)}${wordInt(0)}${wordAddr(wallet)}${wordInt(100)}"
            "${wordAddr(feeTaker)}",
      ]);
      expect(rowLines(withRecipient!.rows), containsAll([recipientYou, ...feeRows]));

      final toSender = await decodeMulticall([
        daiToRouter,
        "3068c554${wordAddr(dai)}${wordInt(0)}${wordInt(100)}${wordAddr(feeTaker)}",
      ]);
      expect(rowLines(toSender!.rows), containsAll([recipientYou, ...feeRows]));
    });

    test("an unwrap of WETH does not deliver a swap that produced another token", () async {
      final decoded = await decodeMulticall([
        router02Single("04e45aaf", usdc, dai, addressThis, usd(100), BigInt.zero),
        unwrapWeth9(BigInt.zero, wallet),
      ]);
      expectStepList(
        decoded,
        [
          pay("100 USDC"),
          token(usdc),
          receiveMin("0 DAI"),
          token(dai),
          recipientRouter,
          receiveMin("0 ETH"),
          recipientYou,
        ],
        swapRouter02,
        warnings: [notYou],
      );
    });

    test("ETH in with refundETH shows ETH once", () async {
      final decoded = await decodeMulticall([
        router02Single("04e45aaf", weth, usdc, wallet, oneEth, usd(3000)),
        "12210e8a",
      ], value: oneEth);
      expect(rowLines(decoded!.rows), [
        pay("1 ETH"),
        receiveMin("3000 USDC"),
        token(usdc),
        recipientYou,
        routerRow(swapRouter02),
      ]);
      expect(decoded.warnings, isEmpty);
      expect(decoded.isValueShown, isTrue);
    });

    test("two swaps to two recipients are both on the main card, in either order", () async {
      final toWallet = router02Single(
        "04e45aaf",
        usdc,
        weth,
        wallet,
        usd(100),
        thirtyThousandthsEth,
      );
      final toAttacker = router02Single("04e45aaf", usdc, weth, attacker, usd(100000), BigInt.one);
      final walletLeg = [pay("100 USDC"), receiveMin("0.03 WETH"), recipientYou];
      final attackerLeg = [
        pay("100000 USDC"),
        receiveMin("0.000000000000000001 WETH"),
        recipient(attacker),
      ];
      final attackerLast = await decodeMulticall([toWallet, toAttacker]);
      expect(attackerLast!.actionTitle, S.current.wc_contract_call);
      expect(rowLines(attackerLast.rows), containsAllInOrder([...walletLeg, ...attackerLeg]));
      expect(attackerLast.warnings, [unread, notYou]);

      final attackerFirst = await decodeMulticall([toAttacker, toWallet]);
      expect(attackerFirst!.actionTitle, S.current.wc_contract_call);
      expect(rowLines(attackerFirst.rows), containsAllInOrder([...attackerLeg, ...walletLeg]));
      expect(attackerFirst.warnings, [unread, notYou]);
    });

    test("a split route sums its legs, paid to the sender or through unwrapWETH9", () async {
      String toWeth(String swapRecipient, int usdcIn, BigInt floor) =>
          router02Single("04e45aaf", usdc, weth, swapRecipient, usd(usdcIn), floor);
      final fifteenThousandthsEth = thirtyThousandthsEth ~/ BigInt.two;

      final straightToWallet = await decodeMulticall([
        toWeth(wallet, 100, thirtyThousandthsEth),
        toWeth(wallet, 50, fifteenThousandthsEth),
      ]);
      expect(straightToWallet!.actionTitle, S.current.wc_action_swap);
      expect(rowLines(straightToWallet.rows), [
        pay("150 USDC"),
        token(usdc),
        receiveMin("0.045 WETH"),
        token(weth),
        recipientYou,
        routerRow(swapRouter02),
      ]);
      expect(straightToWallet.warnings, isEmpty);

      final heldByRouter = await decodeMulticall([
        toWeth(addressThis, 100, BigInt.zero),
        toWeth(addressThis, 50, BigInt.zero),
        unwrapWeth9(thirtyThousandthsEth, wallet),
      ]);
      expect(heldByRouter!.actionTitle, S.current.wc_action_swap);
      expect(rowLines(heldByRouter.rows), [
        pay("150 USDC"),
        token(usdc),
        receiveMin("0.03 ETH"),
        recipientYou,
        routerRow(swapRouter02),
      ]);
      expect(heldByRouter.warnings, isEmpty);
    });

    test("ETH in, exact out, with refundETH shows the value as the most it pays", () async {
      final decoded = await decodeMulticall([
        router02Single("5023b4df", weth, usdc, wallet, usd(3000), oneEth),
        "12210e8a",
      ], value: oneEth + halfEth);
      expect(decoded!.actionTitle, S.current.wc_action_swap);
      expect(rowLines(decoded.rows), [
        payMax("1.5 ETH"),
        receive("3000 USDC"),
        token(usdc),
        recipientYou,
        routerRow(swapRouter02),
      ]);
      expect(decoded.warnings, isEmpty);
      expect(decoded.isValueShown, isTrue);
    });

    test("ETH in, exact out, is the swap only when refundETH sends the rest back", () async {
      final exactOut = router02Single("5023b4df", weth, usdc, wallet, usd(3000), oneEth);
      final exactOutRows = [
        payMax("1 WETH"),
        token(weth),
        receive("3000 USDC"),
        token(usdc),
        recipientYou,
      ];

      final withoutRefund = await decodeMulticall([exactOut], value: oneEth + halfEth);
      expectStepList(withoutRefund, exactOutRows, swapRouter02);

      final unwrapInstead = await decodeMulticall([
        exactOut,
        "49616997${wordInt(0)}",
      ], value: oneEth + halfEth);
      expectStepList(unwrapInstead, [
        ...exactOutRows,
        receiveMin("0 ETH"),
        recipientYou,
      ], swapRouter02);
    });

    group("selfPermit ahead of the swap", () {
      const signature =
          "000000000000000000000000000000000000000000000000000000000000001b"
          "1111111111111111111111111111111111111111111111111111111111111111"
          "2222222222222222222222222222222222222222222222222222222222222222";
      String selfPermit(String selector, String permitted, BigInt amountOrNonce) =>
          "$selector${wordAddr(permitted)}${word(amountOrNonce)}${wordInt(1700000000)}$signature";
      late final swapRows = [pay("100 USDC"), token(usdc), receiveMin("0.03 ETH"), recipientYou];

      test("selfPermit and selfPermitIfNecessary approve the amount they name", () async {
        for (final selector in ["f3995c67", "c2e3140a"]) {
          final decoded = await decodeMulticall([
            selfPermit(selector, usdc, usd(100)),
            toRouter,
            unwrapWeth9(thirtyThousandthsEth, wallet),
          ]);
          expect(decoded!.actionTitle, S.current.wc_action_swap, reason: selector);
          expect(rowLines(decoded.rows), [
            ...swapRows,
            approve("100 USDC"),
            spender(swapRouter02),
            routerRow(swapRouter02),
          ], reason: selector);
          expect(decoded.warnings, isEmpty, reason: selector);
          expect(decoded.detailRows, isEmpty, reason: selector);
        }
      });

      test("the DAI-style permits carry a nonce, not an amount, and allow everything", () async {
        for (final selector in ["4659a494", "a4a78f0c"]) {
          final decoded = await decodeMulticall([
            selfPermit(selector, usdc, BigInt.from(7)),
            toRouter,
            unwrapWeth9(thirtyThousandthsEth, wallet),
          ]);
          expect(decoded!.actionTitle, S.current.wc_action_swap, reason: selector);
          expect(rowLines(decoded.rows), [
            ...swapRows,
            approve("${S.current.wc_unlimited} USDC"),
            spender(swapRouter02),
            routerRow(swapRouter02),
          ], reason: selector);
          expect(decoded.warnings, [S.current.wc_warning_unlimited_approval], reason: selector);
        }
      });

      test("a permit for a token the swap does not pay with", () async {
        final decoded = await decodeMulticall([
          selfPermit("f3995c67", dai, oneEth),
          toRouter,
          unwrapWeth9(thirtyThousandthsEth, wallet),
        ]);
        expectStepList(
          decoded,
          [
            approve("1 DAI"),
            token(dai),
            spender(swapRouter02),
            pay("100 USDC"),
            token(usdc),
            receiveMin("0 WETH"),
            token(weth),
            recipientRouter,
            receiveMin("0.03 ETH"),
            recipientYou,
          ],
          swapRouter02,
          warnings: [notYou],
        );
      });

      test("a permit cut short of its amount leaves the multicall to the caller", () async {
        expect(await decodeMulticall(["f3995c67${wordAddr(usdc)}", toRouter]), isNull);
      });
    });

    group("a path through the wrapped native while ETH is attached", () {
      final ninetyDai = BigInt.from(90) * oneEth;
      final midPathWeth = router02ExactInput([weth, usdc, weth, dai], wallet, halfEth, ninetyDai);
      final direct = router02Single(
        "04e45aaf",
        weth,
        dai,
        wallet,
        halfEth,
        BigInt.from(95) * oneEth,
      );
      late final bothLegs = [
        pay("0.5 WETH"),
        token(weth),
        receiveMin("90 DAI"),
        token(dai),
        recipientYou,
        pay("0.5 WETH"),
        receiveMin("95 DAI"),
        recipientYou,
      ];

      test(
        "the mid-path hop is paid out of the value, so a later leg pulls from the wallet",
        () async {
          final decoded = await decodeMulticall([midPathWeth, direct], value: oneEth);
          expectStepList(decoded, bothLegs, swapRouter02);
        },
      );

      test("without value attached the same calls are one swap", () async {
        final decoded = await decodeMulticall([midPathWeth, direct]);
        expect(decoded!.actionTitle, S.current.wc_action_swap);
        expect(rowLines(decoded.rows), [
          pay("1 WETH"),
          token(weth),
          receiveMin("185 DAI"),
          token(dai),
          recipientYou,
          routerRow(swapRouter02),
        ]);
      });

      test("the wrapped native at the start of a path is what the value pays for", () async {
        final decoded = await decodeMulticall([
          router02ExactInput([weth, usdc, dai], wallet, oneEth, ninetyDai),
        ], value: oneEth);
        expect(decoded!.actionTitle, S.current.wc_action_swap);
        expect(rowLines(decoded.rows).first, pay("1 ETH"));
        expect(decoded.isValueShown, isTrue);
      });

      test("at the end of a path it is only what comes out", () async {
        final decoded = await decodeMulticall([
          router02ExactInput([weth, usdc, weth], wallet, oneEth, halfEth),
        ], value: oneEth);
        expect(decoded!.actionTitle, S.current.wc_action_swap);
        expect(rowLines(decoded.rows), [
          pay("1 ETH"),
          receiveMin("0.5 WETH"),
          token(weth),
          recipientYou,
          routerRow(swapRouter02),
        ]);
      });

      test("a chained section whose path passes through it mid-way", () async {
        final decoded = await decodeMulticall([
          router02Single("04e45aaf", weth, usdc, addressThis, oneEth, BigInt.zero),
          router02ExactInput([usdc, weth, dai], wallet, BigInt.zero, ninetyDai),
        ], value: oneEth);
        expect(decoded!.actionTitle, S.current.wc_contract_call);
        expect(decoded.warnings, [unread, notYou]);
        expect(decoded.isValueShown, isFalse);
      });

      test("a chained section that starts from it", () async {
        final decoded = await decodeMulticall([
          router02Single("04e45aaf", weth, usdc, addressThis, oneEth, BigInt.zero),
          router02Single("04e45aaf", usdc, weth, addressThis, BigInt.zero, BigInt.zero),
          router02Single("04e45aaf", weth, dai, wallet, BigInt.zero, ninetyDai),
        ], value: oneEth);
        expect(decoded!.actionTitle, S.current.wc_contract_call);
        expect(decoded.warnings, [unread, notYou]);
        expect(decoded.isValueShown, isFalse);
      });
    });

    test("an amount in of 0 spends what the previous swap left with the router", () async {
      final decoded = await decodeMulticall([
        router02Single("04e45aaf", usdc, dai, addressThis, usd(100), BigInt.zero),
        router02Single("04e45aaf", dai, weth, wallet, BigInt.zero, thirtyThousandthsEth),
      ]);
      expect(rowLines(decoded!.rows), [
        pay("100 USDC"),
        token(usdc),
        receiveMin("0.03 WETH"),
        token(weth),
        recipientYou,
        routerRow(swapRouter02),
      ]);
      expect(decoded.warnings, isEmpty);
    });

    test("the original SwapRouter keeps the output for address(0) until unwrapWETH9", () async {
      final decoded = await decodeMulticall([
        "414bf389${wordAddr(usdc)}${wordAddr(weth)}${wordInt(500)}${wordAddr(zeroAddress)}"
            "${wordInt(1700000000)}${word(usd(100))}${wordInt(0)}${wordInt(0)}",
        unwrapWeth9(thirtyThousandthsEth, wallet),
      ], router: swapRouter);
      expect(rowLines(decoded!.rows), [
        pay("100 USDC"),
        token(usdc),
        receiveMin("0.03 ETH"),
        recipientYou,
        routerRow(swapRouter),
      ]);
      expect(decoded.warnings, isEmpty);
    });

    test("a call that is not a swap router call leaves the multicall to the caller", () async {
      expect(
        await decodeMulticall([toRouter, "a9059cbb${wordAddr(attacker)}${wordInt(1)}"]),
        isNull,
      );
      expect(await decodeMulticall([toRouter, "49404b7c${wordInt(1)}"]), isNull);
    });

    test("payment calls without a swap still name who they pay", () async {
      final decoded = await decodeMulticall([
        unwrapWeth9(thirtyThousandthsEth, attacker),
        "12210e8a",
      ]);
      expectStepList(
        decoded,
        [receiveMin("0.03 ETH"), recipient(attacker), receiveMin("0 ETH"), recipientYou],
        swapRouter02,
        warnings: [notYou],
      );
    });
  });

  group("opaque routers", () {
    const zeroXExchangeProxy = "0xDef1C0ded9bec7F1a1670819833240f027b25EfF";
    const oneInchV5Router = "0x1111111254EEB25477B68fb85Ed929f73A960582";
    final opaque = <String, (String, String)>{
      "c04b8d59": ("Uniswap V3", swapRouter),
      "f28c0498": ("Uniswap V3", swapRouter),
      "b858183f": ("Uniswap V3", swapRouter),
      "09b81346": ("Uniswap V3", swapRouter),
      "415565b0": ("0x Protocol", zeroXExchangeProxy),
      "f6274f66": ("0x Protocol", zeroXExchangeProxy),
      "7c025200": ("1inch", oneInchV5Router),
      "0502b1c5": ("1inch", oneInchV5Router),
      "b0431182": ("1inch", oneInchV5Router),
      "12aa3caf": ("1inch", oneInchV5Router),
    };

    for (final entry in opaque.entries) {
      final (protocol, deployment) = entry.value;
      test("${entry.key} on $protocol's own router names it and does not call it a swap", () async {
        final decoded = await decode("0x${entry.key}${wordInt(1)}", deployment);
        expect(decoded!.actionSubtitle, S.current.wc_via(protocol));
        expectStepList(decoded, [], deployment);
      });
    }

    test("1inch's V6 router, none of whose own calls are read, is not vouched for", () async {
      const oneInchV6Router = "0x111111125421ca6dc452d289314280a0f8842a65";
      final v6Swap = selectorOf(
        "swap(address,(address,address,address,address,uint256,uint256,uint256),bytes)",
      );
      expect(v6Swap, "07ed2379");
      expect(await decode("0x$v6Swap${wordInt(1)}", oneInchV6Router), isNull);

      final decoded = await decode("0x12aa3caf${wordInt(1)}", oneInchV6Router);
      expect(decoded!.actionSubtitle, S.current.wc_via("0x1111…2a65"));
      expectStepList(
        decoded,
        [],
        oneInchV6Router,
        warnings: [S.current.wc_warning_unknown_contract],
      );
    });

    test("a router selector with unreadable arguments is not called a swap", () async {
      expectStepList(await decode("0x38ed1739${wordInt(1)}", v2Router), [], v2Router);
    });

    test("on an unlisted contract it is named by address and warned about", () async {
      for (final calldata in ["0x12aa3caf${wordInt(1)}", "0x38ed1739${wordInt(1)}"]) {
        final decoded = await decode(calldata, attacker);
        expect(decoded!.actionSubtitle, S.current.wc_via("0x9999…9999"), reason: calldata);
        expectStepList(decoded, [], attacker, warnings: [S.current.wc_warning_unknown_contract]);
      }
    });
  });

  group("router identity", () {
    final swapExactEthForTokens = v2EthSwap("7ff36ab5", usd(1500), [weth, usdc], wallet);

    test("an unlisted contract using a Uniswap selector is not called Uniswap", () async {
      final decoded = await decode(swapExactEthForTokens, attacker, value: halfEth);
      expect(decoded!.actionSubtitle, S.current.wc_via("0x9999…9999"));
      expectStepList(
        decoded,
        [pay("0.5 WETH"), token(weth), receiveMin("1500 USDC"), token(usdc), recipientYou],
        attacker,
        warnings: [S.current.wc_warning_unknown_contract],
      );
    });

    test("a multicall on an unlisted contract is a step list too", () async {
      final decoded = await decodeMulticall([
        router02Single("04e45aaf", weth, usdc, wallet, oneEth, usd(3000)),
      ], router: attacker);
      expectStepList(
        decoded,
        [...wethForUsdc, recipientYou],
        attacker,
        warnings: [S.current.wc_warning_unknown_contract],
      );
    });

    test("a Uniswap router on another chain is not trusted by address alone", () async {
      final decoded = await decode(swapExactEthForTokens, v2Router, value: halfEth, chainId: 8453);
      expect(decoded!.actionTitle, S.current.wc_contract_call);
      expect(decoded.actionSubtitle, isNot(S.current.wc_via("Uniswap V2")));
      expect(decoded.warnings, [unread, S.current.wc_warning_unknown_contract]);
    });

    test("the listed router keeps its name and still shows its address", () async {
      final decoded = await decode(swapExactEthForTokens, v2Router, value: halfEth);
      expect(decoded!.actionSubtitle, S.current.wc_via("Uniswap V2"));
      expect(rowLines(decoded.rows).last, routerRow(v2Router));
      expect(decoded.warnings, isEmpty);
    });
  });

  test("non-router selector returns null", () async {
    expect(await decode("0xdeadbeef${wordInt(1)}", v2Router), isNull);
  });

  test("a token is unknown without a wallet to check it against", () async {
    final decoded = await DexRouterDecoder(Erc20TokenResolver(null)).decode(
      calldata: EvmCalldata.parse(
        v2TokenSwap("38ed1739", oneEth, usd(3000), [weth, usdc], wallet),
      )!,
      nativeSymbol: "ETH",
      routerAddress: v2Router,
      walletAddress: wallet,
      valueWei: BigInt.zero,
      chainId: 1,
    );
    expect(rowLines(decoded!.rows).take(4), [
      pay("1000000000000000000 0xc02a…6cc2"),
      token(weth),
      receiveMin("3000000000 0xa0b8…eb48"),
      token(usdc),
    ]);
    expect(decoded.warnings, [S.current.wc_warning_unknown_token]);
  });
}
