import "dart:convert";

import "package:cake_wallet/exchange/provider/swapsxyz/swapsxyz_api_schema.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:flutter_test/flutter_test.dart";

import "../fixture.dart";

void _expectPayment(SwapsXyzPayment payment, Map<String, dynamic> raw) {
  expect(payment.amount, BigInt.parse(raw["amount"] as String));
  expect(payment.address, raw["address"]);
  expect(payment.chainId, raw["chainId"]);
  expect(payment.isNative, raw["isNative"]);
  expect(payment.name, raw["name"]);
  expect(payment.symbol, raw["symbol"]);
  expect(payment.decimals, raw["decimals"]);
  expect(payment.usdAmount, raw["usdAmount"]);
}

void main() {
  group("SwapsXyzChain", () {
    test("parses every chain in chain_list", () {
      final raw = fixtureList("swapsxyz", "chain_list");
      final chains = raw.map((e) => SwapsXyzChain.fromJson(e as Map<String, dynamic>)).toList();

      expect(chains, hasLength(raw.length));

      for (var i = 0; i < raw.length; i++) {
        final rawChain = raw[i] as Map<String, dynamic>;

        expect(chains[i].chainId, rawChain["chainId"]);
        expect(chains[i].name, rawChain["name"]);
        expect(chains[i].vmId.name, isNotEmpty);
      }
    });

    test("every vm id in the list is one the schema knows", () {
      final chains = fixtureList("swapsxyz", "chain_list")
          .map((e) => SwapsXyzChain.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(chains.where((c) => c.vmId == SwapsXyzVmId.unknown), isEmpty);
      expect(chains.map((c) => c.vmId).toSet(), contains(SwapsXyzVmId.evm));
    });
  });

  group("SwapsXyzPathsResponse", () {
    test("parses paths field by field", () {
      final raw = fixtureMap("swapsxyz", "paths");
      final response = SwapsXyzPathsResponse.fromJson(raw);
      final rawToken = raw["srcToken"] as Map<String, dynamic>;

      expect(response.srcChainId, raw["srcChainId"]);
      expect(response.timestamp, raw["timestamp"]);
      expect(response.srcToken.chainId, rawToken["chainId"]);
      expect(response.srcToken.address, rawToken["address"]);
      expect(response.srcToken.name, rawToken["name"]);
      expect(response.srcToken.symbol, rawToken["symbol"]);
      expect(response.srcToken.decimals, rawToken["decimals"]);
      expect(response.srcToken.isNative, rawToken["isNative"]);
      expect(response.srcToken.logo, rawToken["logo"]);
      expect(response.srcToken.swapsXyzCode, rawToken["swapsXyzCode"]);
      expect(response.srcToken.minAmount, rawToken["minAmount"]);
      expect(response.srcToken.maxAmount, rawToken["maxAmount"]);
      expect(response.paths, hasLength((raw["paths"] as List).length));
    });

    test("parses each path, whichever form its tokens take", () {
      final raw = fixtureMap("swapsxyz", "paths");
      final response = SwapsXyzPathsResponse.fromJson(raw);
      final rawPaths = raw["paths"] as List<dynamic>;

      for (var i = 0; i < rawPaths.length; i++) {
        final rawPath = rawPaths[i] as Map<String, dynamic>;
        final path = response.paths[i];

        expect(path.chainId, rawPath["chainId"]);
        expect(path.supportsExactAmountIn, rawPath["supportsExactAmountIn"]);
        expect(path.supportsExactAmountOut, rawPath["supportsExactAmountOut"]);

        if (rawPath["tokens"] == "all") {
          expect(path.tokens.isAll, isTrue);
          expect(path.tokens.tokens, isNull);
        } else {
          expect(path.tokens.isAll, isFalse);
          expect(path.tokens.tokens, hasLength((rawPath["tokens"] as List).length));
        }
      }
    });

    test("the deprecated amountLimits still parses when it is there", () {
      final raw = fixtureMap("swapsxyz", "paths");
      final response = SwapsXyzPathsResponse.fromJson(raw);
      final rawPaths = raw["paths"] as List<dynamic>;

      for (var i = 0; i < rawPaths.length; i++) {
        final rawLimits = (rawPaths[i] as Map<String, dynamic>)["amountLimits"];

        if (rawLimits == null) {
          expect(response.paths[i].amountLimits, isNull);
        } else {
          expect(response.paths[i].amountLimits!.minAmount, rawLimits["minAmount"]);
          expect(response.paths[i].amountLimits!.maxAmount, rawLimits["maxAmount"]);
        }
      }
    });
  });

  group("SwapsXyzQuote", () {
    test("parses quote field by field", () {
      final raw = fixtureMap("swapsxyz", "quote");
      final quote = SwapsXyzQuote.fromJson(raw);

      _expectPayment(quote.amountIn, raw["amountIn"] as Map<String, dynamic>);
      _expectPayment(quote.amountInMax, raw["amountInMax"] as Map<String, dynamic>);
      _expectPayment(quote.amountOut, raw["amountOut"] as Map<String, dynamic>);
      _expectPayment(quote.amountOutMin, raw["amountOutMin"] as Map<String, dynamic>);
      _expectPayment(quote.protocolFee!, raw["protocolFee"] as Map<String, dynamic>);
      _expectPayment(quote.applicationFee!, raw["applicationFee"] as Map<String, dynamic>);
      _expectPayment(quote.bridgeFee!, raw["bridgeFee"] as Map<String, dynamic>);

      expect(quote.exchangeRate, raw["exchangeRate"]);
      expect(quote.estimatedTxTime, (raw["estimatedTxTime"] as num).toDouble());
      expect(quote.estimatedPriceImpact, raw["estimatedPriceImpact"]);
      expect(quote.vmId, SwapsXyzVmId.evm);
      expect(quote.requiresTokenApproval, raw["requiresTokenApproval"]);
      expect(quote.requiresRegisterTransaction, raw["requiresRegisterTransaction"]);
      expect(quote.executionsType, SwapsXyzExecutionsType.standard);
    });

    test("the exchange rate agrees with the amounts", () {
      final quote = SwapsXyzQuote.fromJson(fixtureMap("swapsxyz", "quote"));
      final inHuman = quote.amountIn.amount / BigInt.from(10).pow(quote.amountIn.decimals);
      final outHuman = quote.amountOut.amount / BigInt.from(10).pow(quote.amountOut.decimals);

      expect(outHuman / inHuman, closeTo(quote.exchangeRate, quote.exchangeRate * 0.001));
    });

    test("the slippage floor is below the quoted output", () {
      final quote = SwapsXyzQuote.fromJson(fixtureMap("swapsxyz", "quote"));

      expect(quote.amountOutMin.amount <= quote.amountOut.amount, isTrue);
    });

    test("the application fee is denominated in the source token", () {
      final quote = SwapsXyzQuote.fromJson(fixtureMap("swapsxyz", "quote"));

      expect(quote.applicationFee!.symbol, quote.amountIn.symbol);
      expect(quote.applicationFee!.amount, greaterThan(BigInt.zero));
    });
  });

  group("SwapsXyzActionResponse", () {
    test("parses action field by field", () {
      final raw = fixtureMap("swapsxyz", "action");
      final action = SwapsXyzActionResponse.fromJson(raw);

      expect(action.txId, raw["txId"]);
      expect(action.vmId, SwapsXyzVmId.evm);
      expect(action.tx, raw["tx"]);
      expect(action.exchangeRate, raw["exchangeRate"]);
      expect(action.estimatedTxTime, (raw["estimatedTxTime"] as num).toDouble());
      expect(action.estimatedPriceImpact, raw["estimatedPriceImpact"]);
      expect(action.requiresTokenApproval, raw["requiresTokenApproval"]);
      expect(action.requiresRegisterTransaction, raw["requiresRegisterTransaction"]);
      expect(action.executionsType, SwapsXyzExecutionsType.standard);
      expect(action.bridgeIds, raw["bridgeIds"]);
      expect(action.allRoutes, hasLength((raw["allRoutes"] as List).length));

      _expectPayment(action.amountIn, raw["amountIn"] as Map<String, dynamic>);
      _expectPayment(action.amountInMax, raw["amountInMax"] as Map<String, dynamic>);
      _expectPayment(action.amountOut, raw["amountOut"] as Map<String, dynamic>);
      _expectPayment(action.amountOutMin, raw["amountOutMin"] as Map<String, dynamic>);
      _expectPayment(action.protocolFee, raw["protocolFee"] as Map<String, dynamic>);
      _expectPayment(action.applicationFee, raw["applicationFee"] as Map<String, dynamic>);
    });

    test("the evm accessor types the transaction the wallet has to sign", () {
      final raw = fixtureMap("swapsxyz", "action");
      final action = SwapsXyzActionResponse.fromJson(raw);
      final rawTx = raw["tx"] as Map<String, dynamic>;

      expect(action.evmTx.to, rawTx["to"]);
      expect(action.evmTx.data, rawTx["data"]);
      expect(action.evmTx.value, rawTx["value"]);
      expect(action.evmTx.chainId, rawTx["chainId"]);
      expect(action.evmTx.data, startsWith("0x"));
    });

    test("the calldata selector is one the provider recognises", () {
      final action = SwapsXyzActionResponse.fromJson(fixtureMap("swapsxyz", "action"));

      expect(
        action.evmTx.data.substring(0, 10),
        anyOf("0xa9059cbb", "0x9be111d1"),
        reason: "transfer or swapAndExecute",
      );
    });

    test("a swap needing no approval still needs registering", () {
      final action = SwapsXyzActionResponse.fromJson(fixtureMap("swapsxyz", "action"));

      expect(action.requiresTokenApproval, isFalse, reason: "the source is the native token");
      expect(action.txId, startsWith("0x"));
    });
  });

  group("SwapsXyzErrorResponse", () {
    test("parses the unauthenticated body", () {
      final raw = fixtureMap("swapsxyz", "error_no_api_key");
      final error = SwapsXyzErrorResponse.fromJson(raw);
      final rawError = raw["error"] as Map<String, dynamic>;

      expect(error.success, isFalse);
      expect(error.error!.code, rawError["code"]);
      expect(error.error!.name, rawError["name"]);
      expect(error.error!.message, rawError["message"]);
      expect(error.error!.title, rawError["title"]);
      expect(error.error!.statusCode, rawError["statusCode"]);
      expect(error.error!.timestamp, DateTime.parse(rawError["timestamp"] as String));
      expect(error.error!.details, rawError["details"]);
    });

    test("a status lookup before registering the tx answers NOT_FOUND", () {
      final raw = fixtureMap("swapsxyz", "status");
      final error = SwapsXyzErrorResponse.fromJson(raw);

      expect(error.success, isFalse);
      expect(error.error!.code, "NOT_FOUND");
      expect(error.error!.statusCode, 404);
      expect(error.error!.message, contains("registerTxs"));
    });

    test("details carries the max amount when the amount was too high", () {
      const body = '{"success":false,"error":{"code":"AMOUNT_TOO_HIGH","name":"AmountTooHighError",'
          '"message":"The specified amount is too high.","title":"Amount too high",'
          '"statusCode":400,"details":{"srcChainId":1,"maxAmount":100000000000000000000},'
          '"timestamp":"2024-01-01T00:00:00.000Z"}}';
      final error = SwapsXyzErrorResponse.fromJson(json.decode(body) as Map<String, dynamic>);

      expect(error.error!.code, "AMOUNT_TOO_HIGH");
      expect(error.error!.details, isNotNull);
      expect(error.error!.details!["maxAmount"], isNotNull);
    });
  });

  group("SwapsXyzTxDetails", () {
    // getStatus only answers with this once the transaction has been registered, which the
    // fixture script never does, so this is the documented shape
    test("parses a status body with both legs", () {
      const body = '{"status":"pending","sender":"0xsender","srcChainId":1,"dstChainId":137,'
          '"txId":"0xtxid","usdValue":190.5,'
          '"bridgeDetails":{"isBridge":true,"bridgeTime":420,'
          '"txPath":[{"chainId":1,"txHash":"0xa","timestamp":1640995200,"nextBridge":"layerZero"}]},'
          '"srcTx":{"txHash":"0xsrc","chainId":1,"timestamp":1640995200,"toAddress":"0xrouter",'
          '"paymentToken":{"name":"Ether","symbol":"ETH","decimals":18,'
          '"amount":"100000000000000000","chainId":1,"isNative":true,"usdAmount":190.5}},'
          '"dstTx":{"txHash":"0xdst","chainId":137,"timestamp":"1640995800",'
          '"paymentToken":{"name":"USD Coin","symbol":"USDC","decimals":6,"amount":"190000000",'
          '"chainId":137,"address":"0x2791","isNative":false}}}';
      final details = SwapsXyzTxDetails.fromJson(json.decode(body) as Map<String, dynamic>);

      expect(details.status, SwapsXyzTxStatusValue.pending);
      expect(details.sender, "0xsender");
      expect(details.srcChainId, 1);
      expect(details.dstChainId, 137);
      expect(details.txId, "0xtxid");
      expect(details.usdValue, 190.5);
      expect(details.srcTx!.txHash, "0xsrc");
      expect(details.srcTx!.toAddress, "0xrouter");
      expect(details.srcTx!.paymentToken!.symbol, "ETH");
      expect(details.srcTx!.paymentToken!.amount, BigInt.parse("100000000000000000"));
      expect(details.srcTx!.paymentToken!.isNative, isTrue);
      expect(details.dstTx!.paymentToken!.symbol, "USDC");
      expect(details.dstTx!.paymentToken!.amount, BigInt.from(190000000));
      expect(details.bridgeDetails!.isBridge, isTrue);
      expect(details.bridgeDetails!.bridgeTime, 420);
      expect(details.bridgeDetails!.txPath, hasLength(1));
      expect(details.bridgeDetails!.txPath!.first.nextBridge, "layerZero");
    });

    test("a timestamp parses whether it is a number or a string", () {
      const body = '{"status":"pending","sender":"0x","srcChainId":1,"txId":"0x",'
          '"srcTx":{"txHash":"0xa","chainId":1,"timestamp":1640995200},'
          '"dstTx":{"txHash":"0xb","chainId":1,"timestamp":"1640995200"}}';
      final details = SwapsXyzTxDetails.fromJson(json.decode(body) as Map<String, dynamic>);

      expect(details.srcTx!.timestamp, details.dstTx!.timestamp);
      expect(
        details.srcTx!.timestamp,
        DateTime.fromMillisecondsSinceEpoch(1640995200 * 1000, isUtc: true),
      );
    });

    test("every documented status parses, spaces and all", () {
      const wire = {
        "not yet created": SwapsXyzTxStatusValue.notYetCreated,
        "submitted": SwapsXyzTxStatusValue.submitted,
        "pending": SwapsXyzTxStatusValue.pending,
        "success": SwapsXyzTxStatusValue.success,
        "completed": SwapsXyzTxStatusValue.completed,
        "requires refund": SwapsXyzTxStatusValue.requiresRefund,
        "refunded": SwapsXyzTxStatusValue.refunded,
        "expired": SwapsXyzTxStatusValue.expired,
        "failed": SwapsXyzTxStatusValue.failed,
      };

      wire.forEach((raw, expected) {
        final details = SwapsXyzTxDetails.fromJson(
          json.decode('{"status":"$raw","sender":"0x","srcChainId":1,"txId":"0x"}')
              as Map<String, dynamic>,
        );

        expect(details.status, expected, reason: raw);
      });
    });

    test("an unrecognised status falls back to unknown", () {
      final details = SwapsXyzTxDetails.fromJson(
        json.decode('{"status":"brand new","sender":"0x","srcChainId":1,"txId":"0x"}')
            as Map<String, dynamic>,
      );

      expect(details.status, SwapsXyzTxStatusValue.unknown);
    });
  });

  group("StatusToState", () {
    test("maps every status to a trade state", () {
      expect(SwapsXyzTxStatusValue.notYetCreated.toState, TradeState.toBeCreated);
      expect(SwapsXyzTxStatusValue.submitted.toState, TradeState.pending);
      expect(SwapsXyzTxStatusValue.pending.toState, TradeState.pending);
      expect(SwapsXyzTxStatusValue.success.toState, TradeState.success);
      expect(SwapsXyzTxStatusValue.completed.toState, TradeState.success);
      expect(SwapsXyzTxStatusValue.requiresRefund.toState, TradeState.refund);
      expect(SwapsXyzTxStatusValue.refunded.toState, TradeState.refunded);
      expect(SwapsXyzTxStatusValue.expired.toState, TradeState.expired);
      expect(SwapsXyzTxStatusValue.failed.toState, TradeState.failed);
      expect(SwapsXyzTxStatusValue.unknown.toState, TradeState.notFound);
    });

    test("a refunded swap does not read as still pending", () {
      expect(SwapsXyzTxStatusValue.refunded.toState, isNot(TradeState.pending));
      expect(SwapsXyzTxStatusValue.expired.toState, isNot(TradeState.pending));
    });
  });

  group("requests", () {
    test("SwapsXyzPathsRequest serializes the query params as strings", () {
      final json = const SwapsXyzPathsRequest(
        srcChainId: "1",
        srcToken: "0x0",
        dstChainId: "137",
      ).toJson();

      expect(json, {"srcChainId": "1", "srcToken": "0x0", "dstChainId": "137"});
      expect(json.containsKey("dstToken"), isFalse);
      expect(json.containsKey("excludeBridgeIds"), isFalse);
    });

    test("SwapsXyzPathsRequest keeps the exclude lists as lists for repeated params", () {
      final json = const SwapsXyzPathsRequest(
        srcChainId: "1",
        srcToken: "0x0",
        excludeBridgeIds: ["across"],
        excludeDexIds: ["uniswap"],
      ).toJson();

      expect(json["excludeBridgeIds"], ["across"]);
      expect(json["excludeDexIds"], ["uniswap"]);
    });

    test("SwapsXyzQuoteRequest serializes the swap direction as its wire value", () {
      final json = const SwapsXyzQuoteRequest(
        srcChainId: "1",
        srcToken: "0x0",
        dstChainId: "1",
        dstToken: "0xdac",
        amount: "100000000000000000",
        swapDirection: SwapsXyzSwapDirection.exactAmountIn,
      ).toJson();

      expect(json["swapDirection"], "exact-amount-in");
      expect(json["amount"], "100000000000000000");
      expect(json.values.whereType<String>(), hasLength(json.length));
    });

    test("SwapsXyzActionRequest serializes the action type and the booleans as strings", () {
      final json = const SwapsXyzActionRequest(
        actionType: SwapsXyzActionType.swapAction,
        sender: "0xsender",
        srcChainId: "1",
        srcToken: "0x0",
        dstChainId: "1",
        dstToken: "0xdac",
        slippage: "300",
        amount: "100000000000000000",
        swapDirection: SwapsXyzSwapDirection.exactAmountIn,
        recipient: "0xrecipient",
        returnDepositAddress: false,
        gasless: true,
      ).toJson();

      expect(json["actionType"], "swap-action");
      expect(json["swapDirection"], "exact-amount-in");
      expect(json["returnDepositAddress"], "false");
      expect(json["gasless"], "true");
      expect(json.values.whereType<String>(), hasLength(json.length));
    });

    test("SwapsXyzTxRegistrationRequest carries the undocumented vmId and chainId too", () {
      final json = const SwapsXyzTxRegistrationRequest(
        txId: "0xtxid",
        txHash: "0xhash",
        vmId: "evm",
        chainId: 1,
      ).toJson();

      expect(json, {"txId": "0xtxid", "txHash": "0xhash", "vmId": "evm", "chainId": 1});
    });

    test("SwapsXyzStatusRequest can look up by txId or by hash and chain", () {
      expect(const SwapsXyzStatusRequest(txId: "0xtxid").toJson(), {"txId": "0xtxid"});
      expect(
        const SwapsXyzStatusRequest(txHash: "0xhash", chainId: "1").toJson(),
        {"txHash": "0xhash", "chainId": "1"},
      );
    });
  });

  group("SwapsXyzPathTokensConverter", () {
    const converter = SwapsXyzPathTokensConverter();

    test("reads the all form", () {
      final tokens = converter.fromJson("all");

      expect(tokens.isAll, isTrue);
      expect(tokens.tokens, isNull);
    });

    test("reads the list form", () {
      final tokens = converter.fromJson([
        {
          "chainId": 1,
          "address": "0x0",
          "name": "Ether",
          "symbol": "ETH",
          "decimals": 18,
          "isNative": true,
          "minAmount": "0.001",
          "maxAmount": null,
        },
      ]);

      expect(tokens.isAll, isFalse);
      expect(tokens.tokens, hasLength(1));
      expect(tokens.tokens!.first.symbol, "ETH");
      expect(tokens.tokens!.first.minAmount, "0.001");
      expect(tokens.tokens!.first.maxAmount, isNull);
    });

    test("writes each form back", () {
      expect(converter.toJson(const SwapsXyzPathTokens.all()), "all");
      expect(converter.toJson(const SwapsXyzPathTokens.list([])), isEmpty);
    });
  });

  group("SwapsXyzTimestampConverter", () {
    const converter = SwapsXyzTimestampConverter();

    test("reads unix seconds as a number", () {
      expect(
        converter.fromJson(1640995200),
        DateTime.fromMillisecondsSinceEpoch(1640995200 * 1000, isUtc: true),
      );
    });

    test("reads unix seconds as a string", () {
      expect(converter.fromJson("1640995200"), converter.fromJson(1640995200));
    });

    test("falls back to parsing an iso date", () {
      expect(converter.fromJson("2026-07-29T14:05:06.967Z"), DateTime.utc(2026, 7, 29, 14, 5, 6, 967));
    });

    test("round trips through seconds", () {
      expect(converter.toJson(converter.fromJson(1640995200)), 1640995200);
    });
  });

  group("SwapsXyzBigIntAmountConverter", () {
    const converter = SwapsXyzBigIntAmountConverter();

    test("reads a base unit string", () {
      expect(converter.fromJson("100000000000000000"), BigInt.parse("100000000000000000"));
    });

    test("keeps precision a double would lose", () {
      const huge = "123456789012345678901234567890";

      expect(converter.fromJson(huge), BigInt.parse(huge));
      expect(converter.toJson(BigInt.parse(huge)), huge);
    });
  });
}
