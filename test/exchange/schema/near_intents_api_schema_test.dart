import "package:cake_wallet/exchange/provider/near_intents/near_intents_api_schema.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:flutter_test/flutter_test.dart";

import "../fixture.dart";

BigInt? _bigInt(Object? raw) => raw == null ? null : BigInt.parse(raw.toString());

void main() {
  group("NearIntentsToken", () {
    test("parses every token in tokens", () {
      final raw = fixtureList("nearintents", "tokens");
      final tokens = raw.map((e) => NearIntentsToken.fromJson(e as Map<String, dynamic>)).toList();

      expect(tokens, hasLength(raw.length));
      expect(tokens, isNotEmpty);

      for (var i = 0; i < raw.length; i++) {
        final rawToken = raw[i] as Map<String, dynamic>;
        final token = tokens[i];

        expect(token.assetId, rawToken["assetId"]);
        expect(token.decimals, rawToken["decimals"]);
        expect(token.blockchain, rawToken["blockchain"]);
        expect(token.symbol, rawToken["symbol"]);
        expect(token.price, (rawToken["price"] as num).toDouble());
        expect(token.priceUpdatedAt, DateTime.parse(rawToken["priceUpdatedAt"] as String));
        expect(token.contractAddress, rawToken["contractAddress"]);
        expect(token.coingeckoId, rawToken["coingeckoId"]);
      }
    });

    test("a native coin has no contract address", () {
      final tokens = fixtureList("nearintents", "tokens")
          .map((e) => NearIntentsToken.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(tokens.where((t) => t.contractAddress == null), isNotEmpty);
    });

    test("price parses whether it arrives as an int or a double", () {
      final tokens = fixtureList("nearintents", "tokens")
          .map((e) => NearIntentsToken.fromJson(e as Map<String, dynamic>))
          .toList();

      for (final token in tokens) {
        expect(token.price, isA<double>());
      }
    });

    test("the blockchain list is wider than the spec's enum, which is why it stays a string", () {
      final chains = fixtureList("nearintents", "tokens")
          .map((e) => (e as Map<String, dynamic>)["blockchain"] as String)
          .toSet();

      expect(chains.length, greaterThan(30));
    });
  });

  group("NearIntentsQuoteResponse", () {
    for (final name in ["quote_dry", "quote_live"]) {
      test("parses $name field by field", () {
        final raw = fixtureMap("nearintents", name);
        final response = NearIntentsQuoteResponse.fromJson(raw);
        final rawQuote = raw["quote"] as Map<String, dynamic>;

        expect(response.correlationId, raw["correlationId"]);
        expect(response.timestamp, DateTime.parse(raw["timestamp"] as String));
        expect(response.signature, raw["signature"]);

        expect(response.quote.amountIn, _bigInt(rawQuote["amountIn"]));
        expect(response.quote.amountInFormatted, rawQuote["amountInFormatted"]);
        expect(response.quote.amountInUsd, rawQuote["amountInUsd"]);
        expect(response.quote.minAmountIn, _bigInt(rawQuote["minAmountIn"]));
        expect(response.quote.amountOut, _bigInt(rawQuote["amountOut"]));
        expect(response.quote.amountOutFormatted, rawQuote["amountOutFormatted"]);
        expect(response.quote.amountOutUsd, rawQuote["amountOutUsd"]);
        expect(response.quote.minAmountOut, _bigInt(rawQuote["minAmountOut"]));
        expect(response.quote.timeEstimate, rawQuote["timeEstimate"]);
        expect(response.quote.depositAddress, rawQuote["depositAddress"]);
        expect(response.quote.depositMemo, rawQuote["depositMemo"]);
        expect(response.quote.refundFee, _bigInt(rawQuote["refundFee"]));
        expect(response.quote.withdrawFee, _bigInt(rawQuote["withdrawFee"]));
        expect(
          response.quote.deadline,
          rawQuote["deadline"] == null
              ? isNull
              : DateTime.parse(rawQuote["deadline"] as String),
        );
        expect(
          response.quote.timeWhenInactive,
          rawQuote["timeWhenInactive"] == null
              ? isNull
              : DateTime.parse(rawQuote["timeWhenInactive"] as String),
        );
      });
    }

    test("the echoed request round trips back into typed enums", () {
      final raw = fixtureMap("nearintents", "quote_dry");
      final request = NearIntentsQuoteResponse.fromJson(raw).quoteRequest;
      final rawRequest = raw["quoteRequest"] as Map<String, dynamic>;

      expect(request.dry, rawRequest["dry"]);
      expect(request.swapType, NearIntentsSwapType.exactInput);
      expect(request.depositType, NearIntentsDepositType.originChain);
      expect(request.refundType, NearIntentsDepositType.originChain);
      expect(request.recipientType, NearIntentsRecipientType.destinationChain);
      expect(request.depositMode, NearIntentsDepositMode.simple);
      expect(request.slippageTolerance, rawRequest["slippageTolerance"]);
      expect(request.originAsset, rawRequest["originAsset"]);
      expect(request.destinationAsset, rawRequest["destinationAsset"]);
      expect(request.amount, _bigInt(rawRequest["amount"]));
      expect(request.refundTo, rawRequest["refundTo"]);
      expect(request.recipient, rawRequest["recipient"]);
      expect(request.deadline, DateTime.parse(rawRequest["deadline"] as String));
    });

    test("a dry quote has no deposit address, a live one does", () {
      final dry = NearIntentsQuoteResponse.fromJson(fixtureMap("nearintents", "quote_dry"));
      final live = NearIntentsQuoteResponse.fromJson(fixtureMap("nearintents", "quote_live"));

      expect(dry.quoteRequest.dry, isTrue);
      expect(dry.quote.depositAddress, isNull);
      expect(live.quoteRequest.dry, isFalse);
      expect(live.quote.depositAddress, isNotNull);
    });

    test("the formatted amounts agree with the base unit ones", () {
      final quote = NearIntentsQuoteResponse.fromJson(
        fixtureMap("nearintents", "quote_dry"),
      ).quote;
      final decimals = BigInt.from(10).pow(6);

      expect(
        double.parse(quote.amountInFormatted),
        closeTo(quote.amountIn / decimals, 0.000001),
        reason: "the origin asset in this fixture has six decimals",
      );
    });

    test("the minimum out is at or below the quoted out", () {
      final quote = NearIntentsQuoteResponse.fromJson(
        fixtureMap("nearintents", "quote_dry"),
      ).quote;

      expect(quote.minAmountOut <= quote.amountOut, isTrue);
    });
  });

  group("NearIntentsErrorResponse", () {
    test("parses the bad request body", () {
      final raw = fixtureMap("nearintents", "quote_bad_request");
      final error = NearIntentsErrorResponse.fromJson(raw);

      expect(error.message, raw["message"]);
      expect(error.message, isNotEmpty);
    });
  });

  group("NearIntentsStatusResponse", () {
    test("parses status field by field", () {
      final raw = fixtureMap("nearintents", "status");
      final response = NearIntentsStatusResponse.fromJson(raw);

      expect(response.correlationId, raw["correlationId"]);
      expect(response.updatedAt, DateTime.parse(raw["updatedAt"] as String));
      expect(response.status, isNot(NearIntentsStatus.unknown));
      expect(response.quoteResponse.quote.depositAddress, isNotNull);
    });

    test("parses the swap details, amounts and hashes included", () {
      final raw = fixtureMap("nearintents", "status");
      final rawDetails = raw["swapDetails"] as Map<String, dynamic>;
      final details = NearIntentsStatusResponse.fromJson(raw).swapDetails;

      expect(details.intentHashes, rawDetails["intentHashes"]);
      expect(details.nearTxHashes, rawDetails["nearTxHashes"]);
      expect(
        details.originChainTxHashes,
        hasLength((rawDetails["originChainTxHashes"] as List).length),
      );
      expect(
        details.destinationChainTxHashes,
        hasLength((rawDetails["destinationChainTxHashes"] as List).length),
      );
      expect(details.amountIn, _bigInt(rawDetails["amountIn"]));
      expect(details.amountInFormatted, rawDetails["amountInFormatted"]);
      expect(details.amountOut, _bigInt(rawDetails["amountOut"]));
      expect(details.amountOutFormatted, rawDetails["amountOutFormatted"]);
      expect(details.slippage, rawDetails["slippage"]);
      expect(details.depositedAmount, _bigInt(rawDetails["depositedAmount"]));
      expect(details.depositedAmountFormatted, rawDetails["depositedAmountFormatted"]);
      expect(details.refundedAmount, _bigInt(rawDetails["refundedAmount"]));
      expect(details.refundedAmountFormatted, rawDetails["refundedAmountFormatted"]);
      expect(details.refundedAmountUsd, rawDetails["refundedAmountUsd"]);
      expect(details.refundReason, rawDetails["refundReason"]);
      expect(details.withdrawFee, _bigInt(rawDetails["withdrawFee"]));
      expect(details.referral, rawDetails["referral"]);
    });

    test("nothing has been deposited, so the swap amounts are still null", () {
      final details = NearIntentsStatusResponse.fromJson(
        fixtureMap("nearintents", "status"),
      ).swapDetails;

      expect(details.depositedAmount, isNull);
      expect(details.amountIn, isNull);
      expect(details.originChainTxHashes, isEmpty);
    });

    test("the status chains off the deposit address the live quote allocated", () {
      final live = NearIntentsQuoteResponse.fromJson(fixtureMap("nearintents", "quote_live"));
      final status = NearIntentsStatusResponse.fromJson(fixtureMap("nearintents", "status"));

      expect(status.quoteResponse.quote.depositAddress, live.quote.depositAddress);
    });
  });

  group("StatusToState", () {
    test("maps every status to a trade state", () {
      expect(NearIntentsStatus.pendingDeposit.toState, TradeState.pending);
      expect(NearIntentsStatus.processing.toState, TradeState.processing);
      expect(NearIntentsStatus.success.toState, TradeState.success);
      expect(NearIntentsStatus.incompleteDeposit.toState, TradeState.underpaid);
      expect(NearIntentsStatus.refunded.toState, TradeState.refunded);
      expect(NearIntentsStatus.failed.toState, TradeState.failed);
    });

    test("the states with no mapping fall through to not found", () {
      expect(NearIntentsStatus.knownDepositTx.toState, TradeState.notFound);
      expect(NearIntentsStatus.unknown.toState, TradeState.notFound);
    });

    test("every enum value has a state, so the switch stays exhaustive", () {
      for (final status in NearIntentsStatus.values) {
        expect(status.toState, isA<TradeState>(), reason: status.name);
      }
    });
  });

  group("requests", () {
    NearIntentsQuoteRequest build({bool dry = true, NearIntentsDepositMode? mode}) =>
        NearIntentsQuoteRequest(
          dry: dry,
          swapType: NearIntentsSwapType.exactInput,
          slippageTolerance: 100,
          originAsset: "nep141:origin",
          depositType: NearIntentsDepositType.originChain,
          destinationAsset: "nep141:wrap.near",
          amount: BigInt.from(10000000),
          refundTo: "0xrefund",
          refundType: NearIntentsDepositType.originChain,
          recipient: "cakewallet.near",
          recipientType: NearIntentsRecipientType.destinationChain,
          deadline: DateTime.utc(2026, 7, 29, 16),
          depositMode: mode,
          appFees: const [NearIntentsAppFee(recipient: "cake.near", fee: 75)],
        );

    test("serializes the enums as their wire values", () {
      final json = build(mode: NearIntentsDepositMode.simple).toJson();

      expect(json["swapType"], "EXACT_INPUT");
      expect(json["depositType"], "ORIGIN_CHAIN");
      expect(json["refundType"], "ORIGIN_CHAIN");
      expect(json["recipientType"], "DESTINATION_CHAIN");
      expect(json["depositMode"], "SIMPLE");
    });

    test("serializes the amount as a string and the deadline as iso", () {
      final json = build().toJson();

      expect(json["amount"], "10000000");
      expect(json["deadline"], "2026-07-29T16:00:00.000Z");
      expect(json["dry"], isTrue);
      expect(json["slippageTolerance"], 100);
    });

    test("nests the app fees", () {
      final json = build().toJson();

      expect(json["appFees"], [
        {"recipient": "cake.near", "fee": 75},
      ]);
    });

    test("omits the optional keys that were not set", () {
      final json = build().toJson();

      for (final key in [
        "depositMode",
        "connectedWallets",
        "sessionId",
        "virtualChainRecipient",
        "customRecipientMsg",
        "confidentiality",
        "referral",
        "rebates",
        "quoteWaitingTimeMs",
        "insured",
      ]) {
        expect(json.containsKey(key), isFalse, reason: key);
      }
    });

    test("NearIntentsAppFee and NearIntentsRebate serialize their own keys", () {
      expect(
        const NearIntentsAppFee(recipient: "cake.near", fee: 75).toJson(),
        {"recipient": "cake.near", "fee": 75},
      );
      expect(
        const NearIntentsRebate(recipient: "rebate.near", share: 20).toJson(),
        {"recipient": "rebate.near", "share": 20},
      );
    });
  });
}
