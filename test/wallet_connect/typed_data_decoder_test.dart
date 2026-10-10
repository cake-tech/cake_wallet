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

  const swapper = "0x9379e546675db383365f8718342a92ac3ba3a4f8";
  const v2Reactor = "0x00000011F84B9aa48e5f8aA8B9897600006289Be";

  String uniswapXOrder({
    required String? outputRecipient,
    String spender = v2Reactor,
    String reactor = v2Reactor,
  }) =>
      jsonEncode({
        "types": <String, dynamic>{},
        "primaryType": "PermitWitnessTransferFrom",
        "domain": {
          "name": "Permit2",
          "chainId": 1,
          "verifyingContract": "0x000000000022D473030F116dDEE9F6B43aC78BA3",
        },
        "message": {
          "permitted": {
            "token": "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
            "amount": "40000000000000000000",
          },
          "spender": spender,
          "nonce": "1",
          "deadline": "1791460959",
          "witness": {
            "info": {
              "reactor": reactor,
              "swapper": "0x9379e546675db383365f8718342a92ac3ba3a4f8",
              "nonce": "1",
              "deadline": "1791460959",
              "additionalValidationContract": "0x0000000000000000000000000000000000000000",
              "additionalValidationData": "0x",
            },
            "cosigner": "0x4449Cd34d1eB1FEDCF02A1Be3834FfDe8E6A6180",
            "baseInputToken": "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
            "baseInputStartAmount": "40000000000000000000",
            "baseInputEndAmount": "40000000000000000000",
            "baseOutputs": [
              {
                "token": "0xdAC17F958D2ee523a2206206994597C13D831ec7",
                "startAmount": "101430499832",
                "endAmount": "101329069331",
                if (outputRecipient != null) "recipient": outputRecipient,
              },
            ],
          },
        },
      });

  test("a UniswapX order reads as a swap with the least the swapper receives", () async {
    final decoded = await decoder.decode(
      uniswapXOrder(outputRecipient: swapper),
      walletAddress: swapper,
    );
    expect(decoded.actionTitle, S.current.wc_action_swap);
    expect(decoded.actionSubtitle, S.current.wc_via("UniswapX"));
    expect(
      decoded.rows.firstWhere((r) => r.label == S.current.wc_swap_from_max).value,
      startsWith("40000000000000000000 "),
    );
    expect(
      decoded.rows.firstWhere((r) => r.label == S.current.wc_swap_to_min).value,
      startsWith("101329069331 "),
    );
    expect(decoded.rows.any((r) => r.label == S.current.wc_recipient), isFalse);
  });

  test("a UniswapX order paying someone else names that recipient on the sheet", () async {
    const stranger = "0x9999999999999999999999999999999999999999";
    final decoded = await decoder.decode(
      uniswapXOrder(outputRecipient: stranger),
      walletAddress: swapper,
    );
    expect(decoded.rows.any((r) => r.label == S.current.wc_swap_to_min), isFalse);
    expect(
      decoded.rows.firstWhere((r) => r.label == S.current.wc_recipient).value,
      stranger,
    );
  });

  test("an order whose spender is not a known reactor is not shown as a swap", () async {
    const stranger = "0x9999999999999999999999999999999999999999";
    final decoded = await decoder.decode(
      uniswapXOrder(outputRecipient: swapper, spender: stranger, reactor: stranger),
      walletAddress: swapper,
    );
    expect(decoded.actionTitle, isNot(S.current.wc_action_swap));
    expect(decoded.rows.any((r) => r.label == S.current.wc_swap_to_min), isFalse);
  });

  test("an order whose spender differs from its reactor is not shown as a swap", () async {
    final decoded = await decoder.decode(
      uniswapXOrder(
        outputRecipient: swapper,
        spender: "0x9999999999999999999999999999999999999999",
      ),
      walletAddress: swapper,
    );
    expect(decoded.actionTitle, isNot(S.current.wc_action_swap));
  });

  test("an order output with no recipient is not shown as a swap", () async {
    final decoded = await decoder.decode(
      uniswapXOrder(outputRecipient: null),
      walletAddress: swapper,
    );
    expect(decoded.actionTitle, isNot(S.current.wc_action_swap));
  });
}
