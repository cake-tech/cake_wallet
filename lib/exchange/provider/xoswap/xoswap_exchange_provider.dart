import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/xoswap/xoswap_api_schema.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_not_created_exception.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/utils/provider_api.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/utils/package_info.dart";
import "package:collection/collection.dart" show IterableDoubleExtension;
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";

class XOSwapExchangeProvider extends ExchangeProvider {
  XOSwapExchangeProvider({super.proxyWrapper}) {
    _addAppVersionHeader();
  }

  Future<void> _addAppVersionHeader() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      _headers["App-Version"] = currentVersion;
    } catch (_) {}
  }

  static const _apiAuthority = "exchange.exodus.io";

  static final _headers = {"App-Name": "cake-labs"};

  late final _api = ProviderApi(
    proxyWrapper,
    authority: _apiAuthority,
    headers: _headers,
    errorMessage: (json) => (json["message"] ?? json["error"])?.toString(),
  );

  final _networks = <String, String>{
    "POL": "matic",
    "ETH": "ethereum",
    "BTC": "bitcoin",
    "BSC": "bsc",
    "SOL": "solana",
    "TRX": "tronmainnet",
    "ZEC": "zcash",
    "ADA": "cardano",
    "DOGE": "dogecoin",
    "XMR": "monero",
    "BCH": "bcash",
    "BSV": "bitcoinsv",
    "XRP": "ripple",
    "LTC": "litecoin",
    "EOS": "eosio",
    "XLM": "stellar",
    "BASE": "basemainnet",
    "ARB": "arbitrum",
  };

  static const supportedTags = [
    "POL",
    "ETH",
    "BTC",
    "BSC",
    "SOL",
    "TRX",
    "ZEC",
    "ADA",
    "DOGE",
    "XMR",
    "BCH",
    "BSV",
    "XRP",
    "LTC",
    "EOS",
    "XLM",
    "BASE",
    "ARB",
  ];

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.xoSwap;

  Future<String?> _getAssets(CryptoCurrency currency) async {
    if (currency.tag == null) {
      return currency.title;
    }
    try {
      final normalizedNetwork = _networks[currency.tag];
      if (normalizedNetwork == null) {
        return null;
      }

      final assets = await _api.send(
        XOSwapAssetsRequest(networks: normalizedNetwork, query: currency.title),
      );

      final asset = assets.firstWhereOrNull(
        (asset) => removeNonAlphanumeric(asset.symbol.toString()) == currency.title,
      );

      return asset?.id;
    } catch (e) {
      printV(e.toString());
      return null;
    }
  }

  String removeNonAlphanumeric(String str) =>
      str.toUpperCase().replaceAll(RegExp(r"[^A-Z0-9]"), "");

  Future<List<XOSwapRate>> getRatesForPair({
    required CryptoCurrency from,
    required CryptoCurrency to,
  }) async {
    try {
      final curFrom = await _getAssets(from);
      final curTo = await _getAssets(to);
      if (curFrom == null || curTo == null) {
        return [];
      }
      return await _api.send(XOSwapPairRatesRequest(pairId: "${curFrom}_$curTo"));
    } catch (e) {
      printV(e.toString());
      return [];
    }
  }

  ExchangeLimits _exchangeLimitsFromRateList(CryptoCurrency from, List<XOSwapRate> rates) => ExchangeLimits(
        min: Money.trySafeParse(rates.map((rate) => rate.min.value).min, from),
        max: Money.trySafeParse(rates.map((rate) => rate.max.value).max, from),
      );


  @override
  Future<ExchangeLimits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    final rates = await getRatesForPair(from: from, to: to);
    if (rates.isEmpty) {
      throw Exception("No rates found for $from to $to");
    }

    return _exchangeLimitsFromRateList(from, rates);
  }

  @override
  Future<ProviderRate> fetchRate(
      {required Money from, required bool isFixedRate, required CryptoCurrency to}) async {
    final rates = await getRatesForPair(from: from.currency as CryptoCurrency, to: to);
    if (rates.isEmpty) {
      throw Exception("no rate from xoswap");
    }

    final amount = double.parse(from.toString());
    double result;
    if (!isFixedRate) {
      double bestOutput = 0;
      for (final rate in rates) {
        final double minVal = rate.min.value;
        final double maxVal = rate.max.value;
        if (amount >= minVal && amount <= maxVal) {
          final double rateMultiplier = rate.amount.value;
          final double minerFee = rate.minerFee.value;
          final double outputAmount = (amount * rateMultiplier) - minerFee;
          if (outputAmount > bestOutput) {
            bestOutput = outputAmount;
          }
        }
      }
      result = bestOutput > 0 ? (bestOutput / amount) : 0;
    } else {
      double bestInput = double.infinity;
      for (final rate in rates) {
        final double rateMultiplier = rate.amount.value;
        final double minerFee = rate.minerFee.value;
        final double minVal = rate.min.value;
        final double maxVal = rate.max.value;
        final double requiredSend = (amount + minerFee) / rateMultiplier;
        if (requiredSend >= minVal && requiredSend <= maxVal) {
          if (requiredSend < bestInput) {
            bestInput = requiredSend;
          }
        }
      }
      result = bestInput < double.infinity ? amount / bestInput : 0;
    }

    return ProviderRate(provider: description,
        rate: ExchangeRate(base: from.currency, quote: Money.safeParse(result, to)),
        limits: _exchangeLimitsFromRateList(from.currency as CryptoCurrency, rates));
  }

  @override
  Future<Trade> createTrade({
    required TradeRequest request,
  }) async {
      final curFrom = await _getAssets(request.depositCurrency);
      final curTo = await _getAssets(request.payoutCurrency);

      if (curFrom == null || curTo == null) {
        throw TradeNotCreatedException(description);
      }

      final pairId = "${curFrom}_$curTo";

      final responseData = await _api.send(XOSwapCreateOrderRequest(pairId: pairId,
          fromAmount: request.depositAmount.toString(),
          fromAddress: request.refundAddress,
          toAmount: request.payoutAmount.toString(),
          toAddress: request.payoutAddress,
          toAddressTag: request.toAddressExtraId
      ));


      return Trade(
        depositAmount: Money.safeParse(responseData.amount.value, request.depositCurrency),
        payoutAmount: Money.safeParse(responseData.toAmount!.value, request.payoutCurrency),
        id: responseData.id,
        provider: description,
        refundAddress: responseData.fromAddress,
        state: responseData.status,
        createdAt: responseData.createdAt,
        payoutAddress: responseData.toAddress,
        fundingAddress: responseData.payInAddress,
        extraId: responseData.payInAddressTag,
        toAddressExtraId: request.toAddressExtraId,
      );
  }

  @override
  Future<Trade> updateTrade(Trade trade) async {
    final responseData = await _api.send(
      XOSwapOrderRequest(id: trade.id),
      mapError: (e) => switch (e.json) {
        {"code": "NOT_FOUND"} => Exception("Trade not found"),
        _ => null,
      },
    );


    return trade.copyWith(
      refundAddress: responseData.fromAddress,
      fundingAddress: responseData.payInAddress,
      depositAmount: Money.safeParse(responseData.amount.value, trade.depositCurrency),
      payoutAmount: responseData.toAmount?.value != null ? Money.safeParse(
          responseData.toAmount!.value, trade.payoutCurrency) : null,
      state: responseData.status,
      createdAt: responseData.createdAt,
      payoutAddress: responseData.toAddress,
      extraId: responseData.payInAddressTag,
    );
  }

}
