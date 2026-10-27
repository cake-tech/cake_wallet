import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/trocador/trocador_api_schema.dart";
import "package:cake_wallet/exchange/rate_request.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/utils/provider_api.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/utils/exchange_provider_logger.dart";
import "package:cake_wallet/wallet_type_utils.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";

class TrocadorExchangeProvider extends ExchangeProvider {
  TrocadorExchangeProvider({
    this.useTorOnly = false,
    this.providerStates = const {},
    super.proxyWrapper,
  });

  bool useTorOnly;
  Map<String, bool> providerStates;

  static const List<String> availableProviders = [
    "Swapter",
    "StealthEx",
    "Simpleswap",
    "Swapuz",
    "ChangeNow",
    "Changehero",
    "FixedFloat",
    "LetsExchange",
    "Exolix",
    "Godex",
    "Exch",
    "CoinCraddle",
    "Alfacash",
    "LocalMonero",
    "XChange",
    "NeroSwap",
    "Changee",
    "BitcoinVN",
    "EasyBit",
    "WizardSwap",
    "Quantex",
    "SwapSpace",
  ];

  static final apiKey = isMoneroOnly ? secrets.trocadorMoneroApiKey : secrets.trocadorApiKey;
  static const clearNetAuthority = "api.trocador.app";
  // static const onionApiAuthority = 'trocadorfyhlu27aefre5u7zri66gudtzdyelymftvr4yjwcxhfaqsid.onion';
  static const markup = secrets.trocadorExchangeMarkup;

  late final _api = ProviderApi(
    proxyWrapper,
    authority: clearNetAuthority,
    headers: {"API-Key": apiKey},
    errorMessage: (json) => switch ((json["error"], json["message"])) {
      (null, null) => null,
      (final error, final message) => "${error ?? "Unknown error"}\n${message ?? ""}",
    },
  );


  @override
  bool get supportsFixedRate => true;

  @override
  bool get supportsOnionAddress => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.trocador;

  @override
  Future<ExchangeLimits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    final coins = await _api.send(
      TrocadorCoinRequest(ticker: _normalizeCurrency(from), name: from.name),
    );

    final coinJson = coins.first;

