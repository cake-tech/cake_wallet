import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_decoder.dart";
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

  final resolver = Erc20TokenResolver(null);
  final decoder = Erc20Decoder(resolver);
  const contract = "0x1111111111111111111111111111111111111111";
  const wethContract = "0x5555555555555555555555555555555555555555";
  final wethDecoder = Erc20Decoder(
    StubErc20Resolver({
      wethContract: Erc20Token(
        name: "Wrapped Ether",
        symbol: "WETH",
        contractAddress: wethContract,
        decimal: 18,
      ),
      contract: Erc20Token(
        name: "USD Coin",
        symbol: "USDC",
        contractAddress: contract,
        decimal: 6,
      ),
    }),
  );
  const spender = "0x2222222222222222222222222222222222222222";
  const recipient = "0x3333333333333333333333333333333333333333";

  EvmCalldata calldata(String selector, String body) => EvmCalldata.parse("0x$selector$body")!;

  group("approve", () {
    test("decodes spender and amount", () async {
      final decoded = await decoder.decode(
        calldata: calldata("095ea7b3", wordAddr(spender) + wordInt(100)),
        contractAddress: contract,
        nativeSymbol: "ETH",
      );
      expect(decoded, isNotNull);
      expect(decoded!.actionTitle, S.current.wc_action_approve);
      expect(decoded.rows.any((r) => r.value == spender), isTrue);
      expect(decoded.rows.any((r) => r.value.startsWith("100")), isTrue);
      expect(decoded.warnings, isNot(contains(S.current.wc_warning_unlimited_approval)));
      expect(decoded.hideValue, isFalse);
      expect(decoded.hideTo, isTrue);
    });

    test("warns on max uint256 approval", () async {
      final max = (BigInt.one << 256) - BigInt.one;
      final decoded = await decoder.decode(
        calldata: calldata("095ea7b3", wordAddr(spender) + word(max)),
        contractAddress: contract,
        nativeSymbol: "ETH",
      );
      expect(decoded!.warnings, contains(S.current.wc_warning_unlimited_approval));
      expect(decoded.rows.any((r) => r.value.startsWith(S.current.wc_unlimited)), isTrue);
    });

    test("warns on max uint160 approval", () async {
      final max = (BigInt.one << 160) - BigInt.one;
      final decoded = await decoder.decode(
        calldata: calldata("095ea7b3", wordAddr(spender) + word(max)),
        contractAddress: contract,
        nativeSymbol: "ETH",
      );
      expect(decoded!.warnings, contains(S.current.wc_warning_unlimited_approval));
    });

    test("zero amount decodes as revoke", () async {
      final decoded = await decoder.decode(
        calldata: calldata("095ea7b3", wordAddr(spender) + wordInt(0)),
        contractAddress: contract,
        nativeSymbol: "ETH",
      );
      expect(decoded!.actionTitle, S.current.wc_action_revoke_approval);
    });
  });

  test("transfer decodes recipient and amount", () async {
    final decoded = await decoder.decode(
      calldata: calldata("a9059cbb", wordAddr(recipient) + wordInt(2500)),
      contractAddress: contract,
      nativeSymbol: "ETH",
    );
    expect(decoded!.actionTitle, S.current.wc_action_transfer);
    expect(decoded.rows.any((r) => r.value == recipient), isTrue);
    expect(decoded.rows.any((r) => r.value.startsWith("2500")), isTrue);
  });

  test("unlimited increaseAllowance warns like approve does", () async {
    final max = (BigInt.one << 256) - BigInt.one;
    final decoded = await decoder.decode(
      calldata: calldata("39509351", wordAddr(spender) + word(max)),
      contractAddress: contract,
      nativeSymbol: "ETH",
    );
    expect(decoded!.actionTitle, S.current.wc_action_increase_allowance);
    expect(decoded.warnings, contains(S.current.wc_warning_unlimited_approval));
    expect(decoded.warnings, contains(S.current.wc_warning_unknown_token));
  });

  test("transferFrom decodes both parties", () async {
    final decoded = await decoder.decode(
      calldata: calldata(
        "23b872dd",
        wordAddr(spender) + wordAddr(recipient) + wordInt(7),
      ),
      contractAddress: contract,
      nativeSymbol: "ETH",
    );
    expect(decoded!.rows.any((r) => r.value == spender), isTrue);
    expect(decoded.rows.any((r) => r.value == recipient), isTrue);
  });

  test("decreaseAllowance carries the delta and the spender", () async {
    final decoded = await decoder.decode(
      calldata: calldata("a457c2d7", wordAddr(spender) + wordInt(40)),
      contractAddress: contract,
      nativeSymbol: "ETH",
    );
    expect(decoded!.actionTitle, S.current.wc_action_decrease_allowance);
    expect(decoded.rows.any((r) => r.value.startsWith("40")), isTrue);
    expect(decoded.rows.any((r) => r.value == spender), isTrue);
  });

  group("wrapped native", () {
    test("deposit on the wrapped-native contract reads as wrap", () async {
      final decoded = await wethDecoder.decode(
        calldata: calldata("d0e30db0", ""),
        contractAddress: wethContract,
        nativeSymbol: "ETH",
      );
      expect(decoded, isNotNull);
      expect(decoded!.actionTitle, S.current.wc_action_wrap("ETH"));
      expect(decoded.hideValue, isFalse, reason: "the wrapped amount is the tx value");
    });

    test("withdraw reads as unwrap and shows the native amount", () async {
      final decoded = await wethDecoder.decode(
        calldata: calldata("2e1a7d4d", word(BigInt.from(10).pow(17))),
        contractAddress: wethContract,
        nativeSymbol: "ETH",
      );
      expect(decoded!.actionTitle, S.current.wc_action_unwrap("ETH"));
      expect(decoded.rows.single.value, "0.1 ETH");
    });

    test("deposit on an unrelated token is not claimed as a wrap", () async {
      final decoded = await wethDecoder.decode(
        calldata: calldata("d0e30db0", ""),
        contractAddress: contract,
        nativeSymbol: "ETH",
      );
      expect(decoded, isNull);
    });
  });

  test("truncated approve returns null and falls through", () async {
    final decoded = await decoder.decode(
      calldata: calldata("095ea7b3", wordAddr(spender)),
      contractAddress: contract,
      nativeSymbol: "ETH",
    );
    expect(decoded, isNull);
  });
}
