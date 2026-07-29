import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_address.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "fakes.dart";
import "mock_proxy_wrapper.dart";

/// A provider wired to its own mock, built fresh for every test.
///
/// Fresh matters: several providers cache the last rate id, the chosen sub-provider or the
/// supported-asset list on the instance, so reusing one would let an earlier test decide
/// whether a later one passes.
class ProviderUnderTest {
  const ProviderUnderTest(this.provider, this.mock);

  final ExchangeProvider provider;
  final MockProxyWrapper mock;
}

/// Every [Trade] field the four provider functions are expected to fill in.
class ExpectedTrade {
  const ExpectedTrade({
    required this.id,
    required this.state,
    required this.depositAmount,
    required this.payoutAmount,
    required this.fundingAddress,
    required this.payoutAddress,
    required this.refundAddress,
    this.extraId,
    this.toAddressExtraId,
    this.memo,
    this.txId,
    this.outputTransaction,
    this.providerId,
    this.password,
    this.isRefund,
    this.createdAt,
    this.createdAtIsNow = false,
    this.expiredAt,
    this.expiredAtIsNowPlus,
  });

  final String id;
  final TradeState state;
  final Money depositAmount;
  final Money payoutAmount;
  final String fundingAddress;
  final String payoutAddress;
  final String refundAddress;
  final String? extraId;
  final String? toAddressExtraId;
  final String? memo;
  final String? txId;
  final String? outputTransaction;
  final String? providerId;
  final String? password;
  final bool? isRefund;

  /// The exact timestamp the api reported, when the provider passes one through.
  final DateTime? createdAt;

  /// Set instead of [createdAt] for the providers that stamp `DateTime.now()` themselves.
  final bool createdAtIsNow;

  final DateTime? expiredAt;

  /// Set instead of [expiredAt] for the providers that invent an expiry from the clock.
  final Duration? expiredAtIsNowPlus;
}

/// What one provider is expected to do for one pair, with the api answering from a mock.
class ProviderScenario {
  const ProviderScenario({
    required this.title,
    required this.build,
    required this.from,
    required this.to,
    required this.depositAmount,
    required this.payoutAmount,
    required this.isFixedRate,
    required this.expectedLimitsMin,
    required this.expectedLimitsMax,
    required this.expectedRateQuote,
    required this.expectedRateLimitsMin,
    required this.expectedRateLimitsMax,
    required this.expectedCreatedTrade,
    required this.tradeId,
    this.expectedFoundTrade,
    this.findTradeByIdThrows,
    this.unknownTradeIdThrows,
    this.unknownTradeId = "no-such-trade-id",
    this.refundAddress = "refund-address",
    this.payoutAddress = "payout-address",
    this.toAddressExtraId = "",
    this.warmUp,
  });

  final String title;
  final ProviderUnderTest Function() build;

  final CryptoCurrency from;
  final CryptoCurrency to;

  /// What the user wants to send, and what the mocked api quotes back for it.
  final Money depositAmount;
  final Money payoutAmount;
  final bool isFixedRate;

  final Money? expectedLimitsMin;
  final Money? expectedLimitsMax;

  /// `ProviderRate.rate.quote` - the price of one whole [from] in [to].
  final Money expectedRateQuote;
  final Money? expectedRateLimitsMin;
  final Money? expectedRateLimitsMax;

  final ExpectedTrade expectedCreatedTrade;

  /// The id handed to `findTradeById`.
  final String tradeId;

  /// Null when the provider cannot look a trade up at all - then [findTradeByIdThrows] says
  /// what it does instead.
  final ExpectedTrade? expectedFoundTrade;
  final Matcher? findTradeByIdThrows;

  /// What a lookup for a trade the exchange has never heard of does.
  final Matcher? unknownTradeIdThrows;
  final String unknownTradeId;

  final String refundAddress;
  final String payoutAddress;
  final String toAddressExtraId;

  /// Run before `createTrade`, for the providers that only work once a rate has been
  /// fetched (Trocador picks its sub-provider during `fetchRate` and createTrade needs it).
  final Future<void> Function(ExchangeProvider provider)? warmUp;

  TradeRequest get request => TradeRequest(
    refundAddress: refundAddress,
    payoutAddress: ExternalSwapAddress(payoutAddress),
    depositAmount: swapAmount(depositAmount),
    payoutAmount: swapAmount(payoutAmount),
    isFixedRate: isFixedRate,
    toAddressExtraId: toAddressExtraId,
  );
}

Matcher _closeToNow({Duration tolerance = const Duration(minutes: 1)}) =>
    predicate<DateTime?>((value) {
      if (value == null) {
        return false;
      }
      return DateTime.now().difference(value).abs() < tolerance;
    }, "within $tolerance of now");

Matcher _closeTo(DateTime target, {Duration tolerance = const Duration(minutes: 1)}) =>
    predicate<DateTime?>((value) {
      if (value == null) {
        return false;
      }
      return target.difference(value).abs() < tolerance;
    }, "within $tolerance of $target");

