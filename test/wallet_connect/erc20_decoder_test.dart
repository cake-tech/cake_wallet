import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cw_core/crypto_currency.dart";
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
  const spoofedWeth = "0x5555555555555555555555555555555555555555";
  const mainnetWeth = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  const nftCollection = "0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d";
  const unlistedToken = "0x6666666666666666666666666666666666666666";
  final wethDecoder = Erc20Decoder(
    StubErc20Resolver(
      {
        spoofedWeth: Erc20Token(
          name: "Wrapped Ether",
          symbol: "WETH",
          contractAddress: spoofedWeth,
          decimal: 18,
        ),
        contract: Erc20Token(
          name: "USD Coin",
          symbol: "USDC",
          contractAddress: contract,
          decimal: 6,
        ),
        nftCollection: Erc20Token(
          name: "BoredApeYachtClub",
          symbol: "BAYC",
          contractAddress: nftCollection,
          decimal: 0,
        ),
        unlistedToken: Erc20Token(
          name: "USD Coin",
          symbol: "USDC",
          contractAddress: unlistedToken,
          decimal: 6,
        ),
      },
      known: {spoofedWeth, contract},
    ),
  );
  const spender = "0x2222222222222222222222222222222222222222";
  const recipient = "0x3333333333333333333333333333333333333333";
  const owner = "0x4444444444444444444444444444444444444444";
  late final unresolvedToken = row(S.current.wc_token, contract);

  EvmCalldata calldata(String selector, String body) => EvmCalldata.parse("0x$selector$body")!;

  group("approve", () {
    test("decodes spender and amount", () async {
      final decoded = await decoder.decode(
        calldata: calldata("095ea7b3", wordAddr(spender) + wordInt(100)),
        contractAddress: contract,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(decoded!.actionTitle, S.current.wc_action_approve);
      expect(rowLines(decoded.rows), [
        unresolvedToken,
        row("${S.current.wc_amount} / ${S.current.wc_token_id}", "100 0x1111…1111"),
        row(S.current.wc_approved_spender, spender),
      ]);
      expect(decoded.warnings, [S.current.wc_warning_unknown_token]);
      expect(decoded.isValueShown, isFalse);
    });

    test("warns on max uint256 approval", () async {
      final max = (BigInt.one << 256) - BigInt.one;
      final decoded = await decoder.decode(
        calldata: calldata("095ea7b3", wordAddr(spender) + word(max)),
        contractAddress: contract,
        nativeSymbol: "ETH",
        chainId: 1,
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
        chainId: 1,
      );
      expect(decoded!.warnings, contains(S.current.wc_warning_unlimited_approval));
    });

    test("zero amount on a token that resolves as ERC-20 decodes as revoke", () async {
      final decoded = await wethDecoder.decode(
        calldata: calldata("095ea7b3", wordAddr(spender) + wordInt(0)),
        contractAddress: contract,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(decoded!.actionTitle, S.current.wc_action_revoke_approval);
      expect(decoded.rows.map((r) => r.label), [S.current.wc_token, S.current.wc_approved_spender]);
      expect(decoded.warnings, isEmpty);
    });

    test("zero on a contract that is not a listed token may be ERC-721 token #0", () async {
      const unresolved = "0x7777777777777777777777777777777777777777";
      final amountOrTokenId = "${S.current.wc_amount} / ${S.current.wc_token_id}";

      final withMetadata = await wethDecoder.decode(
        calldata: calldata("095ea7b3", wordAddr(spender) + wordInt(0)),
        contractAddress: nftCollection,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(withMetadata!.actionTitle, S.current.wc_action_approve);
      expect(rowLines(withMetadata.rows), [
        "${S.current.wc_token}: BoredApeYachtClub (BAYC)",
        "${S.current.wc_token}: $nftCollection",
        "$amountOrTokenId: 0 BAYC",
        "${S.current.wc_approved_spender}: $spender",
      ]);
      expect(withMetadata.warnings, [S.current.wc_warning_unknown_token]);

      final withoutMetadata = await wethDecoder.decode(
        calldata: calldata("095ea7b3", wordAddr(spender) + wordInt(0)),
        contractAddress: unresolved,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(withoutMetadata!.actionTitle, S.current.wc_action_approve);
      expect(rowLines(withoutMetadata.rows), [
        "${S.current.wc_token}: $unresolved",
        "$amountOrTokenId: 0 0x7777…7777",
        "${S.current.wc_approved_spender}: $spender",
      ]);
      expect(withoutMetadata.warnings, [S.current.wc_warning_unknown_token]);
    });

    test("a resolved token keeps the plain amount label", () async {
      final decoded = await wethDecoder.decode(
        calldata: calldata("095ea7b3", wordAddr(spender) + wordInt(2500000)),
        contractAddress: contract,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(decoded!.rows[1].label, S.current.wc_amount);
      expect(decoded.rows[1].value, "2.5 USDC");
    });
  });

  test("a token that resolves but is not listed warns and shows its contract address", () async {
    final calls = {
      "095ea7b3": wordAddr(spender) + wordInt(2500000),
      "a9059cbb": wordAddr(recipient) + wordInt(2500000),
      "23b872dd": wordAddr(spender) + wordAddr(recipient) + wordInt(2500000),
      "39509351": wordAddr(spender) + wordInt(2500000),
    };

    for (final call in calls.entries) {
      final unlisted = await wethDecoder.decode(
        calldata: calldata(call.key, call.value),
        contractAddress: unlistedToken,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(unlisted!.rows.take(2).map((r) => r.value), [
        "USD Coin (USDC)",
        unlistedToken,
      ], reason: call.key);
      expect(unlisted.warnings, [S.current.wc_warning_unknown_token], reason: call.key);

      final listed = await wethDecoder.decode(
        calldata: calldata(call.key, call.value),
        contractAddress: contract,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(listed!.rows.any((r) => r.value == contract), isFalse, reason: call.key);
      expect(listed.warnings, isEmpty, reason: call.key);
    }
  });

  test("transfer decodes recipient and amount", () async {
    final decoded = await decoder.decode(
      calldata: calldata("a9059cbb", wordAddr(recipient) + wordInt(2500)),
      contractAddress: contract,
      nativeSymbol: "ETH",
      chainId: 1,
    );
    expect(decoded!.actionTitle, S.current.wc_action_transfer);
    expect(rowLines(decoded.rows), [
      unresolvedToken,
      row(S.current.wc_amount, "2500 0x1111…1111"),
      row(S.current.to, recipient),
    ]);
  });

  test("a transfer carries the fiat value of its amount, an unlimited one carries none", () async {
    final usdc = Erc20Token(
      name: "USD Coin",
      symbol: "USDC",
      contractAddress: contract,
      decimal: 6,
    );
    final pricing = Erc20Decoder(_PricedResolver({contract: usdc}));
    Future<WCDecodedRow> amountRow(BigInt rawAmount) async {
      final decoded = await pricing.decode(
        calldata: calldata("a9059cbb", wordAddr(recipient) + word(rawAmount)),
        contractAddress: contract,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      return decoded!.rows.singleWhere((shown) => shown.label == S.current.wc_amount);
    }

    final priced = await amountRow(BigInt.from(2500000));
    expect(priced.value, "2.5 USDC");
    expect(priced.fiatValue, "fiat of 2.5 USDC");

    final unlimited = await amountRow((BigInt.one << 256) - BigInt.one);
    expect(unlimited.value, "${S.current.wc_unlimited} USDC");
    expect(unlimited.fiatValue, isNull);
  });

  test("unlimited increaseAllowance warns like approve does", () async {
    final max = (BigInt.one << 256) - BigInt.one;
    final decoded = await decoder.decode(
      calldata: calldata("39509351", wordAddr(spender) + word(max)),
      contractAddress: contract,
      nativeSymbol: "ETH",
      chainId: 1,
    );
    expect(decoded!.actionTitle, S.current.wc_increase_allowance);
    expect(decoded.warnings, contains(S.current.wc_warning_unlimited_approval));
    expect(decoded.warnings, contains(S.current.wc_warning_unknown_token));
  });

  test("transferFrom names who the tokens leave and who gets them", () async {
    final decoded = await decoder.decode(
      calldata: calldata("23b872dd", wordAddr(owner) + wordAddr(recipient) + wordInt(7)),
      contractAddress: contract,
      nativeSymbol: "ETH",
      chainId: 1,
    );
    expect(decoded!.actionTitle, S.current.wc_action_transfer);
    expect(rowLines(decoded.rows), [
      unresolvedToken,
      row("${S.current.wc_amount} / ${S.current.wc_token_id}", "7 0x1111…1111"),
      row(S.current.from, owner),
      row(S.current.to, recipient),
    ]);
  });

  test("transferFrom on a contract that is not a listed token may move ERC-721 token #7", () async {
    Future<String> amountLabel(String contractAddress) async {
      final decoded = await wethDecoder.decode(
        calldata: calldata("23b872dd", wordAddr(owner) + wordAddr(recipient) + wordInt(7)),
        contractAddress: contractAddress,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      return decoded!.rows.singleWhere((shown) => shown.kind == WCDecodedRowKind.amount).label;
    }

    expect(await amountLabel(nftCollection), "${S.current.wc_amount} / ${S.current.wc_token_id}");
    expect(await amountLabel(contract), S.current.wc_amount);
  });

  test("decreaseAllowance carries the delta and the spender", () async {
    final decoded = await decoder.decode(
      calldata: calldata("a457c2d7", wordAddr(spender) + wordInt(40)),
      contractAddress: contract,
      nativeSymbol: "ETH",
      chainId: 1,
    );
    expect(decoded!.actionTitle, S.current.wc_action_decrease_allowance);
    expect(rowLines(decoded.rows), [
      unresolvedToken,
      row(S.current.wc_amount, "40 0x1111…1111"),
      row(S.current.wc_approved_spender, spender),
    ]);
  });

  test("a decrease by the largest amount is not an unlimited approval", () async {
    final max = (BigInt.one << 256) - BigInt.one;
    for (final signature in [
      "decreaseAllowance(address,uint256)",
      "decreaseApproval(address,uint256)",
    ]) {
      final decoded = await wethDecoder.decode(
        calldata: calldata(selectorOf(signature), wordAddr(spender) + word(max)),
        contractAddress: contract,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(decoded!.actionTitle, S.current.wc_action_decrease_allowance, reason: signature);
      expect(decoded.warnings, isEmpty, reason: signature);
    }
  });

  test("increaseApproval and decreaseApproval of older tokens read as allowance changes", () async {
    final titles = {
      "increaseApproval(address,uint256)": S.current.wc_increase_allowance,
      "decreaseApproval(address,uint256)": S.current.wc_action_decrease_allowance,
    };
    expect(titles.keys.map(selectorOf), ["d73dd623", "66188463"]);

    for (final call in titles.entries) {
      final decoded = await wethDecoder.decode(
        calldata: calldata(selectorOf(call.key), wordAddr(spender) + wordInt(2500000)),
        contractAddress: contract,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(decoded!.actionTitle, call.value, reason: call.key);
      expect(rowLines(decoded.rows), [
        row(S.current.wc_token, "USD Coin (USDC)"),
        row(S.current.wc_amount, "2.5 USDC"),
        row(S.current.wc_approved_spender, spender),
      ], reason: call.key);
    }

    final unlimited = await wethDecoder.decode(
      calldata: calldata(
        selectorOf("increaseApproval(address,uint256)"),
        wordAddr(spender) + word((BigInt.one << 256) - BigInt.one),
      ),
      contractAddress: contract,
      nativeSymbol: "ETH",
      chainId: 1,
    );
    expect(unlimited!.warnings, [S.current.wc_warning_unlimited_approval]);
  });

  group("wrapped native", () {
    test("deposit on the wrapped-native contract reads as wrap", () async {
      final decoded = await wethDecoder.decode(
        calldata: calldata("d0e30db0", ""),
        contractAddress: mainnetWeth,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(decoded, isNotNull);
      expect(decoded!.actionTitle, S.current.wc_action_wrap("ETH"));
      expect(rowLines(decoded.rows), [row(S.current.to, mainnetWeth)]);
      expect(decoded.isValueShown, isFalse, reason: "the wrapped amount is the tx value");
    });

    test("withdraw reads as unwrap and shows the native amount", () async {
      final decoded = await wethDecoder.decode(
        calldata: calldata("2e1a7d4d", word(BigInt.from(10).pow(17))),
        contractAddress: mainnetWeth,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(decoded!.actionTitle, S.current.wc_action_unwrap("ETH"));
      expect(decoded.rows.single.value, "0.1 ETH");
    });

    test("a contract that only calls itself WETH is not claimed as a wrap", () async {
      final decoded = await wethDecoder.decode(
        calldata: calldata("d0e30db0", ""),
        contractAddress: spoofedWeth,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(decoded, isNull);
    });

    test("the mainnet wrapped-native address is not trusted on another chain", () async {
      final decoded = await wethDecoder.decode(
        calldata: calldata("d0e30db0", ""),
        contractAddress: mainnetWeth,
        nativeSymbol: "ETH",
        chainId: 8453,
      );
      expect(decoded, isNull);
    });

    test("deposit on an unrelated token is not claimed as a wrap", () async {
      final decoded = await wethDecoder.decode(
        calldata: calldata("d0e30db0", ""),
        contractAddress: contract,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(decoded, isNull);
    });
  });

  group("calldata cut short is shown as an old token runs it", () {
    final max = (BigInt.one << 256) - BigInt.one;
    final amount = BigInt.parse("0102030405060708", radix: 16);

    test("a 67-byte approve of nearly everything keeps its spender, amount and warning", () async {
      final body = wordAddr(spender) + word(max);
      final decoded = await wethDecoder.decode(
        calldata: calldata("095ea7b3", body.substring(0, body.length - 2)),
        contractAddress: contract,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(decoded!.actionTitle, S.current.wc_action_approve);
      expect(rowLines(decoded.rows), [
        row(S.current.wc_token, "USD Coin (USDC)"),
        row(S.current.wc_amount, "${S.current.wc_unlimited} USDC"),
        row(S.current.wc_approved_spender, spender),
      ]);
      expect(decoded.warnings, [
        S.current.wc_warning_unlimited_approval,
        S.current.wc_warning_decode_failed,
      ]);
    });

    final calls = {
      "approve(address,uint256)": wordAddr(spender) + word(amount),
      "transfer(address,uint256)": wordAddr(recipient) + word(amount),
      "transferFrom(address,address,uint256)": wordAddr(owner) + wordAddr(recipient) + word(amount),
      "increaseAllowance(address,uint256)": wordAddr(spender) + word(amount),
      "decreaseAllowance(address,uint256)": wordAddr(spender) + word(amount),
      "increaseApproval(address,uint256)": wordAddr(spender) + word(amount),
      "decreaseApproval(address,uint256)": wordAddr(spender) + word(amount),
    };

    for (final call in calls.entries) {
      test("${call.key} one byte short reads the missing byte as zero and warns", () async {
        Future<WCDecodedRequest?> decode(String body) => wethDecoder.decode(
          calldata: calldata(selectorOf(call.key), body),
          contractAddress: contract,
          nativeSymbol: "ETH",
          chainId: 1,
        );
        final cutShort = call.value.substring(0, call.value.length - 2);

        final decoded = await decode(cutShort);
        final asRun = await decode("${cutShort}00");
        expect(decoded, isNotNull);
        expect(rowLines(decoded!.rows), rowLines(asRun!.rows));
        expect(
          rowLines(decoded.rows),
          contains(row(S.current.wc_amount, "72623859790.382848 USDC")),
        );
        expect(decoded.warnings, [...asRun.warnings, S.current.wc_warning_decode_failed]);
        expect(asRun.warnings, isNot(contains(S.current.wc_warning_decode_failed)));
      });
    }

    test("a whole missing argument reads as zero", () async {
      final decoded = await wethDecoder.decode(
        calldata: calldata("a9059cbb", wordAddr(recipient)),
        contractAddress: contract,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(rowLines(decoded!.rows), [
        row(S.current.wc_token, "USD Coin (USDC)"),
        row(S.current.wc_amount, "0 USDC"),
        row(S.current.to, recipient),
      ]);
      expect(decoded.warnings, [S.current.wc_warning_decode_failed]);
    });

    test("a withdraw cut short unwraps the amount the wrapped-native contract reads", () async {
      final wad = word(BigInt.from(10).pow(17) + BigInt.one);
      final decoded = await wethDecoder.decode(
        calldata: calldata("2e1a7d4d", wad.substring(0, wad.length - 2)),
        contractAddress: mainnetWeth,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(decoded!.actionTitle, S.current.wc_action_unwrap("ETH"));
      expect(decoded.rows.single.value, "0.1 ETH");
      expect(decoded.warnings, [S.current.wc_warning_decode_failed]);
    });

    test("a full body carries no decode warning", () async {
      final decoded = await wethDecoder.decode(
        calldata: calldata("095ea7b3", wordAddr(spender) + word(amount)),
        contractAddress: contract,
        nativeSymbol: "ETH",
        chainId: 1,
      );
      expect(decoded!.warnings, isEmpty);
    });
  });

  test("approving Permit2 names it and explains the per-swap signature", () async {
    final max = (BigInt.one << 256) - BigInt.one;
    final decoded = await decoder.decode(
      calldata: calldata(
        "095ea7b3",
        wordAddr("0x000000000022D473030F116dDEE9F6B43aC78BA3") + word(max),
      ),
      contractAddress: contract,
      nativeSymbol: "ETH",
      chainId: 1,
    );
    expect(decoded!.actionSubtitle, "Permit2");
    expect(decoded.warnings, contains(S.current.wc_warning_unlimited_approval));
    expect(decoded.warnings, contains(S.current.wc_warning_permit2_approval));
  });

  test("approving any other spender carries no Permit2 note", () async {
    final decoded = await decoder.decode(
      calldata: calldata("095ea7b3", wordAddr(spender) + wordInt(500)),
      contractAddress: contract,
      nativeSymbol: "ETH",
      chainId: 1,
    );
    expect(decoded!.actionSubtitle, isNull);
    expect(decoded.warnings, isNot(contains(S.current.wc_warning_permit2_approval)));
  });
}

class _PricedResolver extends StubErc20Resolver {
  _PricedResolver(super.tokens);

  @override
  String? fiatFor(CryptoCurrency currency, String cryptoAmount) =>
      "fiat of $cryptoAmount ${currency.title}";
}
