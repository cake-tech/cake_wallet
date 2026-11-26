import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/permit2_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cw_core/erc20_token.dart";
import "package:flutter_test/flutter_test.dart";

import "abi_hex.dart";
import "stubs.dart";

void main() {
  setUpAll(() {
    S.current = const S();
  });

  final decoder = Permit2Decoder(Erc20TokenResolver(null));
  const owner = "0x1111111111111111111111111111111111111111";
  const token = "0x2222222222222222222222222222222222222222";
  const tokenB = "0x3333333333333333333333333333333333333333";
  const spender = "0x4444444444444444444444444444444444444444";
  const recipient = "0x5555555555555555555555555555555555555555";
  const permit2 = "0x000000000022D473030F116dDEE9F6B43aC78BA3";
  const lookAlike = "0x6666666666666666666666666666666666666666";
  final uint160Max = (BigInt.one << 160) - BigInt.one;
  const expiration = 1700000000;
  const otherExpiration = 1700007200;
  const sigDeadline = 1700003600;
  String at(int seconds) => Erc20TokenResolver(null).formatTimestamp(BigInt.from(seconds));

  EvmCalldata calldata(String selector, String body) => EvmCalldata.parse("0x$selector$body")!;

  test("permit single decodes token, amount, spender and deadlines", () async {
    final body =
        wordAddr(owner) +
        wordAddr(token) +
        word(uint160Max) +
        wordInt(expiration) +
        wordInt(1) +
        wordAddr(spender) +
        wordInt(sigDeadline) +
        wordInt(0x100);
    final decoded = await decoder.decode(
      calldata: calldata("2b67b570", body),
      contractAddress: permit2,
      chainId: 1,
    );
    expect(decoded!.actionTitle, S.current.wc_action_permit2);
    expect(rowLines(decoded.rows), [
      row(S.current.wc_token, token),
      row(S.current.wc_amount, "${S.current.wc_unlimited} 0x2222…2222"),
      row(S.current.wc_expiration, at(expiration)),
      row(S.current.wc_approved_spender, spender),
      row(S.current.wc_signature_valid_until, at(sigDeadline)),
    ]);
    expect(decoded.warnings, [
      S.current.wc_warning_permit_review,
      S.current.wc_warning_unlimited_approval,
      S.current.wc_warning_unknown_token,
    ]);
  });

  test("permit batch decodes every detail entry", () async {
    final details =
        wordInt(2) +
        wordAddr(token) +
        wordInt(500) +
        wordInt(expiration) +
        wordInt(1) +
        wordAddr(tokenB) +
        wordInt(900) +
        wordInt(otherExpiration) +
        wordInt(2);
    final structBody = wordInt(0x60) + wordAddr(spender) + wordInt(sigDeadline) + details;
    final body = wordAddr(owner) + wordInt(0x60) + wordInt(0x400) + structBody;
    final decoded = await decoder.decode(
      calldata: calldata("2a2d80d1", body),
      contractAddress: permit2,
      chainId: 1,
    );
    expect(rowLines(decoded!.rows), [
      row(S.current.wc_token, token),
      row(S.current.wc_amount, "500 0x2222…2222"),
      row(S.current.wc_expiration, at(expiration)),
      row(S.current.wc_token, tokenB),
      row(S.current.wc_amount, "900 0x3333…3333"),
      row(S.current.wc_expiration, at(otherExpiration)),
      row(S.current.wc_approved_spender, spender),
      row(S.current.wc_signature_valid_until, at(sigDeadline)),
    ]);
  });

  test("permitTransferFrom shows the requested amount", () async {
    final body =
        wordAddr(token) +
        wordInt(500) +
        wordInt(9) +
        wordInt(sigDeadline) +
        wordAddr(recipient) +
        wordInt(400) +
        wordAddr(owner) +
        wordInt(0x100);
    final decoded = await decoder.decode(
      calldata: calldata("30f28b7a", body),
      contractAddress: permit2,
      chainId: 1,
    );
    expect(rowLines(decoded!.rows), [
      row(S.current.wc_token, token),
      row(S.current.wc_amount, "400 0x2222…2222"),
      row(S.current.to, recipient),
      row(S.current.wc_signature_valid_until, at(sigDeadline)),
    ]);
  });

  test("transferFrom decodes as a transfer", () async {
    final body = wordAddr(owner) + wordAddr(recipient) + wordInt(123) + wordAddr(token);
    final decoded = await decoder.decode(
      calldata: calldata("36c78516", body),
      contractAddress: permit2,
      chainId: 1,
    );
    expect(decoded!.actionTitle, S.current.wc_action_transfer);
    expect(rowLines(decoded.rows), [
      row(S.current.wc_token, token),
      row(S.current.wc_amount, "123 0x2222…2222"),
      row(S.current.from, owner),
      row(S.current.to, recipient),
    ]);
  });

  test("erc2612 permit resolves the called contract as the token", () async {
    final max = (BigInt.one << 256) - BigInt.one;
    final body = wordAddr(owner) + wordAddr(spender) + word(max) + wordInt(sigDeadline);
    final decoded = await decoder.decode(
      calldata: calldata("d505accf", body),
      contractAddress: token,
      chainId: 1,
    );
    expect(decoded!.actionTitle, S.current.wc_action_permit);
    expect(rowLines(decoded.rows), [
      row(S.current.wc_token, token),
      row(S.current.wc_amount, "${S.current.wc_unlimited} 0x2222…2222"),
      row(S.current.wc_approved_spender, spender),
      row(S.current.wc_signature_valid_until, at(sigDeadline)),
    ]);
    expect(decoded.warnings, [
      S.current.wc_warning_permit_review,
      S.current.wc_warning_unlimited_approval,
      S.current.wc_warning_unknown_token,
    ]);
  });

  test("a deadline or expiration past the year 9999 reads as never", () async {
    final uint48Max = (BigInt.one << 48) - BigInt.one;
    final uint256Max = (BigInt.one << 256) - BigInt.one;
    String? shown(WCDecodedRequest? decoded, String label) => rowValue(decoded!.rows, label);

    Future<WCDecodedRequest?> permitSingle(BigInt expiration, BigInt sigDeadline) => decoder.decode(
      calldata: calldata(
        "2b67b570",
        wordAddr(owner) +
            wordAddr(token) +
            wordInt(500) +
            word(expiration) +
            wordInt(1) +
            wordAddr(spender) +
            word(sigDeadline) +
            wordInt(0x100),
      ),
      contractAddress: permit2,
      chainId: 1,
    );
    final dated = await permitSingle(BigInt.from(expiration), BigInt.from(sigDeadline));
    expect(shown(dated, S.current.wc_expiration), at(expiration));
    expect(shown(dated, S.current.wc_signature_valid_until), at(sigDeadline));

    final openEnded = await permitSingle(uint48Max, uint256Max);
    expect(shown(openEnded, S.current.wc_expiration), S.current.wc_never);
    expect(shown(openEnded, S.current.wc_signature_valid_until), S.current.wc_never);

    final transfer = await decoder.decode(
      calldata: calldata(
        "30f28b7a",
        wordAddr(token) +
            wordInt(500) +
            wordInt(9) +
            word(uint256Max) +
            wordAddr(recipient) +
            wordInt(400) +
            wordAddr(owner) +
            wordInt(0x100),
      ),
      contractAddress: permit2,
      chainId: 1,
    );
    expect(shown(transfer, S.current.wc_signature_valid_until), S.current.wc_never);

    final tokenPermit = await decoder.decode(
      calldata: calldata(
        "d505accf",
        wordAddr(owner) + wordAddr(spender) + wordInt(500) + word(uint256Max),
      ),
      contractAddress: token,
      chainId: 1,
    );
    expect(shown(tokenPermit, S.current.wc_signature_valid_until), S.current.wc_never);
  });

  test("malformed permit falls back to the opaque view", () async {
    final decoded = await decoder.decode(
      calldata: calldata("2b67b570", wordInt(1)),
      contractAddress: permit2,
      chainId: 1,
    );
    expect(decoded!.rows, isEmpty);
    expect(decoded.warnings, contains(S.current.wc_warning_permit_review));
  });

  test("a token that resolves but is not listed warns and shows its address", () async {
    final resolving = Permit2Decoder(
      StubErc20Resolver(
        {
          token: Erc20Token(name: "USD Coin", symbol: "USDC", contractAddress: token, decimal: 6),
          tokenB: Erc20Token(name: "Dai", symbol: "DAI", contractAddress: tokenB, decimal: 18),
        },
        known: {tokenB},
      ),
    );
    Map<String, String> callsOn(String named) => {
      "2b67b570":
          wordAddr(owner) +
          wordAddr(named) +
          wordInt(2500000) +
          wordInt(1700000000) +
          wordInt(1) +
          wordAddr(spender) +
          wordInt(1700003600) +
          wordInt(0x100),
      "30f28b7a":
          wordAddr(named) +
          wordInt(2500000) +
          wordInt(9) +
          wordInt(1700000000) +
          wordAddr(recipient) +
          wordInt(2500000),
      "36c78516": wordAddr(owner) + wordAddr(recipient) + wordInt(2500000) + wordAddr(named),
    };
    final unknownToken = S.current.wc_warning_unknown_token;

    for (final selector in callsOn(token).keys) {
      final unlisted = await resolving.decode(
        calldata: calldata(selector, callsOn(token)[selector]!),
        contractAddress: permit2,
        chainId: 1,
      );
      expect(unlisted!.rows.take(2).map((r) => r.value), [
        "USD Coin (USDC)",
        token,
      ], reason: selector);
      expect(unlisted.warnings, contains(unknownToken), reason: selector);

      final listed = await resolving.decode(
        calldata: calldata(selector, callsOn(tokenB)[selector]!),
        contractAddress: permit2,
        chainId: 1,
      );
      expect(listed!.rows.any((r) => r.value == tokenB), isFalse, reason: selector);
      expect(listed.warnings, isNot(contains(unknownToken)), reason: selector);
    }

    final erc2612Permit = calldata(
      "d505accf",
      wordAddr(owner) + wordAddr(spender) + wordInt(2500000) + wordInt(1700000000),
    );
    final unlisted = await resolving.decode(
      calldata: erc2612Permit,
      contractAddress: token,
      chainId: 1,
    );
    expect(unlisted!.rows.take(2).map((r) => r.value), ["USD Coin (USDC)", token]);
    expect(unlisted.warnings, contains(unknownToken));

    final listed = await resolving.decode(
      calldata: erc2612Permit,
      contractAddress: tokenB,
      chainId: 1,
    );
    expect(listed!.rows.any((r) => r.value == tokenB), isFalse);
    expect(listed.warnings, isNot(contains(unknownToken)));
  });

  test("the Permit2 selectors on any other contract are not called Permit2", () async {
    final permitSingle =
        wordAddr(owner) +
        wordAddr(token) +
        word(uint160Max) +
        wordInt(1700000000) +
        wordInt(1) +
        wordAddr(spender) +
        wordInt(1700003600) +
        wordInt(0x100);
    final permit2Calls = {
      "2b67b570": permitSingle,
      "2a2d80d1": wordAddr(owner) + wordInt(0x60) + wordInt(0x400) + wordInt(1),
      "36c78516": wordAddr(owner) + wordAddr(recipient) + wordInt(123) + wordAddr(token),
      "30f28b7a": wordAddr(token) + wordInt(500) + wordInt(9) + wordInt(1700000000),
    };

    for (final call in permit2Calls.entries) {
      for (final contract in [lookAlike, null]) {
        final decoded = await decoder.decode(
          calldata: calldata(call.key, call.value),
          contractAddress: contract,
          chainId: 1,
        );
        expect(decoded, isNull, reason: "${call.key} on $contract");
      }
      final onPermit2 = await decoder.decode(
        calldata: calldata(call.key, call.value),
        contractAddress: permit2,
        chainId: 1,
      );
      expect(onPermit2, isNotNull, reason: call.key);
    }
  });

  group("approve on Permit2, the allowance set without a signature", () {
    final approve = selectorOf("approve(address,address,uint160,uint48)");
    String body(BigInt amount) =>
        wordAddr(token) + wordAddr(spender) + word(amount) + wordInt(expiration);

    test("names the token, the amount, when it ends and who may spend", () async {
      expect(approve, "87517c45");
      final decoded = await decoder.decode(
        calldata: calldata(approve, body(BigInt.from(500))),
        contractAddress: permit2,
        chainId: 1,
      );
      expect(decoded!.actionTitle, S.current.wc_action_permit2);
      expect(decoded.actionSubtitle, "Permit2");
      expect(rowLines(decoded.rows), [
        row(S.current.wc_token, token),
        row(S.current.wc_amount, "500 0x2222…2222"),
        row(S.current.wc_expiration, at(expiration)),
        row(S.current.wc_approved_spender, spender),
      ]);
      expect(decoded.warnings, [S.current.wc_warning_unknown_token]);
    });

    test("the largest amount is unlimited, with no note about a signature per swap", () async {
      final decoded = await decoder.decode(
        calldata: calldata(approve, body(uint160Max)),
        contractAddress: permit2,
        chainId: 1,
      );
      expect(rowValue(decoded!.rows, S.current.wc_amount), "${S.current.wc_unlimited} 0x2222…2222");
      expect(decoded.warnings, [
        S.current.wc_warning_unlimited_approval,
        S.current.wc_warning_unknown_token,
      ]);
    });

    test("on any other contract it is not called Permit2", () async {
      final decoded = await decoder.decode(
        calldata: calldata(approve, body(uint160Max)),
        contractAddress: lookAlike,
        chainId: 1,
      );
      expect(decoded, isNull);
    });

    test("a body Permit2 would revert on falls back to the opaque view", () async {
      final decoded = await decoder.decode(
        calldata: calldata(approve, wordAddr(token) + wordAddr(spender)),
        contractAddress: permit2,
        chainId: 1,
      );
      expect(decoded!.actionTitle, S.current.wc_action_permit2);
      expect(decoded.rows, isEmpty);
    });
  });

  test("unrelated selector returns null", () async {
    final decoded = await decoder.decode(
      calldata: calldata("deadbeef", wordInt(1)),
      contractAddress: permit2,
      chainId: 1,
    );
    expect(decoded, isNull);
  });
}
