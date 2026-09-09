import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_request_decoder.dart";
import "package:flutter_test/flutter_test.dart";

import "abi_hex.dart";

void main() {
  setUpAll(() {
    S.current = const S();
  });

  final decoder = EvmRequestDecoder(null);
  const router = "0x1111111111111111111111111111111111111111";
  const recipient = "0x2222222222222222222222222222222222222222";
  const sender = "0x3333333333333333333333333333333333333333";
  final halfEth = BigInt.from(5) * BigInt.from(10).pow(17);

  String transferCalldata(String to, int amount) => "a9059cbb${wordAddr(to)}${wordInt(amount)}";

  test("no calldata decodes as a native send that owns its value row", () async {
    final decoded = await decoder.decodeTransaction(
      rawData: null,
      toAddress: recipient,
      fromAddress: sender,
      nativeSymbol: "ETH",
      valueWei: halfEth,
    );
    expect(decoded.actionTitle, S.current.wc_action_send);
    expect(decoded.rows.first.value, "0.5 ETH");
    expect(decoded.rows.any((r) => r.value == recipient), isTrue);
    expect(decoded.hideValue, isTrue);
  });

  test("unknown selector keeps the value visible and warns", () async {
    final decoded = await decoder.decodeTransaction(
      rawData: "0xdeadbeef${wordInt(1)}",
      toAddress: router,
      fromAddress: sender,
      nativeSymbol: "ETH",
      valueWei: halfEth,
    );
    expect(decoded.actionTitle, S.current.wc_contract_call);
    expect(decoded.actionSubtitle, "0xdeadbeef");
    expect(decoded.warnings, contains(S.current.wc_warning_unknown_contract));
    expect(decoded.rows.any((r) => r.value == "0.5 ETH"), isTrue);
    expect(decoded.hideValue, isTrue);
  });

  test("checksummed-case calldata still matches the selector", () async {
    final decoded = await decoder.decodeTransaction(
      rawData: "0x${transferCalldata(recipient, 42).toUpperCase()}",
      toAddress: router,
      fromAddress: sender,
      nativeSymbol: "ETH",
      valueWei: BigInt.zero,
    );
    expect(decoded.actionTitle, S.current.wc_action_transfer);
  });

  group("multicall", () {
    test("single inner call surfaces as the inner decode plus deadline", () async {
      final body =
          wordInt(1700000000) + wordInt(0x40) + bytesArrayBody([transferCalldata(recipient, 42)]);
      final decoded = await decoder.decodeTransaction(
        rawData: "0x5ae401dc$body",
        toAddress: router,
        fromAddress: sender,
        nativeSymbol: "ETH",
        valueWei: BigInt.zero,
      );
      expect(decoded.actionTitle, S.current.wc_action_transfer);
      expect(decoded.rows.last.label, S.current.wc_deadline);
      expect(decoded.rows.any((r) => r.value == recipient), isTrue);
    });

    test("several inner calls keep a per-step breakdown", () async {
      final body = wordInt(0x20) +
          bytesArrayBody([
            transferCalldata(recipient, 42),
            "deadbeef${wordInt(1)}",
          ]);
      final decoded = await decoder.decodeTransaction(
        rawData: "0xac9650d8$body",
        toAddress: router,
        fromAddress: sender,
        nativeSymbol: "ETH",
        valueWei: BigInt.zero,
      );
      expect(decoded.actionTitle, S.current.wc_action_transfer);
      expect(decoded.detailRows.first.label, S.current.wc_step_n("1"));
      expect(decoded.detailRows.any((r) => r.label == S.current.wc_step_n("2")), isTrue);
      expect(decoded.warnings, contains(S.current.wc_warning_unknown_contract));
    });

    test("raw fallback stays with the service layer, not the decoder", () async {
      final decoded = await decoder.decodeTransaction(
        rawData: "0xdeadbeef${wordInt(1)}",
        toAddress: router,
        fromAddress: sender,
        nativeSymbol: "ETH",
        valueWei: BigInt.zero,
      );
      expect(decoded.rawFallback, isNull);
    });
  });
}
