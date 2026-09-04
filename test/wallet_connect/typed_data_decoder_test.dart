import "dart:convert";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/typed_data_decoder.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  setUpAll(() {
    S.current = const S();
  });

  final decoder = TypedDataDecoder(Erc20TokenResolver(null));
  const token = "0x2222222222222222222222222222222222222222";
  const spender = "0x4444444444444444444444444444444444444444";
  const owner = "0x1111111111111111111111111111111111111111";
  final uint160Max = ((BigInt.one << 160) - BigInt.one).toString();

  test("PermitSingle typed data decodes amounts and warns on unlimited", () async {
    final payload = jsonEncode({
      "domain": {"name": "Permit2", "chainId": 1},
      "primaryType": "PermitSingle",
      "types": <String, dynamic>{},
      "message": {
        "details": {
          "token": token,
          "amount": uint160Max,
          "expiration": "1700000000",
          "nonce": "0",
        },
        "spender": spender,
        "sigDeadline": "1700003600",
      },
    });
    final decoded = await decoder.decode(payload);
    expect(decoded.actionTitle, S.current.wc_action_permit2);
    expect(decoded.rows.any((r) => r.value == spender), isTrue);
    expect(decoded.warnings, contains(S.current.wc_warning_unlimited_approval));
    expect(decoded.rawFallback, isNotNull);
  });

  test("EIP-2612 permit resolves the verifying contract as the token", () async {
    final payload = jsonEncode({
      "domain": {"name": "USD Coin", "verifyingContract": token},
      "primaryType": "Permit",
      "types": <String, dynamic>{},
      "message": {
        "owner": owner,
        "spender": spender,
        "value": "500",
        "nonce": "1",
        "deadline": "1700000000",
      },
    });
    final decoded = await decoder.decode(payload);
    expect(decoded.actionTitle, S.current.wc_action_permit);
    expect(decoded.rows.any((r) => r.value.startsWith("500")), isTrue);
    expect(decoded.rows.any((r) => r.label == S.current.wc_signature_valid_until), isTrue);
    expect(decoded.warnings, isNot(contains(S.current.wc_warning_unlimited_approval)));
  });

  test("generic typed data flattens the message with humanized timestamps", () async {
    final payload = jsonEncode({
      "domain": {"name": "Example dApp", "chainId": 1},
      "primaryType": "Order",
      "types": {
        "Order": [
          {"name": "maker", "type": "address"},
          {"name": "deadline", "type": "uint256"},
        ],
      },
      "message": {"maker": owner, "deadline": 1700000000},
    });
    final decoded = await decoder.decode(payload);
    expect(decoded.actionTitle, S.current.wc_action_sign_typed_data);
    expect(decoded.rows.any((r) => r.value == "Example dApp"), isTrue);
    expect(decoded.rows.any((r) => r.value == owner), isTrue);

    final deadlineRow = decoded.rows.firstWhere((r) => r.label == "deadline");
    expect(deadlineRow.value, isNot("1700000000"));
  });

  test("list payloads take the json element", () async {
    final payload = [
      owner,
      jsonEncode({
        "domain": {"name": "Example"},
        "primaryType": "Thing",
        "types": <String, dynamic>{},
        "message": {"note": "hi"},
      }),
    ];
    final decoded = await decoder.decode(payload);
    expect(decoded.rows.any((r) => r.value == "hi"), isTrue);
  });

  test("PermitBatch typed data lists every token in the batch", () async {
    final payload = jsonEncode({
      "domain": {"name": "Permit2", "chainId": 1},
      "primaryType": "PermitBatch",
      "types": <String, dynamic>{},
      "message": {
        "details": [
          {"token": token, "amount": "1000000", "expiration": "1700000000", "nonce": "0"},
          {"token": spender, "amount": uint160Max, "expiration": "1700000000", "nonce": "1"},
        ],
        "spender": spender,
        "sigDeadline": "1700003600",
      },
    });
    final decoded = await decoder.decode(payload);
    expect(decoded.actionTitle, S.current.wc_action_permit2);
    expect(decoded.rows.where((r) => r.label == S.current.wc_token).length, 2);
    expect(decoded.warnings, contains(S.current.wc_warning_unlimited_approval));
  });

  test("nested structs and arrays are flattened with dotted labels", () async {
    final payload = jsonEncode({
      "domain": {"name": "Seaport", "chainId": 1},
      "primaryType": "Order",
      "types": {
        "Order": [
          {"name": "offerer", "type": "address"},
          {"name": "consideration", "type": "Item[]"},
          {"name": "terms", "type": "Terms"},
        ],
        "Item": [
          {"name": "recipient", "type": "address"},
          {"name": "amount", "type": "uint256"},
        ],
        "Terms": [
          {"name": "expiry", "type": "uint256"},
        ],
      },
      "message": {
        "offerer": owner,
        "consideration": [
          {"recipient": spender, "amount": "12"},
          {"recipient": owner, "amount": "34"},
        ],
        "terms": {"expiry": 1700000000},
      },
    });
    final decoded = await decoder.decode(payload);
    expect(decoded.rows.any((r) => r.label == "consideration" && r.value == "[2]"), isTrue);
    expect(decoded.rows.any((r) => r.label == "consideration[0].recipient"), isTrue);
    expect(
      decoded.rows.any((r) => r.label == "consideration[1].amount" && r.value == "34"),
      isTrue,
    );
    final expiry = decoded.rows.firstWhere((r) => r.label == "terms.expiry");
    expect(expiry.value, isNot("1700000000"), reason: "timestamps humanize even when nested");
  });

  test("legacy V1 array payloads render their entries", () async {
    final payload = jsonEncode([
      {"type": "string", "name": "greeting", "value": "Hello from a legacy dApp"},
      {"type": "address", "name": "wallet", "value": owner},
    ]);
    final decoded = await decoder.decode(payload);
    expect(decoded.actionTitle, S.current.wc_action_sign_typed_data);
    expect(decoded.warnings, isEmpty);
    expect(decoded.rows.any((r) => r.value == "Hello from a legacy dApp"), isTrue);
    expect(decoded.rows.any((r) => r.value == owner), isTrue);
    expect(decoded.rawFallback, isNotNull);
  });

  test("unparseable payloads fall back to the raw view with a warning", () async {
    final decoded = await decoder.decode("not json at all");
    expect(decoded.warnings, contains(S.current.wc_warning_typed_data_invalid));
    expect(decoded.rawFallback, "not json at all");
  });
}