    return ExchangeLimits(
      min: Money.trySafeParse(coinJson.minimum, from),
      max: Money.trySafeParse(coinJson.maximum, from),
    );
  }

  @override
  Future<ProviderRate> fetchRate(RateRequest request) async {
    final (rate, quotes) = await _getQuotes(request);

    return ProviderRate(
      provider: description,
      rate: ExchangeRate.fromAmounts(
        Money.safeParse(quotes.first.amountFrom ?? rate.amountFrom, request.depositCurrency),
        Money.safeParse(quotes.first.amountTo ?? rate.amountTo, request.payoutCurrency),
      ),
      limits: await fetchLimits(
        from: request.depositCurrency,
        to: request.payoutCurrency,
        isFixedRateMode: request is FixedRateRequest,
      ),
    );
  }

  @override
  Future<Trade> createTrade({required TradeRequest request}) async {
    final (rate, quotes) = await _getQuotes(request.rateRequest);

    final responseData = await _newTrade(request, rate.tradeId, quotes.take(3).toList());

    final depositAmount = responseData.amountFrom.isEmpty
        ? request.depositAmount
        : Money.safeParse(responseData.amountFrom, request.depositCurrency);
    final payoutAmount = responseData.amountTo.isEmpty
        ? request.payoutAmount
        : Money.safeParse(responseData.amountTo, request.payoutCurrency);

    final trade = Trade(
      id: responseData.tradeId,
      provider: description,
      providerName: responseData.provider,
      fundingAddress: responseData.addressProvider,
      refundAddress: responseData.refundAddress ?? request.refundAddress,
      state: responseData.status,
      password: responseData.password,
      providerId: responseData.idProvider,
      createdAt: responseData.date?.toLocal(),
      payoutAddress: responseData.addressUser,
      extraId: responseData.addressProviderMemo,
      toAddressExtraId: request.toAddressExtraId,
      depositAmount: depositAmount,
      payoutAmount: payoutAmount,
    );

    try {
      // if trocador decides to update the amounts right after, this'll show the correct amounts
      return await updateTrade(trade);
    } catch (e) {
      printV("failed to refresh trocador trade ${trade.id}: $e");
      return trade;
    }
  }

  Future<TrocadorTrade> _newTrade(
    TradeRequest request,
    String rateId,
    List<TrocadorQuote> quotes,
  ) async {
    try {
      return await _api.send(TrocadorNewTradeRequest(
        id: rateId,
        tickerFrom: _normalizeCurrency(request.depositCurrency),
        networkFrom: _networkFor(request.depositCurrency),
        tickerTo: _normalizeCurrency(request.payoutCurrency),
        networkTo: _networkFor(request.payoutCurrency),
        address: request.payoutAddress,
        refundMemo: "0",
        provider: quotes.first.provider,
        fixed: request.isFixedRate,
        payment: request.isFixedRate,
        minKycrating: .c,
        markup: markup,
        amountFrom: request.isFixedRate ? null : request.depositAmount.toString(),
        amountTo: request.isFixedRate ? request.payoutAmount.toString() : null,
        addressMemo: request.toAddressExtraId,
        refund: request.refundAddress,
      ));
    } on ProviderHttpException catch (e, st) {
      if (e.statusCode != 400 || quotes.length == 1) {
        rethrow;
      }

      ExchangeProviderLogger.logError(
        provider: description,
        function: "createTrade",
        error: e,
        stackTrace: st,
        requestData: {"rateId": rateId, "subProvider": quotes.first.provider},
      );
      return _newTrade(request, rateId, quotes.sublist(1));
    }
  }

  Future<(TrocadorRate, List<TrocadorQuote>)> _getQuotes(RateRequest request) async {
    final (amountFrom, amountTo) = switch (request) {
      FloatingRateRequest(:final depositAmount) => (depositAmount.toString(), null),
      FixedRateRequest(:final payoutAmount) => (null, payoutAmount.toString()),
    };

    final rate = await _api.send(TrocadorNewRateRequest(
      tickerFrom: _normalizeCurrency(request.depositCurrency),
      networkFrom: _networkFor(request.depositCurrency),
      tickerTo: _normalizeCurrency(request.payoutCurrency),
      networkTo: _networkFor(request.payoutCurrency),
      amountFrom: amountFrom,
      amountTo: amountTo,
      payment: request is FixedRateRequest,
      minKycrating: .c,
      markup: markup,
    ));

    final quotes = (rate.quotes?.quotes ?? [])
        .where((quote) => providerStates[quote.provider] != false)
        .where((quote) => quote.fixed == null || quote.fixed == (request is FixedRateRequest))
        .toList();

    if (quotes.isEmpty) {
      throw Exception("No enabled providers found for the selected trade.");
    }

    return (rate, quotes);
  }

  @override
  Future<Trade> updateTrade(Trade trade) async {
    final responseData = await _api.send(TrocadorTradeRequest(id: trade.id));

    return trade.copyWith(
      refundAddress: responseData.refundAddress ?? "",
      createdAt: responseData.date?.toLocal(),
      state: responseData.status,
      payoutAddress: responseData.addressUser,
      providerName: responseData.provider,
      password: responseData.password,
      providerId: responseData.idProvider,
      extraId: responseData.addressProviderMemo,
      depositAmount: Money.safeParse(responseData.amountFrom, trade.depositCurrency),
      payoutAmount: Money.safeParse(responseData.amountTo, trade.payoutCurrency),
      fundingAddress: responseData.addressProvider,
    );
  }

  Future<List<TrocadorPartner>> fetchProviders() async {
    final response = await _api.send(TrocadorExchangesRequest(apiKey: apiKey));

    return response.list.where((provider) => provider.rating != TrocadorRating.d).toList()
      ..sort(
        (a, b) => (a.rating ?? TrocadorRating.unknown).index
            .compareTo((b.rating ?? TrocadorRating.unknown).index),
      );
  }

  String _networkFor(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.eth:
        return "ERC20";
      case CryptoCurrency.maticpoly:
        return "Mainnet";
      case CryptoCurrency.usdcpoly:
      case CryptoCurrency.usdtPoly:
      case CryptoCurrency.usdcEPoly:
        return "MATIC";
      case CryptoCurrency.zec:
        return "Mainnet";
      case CryptoCurrency.arb:
        return "Mainnet";
      default:
        return currency.tag != null ? _normalizeTag(currency.tag!) : "Mainnet";
    }
  }

  String _normalizeCurrency(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.zec:
        return "zec";
      case CryptoCurrency.usdcEPoly:
        return "usdce";
      default:
        return currency.title.toLowerCase();
    }
  }

  String _normalizeTag(String tag) {
    if (tag.contains("ARB")) {
      return "Arbitrum";
    }

    switch (tag) {
      case "ETH":
        return "ERC20";
      case "TRX":
        return "TRC20";
      case "LN":
        return "Lightning";
      case "BSC":
        return "BEP20";
      default:
        return tag.toLowerCase();
    }
  }
}
