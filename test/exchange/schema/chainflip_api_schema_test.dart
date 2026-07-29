import "package:cake_wallet/exchange/provider/chainflip/chainflip_api_schema.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "../fixture.dart";

DateTime _millis(Object raw) =>
    DateTime.fromMillisecondsSinceEpoch(int.parse(raw.toString()), isUtc: true);

void main() {
  group("ChainflipAssetsResponse", () {
    test("parses the assets it can map and skips the ones cake has no currency for", () {
      final raw = fixtureMap("chainflip", "assets");
      final response = ChainflipAssetsResponse.fromJson(raw);
      final rawAssets = raw["assets"] as List<dynamic>;

      expect(response.assets, isNotEmpty);
      expect(
        response.assets.length,
        lessThanOrEqualTo(rawAssets.length),
        reason: "an unmappable asset is dropped rather than throwing",
      );
    });

    test("parses each mapped asset field by field", () {
      final raw = fixtureMap("chainflip", "assets");
      final response = ChainflipAssetsResponse.fromJson(raw);
      final rawById = {
        for (final asset in raw["assets"] as List<dynamic>)
          (asset as Map<String, dynamic>)["id"] as String: asset,
      };
      const currencyConverter = ChainflipCurrencyConverter();

      for (final asset in response.assets) {
        final rawAsset = rawById[currencyConverter.toJson(asset.id)];

        expect(rawAsset, isNotNull, reason: "the id has to round trip back to its wire form");
        expect(asset.enabled, rawAsset!["enabled"]);
        expect(asset.ticker, rawAsset["ticker"]);
        expect(asset.name, rawAsset["name"]);
        expect(asset.contractAddress, rawAsset["contractAddress"]);
        expect(asset.networkLogo, rawAsset["networkLogo"]);
        expect(asset.assetLogo, rawAsset["assetLogo"]);
        expect(asset.decimals, rawAsset["decimals"]);
        expect(asset.minimalAmountNative, BigInt.parse(rawAsset["minimalAmountNative"] as String));
        expect(asset.usdPriceNative, BigInt.parse(rawAsset["usdPriceNative"] as String));
        expect(asset.platforms, rawAsset["platforms"]);
      }
    });
  });

  group("ChainflipFetchQuotesResponse", () {
    test("parses quotes_native field by field", () {
      final raw = fixtureList("chainflip", "quotes_native");
      final response = ChainflipFetchQuotesResponse.fromJson(raw);

      expect(response.quotes, hasLength(raw.length));

      for (var i = 0; i < raw.length; i++) {
        final rawQuote = raw[i] as Map<String, dynamic>;
        final quote = response.quotes[i];

        expect(quote.ingressAmountNative, BigInt.parse(rawQuote["ingressAmountNative"] as String));
        expect(quote.egressAmountNative, BigInt.parse(rawQuote["egressAmountNative"] as String));
        expect(
          quote.intermediateAmountNative,
          rawQuote["intermediateAmountNative"] == null
              ? isNull
              : BigInt.parse(rawQuote["intermediateAmountNative"] as String),
        );
        expect(
          quote.recommendedSlippageTolerancePercent,
          (rawQuote["recommendedSlippageTolerancePercent"] as num).toDouble(),
        );
        expect(quote.lowLiquidityWarning, rawQuote["lowLiquidityWarning"]);
        expect(quote.estimatedDurationSeconds, (rawQuote["estimatedDurationSeconds"] as num).toDouble());
        expect(quote.estimatedPrice, (rawQuote["estimatedPrice"] as num).toDouble());
        expect(quote.platform, rawQuote["platform"]);
        expect(quote.includedFees, hasLength((rawQuote["includedFees"] as List).length));
        expect(quote.poolInfo, hasLength((rawQuote["poolInfo"] as List).length));

        final rawDurations = rawQuote["estimatedDurationsSeconds"] as Map<String, dynamic>;
        expect(quote.estimatedDurationsSeconds.deposit, (rawDurations["deposit"] as num).toDouble());
        expect(quote.estimatedDurationsSeconds.swap, (rawDurations["swap"] as num).toDouble());
        expect(quote.estimatedDurationsSeconds.egress, (rawDurations["egress"] as num).toDouble());
      }
    });

    test("parses the fees, each with its own asset", () {
      final raw = fixtureList("chainflip", "quotes_native");
      final quote = ChainflipFetchQuotesResponse.fromJson(raw).quotes.first;
      final rawFees = (raw.first as Map<String, dynamic>)["includedFees"] as List<dynamic>;

      for (var i = 0; i < rawFees.length; i++) {
        final rawFee = rawFees[i] as Map<String, dynamic>;

        expect(quote.includedFees[i].amountNative, BigInt.parse(rawFee["amountNative"] as String));
        expect(quote.includedFees[i].type, isNot(ChainflipFeeType.unknown));
      }
    });

    test("the assets round trip through the currency converter", () {
      const converter = ChainflipCurrencyConverter();
      final raw = fixtureList("chainflip", "quotes_native");
      final rawQuote = raw.first as Map<String, dynamic>;
      final quote = ChainflipFetchQuotesResponse.fromJson(raw).quotes.first;

      expect(converter.toJson(quote.ingressAsset), rawQuote["ingressAsset"]);
      expect(converter.toJson(quote.egressAsset), rawQuote["egressAsset"]);
    });

    test("a bad amount answers with a problem document, not a quote list", () {
      final raw = fixtureMap("chainflip", "quotes_native_bad_amount");

      expect(raw["status"], 400);
      expect(raw["detail"], isNotNull);
      expect(raw["errors"]["minimalAmountNative"], isNotNull);
      // there is no error class for this api, so the caller has to check the status code
    });
  });

  group("ChainflipSwapResponse", () {
    test("parses swap field by field", () {
      final raw = fixtureMap("chainflip", "swap");
      final swap = ChainflipSwapResponse.fromJson(raw);

      expect(swap.id, raw["id"]);
      expect(swap.address, raw["address"]);
      expect(swap.issuedBlock, raw["issuedBlock"]);
      expect(swap.network, ChainflipNetwork.ethereum);
      expect(swap.channelId, raw["channelId"]);
      expect(swap.sourceExpiryBlock, raw["sourceExpiryBlock"]);
      expect(swap.explorerUrl, raw["explorerUrl"]);
      expect(
        swap.channelOpeningFeeNative,
        BigInt.parse(raw["channelOpeningFeeNative"].toString()),
      );
    });

    test("the swap carries everything the status lookup needs", () {
      final swap = ChainflipSwapResponse.fromJson(fixtureMap("chainflip", "swap"));
      final status = ChainflipStatusResponse.fromJson(
        fixtureMap("chainflip", "status_by_deposit_channel"),
      );

      expect(swap.issuedBlock, isPositive);
      expect(swap.channelId, isPositive);
      expect(status.status.depositChannel, isNotNull);
    });
  });

  group("ChainflipStatusResponse", () {
    test("parses status_by_deposit_channel field by field", () {
      final raw = fixtureMap("chainflip", "status_by_deposit_channel");
      final response = ChainflipStatusResponse.fromJson(raw);
      final rawStatus = raw["status"] as Map<String, dynamic>;
      final status = response.status;
      const converter = ChainflipCurrencyConverter();

      expect(response.id, raw["id"]);
      expect(status.state, TradeState.waiting);
      expect(converter.toJson(status.sourceAsset), rawStatus["sourceAsset"]);
      expect(converter.toJson(status.destinationAsset), rawStatus["destinationAsset"]);
      expect(status.destinationAddress, rawStatus["destinationAddress"]);
      expect(status.swapId, rawStatus["swapId"]);
      expect(
        status.estimatedDurationSeconds,
        (rawStatus["estimatedDurationSeconds"] as num).toDouble(),
      );
      expect(
        status.sourceChainRequiredBlockConfirmations,
        rawStatus["sourceChainRequiredBlockConfirmations"],
      );
      expect(status.lastStateChainUpdateAt, _millis(rawStatus["lastStateChainUpdateAt"] as Object));
      expect(status.fees, hasLength((rawStatus["fees"] as List).length));
      expect(status.deposit, isNull, reason: "nothing has been deposited yet");
      expect(status.swapEgress, isNull);
      expect(status.refundEgress, isNull);
    });

    test("parses the deposit channel", () {
      final raw = fixtureMap("chainflip", "status_by_deposit_channel");
      final rawChannel = raw["status"]["depositChannel"] as Map<String, dynamic>;
      final channel = ChainflipStatusResponse.fromJson(raw).status.depositChannel!;

      expect(channel.id, rawChannel["id"]);
      expect(channel.createdAt, _millis(rawChannel["createdAt"] as Object));
      expect(channel.brokerCommissionBps, rawChannel["brokerCommissionBps"]);
      expect(channel.depositAddress, rawChannel["depositAddress"]);
      expect(
        channel.sourceChainExpiryBlock,
        BigInt.parse(rawChannel["sourceChainExpiryBlock"].toString()),
      );
      expect(channel.estimatedExpiryTime, _millis(rawChannel["estimatedExpiryTime"] as Object));
      expect(channel.isExpired, rawChannel["isExpired"]);
      expect(channel.openedThroughBackend, rawChannel["openedThroughBackend"]);
      expect(channel.affiliateBrokers, hasLength((rawChannel["affiliateBrokers"] as List).length));
    });

    test("the deposit address is where the user sends funds", () {
      final status = ChainflipStatusResponse.fromJson(
        fixtureMap("chainflip", "status_by_deposit_channel"),
      );

      expect(status.status.depositChannel!.depositAddress, isNotEmpty);
      expect(status.status.depositChannel!.isExpired, isFalse);
    });
  });

  group("ChainflipCurrencyConverter", () {
    const converter = ChainflipCurrencyConverter();

    test("writes a native coin as title.title", () {
      expect(converter.toJson(CryptoCurrency.btc), "btc.btc");
      expect(converter.toJson(CryptoCurrency.eth), "eth.eth");
    });

    test("writes a token as title.tag", () {
      expect(converter.toJson(CryptoCurrency.usdterc20), "usdt.eth");
    });

    test("keeps the tron special cases", () {
      expect(converter.toJson(CryptoCurrency.trx), "trx.tron");
      expect(converter.toJson(CryptoCurrency.usdttrc20), "usdt.tron");
      expect(converter.fromJson("trx.tron"), CryptoCurrency.trx);
      expect(converter.fromJson("usdt.tron"), CryptoCurrency.usdttrc20);
    });

    test("reads a native coin back", () {
      expect(converter.fromJson("btc.btc"), CryptoCurrency.btc);
      expect(converter.fromJson("eth.eth"), CryptoCurrency.eth);
    });

    test("round trips the assets in the fixtures", () {
      for (final wire in ["btc.btc", "eth.eth", "usdt.eth", "trx.tron"]) {
        expect(converter.toJson(converter.fromJson(wire)), wire);
      }
    });

    test("rejects an input that is not chain qualified", () {
      expect(() => converter.fromJson("btc"), throwsA(isA<ArgumentError>()));
      expect(() => converter.fromJson("a.b.c"), throwsA(isA<ArgumentError>()));
    });

    test("throws on an asset cake has no currency for", () {
      expect(() => converter.fromJson("nosuchcoin.nosuchchain"), throwsA(isA<ArgumentError>()));
    });
  });

  group("ChainflipTradeStateConverter", () {
    const converter = ChainflipTradeStateConverter();

    test("maps every state chainflip reports", () {
      expect(converter.fromJson("waiting"), TradeState.waiting);
      expect(converter.fromJson("receiving"), TradeState.processing);
      expect(converter.fromJson("swapping"), TradeState.processing);
      expect(converter.fromJson("sending"), TradeState.processing);
      expect(converter.fromJson("sent"), TradeState.processing);
      expect(converter.fromJson("completed"), TradeState.success);
      expect(converter.fromJson("failed"), TradeState.failed);
    });

    test("an unrecognised state becomes not found", () {
      expect(converter.fromJson("something new"), TradeState.notFound);
    });

    test("writes the states it knows back", () {
      expect(converter.toJson(TradeState.waiting), "waiting");
      expect(converter.toJson(TradeState.processing), "processing");
      expect(converter.toJson(TradeState.success), "completed");
      expect(converter.toJson(TradeState.failed), "failed");
      expect(converter.toJson(TradeState.expired), "unknown");
    });
  });

  group("requests", () {
    test("ChainflipFetchQuotesRequest stringifies the amount for the query", () {
      final json = ChainflipFetchQuotesRequest(
        apiKey: "key",
        sourceAsset: CryptoCurrency.btc,
        destinationAsset: CryptoCurrency.eth,
        amount: BigInt.from(10000000),
        commissionBps: "175",
      ).toJson();

      expect(json, {
        "apiKey": "key",
        "sourceAsset": "btc.btc",
        "destinationAsset": "eth.eth",
        "amount": "10000000",
        "commissionBps": "175",
      });
      expect(json.values.whereType<String>(), hasLength(json.length));
    });

    test("ChainflipSwapRequest serializes the channel parameters", () {
      final json = const ChainflipSwapRequest(
        apiKey: "key",
        sourceAsset: CryptoCurrency.eth,
        destinationAsset: CryptoCurrency.usdterc20,
        destinationAddress: "0xpayout",
        commissionBps: "175",
        minimumPrice: "0",
        refundAddress: "0xrefund",
        retryDurationInBlocks: 100,
      ).toJson();

      expect(json["sourceAsset"], "eth.eth");
      expect(json["destinationAsset"], "usdt.eth");
      expect(json["destinationAddress"], "0xpayout");
      expect(json["refundAddress"], "0xrefund");
      expect(json["retryDurationInBlocks"], 100);
      expect(json.containsKey("boostFee"), isFalse);
      expect(json.containsKey("numberOfChunks"), isFalse);
    });

    test("ChainflipStatusRequest serializes the composite channel id", () {
      final json = const ChainflipStatusRequest(
        apiKey: "key",
        issuedBlock: 14138313,
        network: ChainflipNetwork.ethereum,
        channelId: 13128,
      ).toJson();

      expect(json["apiKey"], "key");
      expect(json["issuedBlock"], 14138313);
      expect(json["network"], "Ethereum");
      expect(json["channelId"], 13128);
    });
  });
}
