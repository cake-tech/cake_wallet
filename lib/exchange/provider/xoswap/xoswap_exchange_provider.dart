import "dart:convert";

import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/xoswap/xoswap_api_schema.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_not_created_exception.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/utils/package_info.dart";
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
  static const _apiPath = "/v3";
  static const _pairsPath = "/pairs";
  static const _ratePath = "/rates";
  static const _orders = "/orders";
  static const _assets = "/assets";

  static final _headers = {"Content-Type": "application/json", "App-Name": "cake-labs"};

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

  String _normalizeXOSwapsNetwork(String string) {
    final lower = string.toLowerCase();

    if (lower.endsWith("matic0a883d9b")) {
      return string.replaceFirst(RegExp(r"matic0a883d9b$", caseSensitive: false), "POL");
    }
    if (lower.endsWith("matic86e249c1")) {
      return string.replaceFirst(RegExp(r"matic86e249c1$", caseSensitive: false), "POL");
    }
    if (lower.endsWith("bscddedf0f8")) {
      return string.replaceFirst(RegExp(r"bscddedf0f8$", caseSensitive: false), "BSC");
    }
    if (lower.endsWith("basemainnetb5a52617")) {
      return string.replaceFirst(RegExp(r"basemainnetb5a52617$", caseSensitive: false), "BASE");
    }

    return string;
  }

  @override
  String get title => "XOSwap";

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.xoSwap;

  @override
  Future<bool> checkIsAvailable() async => true;

  Future<String?> _getAssets(CryptoCurrency currency) async {
    if (currency.tag == null) {
      return currency.title;
    }
    try {
      final normalizedNetwork = _networks[currency.tag];
      if (normalizedNetwork == null) {
        return null;
      }

      final uri = Uri.https(_apiAuthority, _apiPath + _assets,
          XOSwapAssetsRequest(networks: normalizedNetwork, query: currency.title).toJson());

      final response = await proxyWrapper.get(clearnetUri: uri, headers: _headers);

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch assets for ${currency.title} on ${currency.tag}");
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException("Unexpected response for`mat");
      }
      final assets = decoded.map((e) => XOSwapAsset.fromJson(e as Map<String,dynamic>)).toList();

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
      final pairId = "${curFrom}_$curTo";
      final uri = Uri.https(_apiAuthority, "$_apiPath$_pairsPath/$pairId$_ratePath");
      final response = await proxyWrapper.get(clearnetUri: uri, headers: _headers);

      if (response.statusCode != 200) {
        return [];
      }
      return (json.decode(response.body) as List<dynamic>).map((item)=>XOSwapRate.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      printV(e.toString());
      return [];
    }
  }

  ExchangeLimits _exchangeLimitsFromRateList(CryptoCurrency from, List<XOSwapRate> rates) {
    double minLimit = double.infinity;
    double maxLimit = 0;

    for (final rate in rates) {
      final double currentMin = rate.min.value;
      final double currentMax = rate.max.value;
      if (currentMin < minLimit) {
        minLimit = currentMin;
      }
      if (currentMax > maxLimit) {
        maxLimit = currentMax;
      }
    }
    return ExchangeLimits(min: Money.tryParse(minLimit, from), max: Money.tryParse(maxLimit, from));
  }


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

    final amount = from.toDouble();
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
        rate: ExchangeRate(base: from.currency, quote: Money.parse(result, to)),
        limits: _exchangeLimitsFromRateList(from.currency as CryptoCurrency, rates));
  }

  @override
  Future<Trade> createTrade({
    required TradeRequest request,
  }) async {
      final uri = Uri.https(_apiAuthority, "$_apiPath$_orders");

      final curFrom = await _getAssets(request.depositCurrency);
      final curTo = await _getAssets(request.payoutCurrency);

      if (curFrom == null || curTo == null) {
        throw TradeNotCreatedException(description);
      }

      final pairId = "${curFrom}_$curTo";

      final payload = XOSwapCreateOrderRequest(pairId: pairId,
          fromAmount: request.depositAmount.cryptoAmount.toString(),
          fromAddress: request.refundAddress,
          toAmount: request.payoutAmount.cryptoAmount.toString(),
          toAddress: request.payoutAddress.address,
          toAddressTag: request.toAddressExtraId
      );

      final response = await proxyWrapper.post(
        clearnetUri: uri,
        headers: _headers,
        body: json.encode(payload),
      );

      if (response.statusCode != 201) {
        final error = XOSwapErrorResponse.fromJson(json.decode(response.body) as Map<String, dynamic>);

        throw Exception(error);
      }
      final responseData = XOSwapOrder.fromJson(json.decode(response.body) as Map<String, dynamic>);


      return Trade(
        depositAmount: Money.parse(responseData.amount.value, request.depositCurrency),
        payoutAmount: Money.parse(responseData.toAmount!.value, request.payoutCurrency),
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
  Future<Trade> findTradeById({required String id}) async {
      final uri = Uri.https(_apiAuthority, "$_apiPath$_orders/$id");
      final response = await proxyWrapper.get(clearnetUri: uri, headers: _headers);

      if (response.statusCode != 200) {
        final error = XOSwapErrorResponse.fromJson(json.decode(response.body) as Map<String, dynamic>);
        if ( error.code == "NOT_FOUND") {
          throw Exception("Trade not found");
        }
        throw Exception(error);
      }
      final responseData = XOSwapOrder.fromJson(json.decode(response.body) as Map<String, dynamic>);

      final pairId = responseData.pairId;
      final pairParts = pairId.split("_");
      final fromAsset = pairParts.isNotEmpty ? pairParts[0] : "";
      final normalizedFromAsset = _normalizeXOSwapsNetwork(fromAsset);
      String? fromAssetTag = _extractTagFromAsset(normalizedFromAsset);

      String fromAssetBase = fromAssetTag != null
          ? normalizedFromAsset.substring(0, normalizedFromAsset.length - fromAssetTag.length)
          : normalizedFromAsset;

      // Special case for USDT defaulting to ETH tag
      if (fromAssetBase == "USDT" && fromAssetTag == null) {
        fromAssetTag = "ETH";
      }

      // Special case for BASE defaulting to BASE tag
      if (fromAssetBase == "BASE" && fromAssetTag == null) {
        fromAssetTag = "BASE";
        fromAssetBase = "ETH";
      }

      final toAsset = pairParts.length > 1 ? pairParts[1] : "";
      final normalizedToAsset = _normalizeXOSwapsNetwork(toAsset);
      String? toAssetTag = _extractTagFromAsset(normalizedToAsset);

      String toAssetBase = toAssetTag != null
          ? normalizedToAsset.substring(0, normalizedToAsset.length - toAssetTag.length)
          : normalizedToAsset;

      // Special case for USDT defaulting to ETH tag
      if (toAssetBase == "USDT" && toAssetTag == null) {
        toAssetTag = "ETH";
      }

      // Special case for BASE defaulting to BASE tag
      if (toAssetBase == "BASE" && toAssetTag == null) {
        toAssetTag = "ETH";
        toAssetBase = "BASE";
      }

      final fromCurrency =
          CryptoCurrency.safeParseCurrencyFromString(fromAssetBase, tag: fromAssetTag);
      final toCurrency = CryptoCurrency.safeParseCurrencyFromString(toAssetBase, tag: toAssetTag);


      return Trade(
        id: responseData.id,
        provider: description,
        refundAddress: responseData.fromAddress,
fundingAddress: responseData.payInAddress,
        depositAmount: Money.parse(responseData.amount.value, fromCurrency!),
        payoutAmount: Money.parse(responseData.toAmount?.value ?? 0, toCurrency!),
        state: responseData.status,
        createdAt: responseData.createdAt,
        payoutAddress: responseData.toAddress,
        extraId: responseData.payInAddressTag,
      );
  }

  // ensure something remains before tag (at least 2 chars)
  String? _extractTagFromAsset(String asset) {
    for (final tag in supportedTags) {
      if (asset.endsWith(tag)) {
        final prefixLength = asset.length - tag.length;
        if (prefixLength >= 2) {
          return tag;
        }
      }
    }
    return null;
  }
}
