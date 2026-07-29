import "dart:convert";

import "package:cake_wallet/exchange/provider/chainflip/chainflip_api_schema.dart";
import "package:cake_wallet/exchange/provider/changenow/changenow_api_schema.dart";
import "package:cake_wallet/exchange/provider/exolix/exolix_api_schema.dart";
import "package:cake_wallet/exchange/provider/jupiter/jupiter_api_schema.dart";
import "package:cake_wallet/exchange/provider/letsexchange/letsexchange_api_schema.dart";
import "package:cake_wallet/exchange/provider/near_intents/near_intents_api_schema.dart";
import "package:cake_wallet/exchange/provider/stealthex/stealthex_api_schema.dart";
import "package:cake_wallet/exchange/provider/swapsxyz/swapsxyz_api_schema.dart";
import "package:cake_wallet/exchange/provider/swaptrade/swaptrade_api_schema.dart";
import "package:cake_wallet/exchange/provider/trocador/trocador_api_schema.dart";
import "package:cake_wallet/exchange/provider/xoswap/xoswap_api_schema.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "canned_responses.dart";

/// Checks the mocked api bodies against the generated schemas, and the arithmetic the
/// provider suite's expectations are built on.
///
/// This is the half of the provider suite that can run without the app: it catches a body
/// that no longer matches its schema, and an expected rate or limit that does not follow
/// from the numbers in the body.
Map<String, dynamic> _map(String body) => json.decode(body) as Map<String, dynamic>;

List<dynamic> _list(String body) => json.decode(body) as List<dynamic>;

