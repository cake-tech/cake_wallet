import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/permit2_decoder.dart";
import "package:flutter_test/flutter_test.dart";

import "abi_hex.dart";

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
  final uint160Max = (BigInt.one << 160) - BigInt.one;

  EvmCalldata calldata(String selector, String body) => EvmCalldata.parse("0x$selector$body")!;

  test("permit single decodes token, amount, spender and deadlines", () async {
    final body = wordAddr(owner) +
        wordAddr(token) +
        word(uint160Max) +
        wordInt(1700000000) +
        wordInt(1) +
        wordAddr(spender) +
        wordInt(1700003600) +
        wordInt(0x100);
    final decoded = await decoder.decode(
      calldata: calldata("2b67b570", body),
      contractAddress: "0xpermit2",
    );
    expect(decoded!.actionTitle, S.current.wc_action_permit2);
    expect(decoded.rows.any((r) => r.value == spender), isTrue);
    expect(decoded.rows.any((r) => r.label == S.current.wc_expiration), isTrue);
    expect(decoded.rows.any((r) => r.label == S.current.wc_signature_valid_until), isTrue);
    expect(decoded.warnings, contains(S.current.wc_warning_unlimited_approval));
    expect(decoded.warnings, contains(S.current.wc_warning_permit_review));
  });

  test("permit batch decodes every detail entry", () async {
    final details = wordInt(2) +
        wordAddr(token) +
        wordInt(500) +
        wordInt(1700000000) +
        wordInt(1) +
        wordAddr(tokenB) +
        wordInt(900) +
        wordInt(1700000000) +
        wordInt(2);
    final structBody = wordInt(0x60) + wordAddr(spender) + wordInt(1700003600) + details;
    final body = wordAddr(owner) + wordInt(0x60) + wordInt(0x400) + structBody;
    final decoded = await decoder.decode(
      calldata: calldata("2a2d80d1", body),
      contractAddress: "0xpermit2",
    );
    expect(decoded!.rows.where((r) => r.label == S.current.wc_token).length, 2);
    expect(decoded.rows.any((r) => r.value.startsWith("500")), isTrue);
    expect(decoded.rows.any((r) => r.value.startsWith("900")), isTrue);
    expect(decoded.rows.any((r) => r.value == spender), isTrue);
  });

  test("permitTransferFrom shows the requested amount", () async {
    final body = wordAddr(token) +
        wordInt(500) +
        wordInt(9) +
        wordInt(1700000000) +
        wordAddr(recipient) +
        wordInt(400) +
        wordAddr(owner) +
        wordInt(0x100);
    final decoded = await decoder.decode(
      calldata: calldata("30f28b7a", body),
      contractAddress: "0xpermit2",
    );
    expect(decoded!.rows.any((r) => r.value.startsWith("400")), isTrue);
    expect(decoded.rows.any((r) => r.value == recipient), isTrue);
  });

  test("transferFrom decodes as a transfer", () async {
    final body = wordAddr(owner) + wordAddr(recipient) + wordInt(123) + wordAddr(token);
    final decoded = await decoder.decode(
      calldata: calldata("36c78516", body),
      contractAddress: "0xpermit2",
    );
    expect(decoded!.actionTitle, S.current.wc_action_transfer);
    expect(decoded.rows.any((r) => r.value.startsWith("123")), isTrue);
  });

  test("erc2612 permit resolves the called contract as the token", () async {
    final max = (BigInt.one << 256) - BigInt.one;
    final body = wordAddr(owner) + wordAddr(spender) + word(max) + wordInt(1700000000);
    final decoded = await decoder.decode(
      calldata: calldata("d505accf", body),
      contractAddress: token,
    );
    expect(decoded!.actionTitle, S.current.wc_action_permit);
    expect(decoded.warnings, contains(S.current.wc_warning_unlimited_approval));
    expect(decoded.rows.any((r) => r.value == spender), isTrue);
  });

  test("malformed permit falls back to the opaque view", () async {
    final decoded = await decoder.decode(
      calldata: calldata("2b67b570", wordInt(1)),
      contractAddress: "0xpermit2",
    );
    expect(decoded!.rows, isEmpty);
    expect(decoded.warnings, contains(S.current.wc_warning_permit_review));
  });

  test("unrelated selector returns null", () async {
    final decoded = await decoder.decode(
      calldata: calldata("deadbeef", wordInt(1)),
      contractAddress: "0xpermit2",
    );
    expect(decoded, isNull);
  });
}
