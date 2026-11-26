import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/dex_router_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cw_core/erc20_token.dart";
import "package:flutter_test/flutter_test.dart";

import "abi_hex.dart";
import "stubs.dart";

const wallet = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const attacker = "0x9999999999999999999999999999999999999999";
const feeTaker = "0x7777777777777777777777777777777777777777";
const nextPool = "0x5555555555555555555555555555555555555555";
const weth = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
const usdc = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
const dai = "0x6b175474e89094c44da98b954eedeac495271d0f";
const fakeWeth = "0x3333333333333333333333333333333333333333";
const nativeEth = "0x0000000000000000000000000000000000000000";
const msgSender = "0x0000000000000000000000000000000000000001";
const addressThis = "0x0000000000000000000000000000000000000002";

const routerV1 = "0xef1c6e67703c7bd7107eed8303fbe6ec2554bf6b";
const routerV12 = "0x3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad";
const routerV20 = "0x66a9893cc07d91d95644aedd05d03f95e1dba8af";
const routerV211 = "0x4c82d1fbfe28c977cbb58d8c7ff8fcf9f70a2cca";

final oneEth = BigInt.from(10).pow(18);
final contractBalance = BigInt.one << 255;
final uint160Max = (BigInt.one << 160) - BigInt.one;

BigInt eth(num amount) => BigInt.from(amount * 1000) * BigInt.from(10).pow(15);

BigInt usd(int amount) => BigInt.from(amount) * BigInt.from(10).pow(6);

const executeDeadline = 1700009000;
const permitExpiration = 1700000000;
const otherPermitExpiration = 1700007200;
const permitSigDeadline = 1700003600;

String execute(String commandsHex, List<String> inputs) =>
    "0x3593564c${wordInt(0x60)}${wordInt(0xa0)}${wordInt(executeDeadline)}"
    "${bytesBlob(commandsHex)}${bytesArrayBody(inputs)}";

String v3Path(List<String> tokens) => [
  for (var i = 0; i < tokens.length; i++) ...[if (i > 0) "000bb8", tokens[i].substring(2)],
].join();

String swapHead(String recipient, BigInt amount, BigInt limit, {required bool payerIsUser}) =>
    wordAddr(recipient) + word(amount) + word(limit) + wordInt(0xa0) + wordInt(payerIsUser ? 1 : 0);

String v3Swap(
  String recipient,
  BigInt amount,
  BigInt limit,
  List<String> tokens, {
  bool payerIsUser = true,
}) => swapHead(recipient, amount, limit, payerIsUser: payerIsUser) + bytesBlob(v3Path(tokens));

String v2Swap(
  String recipient,
  BigInt amount,
  BigInt limit,
  List<String> tokens, {
  bool payerIsUser = true,
}) => swapHead(recipient, amount, limit, payerIsUser: payerIsUser) + addressArrayBody(tokens);

String tokenRecipientAmount(String token, String recipient, BigInt amount) =>
    wordAddr(token) + wordAddr(recipient) + word(amount);

String addressAmount(String address, BigInt amount) => wordAddr(address) + word(amount);

String permitSingle(String token, BigInt amount, String spender, {BigInt? expiration}) =>
    wordAddr(token) +
    word(amount) +
    word(expiration ?? BigInt.from(permitExpiration)) +
    wordInt(0) +
    wordAddr(spender) +
    wordInt(permitSigDeadline);

String v4Plan(String actionsHex, List<String> params) =>
    wordInt(0x40) + wordInt(0x80) + bytesBlob(actionsHex) + bytesArrayBody(params);

String subPlan(String commandsHex, List<String> inputs) => v4Plan(commandsHex, inputs);

String aliasedSubPlan(String commandsHex, String sharedInput) {
  final count = commandsHex.length ~/ 2;
  return wordInt(0x40) +
      wordInt(0x80) +
      bytesBlob(commandsHex) +
      wordInt(count) +
      wordInt(count * 32) * count +
      bytesBlob(sharedInput);
}

String v4Single(
  String currency0,
  String currency1, {
  required bool zeroForOne,
  required BigInt amount,
  required BigInt limit,
  bool hasHopPriceWord = false,
  int leadingOffset = 0x20,
}) =>
    wordInt(leadingOffset) +
    wordAddr(currency0) +
    wordAddr(currency1) +
    wordInt(3000) +
    wordInt(60) +
    wordAddr(nativeEth) +
    wordInt(zeroForOne ? 1 : 0) +
    word(amount) +
    word(limit) +
    (hasHopPriceWord ? wordInt(0) + wordInt(0x140) : wordInt(0x120)) +
    wordInt(0);

String v4PathKey(String intermediateCurrency) =>
    wordAddr(intermediateCurrency) +
    wordInt(3000) +
    wordInt(60) +
    wordAddr(nativeEth) +
    wordInt(0xa0) +
    wordInt(0);

String v4Path(List<String> hops) =>
    wordInt(hops.length) +
    [for (var i = 0; i < hops.length; i++) wordInt(hops.length * 32 + i * 0xc0)].join() +
    hops.map(v4PathKey).join();

String v4MultiHopFourWordHead(String currency, BigInt amount, BigInt limit, List<String> hops) =>
    wordInt(0x20) + wordAddr(currency) + wordInt(0x80) + word(amount) + word(limit) + v4Path(hops);

String v4MultiHopFiveWordHead(String currency, BigInt amount, BigInt limit, List<String> hops) {
  final path = v4Path(hops);
  return wordInt(0x20) +
      wordAddr(currency) +
      wordInt(0xa0) +
      wordInt(0xa0 + path.length ~/ 2) +
      word(amount) +
      word(limit) +
      path +
      wordInt(0);
}

class CountingResolver extends StubErc20Resolver {
  CountingResolver() : super(const {});

  final looked = <String>[];

  @override
  Future<Erc20Token?> resolve(String contractAddress) {
    looked.add(contractAddress);
    return super.resolve(contractAddress);
  }
}