void _expectTrade(Trade trade, ExpectedTrade expected, ExchangeProvider provider) {
  expect(trade.id, expected.id, reason: "id");
  expect(trade.provider, provider.description, reason: "provider");
  expect(trade.state, expected.state, reason: "state");
  expect(trade.depositAmount, expected.depositAmount, reason: "depositAmount");
  expect(trade.depositCurrency, expected.depositAmount.currency, reason: "depositCurrency");
  expect(trade.payoutAmount, expected.payoutAmount, reason: "payoutAmount");
  expect(trade.payoutCurrency, expected.payoutAmount.currency, reason: "payoutCurrency");
  expect(trade.fundingAddress, expected.fundingAddress, reason: "fundingAddress");
  expect(trade.payoutAddress, expected.payoutAddress, reason: "payoutAddress");
  expect(trade.refundAddress, expected.refundAddress, reason: "refundAddress");
  expect(trade.extraId, expected.extraId, reason: "extraId");
  expect(trade.toAddressExtraId, expected.toAddressExtraId, reason: "toAddressExtraId");
  expect(trade.memo, expected.memo, reason: "memo");
  expect(trade.txId, expected.txId, reason: "txId");
  expect(trade.outputTransaction, expected.outputTransaction, reason: "outputTransaction");
  expect(trade.providerId, expected.providerId, reason: "providerId");
  expect(trade.password, expected.password, reason: "password");
  expect(trade.isRefund, expected.isRefund, reason: "isRefund");

  if (expected.createdAtIsNow) {
    expect(trade.createdAt, _closeToNow(), reason: "createdAt");
  } else {
    expect(trade.createdAt, expected.createdAt, reason: "createdAt");
  }

  if (expected.expiredAtIsNowPlus != null) {
    expect(
      trade.expiredAt,
      _closeTo(DateTime.now().add(expected.expiredAtIsNowPlus!)),
      reason: "expiredAt",
    );
  } else {
    expect(trade.expiredAt, expected.expiredAt, reason: "expiredAt");
  }
}

/// The suite every provider runs.
///
/// The api answers from [ProviderScenario.build]'s mock, so the rates, limits and trade
/// bodies are fixed and every expectation below is an exact value rather than a range.
void runExchangeProviderSuite(ProviderScenario scenario) {
  group(scenario.title, () {
    late ExchangeProvider provider;
    late MockProxyWrapper mock;

    setUp(() {
      final underTest = scenario.build();
      provider = underTest.provider;
      mock = underTest.mock;
    });

    test("describes itself consistently", () {
      expect(provider.title, isNotEmpty);
      expect(provider.description.title, isNotEmpty);
      expect(provider.isEnabled, isTrue);
      expect(provider.isAvailable, isTrue);
      expect(provider.checkIsAvailable(), completion(isTrue));
    });

    group("fetchLimits", () {
      test("reports the pair's limits", () async {
        final limits = await provider.fetchLimits(
          from: scenario.from,
          to: scenario.to,
          isFixedRateMode: scenario.isFixedRate,
        );

        expect(limits.min, scenario.expectedLimitsMin, reason: "min");
        expect(limits.max, scenario.expectedLimitsMax, reason: "max");
      });

      test("the limits it reports accept the amount the api quoted", () async {
        final limits = await provider.fetchLimits(
          from: scenario.from,
          to: scenario.to,
          isFixedRateMode: scenario.isFixedRate,
        );
        final bound = limits.min ?? limits.max;

        if (bound == null) {
          // no limit at all is a legitimate answer (Jupiter and Near Intents never
          // constrain the amount), and isWithinLimit says so
          expect(limits.isWithinLimit(scenario.depositAmount), isTrue);
          return;
        }

        // the scenario's deposit amount is the one the mocked api priced, so it has to sit
        // inside the limits the same api reports, in the same currency
        expect(bound.currency, scenario.depositAmount.currency, reason: "limits currency");
        expect(limits.isWithinLimit(scenario.depositAmount), isTrue);
      });
    });

    group("fetchRate", () {
      test("quotes the price of one whole unit", () async {
        final rate = await provider.fetchRate(
          from: scenario.depositAmount,
          to: scenario.to,
          isFixedRate: scenario.isFixedRate,
        );

        expect(rate.provider, provider.description);
        expect(rate.rate.base, scenario.from);
        expect(rate.rate.quote, scenario.expectedRateQuote);
      });

      test("converts the deposit amount with the quoted rate", () async {
        final rate = await provider.fetchRate(
          from: scenario.depositAmount,
          to: scenario.to,
          isFixedRate: scenario.isFixedRate,
        );

        expect(rate.rate.convert(scenario.depositAmount), scenario.payoutAmount);
      });

      test("carries the pair's limits", () async {
        final rate = await provider.fetchRate(
          from: scenario.depositAmount,
          to: scenario.to,
          isFixedRate: scenario.isFixedRate,
        );

        expect(rate.limits.min, scenario.expectedRateLimitsMin, reason: "min");
        expect(rate.limits.max, scenario.expectedRateLimitsMax, reason: "max");
      });
    });

    group("createTrade", () {
      test("builds the trade out of the api's answer", () async {
        await scenario.warmUp?.call(provider);

        final trade = await provider.createTrade(request: scenario.request);

        _expectTrade(trade, scenario.expectedCreatedTrade, provider);
      });

      test("tells the exchange where to send the coins", () async {
        await scenario.warmUp?.call(provider);
        mock.requests.clear();

        await provider.createTrade(request: scenario.request);

        expect(
          mock.wire,
          contains(scenario.payoutAddress),
          reason: "the payout address never reached the api",
        );
      });
    });

    group("findTradeById", () {
      final expectedFoundTrade = scenario.expectedFoundTrade;

      if (expectedFoundTrade == null) {
        test("is not supported", () {
          expect(
            () => provider.findTradeById(id: scenario.tradeId),
            throwsA(scenario.findTradeByIdThrows ?? isA<Exception>()),
          );
        });
      } else {
        test("rebuilds the trade from the api's answer", () async {
          final trade = await provider.findTradeById(id: scenario.tradeId);

          _expectTrade(trade, expectedFoundTrade, provider);
        });
      }

      final unknownTradeIdThrows = scenario.unknownTradeIdThrows;

      if (unknownTradeIdThrows != null) {
        test("throws for a trade the exchange has never heard of", () {
          expect(
            () => provider.findTradeById(id: scenario.unknownTradeId),
            throwsA(unknownTradeIdThrows),
          );
        });
      }
    });
  });
}