void main() {
  group("ChangeNOW", () {
    test("the range body gives 0.001 - 20 btc", () {
      final range = ChangeNowRangeResponse.fromJson(_map(changeNowRange));

      expect(Money.parse(range.minAmount, CryptoCurrency.btc), Money.parse("0.001", CryptoCurrency.btc));
      expect(Money.parse(range.maxAmount, CryptoCurrency.btc), Money.parse("20", CryptoCurrency.btc));
    });

    test("2 btc for 500 xmr prices one btc at 250 xmr", () {
      final estimate = ChangeNowEstimatedAmountResponse.fromJson(_map(changeNowEstimatedAmount));
      final rate = ExchangeRate.fromAmounts(
        Money.parse(estimate.fromAmount, CryptoCurrency.btc),
        Money.parse(estimate.toAmount, CryptoCurrency.xmr),
      );

      expect(rate.quote, Money.parse("250", CryptoCurrency.xmr));
    });

    test("the create body carries the id and the deposit address", () {
      final created = ChangeNowCreateExchangeResponse.fromJson(_map(changeNowCreateExchange));

      expect(created.id, changeNowTradeId);
      expect(created.payinAddress, changeNowPayinAddress);
      expect(created.payinExtraId, isNull);
    });

    test("the by-id body is mid-swap with both amounts filled in", () {
      final transaction = ChangeNowTransactionResponse.fromJson(_map(changeNowById));

      expect(transaction.status, TradeState.confirming);
      expect(Money.parse(transaction.amountFrom, CryptoCurrency.btc), Money.parse("2", CryptoCurrency.btc));
      expect(Money.parse(transaction.amountTo, CryptoCurrency.xmr), Money.parse("500", CryptoCurrency.xmr));
      expect(transaction.payoutHash, "cn-payout-hash");
      expect(transaction.validUntil, DateTime.parse(changeNowValidUntil));
    });

    test("the not found body parses as an error", () {
      expect(ChangeNowErrorResponse.fromJson(_map(changeNowNotFound)).error, "not_found");
    });
  });

  group("Exolix", () {
    test("both rate bodies report the same 0.001 - 20 btc window", () {
      for (final body in [exolixUnitRate, exolixRate]) {
        final rate = ExolixRateResponse.fromJson(_map(body));

        expect(Money.parse(rate.minAmount, CryptoCurrency.btc), Money.parse("0.001", CryptoCurrency.btc));
        expect(Money.parse(rate.maxAmount, CryptoCurrency.btc), Money.parse("20", CryptoCurrency.btc));
      }
    });

    test("the priced rate body is 2 btc for 500 xmr", () {
      final rate = ExolixRateResponse.fromJson(_map(exolixRate));

      expect(
        ExchangeRate.fromAmounts(
          Money.parse(rate.fromAmount, CryptoCurrency.btc),
          Money.parse(rate.toAmount, CryptoCurrency.xmr),
        ).quote,
        Money.parse("250", CryptoCurrency.xmr),
      );
    });

    test("the transaction body is mid-swap on the btc/xmr pair", () {
      final transaction = ExolixTransactionResponse.fromJson(_map(exolixTransaction));

      expect(transaction.id, exolixTradeId);
      expect(transaction.status, TradeState.confirmation);
      expect(transaction.coinFrom.coinCode, "BTC");
      expect(transaction.coinFrom.network, "BTC");
      expect(transaction.coinTo.coinCode, "XMR");
      expect(Money.parse(transaction.amount, CryptoCurrency.btc), Money.parse("2", CryptoCurrency.btc));
      expect(Money.parse(transaction.amountTo, CryptoCurrency.xmr), Money.parse("500", CryptoCurrency.xmr));
      expect(transaction.depositAddress, exolixDepositAddress);
      expect(transaction.hashOut.hash, "exolix-hash-out");
    });
  });

  group("StealthEX", () {
    test("the range body gives 0.001 - 20", () {
      final range = StealthExRange.fromJson(_map(stealthExRange));

      expect(range.minAmount, 0.001);
      expect(range.maxAmount, 20);
    });

    test("the estimate is 500", () {
      expect(StealthExEstimate.fromJson(_map(stealthExEstimatedAmount)).estimatedAmount, 500);
      expect(StealthExEstimate.fromJson(_map(stealthExEstimatedAmount)).rate, isNull);
    });

    test("the exchange body is a waiting btc/xmr swap", () {
      final exchange = StealthExExchange.fromJson(_map(stealthExExchange));

      expect(exchange.id, stealthExTradeId);
      expect(exchange.status, TradeState.waiting);
      expect(exchange.deposit.symbol, "btc");
      expect(exchange.deposit.network, "mainnet");
      expect(exchange.deposit.address, stealthExDepositAddress);
      expect(Money.parse(exchange.deposit.amount, CryptoCurrency.btc), Money.parse("2", CryptoCurrency.btc));
      expect(exchange.withdrawal.symbol, "xmr");
      expect(Money.parse(exchange.withdrawal.amount, CryptoCurrency.xmr), Money.parse("500", CryptoCurrency.xmr));
      expect(exchange.createdAt, DateTime.parse(stealthExCreatedAt));
      expect(exchange.expiresAt, isNull);
    });

    test("the not found body parses as an error", () {
      expect(
        StealthExErrorResponse.fromJson(_map(stealthExNotFound)).err.kind,
        StealthExErrorKind.notFound,
      );
    });
  });

  group("LetsExchange", () {
    test("the info body gives 10 - 50000 usdt and a rate id", () {
      final info = LetsExchangeInfoResponse.fromJson(_map(letsExchangeInfo));

      expect(Money.parse(info.minAmount, CryptoCurrency.usdterc20), Money.parse("10", CryptoCurrency.usdterc20));
      expect(Money.parse(info.maxAmount, CryptoCurrency.usdterc20), Money.parse("50000", CryptoCurrency.usdterc20));
      expect(info.rateId, "le-rate-1");
    });

    test("100 usdt for 99 usdc prices one usdt at 0.99 usdc", () {
      final info = LetsExchangeInfoResponse.fromJson(_map(letsExchangeInfo));
      final rate = ExchangeRate.fromAmounts(
        Money.parse("100", CryptoCurrency.usdterc20),
        Money.parse(info.amount, CryptoCurrency.usdc),
      );

      expect(rate.quote, Money.parse("0.99", CryptoCurrency.usdc));
      expect(
        rate.convert(Money.parse("100", CryptoCurrency.usdterc20)),
        Money.parse("99", CryptoCurrency.usdc),
      );
    });

    test("the transaction body keeps the amounts apart from the addresses", () {
      final transaction = LetsExchangeTransactionResponse.fromJson(_map(letsExchangeTransaction));

      expect(transaction.transactionId, letsExchangeTradeId);
      expect(transaction.status, TradeState.wait);
      expect(transaction.depositAmount, "100");
      expect(transaction.withdrawalAmount, "99");
      expect(transaction.deposit, letsExchangeDepositAddress);
      expect(transaction.withdrawal, payoutAddress);
      expect(transaction.returnAddress, refundAddress);
      expect(transaction.coinFromNetwork, "ERC20");
      expect(transaction.coinToNetwork, "ERC20");
      expect(transaction.createdAt, DateTime.parse(letsExchangeCreatedAt));
      expect(
        transaction.expiredAt,
        DateTime.fromMillisecondsSinceEpoch(letsExchangeExpiredAtSeconds * 1000),
      );
    });
  });

  group("Trocador", () {
    test("the coin body gives 0.001 - 20 btc", () {
      final coins = _list(trocadorCoin)
          .map((item) => TrocadorCoin.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(coins, hasLength(1));
      expect(Money.tryParse(coins.first.minimum, CryptoCurrency.btc), Money.parse("0.001", CryptoCurrency.btc));
      expect(Money.tryParse(coins.first.maximum, CryptoCurrency.btc), Money.parse("20", CryptoCurrency.btc));
    });

    test("the rate body quotes 2 btc for 500 xmr through two sub-providers", () {
      final rate = TrocadorRate.fromJson(_map(trocadorNewRate));

      expect(rate.tradeId, "tr-rate-1");
      expect(rate.quotes?.quotes?.map((quote) => quote.provider), ["ChangeNow", "Exolix"]);
      expect(
        ExchangeRate.fromAmounts(
          Money.parse(rate.amountFrom, CryptoCurrency.btc),
          Money.parse(rate.amountTo, CryptoCurrency.xmr),
        ).quote,
        Money.parse("250", CryptoCurrency.xmr),
      );
    });

    test("the trade body is a waiting btc/xmr swap with a password", () {
      final trade = TrocadorTrade.fromJson(_map(trocadorTrade));

      expect(trade.tradeId, trocadorTradeId);
      expect(trade.status, TradeState.waiting);
      expect(trade.networkFrom, "Mainnet");
      expect(trade.networkTo, "Mainnet");
      expect(trade.addressProvider, trocadorAddressProvider);
      expect(trade.addressUser, payoutAddress);
      expect(trade.refundAddress, refundAddress);
      expect(trade.addressProviderMemo, "tr-memo");
      expect(trade.password, "tr-password");
      expect(trade.idProvider, "tr-provider-id");
      expect(trade.date, DateTime.parse(trocadorDate));
      expect(Money.parse(trade.amountFrom, CryptoCurrency.btc), Money.parse("2", CryptoCurrency.btc));
      expect(Money.parse(trade.amountTo, CryptoCurrency.xmr), Money.parse("500", CryptoCurrency.xmr));
    });
  });

  group("SwapTrade", () {
    test("the coins body gives 0.001 - 20 for btc", () {
      final coins = SwapTradeCoinsResponse.fromJson(_map(swapTradeCoins));
      final btc = coins.data!.firstWhere((coin) => coin.id == "BTC");

      expect(coins.success, isTrue);
      expect(Money.tryParse(btc.min, CryptoCurrency.btc), Money.parse("0.001", CryptoCurrency.btc));
      expect(Money.tryParse(btc.max, CryptoCurrency.btc), Money.parse("20", CryptoCurrency.btc));
      expect(btc.network, ["BTC"]);
    });

    test("the rate body is a unit price, not an output amount", () {
      final rate = SwapTradeRateResponse.fromJson(_map(swapTradeRate));

      expect(rate.data!.symbol, "BTCXMR");
      expect(Money.parse(rate.data!.price, CryptoCurrency.xmr), Money.parse("250", CryptoCurrency.xmr));
    });

    test("the create body only answers with the id, address and output amount", () {
      final created = SwapTradeCreateOrderResponse.fromJson(_map(swapTradeCreateOrder));

      expect(created.success, isTrue);
      expect(created.data!.orderId, swapTradeTradeId);
      expect(created.data!.serverAddress, swapTradeServerAddress);
      expect(
        Money.parse(created.data!.amountReceive, CryptoCurrency.xmr),
        Money.parse("500", CryptoCurrency.xmr),
      );
    });

    test("the order body's numeric status is a swap in flight", () {
      final order = SwapTradeOrderResponse.fromJson(_map(swapTradeOrder));

      expect(order.data!.orderId, swapTradeTradeId);
      expect(order.data!.status, TradeState.exchanging);
      expect(order.data!.coinSend, "BTC");
      expect(order.data!.coinReceive, "XMR");
      expect(Money.parse(order.data!.amountSend, CryptoCurrency.btc), Money.parse("2", CryptoCurrency.btc));
      expect(
        Money.parse(order.data!.amountReceive, CryptoCurrency.xmr),
        Money.parse("500", CryptoCurrency.xmr),
      );
      expect(order.data!.memo, "st-memo");
      expect(order.data!.recipient, payoutAddress);
      expect(order.data!.createdAt, DateTime.parse(swapTradeCreatedAt));
    });

    test("the error body reports success false", () {
      expect(SwapTradeOrderResponse.fromJson(_map(swapTradeOrderNotFound)).success, isFalse);
    });
  });

  group("XOSwap", () {
    test("the widest window across the two makers is 0.001 - 10 btc", () {
      final rates = _list(xoSwapPairRates)
          .map((item) => XOSwapRate.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(rates, hasLength(2));
      expect(rates.map((rate) => rate.min.value).reduce((a, b) => a < b ? a : b), 0.001);
      expect(rates.map((rate) => rate.max.value).reduce((a, b) => a > b ? a : b), 10);
    });

    test("2 btc takes the better maker and prices one btc at 250 xmr", () {
      final rates = _list(xoSwapPairRates)
          .map((item) => XOSwapRate.fromJson(item as Map<String, dynamic>))
          .toList();
      const amount = 2.0;
      var best = 0.0;

      for (final rate in rates) {
        if (amount >= rate.min.value && amount <= rate.max.value) {
          final output = (amount * rate.amount.value) - rate.minerFee.value;
          if (output > best) {
            best = output;
          }
        }
      }

      expect(best, 500);
      expect(best / amount, 250);
    });

    test("the order body is an in-progress btc/xmr order", () {
      final order = XOSwapOrder.fromJson(_map(xoSwapOrder));

      expect(order.id, xoSwapTradeId);
      expect(order.pairId, "BTC_XMR");
      expect(order.status, TradeState.processing);
      // both amounts arrive as strings on this endpoint and as numbers on the rates one
      expect(Money.parse(order.amount.value, CryptoCurrency.btc), Money.parse("2", CryptoCurrency.btc));
      expect(Money.parse(order.toAmount!.value, CryptoCurrency.xmr), Money.parse("500", CryptoCurrency.xmr));
      expect(order.payInAddress, xoSwapPayInAddress);
      expect(order.fromAddress, refundAddress);
      expect(order.toAddress, payoutAddress);
      expect(order.payInAddressTag, isNull);
      expect(order.createdAt, DateTime.parse(xoSwapCreatedAt));
    });

    test("the not found body carries the code the provider checks", () {
      expect(XOSwapErrorResponse.fromJson(_map(xoSwapNotFound)).code, "NOT_FOUND");
    });
  });

  group("Chainflip", () {
    test("the assets body floors btc at 0.001 with no ceiling", () {
      final assets = ChainflipAssetsResponse.fromJson(_map(chainflipAssets));
      final btc = assets.assets.firstWhere((asset) => asset.id == CryptoCurrency.btc);

      expect(Money(btc.minimalAmountNative, CryptoCurrency.btc), Money.parse("0.001", CryptoCurrency.btc));
    });

    test("the best of the two quotes pays 60 eth, so one btc is 30 eth", () {
      final quotes = ChainflipFetchQuotesResponse.fromJson(_list(chainflipQuotes));
      final best = quotes.quotes.reduce((a, b) => a.compareTo(b) > 0 ? a : b);

      expect(Money(best.egressAmountNative, CryptoCurrency.eth), Money.parse("60", CryptoCurrency.eth));
      expect(
        ExchangeRate.fromAmounts(
          Money.parse("2", CryptoCurrency.btc),
          Money(best.egressAmountNative, CryptoCurrency.eth),
        ).quote,
        Money.parse("30", CryptoCurrency.eth),
      );
      expect(best.numberOfChunks, 1);
      expect(best.chunkIntervalBlocks, 2);
    });

    test("the swap body's parts make the trade id findTradeById parses back", () {
      final swap = ChainflipSwapResponse.fromJson(_map(chainflipSwap));

      expect(swap.address, chainflipDepositAddress);
      expect("${swap.issuedBlock}-${swap.network.name}-${swap.channelId}", chainflipTradeId);
    });

    test("the status body is a swap in flight with both legs", () {
      final status = ChainflipStatusResponse.fromJson(_map(chainflipStatus)).status;

      expect(status.state, TradeState.processing);
      expect(status.sourceAsset, CryptoCurrency.btc);
      expect(status.destinationAsset, CryptoCurrency.eth);
      expect(status.destinationAddress, payoutAddress);
      expect(status.depositChannel!.depositAddress, chainflipDepositAddress);
      expect(Money(status.deposit!.amountNative, CryptoCurrency.btc), Money.parse("2", CryptoCurrency.btc));
      expect(
        Money(status.swapEgress!.amountNative, CryptoCurrency.eth),
        Money.parse("60", CryptoCurrency.eth),
      );
      expect(status.swapEgress!.transactionReference, "cf-egress-tx");
      expect(status.refundEgress, isNull);
    });
  });

  group("Near Intents", () {
    test("the token list has the two native assets the pair needs", () {
      final tokens = _list(nearTokens)
          .map((item) => NearIntentsToken.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(tokens.map((token) => token.symbol), ["BTC", "ZEC"]);
      expect(tokens.map((token) => token.blockchain), ["btc", "zec"]);
      expect(tokens.every((token) => token.contractAddress == null), isTrue);
    });

    test("the dry quote prices the pair but reserves no address", () {
      final quote = NearIntentsQuoteResponse.fromJson(_map(nearDryQuote)).quote;

      expect(quote.depositAddress, isNull);
      expect(
        ExchangeRate.fromAmounts(
          Money(quote.amountIn, CryptoCurrency.btc),
          Money(quote.amountOut, CryptoCurrency.zec),
        ).quote,
        Money.parse("250", CryptoCurrency.zec),
      );
    });

    test("the live quote reserves the address that becomes the trade id", () {
      final response = NearIntentsQuoteResponse.fromJson(_map(nearLiveQuote));

      expect(response.quote.depositAddress, nearDepositAddress);
      expect(response.quote.depositMemo, isNull);
      expect(response.quote.amountInFormatted, "2");
      expect(response.quote.amountOutFormatted, "500");
      expect(response.quoteRequest.recipient, payoutAddress);
      expect(response.quoteRequest.refundTo, refundAddress);
      expect(response.quoteRequest.originAsset, nearBtcAsset);
      expect(response.quoteRequest.destinationAsset, nearZecAsset);
    });

    test("the status body is processing with the origin tx hash", () {
      final status = NearIntentsStatusResponse.fromJson(_map(nearStatus));

      expect(status.status, NearIntentsStatus.processing);
      expect(status.status.toState, TradeState.processing);
      expect(status.swapDetails.originChainTxHashes.single.hash, "near-origin-tx");
      expect(status.quoteResponse.quote.depositAddress, nearDepositAddress);
      expect(status.quoteResponse.quoteRequest.originAsset, nearBtcAsset);
    });
  });

  group("Swaps.XYZ", () {
    test("the chain list has the ethereum mainnet entry", () {
      final chains = _list(swapsXyzChainList)
          .map((item) => SwapsXyzChain.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(chains.single.chainId, 1);
      expect(chains.single.name, "Ethereum");
      expect(chains.single.vmId, SwapsXyzVmId.evm);
    });

    test("the token paths body carries the usdt address the provider caches", () {
      final paths = SwapsXyzPathsResponse.fromJson(_map(swapsXyzTokenPaths));

      expect(paths.srcToken.symbol, "ETH");
      expect(paths.srcToken.isNative, isTrue);
      expect(paths.paths.single.tokens.tokens!.single.symbol, "USDT");
      expect(paths.paths.single.tokens.tokens!.single.address, swapsXyzUsdtAddress);
    });

    test("the pair paths body gives 0.01 - 100 eth", () {
      final paths = SwapsXyzPathsResponse.fromJson(_map(swapsXyzPairPaths));
      final limits = paths.paths.single.amountLimits!;

      expect(paths.paths.single.tokens.isAll, isTrue);
      expect(paths.paths.single.supportsExactAmountIn, isTrue);
      expect(paths.paths.single.supportsExactAmountOut, isFalse);
      expect(Money.tryParse(limits.minAmount, CryptoCurrency.eth), Money.parse("0.01", CryptoCurrency.eth));
      expect(Money.tryParse(limits.maxAmount, CryptoCurrency.eth), Money.parse("100", CryptoCurrency.eth));
    });

    test("the quote prices one eth at 2000 usdt, matching its own amounts", () {
      final quote = SwapsXyzQuote.fromJson(_map(swapsXyzQuote));

      expect(Money.parse(quote.exchangeRate, CryptoCurrency.usdterc20), Money.parse("2000", CryptoCurrency.usdterc20));
      expect(Money(quote.amountIn.amount, CryptoCurrency.eth), Money.parse("2", CryptoCurrency.eth));
      expect(
        Money(quote.amountOut.amount, CryptoCurrency.usdterc20),
        Money.parse("4000", CryptoCurrency.usdterc20),
      );
    });

    test("the action body is a swapAndExecute call on the router", () {
      final action = SwapsXyzActionResponse.fromJson(_map(swapsXyzAction));

      expect(action.txId, swapsXyzTxId);
      expect(action.vmId, SwapsXyzVmId.evm);
      expect(action.evmTx.to, swapsXyzRouter);
      expect(action.evmTx.data.substring(0, 10), "0x9be111d1");
      expect(action.evmTx.value, swapsXyzTxValue);
      expect(action.evmTx.chainId, 1);
      expect(action.amountIn.address, swapsXyzNativeAddress);
      expect(action.amountIn.decimals, 18);
      expect(action.requiresTokenApproval, isFalse);
      expect(action.bridgeIds, isEmpty);
    });

    test("the status body is pending with both legs", () {
      final status = SwapsXyzTxDetails.fromJson(_map(swapsXyzStatus));

      expect(status.status, SwapsXyzTxStatusValue.pending);
      expect(status.status.toState, TradeState.pending);
      expect(status.txId, swapsXyzTxId);
      expect(status.sender, refundAddress);
      expect(status.srcTx!.toAddress, swapsXyzRouter);
      expect(status.srcTx!.txHash, "0xswapsxyzsrctx");
      expect(
        status.srcTx!.timestamp,
        DateTime.fromMillisecondsSinceEpoch(swapsXyzTimestamp * 1000, isUtc: true),
      );
      expect(
        Money(status.srcTx!.paymentToken!.amount, CryptoCurrency.eth),
        Money.parse("2", CryptoCurrency.eth),
      );
      expect(status.dstTx!.toAddress, payoutAddress);
      expect(
        Money(status.dstTx!.paymentToken!.amount, CryptoCurrency.usdterc20),
        Money.parse("4000", CryptoCurrency.usdterc20),
      );
    });

    test("the not found body parses as an error envelope", () {
      final error = SwapsXyzErrorResponse.fromJson(_map(swapsXyzNotFound));

      expect(error.success, isFalse);
      expect(error.error!.code, "NOT_FOUND");
    });
  });

  group("Jupiter", () {
    test("the quote-only order prices 2 sol at 400 usdc, so one sol is 200", () {
      final order = JupiterOrder.fromJson(_map(jupiterOrder(withTaker: false)));

      expect(order.taker, isNull);
      expect(order.transaction, isNull);
      expect(Money(order.inAmount, CryptoCurrency.sol), Money.parse("2", CryptoCurrency.sol));
      expect(
        Money(order.outAmount, CryptoCurrency.usdcsol),
        Money.parse("400", CryptoCurrency.usdcsol),
      );
      expect(
        ExchangeRate.fromAmounts(
          Money(order.inAmount, CryptoCurrency.sol),
          Money(order.outAmount, CryptoCurrency.usdcsol),
        ).quote,
        Money.parse("200", CryptoCurrency.usdcsol),
      );
    });

    test("the order with a taker builds a transaction and totals its fees", () {
      final order = JupiterOrder.fromJson(_map(jupiterOrder(withTaker: true)));

      expect(order.requestId, jupiterRequestId);
      expect(order.taker, refundAddress);
      expect(order.transaction, jupiterTransaction);
      expect(order.errorCode, isNull);
      expect(order.errorMessage, isNull);
      expect(order.swapType, JupiterSwapType.aggregator);
      expect(order.swapMode, JupiterSwapMode.exactIn);
      expect(order.slippageBps, 100);
      expect(order.totalFee, 15000, reason: "5000 signature + 10000 prioritization");
      expect(order.routePlan!.single.swapInfo.label, "Orca");
    });
  });
}