String v4Settle(String currency, BigInt amount, {required bool payerIsUser}) =>
    wordAddr(currency) + word(amount) + wordInt(payerIsUser ? 1 : 0);

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
        fakeWeth: Erc20Token(
          name: "Wrapped Ether",
          symbol: "WETH",
          contractAddress: fakeWeth,
          decimal: 18,
        ),
      },
      known: {weth, usdc, dai},
    ),
  );

  Future<WCDecodedRequest?> decode(
    String calldata, {
    String router = routerV20,
    BigInt? value,
    int chainId = 1,
  }) => decoder.decode(
    calldata: EvmCalldata.parse(calldata)!,
    nativeSymbol: "ETH",
    routerAddress: router,
    walletAddress: wallet,
    valueWei: value ?? BigInt.zero,
    chainId: chainId,
  );

  String pay(String amount) => row(S.current.wc_swap_from, amount);
  String payMax(String amount) => row(S.current.wc_swap_from_max, amount);
  String receiveMin(String amount) => row(S.current.wc_swap_to_min, amount);
  String receive(String amount) => row(S.current.wc_swap_to, amount);
  String token(String address) => row(S.current.wc_token, address);
  String recipient(String address) => row(S.current.wc_recipient, address);
  String transfer(String amount) => row(S.current.wc_action_transfer, amount);
  String fee(String amount) => row(S.current.fee, amount);
  String approve(String amount) => row(S.current.wc_action_approve, amount);
  String spender(String address) => row(S.current.wc_approved_spender, address);
  String expiresAt(int seconds) =>
      row(S.current.wc_expiration, decoder.tokenResolver.formatTimestamp(BigInt.from(seconds)));
  String sentTo(String address) => row(S.current.to, address);
  String routerRow(String address) => row(S.current.wc_router, address);
  late final recipientYou = recipient(S.current.wc_recipient_you);
  late final recipientRouter = recipient(S.current.wc_recipient_router_hold);
  late final sentToYou = sentTo(S.current.wc_recipient_you);
  late final sentToRouter = sentTo(S.current.wc_recipient_router_hold);
  late final estimated = S.current.wc_warning_swap_amounts_estimated;
  late final notYou = S.current.wc_warning_recipient_not_you;
  late final unread = S.current.wc_warning_decode_failed;
  late final unknownToken = S.current.wc_warning_unknown_token;
  late final unlimitedApproval = S.current.wc_warning_unlimited_approval;
  late final zeroSlippage = S.current.wc_warning_zero_slippage;

  late final wethForUsdc = [pay("1 WETH"), token(weth), receiveMin("3000 USDC"), token(usdc)];

  void expectSwap(
    WCDecodedRequest? decoded,
    List<String> rows, {
    String router = routerV20,
    List<String> warnings = const [],
  }) {
    expect(decoded!.actionTitle, S.current.wc_action_swap);
    expect(rowLines(decoded.rows), [...rows, routerRow(router)]);
    expect(decoded.warnings, [estimated, ...warnings]);
  }

  void expectStepList(
    WCDecodedRequest? decoded,
    List<String> rows, {
    String router = routerV20,
    List<String> warnings = const [],
  }) {
    expect(decoded!.actionTitle, S.current.wc_contract_call);
    expect(rowLines(decoded.rows), [...rows, routerRow(router)]);
    expect(decoded.warnings, [unread, ...warnings]);
    expect(decoded.isValueShown, isFalse);
  }

  group("the plans Uniswap's SDK builds are shown as one swap", () {
    test("token to token, pulled from the wallet and paid straight to it", () async {
      final overV3 = await decode(
        execute("00", [
          v3Swap(msgSender, oneEth, usd(3000), [weth, usdc]),
        ]),
      );
      expectSwap(overV3, [...wethForUsdc, recipientYou]);
      expect(overV3!.isValueShown, isFalse);

      final overV2 = await decode(
        execute("08", [
          v2Swap(msgSender, oneEth, usd(3000), [weth, dai, usdc]),
        ]),
      );
      expectSwap(overV2, [...wethForUsdc, recipientYou]);

      final exactOut = await decode(
        execute("01", [
          v3Swap(msgSender, usd(3000), eth(1.1), [usdc, weth]),
        ]),
      );
      expectSwap(exactOut, [
        payMax("1.1 WETH"),
        token(weth),
        receive("3000 USDC"),
        token(usdc),
        recipientYou,
      ]);
    });

    test("a recipient written out as the wallet's own address is the sender too", () async {
      final decoded = await decode(
        execute("00", [
          v3Swap(wallet, oneEth, usd(3000), [weth, usdc]),
        ]),
      );
      expectSwap(decoded, [...wethForUsdc, recipientYou]);
    });

    test("PERMIT2_PERMIT for the router ahead of the swap is listed after it", () async {
      final decoded = await decode(
        execute("0a00", [
          permitSingle(weth, uint160Max, routerV20),
          v3Swap(msgSender, oneEth, usd(3000), [weth, usdc]),
        ]),
      );
      expectSwap(
        decoded,
        [
          ...wethForUsdc,
          recipientYou,
          approve("${S.current.wc_unlimited} WETH"),
          spender(routerV20),
        ],
        warnings: [unlimitedApproval],
      );
      expect(rowLines(decoded!.detailRows), [expiresAt(permitExpiration)]);
    });

    test("a PERMIT2_PERMIT with the largest expiration never expires", () async {
      Future<WCDecodedRequest?> withPermit(String permit) => decode(
        execute("0a00", [
          permit,
          v3Swap(msgSender, oneEth, usd(3000), [weth, usdc]),
        ]),
      );
      final uint48Max = (BigInt.one << 48) - BigInt.one;

      final dated = await withPermit(permitSingle(weth, oneEth, routerV20));
      expect(rowLines(dated!.detailRows), [expiresAt(permitExpiration)]);

      final openEnded = await withPermit(
        permitSingle(weth, oneEth, routerV20, expiration: uint48Max),
      );
      expect(openEnded!.actionTitle, S.current.wc_action_swap);
      expect(openEnded.detailRows.single.label, S.current.wc_expiration);
      expect(openEnded.detailRows.single.value, S.current.wc_never);
    });

    test("ETH to token, exact in: WRAP_ETH of the value, the router pays the swap", () async {
      final decoded = await decode(
        execute("0b00", [
          addressAmount(addressThis, oneEth),
          v3Swap(msgSender, oneEth, usd(3000), [weth, usdc], payerIsUser: false),
        ]),
        value: oneEth,
      );
      expectSwap(decoded, [pay("1 ETH"), receiveMin("3000 USDC"), token(usdc), recipientYou]);
      expect(decoded!.isValueShown, isTrue);
    });

    test("ETH to token, exact out, with the trailing UNWRAP_WETH refund", () async {
      final decoded = await decode(
        execute("0b010c", [
          addressAmount(addressThis, eth(1.1)),
          v3Swap(msgSender, usd(3000), eth(1.1), [usdc, weth], payerIsUser: false),
          addressAmount(msgSender, BigInt.zero),
        ]),
        value: eth(1.1),
      );
      expectSwap(decoded, [payMax("1.1 ETH"), receive("3000 USDC"), token(usdc), recipientYou]);
      expect(decoded!.isValueShown, isTrue);
    });

    test("exact out over two routes: each maximum is rounded down, the value is the cap", () async {
      final decoded = await decode(
        execute("0b01010c", [
          addressAmount(addressThis, eth(1.1)),
          v3Swap(msgSender, usd(2000), eth(0.7), [usdc, weth], payerIsUser: false),
          v3Swap(msgSender, usd(1000), eth(0.399), [usdc, dai, weth], payerIsUser: false),
          addressAmount(msgSender, BigInt.zero),
        ]),
        value: eth(1.1),
      );
      expectSwap(decoded, [payMax("1.1 ETH"), receive("3000 USDC"), token(usdc), recipientYou]);
    });

    test("the interface fee: swap to the router, PAY_PORTION, SWEEP to the sender", () async {
      final decoded = await decode(
        execute("0b000604", [
          addressAmount(addressThis, oneEth),
          v3Swap(addressThis, oneEth, BigInt.zero, [weth, usdc], payerIsUser: false),
          tokenRecipientAmount(usdc, feeTaker, BigInt.from(25)),
          tokenRecipientAmount(usdc, msgSender, usd(2990)),
        ]),
        value: oneEth,
      );
      expectSwap(decoded, [
        pay("1 ETH"),
        receiveMin("2990 USDC"),
        token(usdc),
        recipientYou,
        fee("0.25% USDC"),
        sentTo(feeTaker),
      ]);
    });

    test("an exact-output swap pays the fee as a flat TRANSFER", () async {
      final decoded = await decode(
        execute("010504", [
          v3Swap(addressThis, usd(3000), oneEth, [usdc, weth]),
          tokenRecipientAmount(usdc, feeTaker, usd(7)),
          tokenRecipientAmount(usdc, msgSender, usd(2990)),
        ]),
      );
      expectSwap(decoded, [
        payMax("1 WETH"),
        token(weth),
        receive("2993 USDC"),
        token(usdc),
        recipientYou,
        fee("7 USDC"),
        sentTo(feeTaker),
      ]);
    });

    test("a portion fee comes off an exact output and off a floor only the swap carries", () async {
      Future<WCDecodedRequest?> withPortion(String swapCommand, String swap) => decode(
        execute("${swapCommand}0604", [
          swap,
          tokenRecipientAmount(usdc, feeTaker, BigInt.from(25)),
          tokenRecipientAmount(usdc, msgSender, BigInt.zero),
        ]),
      );
      final feeRows = [recipientYou, fee("0.25% USDC"), sentTo(feeTaker)];

      final exactOut = await withPortion(
        "01",
        v3Swap(addressThis, usd(3000), oneEth, [usdc, weth]),
      );
      expectSwap(exactOut, [
        payMax("1 WETH"),
        token(weth),
        receive("2992.5 USDC"),
        token(usdc),
        ...feeRows,
      ]);

      final exactIn = await withPortion("00", v3Swap(addressThis, oneEth, usd(3000), [weth, usdc]));
      expectSwap(exactIn, [
        pay("1 WETH"),
        token(weth),
        receiveMin("2992.5 USDC"),
        token(usdc),
        ...feeRows,
      ]);
    });

    test(
      "a SWEEP minimum is the uint160 the router reads, UNWRAP_WETH's is the whole word",
      () async {
        final highBits = BigInt.one << 200;
        Future<WCDecodedRequest?> sweeping(BigInt minimum) => decode(
          execute("0004", [
            v3Swap(addressThis, oneEth, BigInt.zero, [weth, usdc]),
            tokenRecipientAmount(usdc, msgSender, minimum),
          ]),
        );

        expectSwap(await sweeping(highBits + usd(2990)), [
          pay("1 WETH"),
          token(weth),
          receiveMin("2990 USDC"),
          token(usdc),
          recipientYou,
        ]);
        expectSwap(
          await sweeping(highBits),
          [pay("1 WETH"), token(weth), receiveMin("0 USDC"), token(usdc), recipientYou],
          warnings: [zeroSlippage],
        );

        final unwrapping = await decode(
          execute("000c", [
            v3Swap(addressThis, usd(3000), BigInt.zero, [usdc, weth]),
            addressAmount(msgSender, highBits),
          ]),
        );
        expectSwap(unwrapping, [
          pay("3000 USDC"),
          token(usdc),
          receiveMin("${S.current.wc_unlimited} ETH"),
          recipientYou,
        ]);
      },
    );

    test("token to ETH takes the receive floor from UNWRAP_WETH to the sender", () async {
      final decoded = await decode(
        execute("000c", [
          v3Swap(addressThis, usd(3000), BigInt.zero, [usdc, weth]),
          addressAmount(msgSender, eth(0.99)),
        ]),
      );
      expectSwap(decoded, [pay("3000 USDC"), token(usdc), receiveMin("0.99 ETH"), recipientYou]);
      expect(decoded!.isValueShown, isFalse);
    });

    test("a floor on the swap itself counts when the UNWRAP_WETH names none", () async {
      final decoded = await decode(
        execute("000c", [
          v3Swap(addressThis, usd(3000), eth(0.98), [usdc, weth]),
          addressAmount(msgSender, BigInt.zero),
        ]),
      );
      expectSwap(decoded, [pay("3000 USDC"), token(usdc), receiveMin("0.98 ETH"), recipientYou]);

      final neitherHasAFloor = await decode(
        execute("000c", [
          v3Swap(addressThis, usd(3000), BigInt.zero, [usdc, weth]),
          addressAmount(msgSender, BigInt.zero),
        ]),
      );
      expectSwap(
        neitherHasAFloor,
        [pay("3000 USDC"), token(usdc), receiveMin("0 ETH"), recipientYou],
        warnings: [zeroSlippage],
      );
    });

    test("token to ETH with the fee taken in WETH before the unwrap", () async {
      final decoded = await decode(
        execute("00060c", [
          v3Swap(addressThis, usd(3000), BigInt.zero, [usdc, weth]),
          tokenRecipientAmount(weth, feeTaker, BigInt.from(25)),
          addressAmount(msgSender, eth(0.99)),
        ]),
      );
      expectSwap(decoded, [
        pay("3000 USDC"),
        token(usdc),
        receiveMin("0.99 ETH"),
        recipientYou,
        fee("0.25% WETH"),
        token(weth),
        sentTo(feeTaker),
      ]);
    });

    test("a split route paid straight to the sender sums its legs", () async {
      final decoded = await decode(
        execute("0800", [
          v2Swap(msgSender, eth(0.6), usd(1800), [weth, usdc]),
          v3Swap(msgSender, eth(0.4), usd(1200), [weth, dai, usdc]),
        ]),
      );
      expectSwap(decoded, [...wethForUsdc, recipientYou]);
    });

    test("three routes held by the router are checked by one SWEEP to the sender", () async {
      final decoded = await decode(
        execute("00080004", [
          v3Swap(addressThis, eth(0.5), BigInt.zero, [weth, usdc]),
          v2Swap(addressThis, eth(0.3), BigInt.zero, [weth, usdc]),
          v3Swap(addressThis, eth(0.2), BigInt.zero, [weth, dai, usdc]),
          tokenRecipientAmount(usdc, msgSender, usd(3000)),
        ]),
      );
      expectSwap(decoded, [...wethForUsdc, recipientYou]);
    });

    test(
      "an exact-out V2 route only caps what goes in, a SWEEP floor holds what comes out",
      () async {
        final exactOutRows = [payMax("1 WETH"), token(weth), receive("3000 USDC"), token(usdc)];
        Future<WCDecodedRequest?> sweptWithFloor(BigInt floor) => decode(
          execute("0904", [
            v2Swap(addressThis, usd(3000), oneEth, [weth, usdc]),
            tokenRecipientAmount(usdc, msgSender, floor),
          ]),
        );

        expectSwap(await sweptWithFloor(usd(3000)), [...exactOutRows, recipientYou]);
        expectStepList(
          await sweptWithFloor(usd(3000) - BigInt.one),
          [...exactOutRows, recipientRouter, receiveMin("2999.999999 USDC"), recipientYou],
          warnings: [notYou],
        );

        final straightToSender = await decode(
          execute("09", [
            v2Swap(msgSender, usd(3000), oneEth, [weth, usdc]),
          ]),
        );
        expectStepList(straightToSender, [...exactOutRows, recipientYou]);
      },
    );

    test(
      "with a fee, the SWEEP floor of an exact-out V2 route holds what is left after it",
      () async {
        Future<WCDecodedRequest?> sweptWithFloor(BigInt floor) => decode(
          execute("090604", [
            v2Swap(addressThis, usd(3000), oneEth, [weth, usdc]),
            tokenRecipientAmount(usdc, feeTaker, BigInt.from(25)),
            tokenRecipientAmount(usdc, msgSender, floor),
          ]),
        );
        final afterFee = usd(3000) - usd(3000) * BigInt.from(25) ~/ BigInt.from(10000);

        expectSwap(await sweptWithFloor(afterFee), [
          payMax("1 WETH"),
          token(weth),
          receive("2992.5 USDC"),
          token(usdc),
          recipientYou,
          fee("0.25% USDC"),
          sentTo(feeTaker),
        ]);
        final belowIt = await sweptWithFloor(afterFee - BigInt.one);
        expect(belowIt!.actionTitle, S.current.wc_contract_call);
        expect(belowIt.warnings, [unread, notYou]);
      },
    );

    test("an exact-out swap with no cap on what it spends warns like one with no floor", () async {
      final uncapped = (BigInt.one << 256) - BigInt.one;
      final decoded = await decode(
        execute("01", [
          v3Swap(msgSender, usd(3000), uncapped, [usdc, weth]),
        ]),
      );
      expectSwap(
        decoded,
        [
          payMax("${S.current.wc_unlimited} WETH"),
          token(weth),
          receive("3000 USDC"),
          token(usdc),
          recipientYou,
        ],
        warnings: [zeroSlippage],
      );
    });

    test("a mixed route chained through CONTRACT_BALANCE reads as one swap", () async {
      final decoded = await decode(
        execute("0008", [
          v3Swap(addressThis, usd(100), BigInt.zero, [usdc, dai]),
          v2Swap(msgSender, contractBalance, eth(0.03), [dai, weth], payerIsUser: false),
        ]),
      );
      expectSwap(decoded, [
        pay("100 USDC"),
        token(usdc),
        receiveMin("0.03 WETH"),
        token(weth),
        recipientYou,
      ]);
    });

    test("a mixed route that pays the next section's V2 pair directly", () async {
      const daiWethPair = "0xa478c2975ab1ea89e8196811f51a7b7ade33eb11";
      final decoded = await decode(
        execute("0008", [
          v3Swap(daiWethPair, usd(100), BigInt.zero, [usdc, dai]),
          v2Swap(msgSender, contractBalance, eth(0.03), [dai, weth], payerIsUser: false),
        ]),
      );
      expectSwap(decoded, [
        pay("100 USDC"),
        token(usdc),
        receiveMin("0.03 WETH"),
        token(weth),
        recipientYou,
      ]);
    });

    test("a mixed route that unwraps between a V3 section and a native V4 section", () async {
      final decoded = await decode(
        execute("000c10", [
          v3Swap(addressThis, usd(3000), BigInt.zero, [usdc, weth]),
          addressAmount(addressThis, BigInt.zero),
          v4Plan("0b060e", [
            v4Settle(nativeEth, contractBalance, payerIsUser: false),
            v4Single(nativeEth, dai, zeroForOne: true, amount: BigInt.zero, limit: eth(2900)),
            tokenRecipientAmount(dai, msgSender, BigInt.zero),
          ]),
        ]),
      );
      expectSwap(decoded, [
        pay("3000 USDC"),
        token(usdc),
        receiveMin("2900 DAI"),
        token(dai),
        recipientYou,
      ]);
    });

    test("a pull into the router of exactly what the router-paid swap spends", () async {
      final decoded = await decode(
        execute("0200", [
          tokenRecipientAmount(usdc, addressThis, usd(3000)),
          v3Swap(msgSender, usd(3000), oneEth, [usdc, weth], payerIsUser: false),
        ]),
      );
      expectSwap(decoded, [
        pay("3000 USDC"),
        token(usdc),
        receiveMin("1 WETH"),
        token(weth),
        recipientYou,
      ]);
    });

    test("safe mode ends with a SWEEP of leftover ETH to the sender", () async {
      final decoded = await decode(
        execute("0004", [
          v3Swap(msgSender, oneEth, usd(3000), [weth, usdc]),
          tokenRecipientAmount(nativeEth, msgSender, BigInt.zero),
        ]),
      );
      expectSwap(decoded, [...wethForUsdc, recipientYou]);
    });

    group("V4", () {
      test("the SDK's plan: SWAP_EXACT_IN, SETTLE of the open debt, TAKE to the sender", () async {
        final decoded = await decode(
          execute("10", [
            v4Plan("070b0e", [
              v4MultiHopFourWordHead(usdc, usd(3000), eth(0.99), [dai, weth]),
              v4Settle(usdc, BigInt.zero, payerIsUser: true),
              tokenRecipientAmount(weth, msgSender, BigInt.zero),
            ]),
          ]),
        );
        expectSwap(decoded, [
          pay("3000 USDC"),
          token(usdc),
          receiveMin("0.99 WETH"),
          token(weth),
          recipientYou,
        ]);
      });

      test("the docs' plan: SETTLE_ALL and TAKE_ALL, native ETH in", () async {
        final decoded = await decode(
          execute("10", [
            v4Plan("060c0f", [
              v4Single(nativeEth, usdc, zeroForOne: true, amount: oneEth, limit: usd(3000)),
              addressAmount(nativeEth, oneEth),
              addressAmount(usdc, usd(3000)),
            ]),
          ]),
          value: oneEth,
        );
        expectSwap(decoded, [pay("1 ETH"), receiveMin("3000 USDC"), token(usdc), recipientYou]);
        expect(decoded!.isValueShown, isTrue);
      });

      test("the interface fee: TAKE to the router, PAY_PORTION, SWEEP to the sender", () async {
        final decoded = await decode(
          execute("100604", [
            v4Plan("070b0e", [
              v4MultiHopFourWordHead(usdc, usd(3000), BigInt.zero, [weth]),
              v4Settle(usdc, BigInt.zero, payerIsUser: true),
              tokenRecipientAmount(weth, addressThis, BigInt.zero),
            ]),
            tokenRecipientAmount(weth, feeTaker, BigInt.from(25)),
            tokenRecipientAmount(weth, msgSender, eth(0.99)),
          ]),
        );
        expectSwap(decoded, [
          pay("3000 USDC"),
          token(usdc),
          receiveMin("0.99 WETH"),
          token(weth),
          recipientYou,
          fee("0.25% WETH"),
          sentTo(feeTaker),
        ]);
      });

      test("exact out with native ETH in: TAKE of the exact amount, ETH refund SWEEP", () async {
        final decoded = await decode(
          execute("1004", [
            v4Plan("090b0e", [
              v4MultiHopFourWordHead(usdc, usd(3000), eth(1.1), [nativeEth]),
              v4Settle(nativeEth, BigInt.zero, payerIsUser: true),
              tokenRecipientAmount(usdc, msgSender, usd(3000)),
            ]),
            tokenRecipientAmount(nativeEth, msgSender, BigInt.zero),
          ]),
          value: eth(1.1),
        );
        expectSwap(decoded, [payMax("1.1 ETH"), receive("3000 USDC"), token(usdc), recipientYou]);
        expect(decoded!.isValueShown, isTrue);
      });

      test("settle before swap: a SETTLE of the amount, then a swap of that credit", () async {
        final decoded = await decode(
          execute("10", [
            v4Plan("0b070e", [
              v4Settle(usdc, usd(3000), payerIsUser: true),
              v4MultiHopFourWordHead(usdc, BigInt.zero, eth(0.99), [weth]),
              tokenRecipientAmount(weth, msgSender, BigInt.zero),
            ]),
          ]),
        );
        expectSwap(decoded, [
          pay("3000 USDC"),
          token(usdc),
          receiveMin("0.99 WETH"),
          token(weth),
          recipientYou,
        ]);
      });

      test("WETH into a native pool: pulled to the router and unwrapped there", () async {
        final decoded = await decode(
          execute("020c10", [
            tokenRecipientAmount(weth, addressThis, oneEth),
            addressAmount(addressThis, BigInt.zero),
            v4Plan("070b0e", [
              v4MultiHopFourWordHead(nativeEth, oneEth, usd(3000), [usdc]),
              v4Settle(nativeEth, BigInt.zero, payerIsUser: false),
              tokenRecipientAmount(usdc, msgSender, BigInt.zero),
            ]),
          ]),
        );
        expectSwap(decoded, [...wethForUsdc, recipientYou]);
        expect(decoded!.isValueShown, isFalse);
      });

      test("WETH into a native pool, exact out: the unspent ETH is wrapped back", () async {
        final decoded = await decode(
          execute("020c100b", [
            tokenRecipientAmount(weth, addressThis, eth(1.1)),
            addressAmount(addressThis, BigInt.zero),
            v4Plan("090b0e", [
              v4MultiHopFourWordHead(usdc, usd(3000), eth(1.1), [nativeEth]),
              v4Settle(nativeEth, BigInt.zero, payerIsUser: false),
              tokenRecipientAmount(usdc, msgSender, usd(3000)),
            ]),
            addressAmount(msgSender, contractBalance),
          ]),
        );
        expectSwap(decoded, [
          payMax("1.1 WETH"),
          token(weth),
          receive("3000 USDC"),
          token(usdc),
          recipientYou,
        ]);
      });

      test("a native output wanted as WETH is wrapped in the router, then swept", () async {
        final decoded = await decode(
          execute("100b04", [
            v4Plan("070b0e", [
              v4MultiHopFourWordHead(usdc, usd(3000), BigInt.zero, [nativeEth]),
              v4Settle(usdc, BigInt.zero, payerIsUser: true),
              tokenRecipientAmount(nativeEth, addressThis, BigInt.zero),
            ]),
            addressAmount(addressThis, contractBalance),
            tokenRecipientAmount(weth, msgSender, eth(0.99)),
          ]),
        );
        expectSwap(decoded, [
          pay("3000 USDC"),
          token(usdc),
          receiveMin("0.99 WETH"),
          token(weth),
          recipientYou,
        ]);
      });
    });
  });

  group("a plan that is not one of those shapes is listed step by step", () {
    final swapToSender = v3Swap(msgSender, oneEth, usd(3000), [weth, usdc]);
    final swapToRouter = v3Swap(addressThis, oneEth, usd(3000), [weth, usdc]);

    test("a swap paid to someone else, whatever follows it", () async {
      final decoded = await decode(
        execute("0b000c", [
          addressAmount(addressThis, oneEth),
          v3Swap(attacker, oneEth, usd(3000), [weth, usdc], payerIsUser: false),
          addressAmount(msgSender, BigInt.zero),
        ]),
        value: oneEth,
      );
      expectStepList(
        decoded,
        [
          transfer("1 ETH"),
          sentToRouter,
          ...wethForUsdc,
          recipient(attacker),
          receiveMin("0 ETH"),
          recipientYou,
        ],
        warnings: [notYou],
      );
    });

    test("a V2 leg with an amount in of 0 swaps what its pair already holds", () async {
      final decoded = await decode(
        execute("08", [
          v2Swap(msgSender, BigInt.zero, usd(3000), [weth, usdc]),
        ]),
      );
      expectStepList(decoded, [
        pay("0 WETH"),
        token(weth),
        receiveMin("3000 USDC"),
        token(usdc),
        recipientYou,
      ]);

      final overV3 = await decode(
        execute("00", [
          v3Swap(msgSender, BigInt.zero, usd(3000), [weth, usdc]),
        ]),
      );
      expect(overV3!.actionTitle, S.current.wc_contract_call);
    });

    test("a SWEEP to the sender before the swap does not stand in for one after it", () async {
      final decoded = await decode(
        execute("040004", [
          tokenRecipientAmount(usdc, msgSender, BigInt.zero),
          swapToRouter,
          tokenRecipientAmount(usdc, attacker, BigInt.zero),
        ]),
      );
      expectStepList(
        decoded,
        [
          receiveMin("0 USDC"),
          token(usdc),
          recipientYou,
          pay("1 WETH"),
          token(weth),
          receiveMin("3000 USDC"),
          recipientRouter,
          receiveMin("0 USDC"),
          recipient(attacker),
        ],
        warnings: [notYou],
      );
    });

    test("an output no later step pays out stays with the router", () async {
      final decoded = await decode(execute("00", [swapToRouter]));
      expectStepList(decoded, [...wethForUsdc, recipientRouter], warnings: [notYou]);
    });

    test("a delivery to someone else", () async {
      final decoded = await decode(
        execute("0004", [swapToRouter, tokenRecipientAmount(usdc, attacker, usd(2990))]),
      );
      expectStepList(
        decoded,
        [...wethForUsdc, recipientRouter, receiveMin("2990 USDC"), recipient(attacker)],
        warnings: [notYou],
      );
    });

    test("a delivery of another token than the one the router holds", () async {
      final decoded = await decode(
        execute("0004", [swapToRouter, tokenRecipientAmount(dai, msgSender, eth(2990))]),
      );
      expectStepList(
        decoded,
        [...wethForUsdc, recipientRouter, receiveMin("2990 DAI"), token(dai), recipientYou],
        warnings: [notYou],
      );
    });

    test("a floored SWEEP after a swap that already paid the sender", () async {
      final decoded = await decode(
        execute("0004", [swapToSender, tokenRecipientAmount(dai, msgSender, eth(5))]),
      );
      expectStepList(decoded, [
        ...wethForUsdc,
        recipientYou,
        receiveMin("5 DAI"),
        token(dai),
        recipientYou,
      ]);
    });

    test("PERMIT2_TRANSFER_FROM to a third party next to a swap", () async {
      final decoded = await decode(
        execute("0002", [swapToSender, tokenRecipientAmount(weth, attacker, eth(5))]),
      );
      expectStepList(
        decoded,
        [...wethForUsdc, recipientYou, transfer("5 WETH"), sentTo(attacker)],
        warnings: [notYou],
      );
    });

    test("a pull into the router that is not exactly what the swap spends", () async {
      final pull = tokenRecipientAmount(usdc, addressThis, usd(3000));
      final swap = v3Swap(msgSender, usd(3000), oneEth, [usdc, weth], payerIsUser: false);
      final swapRows = [pay("3000 USDC"), receiveMin("1 WETH"), token(weth), recipientYou];

      for (final pulled in [usd(2999), usd(3001)]) {
        final decoded = await decode(
          execute("0200", [tokenRecipientAmount(usdc, addressThis, pulled), swap]),
        );
        expectStepList(
          decoded,
          [transfer("${pulled ~/ usd(1)} USDC"), token(usdc), sentToRouter, ...swapRows],
          warnings: [notYou],
        );
      }

      final twoPulls = await decode(execute("020200", [pull, pull, swap]));
      expectStepList(
        twoPulls,
        [
          transfer("3000 USDC"),
          token(usdc),
          sentToRouter,
          transfer("3000 USDC"),
          sentToRouter,
          ...swapRows,
        ],
        warnings: [notYou],
      );
    });

    test("only a pull from the wallet into the router funds the swap the router pays", () async {
      final swap = v3Swap(msgSender, usd(3000), oneEth, [usdc, weth], payerIsUser: false);
      final swapRows = [pay("3000 USDC"), receiveMin("1 WETH"), token(weth), recipientYou];

      final pulledToSomeoneElse = await decode(
        execute("0200", [tokenRecipientAmount(usdc, attacker, usd(3000)), swap]),
      );
      expectStepList(
        pulledToSomeoneElse,
        [transfer("3000 USDC"), token(usdc), sentTo(attacker), ...swapRows],
        warnings: [notYou],
      );

      final transferNotPull = await decode(
        execute("0500", [tokenRecipientAmount(usdc, addressThis, usd(3000)), swap]),
      );
      expectStepList(
        transferNotPull,
        [transfer("3000 USDC"), token(usdc), sentToRouter, ...swapRows],
        warnings: [notYou],
      );
    });

    test("a pull into the router for a swap the wallet pays itself", () async {
      final decoded = await decode(
        execute("0200", [tokenRecipientAmount(weth, addressThis, oneEth), swapToSender]),
      );
      expectStepList(
        decoded,
        [
          transfer("1 WETH"),
          token(weth),
          sentToRouter,
          pay("1 WETH"),
          receiveMin("3000 USDC"),
          token(usdc),
          recipientYou,
        ],
        warnings: [notYou],
      );
    });

    test("a swap paid by the router that nothing in the plan funds", () async {
      final decoded = await decode(
        execute("00", [
          v3Swap(msgSender, oneEth, usd(3000), [weth, usdc], payerIsUser: false),
        ]),
      );
      expectStepList(decoded, [...wethForUsdc, recipientYou]);
    });

    test("an amount of CONTRACT_BALANCE that the wallet is asked to pay", () async {
      final decoded = await decode(
        execute("00", [
          v3Swap(msgSender, contractBalance, usd(3000), [weth, usdc]),
        ]),
      );
      expectStepList(decoded, [
        pay("${S.current.wc_unlimited} WETH"),
        token(weth),
        receiveMin("3000 USDC"),
        token(usdc),
        recipientYou,
      ]);
    });

    test("the V1 router maps no sentinel for PERMIT2_TRANSFER_FROM, later ones do", () async {
      final pull = execute("02", [tokenRecipientAmount(usdc, addressThis, usd(3000))]);
      final pullRows = [transfer("3000 USDC"), token(usdc)];

      expectStepList(
        await decode(pull, router: routerV1),
        [...pullRows, sentTo(addressThis)],
        router: routerV1,
        warnings: [notYou],
      );
      expectStepList(
        await decode(pull, router: routerV12),
        [...pullRows, sentToRouter],
        router: routerV12,
        warnings: [notYou],
      );
    });

    test(
      "on V1 a TRANSFER to 0x02 is still the router, only the Permit2 pull is literal",
      () async {
        final decoded = await decode(
          execute("05", [tokenRecipientAmount(usdc, addressThis, usd(3000))]),
          router: routerV1,
        );
        expectStepList(
          decoded,
          [transfer("3000 USDC"), token(usdc), sentToRouter],
          router: routerV1,
          warnings: [notYou],
        );
      },
    );

    test("PERMIT2_TRANSFER_FROM_BATCH lists every entry and maps no sentinel", () async {
      final batch =
          wordInt(0x20) +
          wordInt(2) +
          wordAddr(wallet) +
          wordAddr(attacker) +
          word(usd(40)) +
          wordAddr(usdc) +
          wordAddr(wallet) +
          wordAddr(msgSender) +
          word(eth(2)) +
          wordAddr(dai);
      final decoded = await decode(execute("000d", [swapToSender, batch]));
      expectStepList(
        decoded,
        [
          ...wethForUsdc,
          recipientYou,
          transfer("40 USDC"),
          sentTo(attacker),
          transfer("2 DAI"),
          token(dai),
          sentTo(msgSender),
        ],
        warnings: [notYou],
      );
    });

    test("a TRANSFER of the output and a PAY_PORTION of all of it", () async {
      final decoded = await decode(
        execute("000506", [
          swapToRouter,
          tokenRecipientAmount(usdc, attacker, usd(3000)),
          tokenRecipientAmount(usdc, feeTaker, BigInt.from(10000)),
        ]),
      );
      expectStepList(
        decoded,
        [
          ...wethForUsdc,
          recipientRouter,
          transfer("3000 USDC"),
          sentTo(attacker),
          transfer("100% USDC"),
          sentTo(feeTaker),
        ],
        warnings: [notYou],
      );
    });

    test("a portion of up to 1% is the fee, a larger one makes it a step list", () async {
      Future<WCDecodedRequest?> withPortion(int bips) => decode(
        execute("000604", [
          v3Swap(addressThis, oneEth, BigInt.zero, [weth, usdc]),
          tokenRecipientAmount(usdc, feeTaker, BigInt.from(bips)),
          tokenRecipientAmount(usdc, msgSender, usd(2900)),
        ]),
      );

      expectSwap(await withPortion(100), [
        pay("1 WETH"),
        token(weth),
        receiveMin("2900 USDC"),
        token(usdc),
        recipientYou,
        fee("1% USDC"),
        sentTo(feeTaker),
      ]);
      expectStepList(
        await withPortion(101),
        [
          pay("1 WETH"),
          token(weth),
          receiveMin("0 USDC"),
          token(usdc),
          recipientRouter,
          transfer("1.01% USDC"),
          sentTo(feeTaker),
          receiveMin("2900 USDC"),
          recipientYou,
        ],
        warnings: [notYou],
      );
    });

    test("a flat fee of up to 1% of the output is the fee, a larger one is not", () async {
      Future<WCDecodedRequest?> withFlatFee(BigInt flatFee) => decode(
        execute("010504", [
          v3Swap(addressThis, usd(3000), oneEth, [usdc, weth]),
          tokenRecipientAmount(usdc, feeTaker, flatFee),
          tokenRecipientAmount(usdc, msgSender, usd(2900)),
        ]),
      );

      final atOnePercent = await withFlatFee(usd(30));
      expect(atOnePercent!.actionTitle, S.current.wc_action_swap);
      expect(rowLines(atOnePercent.rows), containsAllInOrder([fee("30 USDC"), sentTo(feeTaker)]));

      expectStepList(
        await withFlatFee(usd(30) + BigInt.one),
        [
          payMax("1 WETH"),
          token(weth),
          receive("3000 USDC"),
          token(usdc),
          recipientRouter,
          transfer("30.000001 USDC"),
          sentTo(feeTaker),
          receiveMin("2900 USDC"),
          recipientYou,
        ],
        warnings: [notYou],
      );
    });

    test("a pull from the wallet sized like a fee is not the fee", () async {
      final decoded = await decode(
        execute("010204", [
          v3Swap(addressThis, usd(3000), oneEth, [usdc, weth]),
          tokenRecipientAmount(usdc, feeTaker, usd(7)),
          tokenRecipientAmount(usdc, msgSender, usd(2900)),
        ]),
      );
      expectStepList(
        decoded,
        [
          payMax("1 WETH"),
          token(weth),
          receive("3000 USDC"),
          token(usdc),
          recipientRouter,
          transfer("7 USDC"),
          sentTo(feeTaker),
          receiveMin("2900 USDC"),
          recipientYou,
        ],
        warnings: [notYou],
      );
    });

    test("a portion of another token than the output is not the fee", () async {
      final decoded = await decode(
        execute("000604", [
          v3Swap(addressThis, oneEth, BigInt.zero, [weth, usdc]),
          tokenRecipientAmount(dai, feeTaker, BigInt.from(25)),
          tokenRecipientAmount(usdc, msgSender, usd(2990)),
        ]),
      );
      expectStepList(
        decoded,
        [
          pay("1 WETH"),
          token(weth),
          receiveMin("0 USDC"),
          token(usdc),
          recipientRouter,
          transfer("0.25% DAI"),
          token(dai),
          sentTo(feeTaker),
          receiveMin("2990 USDC"),
          recipientYou,
        ],
        warnings: [notYou],
      );
    });

    test(
      "a portion of ETH is paid from the router's ETH, it is not a fee on a WETH output",
      () async {
        final decoded = await decode(
          execute("000604", [
            v3Swap(addressThis, usd(3000), BigInt.zero, [usdc, weth]),
            tokenRecipientAmount(nativeEth, feeTaker, BigInt.from(25)),
            tokenRecipientAmount(weth, msgSender, eth(0.99)),
          ]),
        );
        expectStepList(
          decoded,
          [
            pay("3000 USDC"),
            token(usdc),
            receiveMin("0 WETH"),
            token(weth),
            recipientRouter,
            transfer("0.25% ETH"),
            sentTo(feeTaker),
            receiveMin("0.99 WETH"),
            recipientYou,
          ],
          warnings: [notYou],
        );
      },
    );

    test("a flat fee in another token than the output", () async {
      final decoded = await decode(
        execute("010504", [
          v3Swap(addressThis, usd(3000), oneEth, [usdc, weth]),
          tokenRecipientAmount(dai, feeTaker, BigInt.one),
          tokenRecipientAmount(usdc, msgSender, usd(2900)),
        ]),
      );
      expect(decoded!.actionTitle, S.current.wc_contract_call);
      expect(
        rowLines(decoded.rows),
        containsAllInOrder([transfer("0.000000000000000001 DAI"), token(dai), sentTo(feeTaker)]),
      );
      expect(decoded.warnings, [unread, notYou]);
    });

    test("more than one fee step", () async {
      final decoded = await decode(
        execute("00060604", [
          v3Swap(addressThis, oneEth, BigInt.zero, [weth, usdc]),
          tokenRecipientAmount(usdc, feeTaker, BigInt.from(25)),
          tokenRecipientAmount(usdc, attacker, BigInt.from(15)),
          tokenRecipientAmount(usdc, msgSender, usd(2900)),
        ]),
      );
      expectStepList(
        decoded,
        [
          pay("1 WETH"),
          token(weth),
          receiveMin("0 USDC"),
          token(usdc),
          recipientRouter,
          transfer("0.25% USDC"),
          sentTo(feeTaker),
          transfer("0.15% USDC"),
          sentTo(attacker),
          receiveMin("2900 USDC"),
          recipientYou,
        ],
        warnings: [notYou],
      );
    });

    test("a fee step on a swap that pays the sender directly", () async {
      final decoded = await decode(
        execute("0006", [swapToSender, tokenRecipientAmount(usdc, feeTaker, BigInt.from(25))]),
      );
      expectStepList(
        decoded,
        [...wethForUsdc, recipientYou, transfer("0.25% USDC"), sentTo(feeTaker)],
        warnings: [notYou],
      );
    });

    test("a PERMIT2_PERMIT whose spender is not the router", () async {
      final decoded = await decode(
        execute("0a00", [permitSingle(weth, uint160Max, attacker), swapToSender]),
      );
      expectStepList(
        decoded,
        [
          approve("${S.current.wc_unlimited} WETH"),
          token(weth),
          spender(attacker),
          pay("1 WETH"),
          receiveMin("3000 USDC"),
          token(usdc),
          recipientYou,
        ],
        warnings: [unlimitedApproval],
      );
    });

    test("a PERMIT2_PERMIT for a token the swap does not pay with", () async {
      final decoded = await decode(
        execute("0a00", [permitSingle(dai, eth(5), routerV20), swapToSender]),
      );
      expectStepList(decoded, [
        approve("5 DAI"),
        token(dai),
        spender(routerV20),
        ...wethForUsdc,
        recipientYou,
      ]);
    });

    test("a second PERMIT2_PERMIT, wherever it sits", () async {
      final forRouter = permitSingle(weth, BigInt.one, routerV20);
      final swapRows = [pay("1 WETH"), receiveMin("3000 USDC"), token(usdc), recipientYou];
      final permitRows = [
        approve("0.000000000000000001 WETH"),
        token(weth),
        spender(routerV20),
        approve("0.000000000000000001 WETH"),
        spender(routerV20),
      ];

      final upFront = await decode(execute("0a0a00", [forRouter, forRouter, swapToSender]));
      expectStepList(upFront, [...permitRows, ...swapRows]);
      expect(rowLines(upFront!.detailRows), [
        expiresAt(permitExpiration),
        expiresAt(permitExpiration),
      ]);

      final afterTheSwap = await decode(execute("0a000a", [forRouter, swapToSender, forRouter]));
      expectStepList(afterTheSwap, [
        approve("0.000000000000000001 WETH"),
        token(weth),
        spender(routerV20),
        ...swapRows,
        approve("0.000000000000000001 WETH"),
        spender(routerV20),
      ]);
    });

    test("PERMIT2_PERMIT_BATCH lists each token with the batch spender", () async {
      final details =
          wordInt(2) +
          wordAddr(usdc) +
          word(usd(500)) +
          wordInt(permitExpiration) +
          wordInt(0) +
          wordAddr(dai) +
          word(uint160Max) +
          wordInt(otherPermitExpiration) +
          wordInt(1);
      final permitBatch = wordInt(0x60) + wordAddr(attacker) + wordInt(permitSigDeadline) + details;
      final decoded = await decode(
        execute("0300", [wordInt(0x40) + wordInt(0x200) + permitBatch, swapToSender]),
      );
      expectStepList(
        decoded,
        [
          approve("500 USDC"),
          token(usdc),
          spender(attacker),
          approve("${S.current.wc_unlimited} DAI"),
          token(dai),
          spender(attacker),
          pay("1 WETH"),
          token(weth),
          receiveMin("3000 USDC"),
          recipientYou,
        ],
        warnings: [unlimitedApproval],
      );
      expect(rowLines(decoded!.detailRows), [
        expiresAt(permitExpiration),
        expiresAt(otherPermitExpiration),
      ]);
    });

    test("split legs over one pair with different recipients", () async {
      final decoded = await decode(
        execute("0808", [
          v2Swap(msgSender, eth(0.01), usd(30), [weth, usdc]),
          v2Swap(attacker, eth(9.99), usd(29970), [weth, usdc]),
        ]),
      );
      expectStepList(
        decoded,
        [
          pay("0.01 WETH"),
          token(weth),
          receiveMin("30 USDC"),
          token(usdc),
          recipientYou,
          pay("9.99 WETH"),
          receiveMin("29970 USDC"),
          recipient(attacker),
        ],
        warnings: [notYou],
      );
    });

    test("swaps of different pairs in one execute", () async {
      final decoded = await decode(
        execute("0808", [
          v2Swap(msgSender, oneEth, usd(3000), [weth, usdc]),
          v2Swap(msgSender, usd(200), eth(180), [usdc, dai]),
        ]),
      );
      expectStepList(decoded, [
        ...wethForUsdc,
        recipientYou,
        pay("200 USDC"),
        receiveMin("180 DAI"),
        token(dai),
        recipientYou,
      ]);
    });

    test("two swaps that pay with one token for two different ones", () async {
      final decoded = await decode(
        execute("0000", [
          swapToSender,
          v3Swap(msgSender, eth(2), eth(2900), [weth, dai]),
        ]),
      );
      expectStepList(decoded, [
        ...wethForUsdc,
        recipientYou,
        pay("2 WETH"),
        receiveMin("2900 DAI"),
        token(dai),
        recipientYou,
      ]);
    });

    test("an exact-in leg next to an exact-out leg of the same pair", () async {
      final decoded = await decode(
        execute("0001", [
          swapToSender,
          v3Swap(msgSender, usd(1500), eth(0.6), [usdc, weth]),
        ]),
      );
      expectStepList(decoded, [
        ...wethForUsdc,
        recipientYou,
        payMax("0.6 WETH"),
        receive("1500 USDC"),
        recipientYou,
      ]);
    });

    test("two swaps held by the router that pay with different tokens", () async {
      final decoded = await decode(
        execute("000004", [
          v3Swap(addressThis, oneEth, BigInt.zero, [weth, usdc]),
          v3Swap(addressThis, eth(3000), BigInt.zero, [dai, usdc]),
          tokenRecipientAmount(usdc, msgSender, usd(3000)),
        ]),
      );
      expectStepList(
        decoded,
        [
          pay("1 WETH"),
          token(weth),
          receiveMin("0 USDC"),
          token(usdc),
          recipientRouter,
          pay("3000 DAI"),
          token(dai),
          receiveMin("0 USDC"),
          recipientRouter,
          receiveMin("3000 USDC"),
          recipientYou,
        ],
        warnings: [notYou],
      );
    });

    group("chained sections", () {
      late final firstSection = [pay("100 USDC"), token(usdc), receiveMin("0 DAI"), token(dai)];
      late final secondSection = [
        pay("${S.current.wc_unlimited} DAI"),
        receiveMin("0.03 WETH"),
        token(weth),
      ];

      test("the last section paid to someone else", () async {
        final decoded = await decode(
          execute("0008", [
            v3Swap(addressThis, usd(100), BigInt.zero, [usdc, dai]),
            v2Swap(attacker, contractBalance, eth(0.03), [dai, weth], payerIsUser: false),
          ]),
        );
        expectStepList(
          decoded,
          [...firstSection, recipientRouter, ...secondSection, recipient(attacker)],
          warnings: [notYou],
        );
      });

      test("a first section paid to an address that is not the next section's pair", () async {
        final decoded = await decode(
          execute("0008", [
            v3Swap(nextPool, usd(100), BigInt.zero, [usdc, dai]),
            v2Swap(msgSender, contractBalance, eth(0.03), [dai, weth], payerIsUser: false),
          ]),
        );
        expectStepList(
          decoded,
          [...firstSection, recipient(nextPool), ...secondSection, recipientYou],
          warnings: [notYou],
        );
      });

      test("the V2 pair is only taken as the next section on a listed router", () async {
        const daiWethPair = "0xa478c2975ab1ea89e8196811f51a7b7ade33eb11";
        final decoded = await decode(
          execute("0008", [
            v3Swap(daiWethPair, usd(100), BigInt.zero, [usdc, dai]),
            v2Swap(msgSender, contractBalance, eth(0.03), [dai, weth], payerIsUser: false),
          ]),
          router: attacker,
        );
        expectStepList(
          decoded,
          [...firstSection, recipient(daiWethPair), ...secondSection, recipientYou],
          router: attacker,
          warnings: [notYou, S.current.wc_warning_unknown_contract],
        );
      });

      test("a second section the wallet is asked to pay", () async {
        final decoded = await decode(
          execute("0008", [
            v3Swap(addressThis, usd(100), BigInt.zero, [usdc, dai]),
            v2Swap(msgSender, contractBalance, eth(0.03), [dai, weth]),
          ]),
        );
        expectStepList(
          decoded,
          [...firstSection, recipientRouter, ...secondSection, recipientYou],
          warnings: [notYou],
        );
      });

      test("a second section that spends a set amount, not all the first one left", () async {
        final decoded = await decode(
          execute("0008", [
            v3Swap(addressThis, usd(100), BigInt.zero, [usdc, dai]),
            v2Swap(msgSender, eth(95), eth(0.03), [dai, weth], payerIsUser: false),
          ]),
        );
        expectStepList(
          decoded,
          [
            ...firstSection,
            recipientRouter,
            pay("95 DAI"),
            receiveMin("0.03 WETH"),
            token(weth),
            recipientYou,
          ],
          warnings: [notYou],
        );
      });

      test("a second section that is exact out leaves the rest with the router", () async {
        final decoded = await decode(
          execute("0001", [
            v3Swap(addressThis, usd(100), BigInt.zero, [usdc, dai]),
            v3Swap(msgSender, eth(0.03), contractBalance, [weth, dai], payerIsUser: false),
          ]),
        );
        expectStepList(
          decoded,
          [
            ...firstSection,
            recipientRouter,
            payMax("${S.current.wc_unlimited} DAI"),
            receive("0.03 WETH"),
            token(weth),
            recipientYou,
          ],
          warnings: [notYou],
        );
      });

      test("an exact-out section in front of one that spends what it left", () async {
        final decoded = await decode(
          execute("0108", [
            v3Swap(addressThis, eth(100), usd(110), [dai, usdc]),
            v2Swap(msgSender, contractBalance, eth(0.03), [dai, weth], payerIsUser: false),
          ]),
        );
        expectStepList(
          decoded,
          [
            payMax("110 USDC"),
            token(usdc),
            receive("100 DAI"),
            token(dai),
            recipientRouter,
            ...secondSection,
            recipientYou,
          ],
          warnings: [notYou],
        );
      });

      test("an output paid to a pair cannot be unwrapped by the router on the way", () async {
        final ethDaiPair = EvmSelectors.uniswapV2Pair(1, nativeEth, dai)!;
        final decoded = await decode(
          execute("000c08", [
            v3Swap(ethDaiPair, usd(100), BigInt.zero, [usdc, weth]),
            addressAmount(addressThis, BigInt.zero),
            v2Swap(msgSender, contractBalance, eth(90), [nativeEth, dai], payerIsUser: false),
          ]),
        );
        expectStepList(
          decoded,
          [
            pay("100 USDC"),
            token(usdc),
            receiveMin("0 WETH"),
            token(weth),
            recipient(ethDaiPair),
            receiveMin("0 ETH"),
            recipientRouter,
            pay("${S.current.wc_unlimited} ETH"),
            receiveMin("90 DAI"),
            token(dai),
            recipientYou,
          ],
          warnings: [notYou],
        );
      });

      test("only a V2 section can be paid at its pair, a V3 section cannot", () async {
        const daiWethPair = "0xa478c2975ab1ea89e8196811f51a7b7ade33eb11";
        final decoded = await decode(
          execute("0000", [
            v3Swap(daiWethPair, usd(100), BigInt.zero, [usdc, dai]),
            v3Swap(msgSender, contractBalance, eth(0.03), [dai, weth], payerIsUser: false),
          ]),
        );
        expectStepList(
          decoded,
          [...firstSection, recipient(daiWethPair), ...secondSection, recipientYou],
          warnings: [notYou],
        );
      });

      test("a section that spends another token than the one before it left", () async {
        final decoded = await decode(
          execute("0008", [
            v3Swap(addressThis, usd(100), BigInt.zero, [usdc, dai]),
            v2Swap(msgSender, contractBalance, usd(90), [weth, usdc], payerIsUser: false),
          ]),
        );
        expect(decoded!.actionTitle, S.current.wc_contract_call);
        expect(decoded.warnings, [unread, notYou]);
      });

      test("a section that would also spend what an earlier route left for the sweep", () async {
        final decoded = await decode(
          execute("00000004", [
            v3Swap(addressThis, usd(3000), BigInt.zero, [usdc, weth]),
            v3Swap(addressThis, usd(100), BigInt.zero, [usdc, weth]),
            v3Swap(addressThis, contractBalance, BigInt.zero, [
              weth,
              dai,
              weth,
            ], payerIsUser: false),
            tokenRecipientAmount(weth, msgSender, eth(0.9)),
          ]),
        );
        expectStepList(
          decoded,
          [
            pay("3000 USDC"),
            token(usdc),
            receiveMin("0 WETH"),
            token(weth),
            recipientRouter,
            pay("100 USDC"),
            receiveMin("0 WETH"),
            recipientRouter,
            pay("${S.current.wc_unlimited} WETH"),
            receiveMin("0 WETH"),
            recipientRouter,
            receiveMin("0.9 WETH"),
            recipientYou,
          ],
          warnings: [notYou],
        );
      });

      test("an UNWRAP_WETH into the router that no section follows", () async {
        final decoded = await decode(
          execute("000c04", [
            v3Swap(addressThis, usd(3000), BigInt.zero, [usdc, weth]),
            addressAmount(addressThis, BigInt.zero),
            tokenRecipientAmount(nativeEth, attacker, eth(0.99)),
          ]),
        );
        expectStepList(
          decoded,
          [
            pay("3000 USDC"),
            token(usdc),
            receiveMin("0 WETH"),
            token(weth),
            recipientRouter,
            receiveMin("0 ETH"),
            recipientRouter,
            receiveMin("0.99 ETH"),
            recipient(attacker),
          ],
          warnings: [notYou],
        );
      });
    });

    test("a step is listed with who it pays, however many come before it", () async {
      final decoded = await decode(
        execute("${"04" * 12}02", [
          for (var i = 0; i < 12; i++) tokenRecipientAmount(usdc, msgSender, BigInt.zero),
          tokenRecipientAmount(usdc, attacker, usd(1000000)),
        ]),
      );
      expectStepList(
        decoded,
        [
          receiveMin("0 USDC"),
          token(usdc),
          recipientYou,
          for (var i = 1; i < 12; i++) ...[receiveMin("0 USDC"), recipientYou],
          transfer("1000000 USDC"),
          sentTo(attacker),
        ],
        warnings: [notYou],
      );
    });

    test("a command that cannot be read keeps the rest of the list", () async {
      for (final unreadable in ["03", "0d", "0e", "12", "14"]) {
        final decoded = await decode(execute("00$unreadable", [swapToSender, wordInt(1)]));
        expectStepList(decoded, [...wethForUsdc, recipientYou]);
      }
    });

    test(
      "BALANCE_CHECK_ERC20 is for routers funded by someone else, not a wallet's swap",
      () async {
        final decoded = await decode(
          execute("000e", [swapToSender, tokenRecipientAmount(attacker, usdc, usd(1))]),
          router: routerV12,
        );
        expectStepList(decoded, [...wethForUsdc, recipientYou], router: routerV12);
      },
    );

    test("a command that is allowed to revert is listed, but it is no promise", () async {
      final decoded = await decode(execute("80", [swapToSender]));
      expectStepList(decoded, [...wethForUsdc, recipientYou]);

      final revertingSweep = await decode(
        execute("0084", [
          v3Swap(addressThis, oneEth, BigInt.zero, [weth, usdc]),
          tokenRecipientAmount(usdc, msgSender, usd(2990)),
        ]),
      );
      expectStepList(
        revertingSweep,
        [
          pay("1 WETH"),
          token(weth),
          receiveMin("0 USDC"),
          token(usdc),
          recipientRouter,
          receiveMin("2990 USDC"),
          recipientYou,
        ],
        warnings: [notYou],
      );
    });

    test("a swap to 0x01 pays the sender and a swap to 0x02 stays with the router", () async {
      Future<WCDecodedRequest?> swapTo(String swapRecipient) => decode(
        execute("00", [
          v3Swap(swapRecipient, oneEth, usd(3000), [weth, usdc]),
        ]),
      );

      expectSwap(await swapTo(msgSender), [...wethForUsdc, recipientYou]);
      expectStepList(
        await swapTo(addressThis),
        [...wethForUsdc, recipientRouter],
        warnings: [notYou],
      );
    });

    group("transaction value", () {
      final paidByRouter = v3Swap(msgSender, oneEth, usd(3000), [weth, usdc], payerIsUser: false);
      late final wrapRows = [transfer("1 ETH"), sentToRouter];

      test("a WRAP_ETH of less or more than the value", () async {
        for (final value in [oneEth - BigInt.one, oneEth + BigInt.one]) {
          final decoded = await decode(
            execute("0b00", [addressAmount(addressThis, oneEth), paidByRouter]),
            value: value,
          );
          expectStepList(decoded, [...wrapRows, ...wethForUsdc, recipientYou], warnings: [notYou]);
        }
      });

      test("an exact-in swap that spends less or more than the wrapped value", () async {
        for (final amountIn in [oneEth - BigInt.one, oneEth + BigInt.one]) {
          final decoded = await decode(
            execute("0b00", [
              addressAmount(addressThis, oneEth),
              v3Swap(msgSender, amountIn, usd(3000), [weth, usdc], payerIsUser: false),
            ]),
            value: oneEth,
          );
          expect(decoded!.actionTitle, S.current.wc_contract_call, reason: "$amountIn");
          expect(decoded.warnings, [unread, notYou], reason: "$amountIn");
          expect(decoded.isValueShown, isFalse, reason: "$amountIn");
        }
      });

      test("an exact-out swap whose maximum is above the wrapped value", () async {
        final decoded = await decode(
          execute("0b010c", [
            addressAmount(addressThis, oneEth),
            v3Swap(msgSender, usd(3000), oneEth + BigInt.one, [usdc, weth], payerIsUser: false),
            addressAmount(msgSender, BigInt.zero),
          ]),
          value: oneEth,
        );
        expect(decoded!.actionTitle, S.current.wc_contract_call);
        expect(decoded.warnings, [unread, notYou]);
      });

      test("value above what the plan wraps, the rest swept to someone else", () async {
        final decoded = await decode(
          execute("0b0004", [
            addressAmount(addressThis, oneEth),
            paidByRouter,
            tokenRecipientAmount(nativeEth, attacker, BigInt.zero),
          ]),
          value: eth(10),
        );
        expectStepList(
          decoded,
          [...wrapRows, ...wethForUsdc, recipientYou, receiveMin("0 ETH"), recipient(attacker)],
          warnings: [notYou],
        );
      });

      test(
        "WRAP_ETH of the value to a third party is a transfer, not the swap's funding",
        () async {
          final decoded = await decode(
            execute("0b00", [addressAmount(attacker, oneEth), paidByRouter]),
            value: oneEth,
          );
          expectStepList(
            decoded,
            [transfer("1 ETH"), sentTo(attacker), ...wethForUsdc, recipientYou],
            warnings: [notYou],
          );
        },
      );

      test("a pull of as many token units as the value is not a wrap of it", () async {
        final decoded = await decode(
          execute("0200", [tokenRecipientAmount(usdc, addressThis, oneEth), paidByRouter]),
          value: oneEth,
        );
        expectStepList(
          decoded,
          [
            transfer("1000000000000 USDC"),
            token(usdc),
            sentToRouter,
            pay("1 WETH"),
            token(weth),
            receiveMin("3000 USDC"),
            recipientYou,
          ],
          warnings: [notYou],
        );
      });

      test("the refund of an exact-out swap sent to someone else", () async {
        final decoded = await decode(
          execute("0b010c", [
            addressAmount(addressThis, eth(1.1)),
            v3Swap(msgSender, usd(3000), eth(1.1), [usdc, weth], payerIsUser: false),
            addressAmount(attacker, BigInt.zero),
          ]),
          value: eth(1.1),
        );
        expectStepList(
          decoded,
          [
            transfer("1.1 ETH"),
            sentToRouter,
            payMax("1.1 WETH"),
            token(weth),
            receive("3000 USDC"),
            token(usdc),
            recipientYou,
            receiveMin("0 ETH"),
            recipient(attacker),
          ],
          warnings: [notYou],
        );
      });

      test("a WETH leg is paid by the value only when that much was wrapped", () async {
        final decoded = await decode(
          execute("0b0000", [
            addressAmount(addressThis, BigInt.one),
            v3Swap(addressThis, usd(3000), BigInt.zero, [usdc, weth]),
            v3Swap(msgSender, oneEth, eth(2900), [weth, dai], payerIsUser: false),
          ]),
          value: oneEth,
        );
        expectStepList(
          decoded,
          [
            transfer("0.000000000000000001 ETH"),
            sentToRouter,
            pay("3000 USDC"),
            token(usdc),
            receiveMin("0 WETH"),
            token(weth),
            recipientRouter,
            pay("1 WETH"),
            receiveMin("2900 DAI"),
            token(dai),
            recipientYou,
          ],
          warnings: [notYou],
        );
      });

      test(
        "value wrapped and sent back to the wallet next to a swap that never spends it",
        () async {
          final decoded = await decode(
            execute("0b00", [addressAmount(msgSender, oneEth), swapToSender]),
            value: oneEth,
          );
          expectStepList(decoded, [transfer("1 ETH"), sentToYou, ...wethForUsdc, recipientYou]);
        },
      );

      test("a WETH leg the wallet pays through Permit2 next to a wrap of the value", () async {
        final decoded = await decode(
          execute("0b00", [addressAmount(addressThis, oneEth), swapToSender]),
          value: oneEth,
        );
        expectStepList(decoded, [...wrapRows, ...wethForUsdc, recipientYou], warnings: [notYou]);
      });

      test("a router-paid WETH leg without a WRAP_ETH is not paid by the value", () async {
        final decoded = await decode(execute("00", [paidByRouter]), value: oneEth);
        expectStepList(decoded, [...wethForUsdc, recipientYou]);
      });

      test("value sent with a swap that never spends it", () async {
        final decoded = await decode(execute("00", [swapToSender]), value: oneEth);
        expectStepList(decoded, [...wethForUsdc, recipientYou]);
      });

      test("a pull into the router next to value", () async {
        final decoded = await decode(
          execute("0b0200", [
            addressAmount(addressThis, contractBalance),
            tokenRecipientAmount(weth, addressThis, oneEth),
            paidByRouter,
          ]),
          value: oneEth,
        );
        expectStepList(
          decoded,
          [
            transfer("${S.current.wc_unlimited} ETH"),
            sentToRouter,
            transfer("1 WETH"),
            token(weth),
            sentToRouter,
            pay("1 WETH"),
            receiveMin("3000 USDC"),
            token(usdc),
            recipientYou,
          ],
          warnings: [notYou],
        );
      });

      test("V4 native input below the value", () async {
        final decoded = await decode(
          execute("10", [
            v4Plan("060c0f", [
              v4Single(nativeEth, usdc, zeroForOne: true, amount: oneEth, limit: usd(3000)),
              addressAmount(nativeEth, oneEth),
              addressAmount(usdc, usd(3000)),
            ]),
          ]),
          value: eth(10),
        );
        expectStepList(decoded, [pay("1 ETH"), receiveMin("3000 USDC"), token(usdc), recipientYou]);
      });
    });

    group("an exact-out swap the router pays for has to send the rest back", () {
      final exactOut = v3Swap(msgSender, usd(3000), eth(1.1), [usdc, weth], payerIsUser: false);
      final refundAsEth = addressAmount(msgSender, BigInt.zero);
      late final legRows = [
        payMax("1.1 WETH"),
        token(weth),
        receive("3000 USDC"),
        token(usdc),
        recipientYou,
      ];

      test("wrapped value with no refund, or with only another token swept back", () async {
        final wrap = addressAmount(addressThis, eth(1.1));
        final withoutRefund = await decode(execute("0b01", [wrap, exactOut]), value: eth(1.1));
        expectStepList(
          withoutRefund,
          [transfer("1.1 ETH"), sentToRouter, ...legRows],
          warnings: [notYou],
        );

        final otherTokenBack = await decode(
          execute("0b0104", [wrap, exactOut, tokenRecipientAmount(dai, msgSender, BigInt.zero)]),
          value: eth(1.1),
        );
        expectStepList(
          otherTokenBack,
          [
            transfer("1.1 ETH"),
            sentToRouter,
            ...legRows,
            receiveMin("0 DAI"),
            token(dai),
            recipientYou,
          ],
          warnings: [notYou],
        );
      });

      test(
        "value far above what the swap can spend is the most it pays only with the refund",
        () async {
          final wrapAll = addressAmount(addressThis, eth(100));
          final stranded = await decode(execute("0b01", [wrapAll, exactOut]), value: eth(100));
          expect(stranded!.actionTitle, S.current.wc_contract_call);
          expect(stranded.isValueShown, isFalse);

          final refunded = await decode(
            execute("0b010c", [wrapAll, exactOut, refundAsEth]),
            value: eth(100),
          );
          expectSwap(refunded, [
            payMax("100 ETH"),
            receive("3000 USDC"),
            token(usdc),
            recipientYou,
          ]);
        },
      );

      test("the rest may come back wrapped", () async {
        final decoded = await decode(
          execute("0b0104", [
            addressAmount(addressThis, eth(1.1)),
            exactOut,
            tokenRecipientAmount(weth, msgSender, BigInt.zero),
          ]),
          value: eth(1.1),
        );
        expectSwap(decoded, [payMax("1.1 ETH"), receive("3000 USDC"), token(usdc), recipientYou]);
      });

      test("a pull from the wallet above what the swap can spend", () async {
        final pull = tokenRecipientAmount(weth, addressThis, eth(100));
        final stranded = await decode(execute("0201", [pull, exactOut]));
        expectStepList(
          stranded,
          [
            transfer("100 WETH"),
            token(weth),
            sentToRouter,
            payMax("1.1 WETH"),
            receive("3000 USDC"),
            token(usdc),
            recipientYou,
          ],
          warnings: [notYou],
        );

        final swept = await decode(
          execute("020104", [pull, exactOut, tokenRecipientAmount(weth, msgSender, BigInt.zero)]),
        );
        expectSwap(swept, [
          payMax("100 WETH"),
          token(weth),
          receive("3000 USDC"),
          token(usdc),
          recipientYou,
        ]);
      });

      test("V4 native input with no SWEEP of the unspent ETH", () async {
        final decoded = await decode(
          execute("10", [
            v4Plan("090b0e", [
              v4MultiHopFourWordHead(usdc, usd(3000), eth(1.1), [nativeEth]),
              v4Settle(nativeEth, BigInt.zero, payerIsUser: true),
              tokenRecipientAmount(usdc, msgSender, usd(3000)),
            ]),
          ]),
          value: eth(100),
        );
        expectStepList(decoded, [
          payMax("1.1 ETH"),
          receive("3000 USDC"),
          token(usdc),
          recipientYou,
        ]);
      });

      test("unwrapped WETH is not sent back by an UNWRAP_WETH of what is left", () async {
        final decoded = await decode(
          execute("020c100c", [
            tokenRecipientAmount(weth, addressThis, eth(1.1)),
            addressAmount(addressThis, BigInt.zero),
            v4Plan("090b0e", [
              v4MultiHopFourWordHead(usdc, usd(3000), eth(1.1), [nativeEth]),
              v4Settle(nativeEth, BigInt.zero, payerIsUser: false),
              tokenRecipientAmount(usdc, msgSender, usd(3000)),
            ]),
            refundAsEth,
          ]),
        );
        expect(decoded!.actionTitle, S.current.wc_contract_call);
        expect(decoded.warnings, containsAll([unread, notYou]));
      });
    });

    group("token identity", () {
      test("a token that only calls itself WETH is not delivered by UNWRAP_WETH", () async {
        final decoded = await decode(
          execute("000c", [
            v3Swap(addressThis, usd(1000), eth(0.3), [usdc, fakeWeth]),
            addressAmount(msgSender, BigInt.zero),
          ]),
        );
        expectStepList(
          decoded,
          [
            pay("1000 USDC"),
            token(usdc),
            receiveMin("0.3 WETH"),
            token(fakeWeth),
            recipientRouter,
            receiveMin("0 ETH"),
            recipientYou,
          ],
          warnings: [unknownToken, notYou],
        );
      });

      test("mainnet WETH on another chain is not what the value is wrapped into", () async {
        const baseRouter = "0x6ff5693b99212da76ad316178a184ab56d299b43";
        final decoded = await decode(
          execute("0b00", [
            addressAmount(addressThis, oneEth),
            v3Swap(msgSender, oneEth, usd(3000), [weth, usdc], payerIsUser: false),
          ]),
          router: baseRouter,
          value: oneEth,
          chainId: 8453,
        );
        expectStepList(
          decoded,
          [transfer("1 ETH"), sentToRouter, ...wethForUsdc, recipientYou],
          router: baseRouter,
          warnings: [notYou],
        );
      });

      test("a WETH output swept as ETH needs an UNWRAP_WETH into the router in between", () async {
        final toRouter = v3Swap(addressThis, usd(3000), BigInt.zero, [usdc, weth]);
        final sweepEth = tokenRecipientAmount(nativeEth, msgSender, eth(0.99));

        final unwrapped = await decode(
          execute("000c04", [toRouter, addressAmount(addressThis, BigInt.zero), sweepEth]),
        );
        expectSwap(unwrapped, [
          pay("3000 USDC"),
          token(usdc),
          receiveMin("0.99 ETH"),
          recipientYou,
        ]);

        final neverUnwrapped = await decode(execute("0004", [toRouter, sweepEth]));
        expectStepList(
          neverUnwrapped,
          [
            pay("3000 USDC"),
            token(usdc),
            receiveMin("0 WETH"),
            token(weth),
            recipientRouter,
            receiveMin("0.99 ETH"),
            recipientYou,
          ],
          warnings: [notYou],
        );
      });

      test("an ETH output swept as WETH needs a WRAP_ETH into the router in between", () async {
        final toRouter = v4Plan("060c0e", [
          v4Single(nativeEth, usdc, zeroForOne: false, amount: usd(3000), limit: BigInt.zero),
          addressAmount(usdc, usd(3000)),
          tokenRecipientAmount(nativeEth, addressThis, BigInt.zero),
        ]);
        final sweepWeth = tokenRecipientAmount(weth, msgSender, eth(0.99));

        final neverWrapped = await decode(execute("1004", [toRouter, sweepWeth]));
        expectStepList(
          neverWrapped,
          [
            pay("3000 USDC"),
            token(usdc),
            receiveMin("0 ETH"),
            recipientRouter,
            receiveMin("0.99 WETH"),
            token(weth),
            recipientYou,
          ],
          warnings: [notYou],
        );

        for (final wrap in [
          addressAmount(addressThis, oneEth),
          addressAmount(attacker, contractBalance),
        ]) {
          final decoded = await decode(execute("100b04", [toRouter, wrap, sweepWeth]));
          expect(decoded!.actionTitle, S.current.wc_contract_call);
          expect(decoded.warnings, [unread, notYou]);
        }
      });

      test("a wrap or an unwrap in the router does not deliver another token", () async {
        final usdcToRouter = v3Swap(addressThis, oneEth, usd(3000), [weth, usdc]);
        final usdcHeld = [...wethForUsdc, recipientRouter];

        final wrapped = await decode(
          execute("000b04", [
            usdcToRouter,
            addressAmount(addressThis, contractBalance),
            tokenRecipientAmount(weth, msgSender, eth(0.99)),
          ]),
        );
        expectStepList(
          wrapped,
          [
            ...usdcHeld,
            transfer("${S.current.wc_unlimited} ETH"),
            sentToRouter,
            receiveMin("0.99 WETH"),
            recipientYou,
          ],
          warnings: [notYou],
        );

        final unwrapped = await decode(
          execute("000c04", [
            usdcToRouter,
            addressAmount(addressThis, BigInt.zero),
            tokenRecipientAmount(nativeEth, msgSender, eth(0.99)),
          ]),
        );
        expectStepList(
          unwrapped,
          [...usdcHeld, receiveMin("0 ETH"), recipientRouter, receiveMin("0.99 ETH"), recipientYou],
          warnings: [notYou],
        );
      });

      test("a SWEEP of WETH into the router is not the unwrap an ETH delivery needs", () async {
        final decoded = await decode(
          execute("000404", [
            v3Swap(addressThis, usd(3000), BigInt.zero, [usdc, weth]),
            tokenRecipientAmount(weth, addressThis, BigInt.zero),
            tokenRecipientAmount(nativeEth, msgSender, eth(0.99)),
          ]),
        );
        expectStepList(
          decoded,
          [
            pay("3000 USDC"),
            token(usdc),
            receiveMin("0 WETH"),
            token(weth),
            recipientRouter,
            receiveMin("0 WETH"),
            recipientRouter,
            receiveMin("0.99 ETH"),
            recipientYou,
          ],
          warnings: [notYou],
        );
      });

      test("a V3 path with bytes after its last hop is not read for a token", () async {
        final paddedPath = v3Path([usdc, fakeWeth]) + weth.substring(2);
        final decoded = await decode(
          execute("00", [
            swapHead(msgSender, usd(1000), oneEth, payerIsUser: true) + bytesBlob(paddedPath),
          ]),
        );
        expectStepList(decoded, []);
      });
    });

    group("address words with junk in the high bytes", () {
      String dirty(String address) => "ffffffffffffffffffffffff${address.substring(2)}";

      test("a swap recipient is the low 160 bits, as the router pays it", () async {
        final decoded = await decode(execute("00", [dirty(attacker) + swapToSender.substring(64)]));
        expectStepList(decoded, [...wethForUsdc, recipient(attacker)], warnings: [notYou]);
      });

      test("a SWEEP recipient is the low 160 bits", () async {
        final decoded = await decode(
          execute("0004", [swapToRouter, wordAddr(usdc) + dirty(attacker) + wordInt(0)]),
        );
        expectStepList(
          decoded,
          [...wethForUsdc, recipientRouter, receiveMin("0 USDC"), recipient(attacker)],
          warnings: [notYou],
        );
      });

      test("a V2 path token is the low 160 bits", () async {
        final decoded = await decode(
          execute("08", [
            swapHead(msgSender, oneEth, usd(3000), payerIsUser: true) +
                wordInt(2) +
                wordAddr(weth) +
                dirty(usdc),
          ]),
        );
        expectSwap(decoded, [...wethForUsdc, recipientYou]);
      });
    });

    group("without a swap", () {
      test("a pull from the wallet to a third party", () async {
        final decoded = await decode(
          execute("02", [tokenRecipientAmount(usdc, attacker, usd(1000000))]),
        );
        expect(decoded!.actionSubtitle, S.current.wc_via("Uniswap Universal Router"));
        expectStepList(
          decoded,
          [transfer("1000000 USDC"), token(usdc), sentTo(attacker)],
          warnings: [notYou],
        );
      });

      test("a permit on its own", () async {
        final decoded = await decode(execute("0a", [permitSingle(usdc, uint160Max, attacker)]));
        expectStepList(
          decoded,
          [approve("${S.current.wc_unlimited} USDC"), token(usdc), spender(attacker)],
          warnings: [unlimitedApproval],
        );
      });

      test("a sweep on its own names who it pays", () async {
        final toAttacker = await decode(
          execute("04", [tokenRecipientAmount(usdc, attacker, usd(5))]),
        );
        expectStepList(
          toAttacker,
          [receiveMin("5 USDC"), token(usdc), recipient(attacker)],
          warnings: [notYou],
        );

        final toSender = await decode(
          execute("04", [tokenRecipientAmount(usdc, msgSender, usd(5))]),
        );
        expectStepList(toSender, [receiveMin("5 USDC"), token(usdc), recipientYou]);
      });

      test("commands that cannot be read are still named for their router", () async {
        final decoded = await decode(execute("0e", [tokenRecipientAmount(attacker, usdc, usd(1))]));
        expect(decoded!.actionSubtitle, S.current.wc_via("Uniswap Universal Router"));
        expectStepList(decoded, []);
      });
    });
  });

  group("router versions", () {
    final toSender = v3Swap(msgSender, oneEth, usd(3000), [weth, usdc]);

    test("the deployments map to the command table Uniswap published for them", () {
      UniversalRouterVersion versionFor(int chainId, String address) =>
          EvmSelectors.universalRouterVersion(chainId, address);

      expect(
        versionFor(1, "0xEf1c6E67703c7BD7107eed8303Fbe6EC2554BF6B"),
        UniversalRouterVersion.v1,
      );
      expect(versionFor(1, routerV12), UniversalRouterVersion.v12);
      expect(versionFor(1, routerV20), UniversalRouterVersion.v20);
      expect(versionFor(1, routerV211), UniversalRouterVersion.v211);
      expect(
        versionFor(1, "0xab863E752Bf67D8DCDD929EaAe9Be9dc83Fb3BbB"),
        UniversalRouterVersion.v211,
      );
      expect(
        versionFor(8453, "0xbe2257d1aafbe6b73f67a9ac971c2f0b344bb3c5"),
        UniversalRouterVersion.v211,
      );
      expect(
        versionFor(8453, "0xf3a4f4094bd2c6c06ca2f61789d8727b8d1e7259"),
        UniversalRouterVersion.v210,
      );
      expect(versionFor(8453, routerV20), UniversalRouterVersion.unlisted);
      expect(UniversalRouterVersion.v1.commandMask, 0x1f);
      expect(UniversalRouterVersion.v20.commandMask, 0x3f);
      expect(UniversalRouterVersion.v211.commandMask, 0x7f);
      expect(UniversalRouterVersion.v20.v4MultiHopHeadWords, 4);
      expect(UniversalRouterVersion.v211.v4MultiHopHeadWords, 5);
    });

    test("byte 0x20 runs a V3 swap on V1 and is undefined on 2.0", () async {
      final onV1 = await decode(execute("20", [toSender]), router: routerV1);
      expectSwap(onV1, [...wethForUsdc, recipientYou], router: routerV1);

      expectStepList(await decode(execute("20", [toSender])), []);
    });

    test("byte 0x40 folds onto a V3 swap under the 2.0 mask, on 2.1.1 it is the bridge", () async {
      expectSwap(await decode(execute("40", [toSender])), [...wethForUsdc, recipientYou]);

      final onV211 = await decode(execute("40", [toSender]), router: routerV211);
      expectStepList(onV211, [], router: routerV211);
    });

    test("byte 0x10 is Seaport before 2.0, never a V4 swap", () async {
      final seaportShapedLikeV4 = execute("10", [
        v4Plan("060c0f", [
          v4Single(nativeEth, usdc, zeroForOne: true, amount: oneEth, limit: usd(3000)),
          addressAmount(nativeEth, oneEth),
          addressAmount(usdc, usd(3000)),
        ]),
      ]);
      final onV12 = await decode(seaportShapedLikeV4, router: routerV12, value: oneEth);
      expectStepList(onV12, [], router: routerV12);

      final onUnlisted = await decode(seaportShapedLikeV4, router: attacker, value: oneEth);
      expectStepList(
        onUnlisted,
        [],
        router: attacker,
        warnings: [S.current.wc_warning_unknown_contract],
      );

      final onV20 = await decode(seaportShapedLikeV4, value: oneEth);
      expect(onV20!.actionTitle, S.current.wc_action_swap);
      expect(rowLines(onV20.rows).first, pay("1 ETH"));
    });

    test("PAY_PORTION_FULL_PRECISION exists from 2.1.1 only", () async {
      final plan = execute("000704", [
        v3Swap(addressThis, oneEth, BigInt.zero, [weth, usdc]),
        tokenRecipientAmount(usdc, feeTaker, BigInt.from(25) * BigInt.from(10).pow(14)),
        tokenRecipientAmount(usdc, msgSender, usd(2990)),
      ]);

      expectSwap(await decode(plan, router: routerV211), [
        pay("1 WETH"),
        token(weth),
        receiveMin("2990 USDC"),
        token(usdc),
        recipientYou,
        fee("0.25% USDC"),
        sentTo(feeTaker),
      ], router: routerV211);

      expectStepList(
        await decode(plan),
        [
          pay("1 WETH"),
          token(weth),
          receiveMin("0 USDC"),
          token(usdc),
          recipientRouter,
          receiveMin("2990 USDC"),
          recipientYou,
        ],
        warnings: [notYou],
      );
    });

    test("a full-precision portion is held to the same 1%", () async {
      Future<WCDecodedRequest?> withPortion(BigInt fraction) => decode(
        execute("000704", [
          v3Swap(addressThis, oneEth, BigInt.zero, [weth, usdc]),
          tokenRecipientAmount(usdc, feeTaker, fraction),
          tokenRecipientAmount(usdc, msgSender, usd(2990)),
        ]),
        router: routerV211,
      );
      final onePercent = BigInt.from(10).pow(16);

      expect((await withPortion(onePercent))!.actionTitle, S.current.wc_action_swap);
      final above = await withPortion(onePercent + BigInt.one);
      expect(above!.actionTitle, S.current.wc_contract_call);
      expect(rowLines(above.rows), contains(transfer("1.0000000000000001% USDC")));
    });

    test("an unlisted contract never gets the swap card, its steps are still read", () async {
      final decoded = await decode(execute("00", [toSender]), router: attacker);
      expect(decoded!.actionSubtitle, S.current.wc_via("0x9999…9999"));
      expectStepList(
        decoded,
        [...wethForUsdc, recipientYou],
        router: attacker,
        warnings: [S.current.wc_warning_unknown_contract],
      );

      expectStepList(
        await decode(execute("20", [toSender]), router: attacker),
        [],
        router: attacker,
        warnings: [S.current.wc_warning_unknown_contract],
      );
    });
  });

  group("V4", () {
    final threeHundredthsEth = eth(0.03);

    Future<WCDecodedRequest?> decodeV4(
      String actionsHex,
      List<String> params, {
      String router = routerV20,
      BigInt? value,
    }) => decode(execute("10", [v4Plan(actionsHex, params)]), router: router, value: value);

    test("zeroForOne false flips which pool currency is paid", () async {
      final decoded = await decodeV4("060c0f", [
        v4Single(weth, usdc, zeroForOne: false, amount: usd(3000), limit: oneEth),
        addressAmount(usdc, usd(3000)),
        addressAmount(weth, BigInt.zero),
      ]);
      expectSwap(decoded, [
        pay("3000 USDC"),
        token(usdc),
        receiveMin("1 WETH"),
        token(weth),
        recipientYou,
      ]);
    });

    test("the one TAKE supplies the receive floor when the swap leaves it zero", () async {
      final swapWithoutFloor = v4Single(
        weth,
        usdc,
        zeroForOne: true,
        amount: oneEth,
        limit: BigInt.zero,
      );

      final takeAll = await decodeV4("060c0f", [
        swapWithoutFloor,
        addressAmount(weth, oneEth),
        addressAmount(usdc, usd(2900)),
      ]);
      expectSwap(takeAll, [
        pay("1 WETH"),
        token(weth),
        receiveMin("2900 USDC"),
        token(usdc),
        recipientYou,
      ]);

      final takeOfAnAmount = await decodeV4("060c0e", [
        swapWithoutFloor,
        addressAmount(weth, oneEth),
        tokenRecipientAmount(usdc, msgSender, usd(2800)),
      ]);
      expect(rowLines(takeOfAnAmount!.rows)[2], receiveMin("2800 USDC"));
      expect(takeOfAnAmount.warnings, [estimated]);

      final neitherHasAFloor = await decodeV4("060c0f", [
        swapWithoutFloor,
        addressAmount(weth, oneEth),
        addressAmount(usdc, BigInt.zero),
      ]);
      expect(rowLines(neitherHasAFloor!.rows)[2], receiveMin("0 USDC"));
      expect(neitherHasAFloor.warnings, [estimated, zeroSlippage]);
    });

    test("an exact-out swap shows its own limit as the most it pays", () async {
      final decoded = await decodeV4("080c0f", [
        v4Single(weth, usdc, zeroForOne: true, amount: usd(3000), limit: eth(1.2)),
        addressAmount(weth, eth(2)),
        addressAmount(usdc, usd(3000)),
      ]);
      expectSwap(decoded, [
        payMax("1.2 WETH"),
        token(weth),
        receive("3000 USDC"),
        token(usdc),
        recipientYou,
      ]);
    });

    test("an exact-out swap is the card only when the TAKE holds it to its amount", () async {
      final exactOut = v4Single(weth, usdc, zeroForOne: true, amount: usd(3000), limit: eth(1.2));
      final settleAll = addressAmount(weth, eth(2));
      final justShort = usd(3000) - BigInt.one;
      final swapRows = [
        payMax("1.2 WETH"),
        token(weth),
        receive("3000 USDC"),
        token(usdc),
        recipientYou,
      ];

      final takeOfTheAmount = await decodeV4("080c0e", [
        exactOut,
        settleAll,
        tokenRecipientAmount(usdc, msgSender, usd(3000)),
      ]);
      expectSwap(takeOfTheAmount, swapRows);

      final takeAllBelow = await decodeV4("080c0f", [
        exactOut,
        settleAll,
        addressAmount(usdc, justShort),
      ]);
      expectStepList(takeAllBelow, [receiveMin("2999.999999 USDC"), token(usdc), recipientYou]);

      final takeOfLess = await decodeV4("080c0e", [
        exactOut,
        settleAll,
        tokenRecipientAmount(usdc, msgSender, justShort),
      ]);
      expectStepList(takeOfLess, [receiveMin("2999.999999 USDC"), token(usdc), recipientYou]);

      final takeOfTheOpenCredit = await decodeV4("080c0e", [
        exactOut,
        settleAll,
        tokenRecipientAmount(usdc, msgSender, BigInt.zero),
      ]);
      expectStepList(takeOfTheOpenCredit, [receiveMin("0 USDC"), token(usdc), recipientYou]);
    });

    test("the 2.1.1 single-hop struct with its extra word reads the same amounts", () async {
      final decoded = await decodeV4(
        "060c0f",
        [
          v4Single(
            nativeEth,
            usdc,
            zeroForOne: true,
            amount: oneEth,
            limit: usd(3000),
            hasHopPriceWord: true,
          ),
          addressAmount(nativeEth, oneEth),
          addressAmount(usdc, usd(3000)),
        ],
        router: routerV211,
        value: oneEth,
      );
      expectSwap(decoded, [
        pay("1 ETH"),
        receiveMin("3000 USDC"),
        token(usdc),
        recipientYou,
      ], router: routerV211);
    });

    test("TAKE to the router followed by a SWEEP to someone else", () async {
      final decoded = await decode(
        execute("1004", [
          v4Plan("060c0e", [
            v4Single(nativeEth, usdc, zeroForOne: true, amount: oneEth, limit: BigInt.zero),
            addressAmount(nativeEth, oneEth),
            tokenRecipientAmount(usdc, addressThis, BigInt.zero),
          ]),
          tokenRecipientAmount(usdc, attacker, usd(2900)),
        ]),
        value: oneEth,
      );
      expectStepList(
        decoded,
        [
          pay("1 ETH"),
          receiveMin("0 USDC"),
          token(usdc),
          recipientRouter,
          receiveMin("2900 USDC"),
          recipient(attacker),
        ],
        warnings: [notYou],
      );
    });

    test("TAKE to someone else", () async {
      final decoded = await decodeV4("060c0e", [
        v4Single(weth, usdc, zeroForOne: true, amount: oneEth, limit: usd(3000)),
        addressAmount(weth, oneEth),
        tokenRecipientAmount(usdc, attacker, BigInt.zero),
      ]);
      expectStepList(decoded, [...wethForUsdc, recipient(attacker)], warnings: [notYou]);
    });

    test("a token the router is told to settle needs a pull that funds it", () async {
      final routerSettles = v4Plan("060b0e", [
        v4Single(weth, usdc, zeroForOne: false, amount: usd(3000), limit: oneEth),
        v4Settle(usdc, BigInt.zero, payerIsUser: false),
        tokenRecipientAmount(weth, msgSender, BigInt.zero),
      ]);
      final swapRows = [
        pay("3000 USDC"),
        token(usdc),
        receiveMin("1 WETH"),
        token(weth),
        recipientYou,
      ];

      final funded = await decode(
        execute("0210", [tokenRecipientAmount(usdc, addressThis, usd(3000)), routerSettles]),
      );
      expectSwap(funded, swapRows);

      expectStepList(await decode(execute("10", [routerSettles])), swapRows);
    });

    test("a pull into the router next to a swap the value pays for", () async {
      final decoded = await decode(
        execute("0210", [
          tokenRecipientAmount(usdc, addressThis, usd(1000000)),
          v4Plan("060c0f", [
            v4Single(nativeEth, usdc, zeroForOne: true, amount: oneEth, limit: usd(3000)),
            addressAmount(nativeEth, oneEth),
            addressAmount(usdc, usd(3000)),
          ]),
        ]),
        value: oneEth,
      );
      expectStepList(
        decoded,
        [
          transfer("1000000 USDC"),
          token(usdc),
          sentToRouter,
          pay("1 ETH"),
          receiveMin("3000 USDC"),
          recipientYou,
        ],
        warnings: [notYou],
      );
    });

    test("unspent ETH wrapped to someone else after an exact-out swap", () async {
      final decoded = await decode(
        execute("100b", [
          v4Plan("090b0e", [
            v4MultiHopFourWordHead(usdc, usd(3000), eth(1.1), [nativeEth]),
            v4Settle(nativeEth, BigInt.zero, payerIsUser: true),
            tokenRecipientAmount(usdc, msgSender, usd(3000)),
          ]),
          addressAmount(attacker, contractBalance),
        ]),
        value: eth(1.1),
      );
      expectStepList(
        decoded,
        [
          payMax("1.1 ETH"),
          receive("3000 USDC"),
          token(usdc),
          recipientYou,
          transfer("${S.current.wc_unlimited} ETH"),
          sentTo(attacker),
        ],
        warnings: [notYou],
      );
    });

    test("a V4 swap next to a V3 swap of another pair that the router keeps", () async {
      final decoded = await decode(
        execute("0010", [
          v3Swap(addressThis, usd(3000), oneEth, [usdc, weth]),
          v4Plan("060c0f", [
            v4Single(dai, weth, zeroForOne: true, amount: eth(10), limit: BigInt.one),
            addressAmount(dai, eth(10)),
            addressAmount(weth, BigInt.one),
          ]),
        ]),
      );
      expectStepList(
        decoded,
        [
          pay("3000 USDC"),
          token(usdc),
          receiveMin("1 WETH"),
          token(weth),
          recipientRouter,
          pay("10 DAI"),
          token(dai),
          receiveMin("0.000000000000000001 WETH"),
          recipientYou,
        ],
        warnings: [notYou],
      );
    });

    group("plans that are not one swap, one SETTLE and one TAKE stay unread", () {
      test("every TAKE is still listed for who it pays", () async {
        final decoded = await decodeV4("060c0e0e", [
          v4Single(nativeEth, usdc, zeroForOne: true, amount: oneEth, limit: usd(3000)),
          addressAmount(nativeEth, oneEth),
          tokenRecipientAmount(usdc, msgSender, usd(1)),
          tokenRecipientAmount(usdc, attacker, BigInt.zero),
        ], value: oneEth);
        expectStepList(
          decoded,
          [
            receiveMin("1 USDC"),
            token(usdc),
            recipientYou,
            receiveMin("0 USDC"),
            recipient(attacker),
          ],
          warnings: [notYou],
        );
      });

      test("TAKE_PORTION states its share and names its recipient", () async {
        final decoded = await decodeV4("060c100f", [
          v4Single(weth, usdc, zeroForOne: true, amount: oneEth, limit: usd(3000)),
          addressAmount(weth, oneEth),
          tokenRecipientAmount(usdc, feeTaker, BigInt.from(25)),
          addressAmount(usdc, usd(2990)),
        ]);
        expectStepList(
          decoded,
          [
            transfer("0.25% USDC"),
            token(usdc),
            sentTo(feeTaker),
            receiveMin("2990 USDC"),
            recipientYou,
          ],
          warnings: [notYou],
        );
      });

      test("TAKE_PORTION as the only take", () async {
        final decoded = await decodeV4("060c10", [
          v4Single(weth, usdc, zeroForOne: true, amount: oneEth, limit: usd(3000)),
          addressAmount(weth, oneEth),
          tokenRecipientAmount(usdc, attacker, BigInt.from(10000)),
        ]);
        expectStepList(
          decoded,
          [transfer("100% USDC"), token(usdc), sentTo(attacker)],
          warnings: [notYou],
        );
      });

      test("the two lengths are read from their low 32 bits, as the router reads them", () async {
        String withHighBits(String plan) {
          final actionsLength = word((BigInt.one << 32) + BigInt.from(3));
          final paramsLength = word((BigInt.one << 200) + BigInt.from(3));
          return plan.substring(0, 128) +
              actionsLength +
              plan.substring(192, 256) +
              paramsLength +
              plan.substring(320);
        }

        final swap = v4Single(weth, usdc, zeroForOne: true, amount: oneEth, limit: usd(3000));
        final toSender = withHighBits(
          v4Plan("060c0f", [swap, addressAmount(weth, oneEth), addressAmount(usdc, usd(3000))]),
        );
        expectSwap(await decode(execute("10", [toSender])), [...wethForUsdc, recipientYou]);

        final toSomeoneElse = withHighBits(
          v4Plan("060c0e", [
            swap,
            addressAmount(weth, oneEth),
            tokenRecipientAmount(usdc, attacker, BigInt.zero),
          ]),
        );
        expectStepList(
          await decode(execute("10", [toSomeoneElse])),
          [...wethForUsdc, recipient(attacker)],
          warnings: [notYou],
        );
      });

      test("a second swap in the same plan", () async {
        final decoded = await decodeV4("06060c0f", [
          v4Single(nativeEth, usdc, zeroForOne: true, amount: oneEth, limit: usd(3000)),
          v4Single(nativeEth, usdc, zeroForOne: true, amount: eth(5), limit: BigInt.zero),
          addressAmount(nativeEth, eth(6)),
          addressAmount(usdc, usd(2)),
        ], value: eth(6));
        expectStepList(decoded, [receiveMin("2 USDC"), token(usdc), recipientYou]);
      });

      test("a second SETTLE of the input currency", () async {
        final decoded = await decodeV4("0b0b060f", [
          v4Settle(usdc, usd(100), payerIsUser: true),
          v4Settle(usdc, usd(1000000), payerIsUser: true),
          v4Single(
            nativeEth,
            usdc,
            zeroForOne: false,
            amount: BigInt.zero,
            limit: threeHundredthsEth,
          ),
          addressAmount(nativeEth, threeHundredthsEth),
        ]);
        expectStepList(decoded, [receiveMin("0.03 ETH"), recipientYou]);
      });

      test("an amount in of 0 with nothing settled before it", () async {
        final swapOfOpenCredit = v4Single(
          nativeEth,
          usdc,
          zeroForOne: false,
          amount: BigInt.zero,
          limit: threeHundredthsEth,
        );
        final takeAll = addressAmount(nativeEth, threeHundredthsEth);
        final takeRows = [receiveMin("0.03 ETH"), recipientYou];

        expectStepList(await decodeV4("060f", [swapOfOpenCredit, takeAll]), takeRows);
        expectStepList(
          await decodeV4("060c0f", [swapOfOpenCredit, addressAmount(usdc, usd(100)), takeAll]),
          takeRows,
        );
        expectStepList(
          await decodeV4("060b0f", [
            swapOfOpenCredit,
            v4Settle(usdc, BigInt.zero, payerIsUser: true),
            takeAll,
          ]),
          takeRows,
        );
      });

      test("a SETTLE of an amount next to a swap that names its own", () async {
        final decoded = await decodeV4("0b060f", [
          v4Settle(usdc, usd(1000000), payerIsUser: true),
          v4Single(nativeEth, usdc, zeroForOne: false, amount: usd(100), limit: threeHundredthsEth),
          addressAmount(nativeEth, threeHundredthsEth),
        ]);
        expectStepList(decoded, [receiveMin("0.03 ETH"), recipientYou]);

        final restTakenBySomeoneElse = await decodeV4("0b060f0e", [
          v4Settle(usdc, usd(1000000), payerIsUser: true),
          v4Single(nativeEth, usdc, zeroForOne: false, amount: usd(100), limit: threeHundredthsEth),
          addressAmount(nativeEth, threeHundredthsEth),
          tokenRecipientAmount(usdc, attacker, BigInt.zero),
        ]);
        expectStepList(
          restTakenBySomeoneElse,
          [
            receiveMin("0.03 ETH"),
            recipientYou,
            receiveMin("0 USDC"),
            token(usdc),
            recipient(attacker),
          ],
          warnings: [notYou],
        );
      });

      test("a SETTLE or a TAKE of another currency than the swap's", () async {
        final swap = v4Single(weth, usdc, zeroForOne: true, amount: oneEth, limit: usd(3000));

        final settlesDai = await decodeV4("060c0f", [
          swap,
          addressAmount(dai, oneEth),
          addressAmount(usdc, usd(3000)),
        ]);
        expectStepList(settlesDai, [receiveMin("3000 USDC"), token(usdc), recipientYou]);

        final takesDai = await decodeV4("060c0f", [
          swap,
          addressAmount(weth, oneEth),
          addressAmount(dai, eth(3000)),
        ]);
        expectStepList(takesDai, [receiveMin("3000 DAI"), token(dai), recipientYou]);
      });

      test("takes and settles without a swap", () async {
        final takeAndSettle = v4Plan("0e0c", [
          tokenRecipientAmount(usdc, attacker, usd(1000000)),
          addressAmount(usdc, usd(1000000)),
        ]);
        final takeRows = [receiveMin("1000000 USDC"), recipient(attacker)];

        final alone = await decode(execute("10", [takeAndSettle]));
        expectStepList(alone, [takeRows.first, token(usdc), takeRows.last], warnings: [notYou]);

        final besideSwap = await decode(
          execute("0010", [
            v3Swap(msgSender, oneEth, usd(3000), [weth, usdc]),
            takeAndSettle,
          ]),
        );
        expectStepList(besideSwap, [...wethForUsdc, recipientYou, ...takeRows], warnings: [notYou]);
      });

      test("an action the V4 router does not run", () async {
        final decoded = await decodeV4("060c12", [
          v4Single(nativeEth, usdc, zeroForOne: true, amount: oneEth, limit: usd(3000)),
          addressAmount(nativeEth, oneEth),
          wordAddr(usdc),
        ]);
        expectStepList(decoded, []);
      });
    });

    group("multi-hop layout follows the router version", () {
      final fourWordHead = v4MultiHopFourWordHead(usdc, usd(10000), threeHundredthsEth, [
        dai,
        nativeEth,
      ]);
      final fiveWordHead = v4MultiHopFiveWordHead(usdc, usd(10000), threeHundredthsEth, [
        dai,
        nativeEth,
      ]);
      final settleAndTake = [addressAmount(usdc, usd(10000)), addressAmount(nativeEth, eth(0.02))];
      late final decodedRows = [
        pay("10000 USDC"),
        token(usdc),
        receiveMin("0.03 ETH"),
        recipientYou,
      ];
      late final onlyTheTake = [receiveMin("0.02 ETH"), recipientYou];

      test("the 4-word head decodes on 2.0", () async {
        expectSwap(await decodeV4("070c0f", [fourWordHead, ...settleAndTake]), decodedRows);
      });

      test("the 5-word head decodes on 2.1.1", () async {
        final decoded = await decodeV4("070c0f", [
          fiveWordHead,
          ...settleAndTake,
        ], router: routerV211);
        expectSwap(decoded, decodedRows, router: routerV211);
      });

      test("each head is refused on the other version", () async {
        expectStepList(
          await decodeV4("070c0f", [fourWordHead, ...settleAndTake], router: routerV211),
          onlyTheTake,
          router: routerV211,
        );
        expectStepList(await decodeV4("070c0f", [fiveWordHead, ...settleAndTake]), onlyTheTake);
      });

      test("a gapped path offset on 2.0 cannot move the amount words", () async {
        final gapped =
            wordInt(0x20) +
            wordAddr(usdc) +
            wordInt(0xa0) +
            word(usd(10000)) +
            word(usd(100)) +
            word(threeHundredthsEth) +
            v4Path([dai, nativeEth]);
        expectStepList(await decodeV4("070c0f", [gapped, ...settleAndTake]), onlyTheTake);
      });

      test(
        "a gapped path offset on 2.0 cannot put a decoy path in front of the real one",
        () async {
          final gapped =
              wordInt(0x20) +
              wordAddr(usdc) +
              wordInt(0xa0) +
              word(usd(10000)) +
              word(threeHundredthsEth) +
              wordInt(2) +
              wordInt(1) +
              wordInt(0x20) +
              v4PathKey(fakeWeth);
          expectStepList(await decodeV4("070c0f", [gapped, ...settleAndTake]), onlyTheTake);
        },
      );

      test("an exact-out swap pays the first hop's currency", () async {
        final decoded = await decodeV4("090c0f", [
          v4MultiHopFourWordHead(nativeEth, threeHundredthsEth, usd(10000), [usdc, dai]),
          addressAmount(usdc, usd(10000)),
          addressAmount(nativeEth, threeHundredthsEth),
        ]);
        expectSwap(decoded, [payMax("10000 USDC"), token(usdc), receive("0.03 ETH"), recipientYou]);
      });
    });

    test("a leading offset that points past a decoy struct is refused", () async {
      final decoy = v4Single(
        nativeEth,
        usdc,
        zeroForOne: false,
        amount: usd(1),
        limit: oneEth,
        leadingOffset: 0x160,
      );
      final signed = v4Single(
        nativeEth,
        usdc,
        zeroForOne: false,
        amount: usd(10000),
        limit: oneEth,
      ).substring(64);
      final decoded = await decodeV4("060c0f", [
        decoy + signed,
        addressAmount(usdc, usd(10000)),
        addressAmount(nativeEth, eth(0.9)),
      ]);
      expectStepList(decoded, [receiveMin("0.9 ETH"), recipientYou]);
    });

    group("offsets and lengths larger than the data", () {
      final huge = (BigInt.one << 256) - BigInt.one;
      final settleAndTake = [addressAmount(usdc, usd(10000)), addressAmount(nativeEth, eth(0.02))];
      late final onlyTheTake = [receiveMin("0.02 ETH"), recipientYou];

      test("a hop count larger than the data", () async {
        final struct =
            wordInt(0x20) +
            wordAddr(usdc) +
            wordInt(0x80) +
            word(usd(10000)) +
            word(threeHundredthsEth) +
            word(huge) +
            wordInt(0x20) +
            v4PathKey(nativeEth);
        expectStepList(await decodeV4("070c0f", [struct, ...settleAndTake]), onlyTheTake);
      });

      test("a hop offset larger than the data", () async {
        final struct =
            wordInt(0x20) +
            wordAddr(usdc) +
            wordInt(0x80) +
            word(usd(10000)) +
            word(threeHundredthsEth) +
            wordInt(1) +
            word(huge) +
            v4PathKey(nativeEth);
        expectStepList(await decodeV4("070c0f", [struct, ...settleAndTake]), onlyTheTake);
      });

      test("a hop offset that is not word aligned", () async {
        final struct =
            wordInt(0x20) +
            wordAddr(usdc) +
            wordInt(0x80) +
            word(usd(10000)) +
            word(threeHundredthsEth) +
            wordInt(1) +
            wordInt(0x21) +
            v4PathKey(nativeEth) +
            wordInt(0);
        expectStepList(await decodeV4("070c0f", [struct, ...settleAndTake]), onlyTheTake);
      });

      test("a params array shorter than the actions", () async {
        final decoded = await decodeV4("060c0f", [
          v4Single(nativeEth, usdc, zeroForOne: true, amount: oneEth, limit: usd(3000)),
        ]);
        expectStepList(decoded, []);
      });

      test("a V4 input that is one stray word", () async {
        expectStepList(await decode(execute("10", [wordInt(1)])), []);
      });
    });

    const swapExactOutGolden =
        "0000000000000000000000000000000000000000000000000000000000000020"
        "000000000000000000000000ca14007eff0db1f8135f4c25b34de49ab0d42766"
        "0000000000000000000000000000000000000000000000000000000000000080"
        "0000000000000000000000000000000000000000000001956bcfca2631de0000"
        "000000000000000000000000000000000000000000000000000000001ac2c1ec"
        "0000000000000000000000000000000000000000000000000000000000000002"
        "0000000000000000000000000000000000000000000000000000000000000040"
        "0000000000000000000000000000000000000000000000000000000000000100"
        "000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7"
        "0000000000000000000000000000000000000000000000000000000000000008"
        "0000000000000000000000000000000000000000000000000000000000000001"
        "0000000000000000000000000000000000000000000000000000000000000000"
        "00000000000000000000000000000000000000000000000000000000000000a0"
        "0000000000000000000000000000000000000000000000000000000000000000"
        "000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
        "00000000000000000000000000000000000000000000000000000000000009c4"
        "0000000000000000000000000000000000000000000000000000000000000019"
        "0000000000000000000000000000000000000000000000000000000000000000"
        "00000000000000000000000000000000000000000000000000000000000000a0"
        "0000000000000000000000000000000000000000000000000000000000000000";

    test("golden vector: mainnet exact-out pays path[0] and receives currencyOut", () async {
      const usdt = "0xdac17f958d2ee523a2206206994597c13d831ec7";
      const currencyOut = "0xca14007eff0db1f8135f4c25b34de49ab0d42766";
      final decoded = await decodeV4("090c0f", [
        swapExactOutGolden,
        addressAmount(usdt, BigInt.from(0x1ac2c1ec)),
        addressAmount(currencyOut, BigInt.parse("1956bcfca2631de0000", radix: 16)),
      ]);
      expectSwap(
        decoded,
        [
          payMax("448971244 0xdac1…1ec7"),
          token(usdt),
          receive("7478700000000000000000 0xca14…2766"),
          token(currencyOut),
          recipientYou,
        ],
        warnings: [unknownToken],
      );
    });
  });

  group("EXECUTE_SUB_PLAN is never part of the SDK's swap, its commands are listed", () {
    final swapToSender = v3Swap(msgSender, oneEth, usd(3000), [weth, usdc]);
    final pullToAttacker = tokenRecipientAmount(usdc, attacker, usd(1000000));
    late final pullRows = [transfer("1000000 USDC"), sentTo(attacker)];

    test("a sub-plan that holds the whole swap", () async {
      final decoded = await decode(
        execute("21", [
          subPlan("00", [swapToSender]),
        ]),
      );
      expectStepList(decoded, [...wethForUsdc, recipientYou]);
    });

    test("the commands of a sub-plan follow the plan's own", () async {
      final decoded = await decode(
        execute("0021", [
          swapToSender,
          subPlan("02", [pullToAttacker]),
        ]),
      );
      expectStepList(decoded, [...wethForUsdc, recipientYou, ...pullRows], warnings: [notYou]);
    });

    test("a sub-plan inside a sub-plan is listed too", () async {
      final decoded = await decode(
        execute("21", [
          subPlan("21", [
            subPlan("0002", [swapToSender, pullToAttacker]),
          ]),
        ]),
      );
      expectStepList(decoded, [...wethForUsdc, recipientYou, ...pullRows], warnings: [notYou]);
    });

    test("nesting deeper than the decoder follows stays unread", () async {
      var nested = subPlan("02", [pullToAttacker]);
      for (var depth = 0; depth < 5; depth++) {
        nested = subPlan("21", [nested]);
      }
      final decoded = await decode(execute("0021", [swapToSender, nested]));
      expectStepList(decoded, [...wethForUsdc, recipientYou]);
    });

    test("a sub-plan that cannot be read", () async {
      final decoded = await decode(execute("0021", [swapToSender, wordInt(1)]));
      expectStepList(decoded, [...wethForUsdc, recipientYou]);
    });

    test("0x21 is not a sub-plan on a router that is not listed", () async {
      final decoded = await decode(
        execute("0021", [
          swapToSender,
          subPlan("02", [pullToAttacker]),
        ]),
        router: attacker,
      );
      expectStepList(
        decoded,
        [...wethForUsdc, recipientYou],
        router: attacker,
        warnings: [S.current.wc_warning_unknown_contract],
      );
    });

    test(
      "a sub-plan allowed to revert is listed like any other, as steps and no promise",
      () async {
        final floorTheSwapCannotMeet = usd(1000000);
        final decoded = await decode(
          execute("00a1", [
            v3Swap(addressThis, oneEth, BigInt.zero, [weth, usdc]),
            subPlan("0402", [
              tokenRecipientAmount(usdc, msgSender, floorTheSwapCannotMeet),
              tokenRecipientAmount(dai, attacker, eth(5)),
            ]),
          ]),
        );
        expectStepList(
          decoded,
          [
            pay("1 WETH"),
            token(weth),
            receiveMin("0 USDC"),
            token(usdc),
            recipientRouter,
            receiveMin("1000000 USDC"),
            recipientYou,
            transfer("5 DAI"),
            token(dai),
            sentTo(attacker),
          ],
          warnings: [notYou],
        );
      },
    );

    test(
      "sub-plans whose inputs all alias one element are refused, not fanned out",
      () async {
        Future<WCDecodedRequest?> nesting(int levels) {
          var nested = aliasedSubPlan("02" * 32, pullToAttacker);
          for (var level = 1; level < levels; level++) {
            nested = aliasedSubPlan("21" * 32, nested);
          }
          return decode(execute("0021", [swapToSender, nested]));
        }

        for (final levels in [2, 5]) {
          expectStepList(await nesting(levels), [...wethForUsdc, recipientYou]);
        }
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });

  group("token lookups", () {
    String numbered(int n) => "0x${n.toRadixString(16).padLeft(40, "0")}";

    Future<WCDecodedRequest?> decodeCounting(CountingResolver resolver, String calldata) =>
        DexRouterDecoder(resolver).decode(
          calldata: EvmCalldata.parse(calldata)!,
          nativeSymbol: "ETH",
          routerAddress: routerV20,
          walletAddress: wallet,
          valueWei: BigInt.zero,
          chainId: 1,
        );

    test("a plan that names many tokens only looks up a bounded number of them", () async {
      final resolver = CountingResolver();
      final decoded = await decodeCounting(
        resolver,
        execute("08" * 10, [
          for (var i = 0; i < 10; i++)
            v2Swap(msgSender, oneEth, oneEth, [numbered(0x100 + i), numbered(0x200 + i)]),
        ]),
      );
      expect(resolver.looked, hasLength(12));
      expect(decoded!.rows.where((r) => r.label == S.current.wc_swap_from), hasLength(10));
      expect(decoded.rows.where((r) => r.label == S.current.wc_token), hasLength(20));
    });

    test("only the tokens the swap card shows are looked up", () async {
      final resolver = CountingResolver();
      final hops = [usdc, for (var i = 0; i < 14; i++) numbered(0x100 + i), dai];
      final decoded = await decodeCounting(
        resolver,
        execute("00${"08" * 14}", [
          v3Swap(addressThis, usd(100), BigInt.zero, [hops[0], hops[1]]),
          for (var i = 1; i < 15; i++)
            v2Swap(
              i == 14 ? msgSender : addressThis,
              contractBalance,
              i == 14 ? oneEth : BigInt.zero,
              [hops[i], hops[i + 1]],
              payerIsUser: false,
            ),
        ]),
      );
      expect(resolver.looked, [usdc, dai]);
      expect(decoded!.actionTitle, S.current.wc_action_swap);
      expect(decoded.rows.where((r) => r.label == S.current.wc_token).map((r) => r.value), [
        usdc,
        dai,
      ]);
    });
  });

  group("malformed execute calldata", () {
    test("an inputs offset larger than the data", () async {
      final calldata =
          "0x3593564c${wordInt(0x60)}${word(BigInt.one << 200)}${wordInt(1700000000)}"
          "${bytesBlob("00")}";
      expect(await decode(calldata), isNull);
    });

    test("fewer inputs than commands", () async {
      expect(
        await decode(
          execute("0004", [
            v3Swap(msgSender, oneEth, usd(3000), [weth, usdc]),
          ]),
        ),
        isNull,
      );
    });

    test("a swap input cut short of its payer word", () async {
      final decoded = await decode(
        execute("00", [wordAddr(msgSender) + word(oneEth) + word(usd(3000)) + wordInt(0xa0)]),
      );
      expectStepList(decoded, []);
    });

    test("a batch length larger than the data keeps the swap rows", () async {
      final decoded = await decode(
        execute("000d", [
          v3Swap(msgSender, oneEth, usd(3000), [weth, usdc]),
          wordInt(0x20) + word(BigInt.one << 64),
        ]),
      );
      expectStepList(decoded, [...wethForUsdc, recipientYou]);
    });
  });
}
