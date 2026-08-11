import "dart:convert";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/trocador/trocador_api_schema.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/wallet_type_utils.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class TrocadorExchangeProvider extends ExchangeProvider {
  TrocadorExchangeProvider({
    this.useTorOnly = false,
    this.providerStates = const {},
    super.proxyWrapper,
  }) : _lastUsedRateId = "",
       _provider = [];

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
  static const onionApiAuthority = clearNetAuthority;

  // static const onionApiAuthority = 'trocadorfyhlu27aefre5u7zri66gudtzdyelymftvr4yjwcxhfaqsid.onion';
  static const markup = secrets.trocadorExchangeMarkup;
  static const newRatePath = "/new_rate";
  static const createTradePath = "/new_trade";
  static const tradePath = "/trade";
  static const coinPath = "/coin";
  static const providersListPath = "/exchanges";

  String _lastUsedRateId;
  List<String> _provider;

  @override
  String get title => "Trocador";

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  bool get supportsOnionAddress => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.trocador;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<ExchangeLimits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    final params = TrocadorCoinRequest(ticker: _normalizeCurrency(from), name: from.name);

    final uri = await _getUri(coinPath, params.toJson());
    final response = await proxyWrapper.get(clearnetUri: uri, headers: {"API-Key": apiKey});

    if (response.statusCode != 200) {
      throw Exception("Unexpected http status: ${response.statusCode}");
    }

    final responseJSON = (json.decode(response.body) as List<dynamic>).map(
      (item) => TrocadorCoin.fromJson(item as Map<String, dynamic>),
    );

    if (responseJSON.isEmpty) {
      throw Exception("No data");
    }

    final coinJson = responseJSON.first;

    return ExchangeLimits(
      min: Money.tryParse(coinJson.minimum, from),
      max: Money.tryParse(coinJson.maximum, from),
    );
  }

  @override
  Future<ProviderRate> fetchRate({
    required Money from,
    required CryptoCurrency to,
    required bool isFixedRate,
  }) async {
    final params = TrocadorNewRateRequest(
      tickerFrom: _normalizeCurrency(from.currency as CryptoCurrency),
      networkFrom: _networkFor(from.currency as CryptoCurrency),
      tickerTo: _normalizeCurrency(to),
      networkTo: _networkFor(to),
      amountFrom: isFixedRate ? null : from.toString(),
      amountTo: isFixedRate ? from.toString() : null,
      payment: isFixedRate,
      minKycrating: .c,
      markup: markup,
    );

    final uri = await _getUri(newRatePath, params.toJson());
    final response = await proxyWrapper.get(clearnetUri: uri, headers: {"API-Key": apiKey});


    if(response.statusCode > 299 || response.statusCode < 200) {
      throw Exception("unknown status code: ${response.statusCode}");
    }

    final responseJSON = TrocadorRate.fromJson(json.decode(response.body) as Map<String, dynamic>);
    if (responseJSON.quotes == null || responseJSON.quotes!.quotes == null) {
      throw Exception("no quotes received");
    }
    _provider = responseJSON.quotes!.quotes!
        .where((quote) => providerStates[quote.provider] != false)
        .map((quote) => quote.provider)
        .toList();

    if (_provider.isEmpty) {
      throw Exception("No enabled providers found for the selected trade.");
    }

    if (responseJSON.tradeId.isNotEmpty) {
      _lastUsedRateId = responseJSON.tradeId;
    }

    return ProviderRate(
      provider: description,
      rate: ExchangeRate.fromAmounts(
        Money.safeParse(responseJSON.amountFrom, from.currency),
        Money.safeParse(responseJSON.amountTo, to),
      ),
      limits: await fetchLimits(
        from: from.currency as CryptoCurrency,
        to: to,
        isFixedRateMode: isFixedRate,
      ),
    );
  }

  @override
  Future<Trade> createTrade({required TradeRequest request}) async {
    if (request.isFixedRate) {
      await fetchRate(
        to: request.payoutCurrency,
        from: request.payoutAmount.cryptoAmount,
        isFixedRate: true,
      );
    }

    final params = TrocadorNewTradeRequest(
      id: request.isFixedRate ? _lastUsedRateId : null,
      tickerFrom: _normalizeCurrency(request.depositCurrency),
      networkFrom: _networkFor(request.depositCurrency),
      tickerTo: _normalizeCurrency(request.payoutCurrency),
      networkTo: _networkFor(request.payoutCurrency),
      address: request.payoutAddress,
      provider: _provider.first,
      fixed: request.isFixedRate,
      payment: request.isFixedRate,
      minKycrating: .c,
      markup: markup,
      amountFrom: request.isFixedRate ? null : request.depositAmount.cryptoAmount.toString(),
      amountTo: request.isFixedRate ? request.payoutAmount.cryptoAmount.toString() : null,
      addressMemo: request.toAddressExtraId,
      refund: request.refundAddress,
    );

    final uri = await _getUri(createTradePath, params.toJson());
    final response = await proxyWrapper.get(clearnetUri: uri, headers: {"API-Key": apiKey});

    if (response.statusCode == 400) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = _safeString(responseJSON, "error", "Unknown error");
      final message = _safeString(responseJSON, "message");

      throw Exception("${error}\n$message");
    }

    if (response.statusCode != 200) {
      print(response.body);
      throw Exception("Unexpected http status: ${response.statusCode}");
    }

    final responseData = TrocadorTrade.fromJson(json.decode(response.body) as Map<String, dynamic>);

    final depositAmount = responseData.amountFrom.isEmpty
        ? request.depositAmount.cryptoAmount
        : Money.safeParse(responseData.amountFrom, request.depositCurrency);
    final payoutAmount = responseData.amountTo.isEmpty
        ? request.payoutAmount.cryptoAmount
        : Money.safeParse(responseData.amountTo, request.payoutCurrency);

    return Trade(
      id: responseData.tradeId,
      provider: description,
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
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final uri = await _getUri(tradePath, {"id": id});
    return proxyWrapper.get(clearnetUri: uri, headers: {"API-Key": apiKey}).then((response) {
      if (response.statusCode != 200) {
        throw Exception("Unexpected http status: ${response.statusCode}");
      }

      final responseListJson = json.decode(response.body) as List;
      final responseData = TrocadorTrade.fromJson(responseListJson.first as Map<String, dynamic>);
      // final id = _safeString(responseJSON, 'trade_id');
      // final payoutAddress = _safeString(responseJSON, 'address_user');
      // final refundAddress = _safeString(responseJSON, 'refund_address');
      // final inputAddress = _safeString(responseJSON, 'address_provider');
      // final fromAmount = responseJSON['amount_from']?.toString() ?? '0';
      // final password = _safeString(responseJSON, 'password');
      // final providerId = _safeString(responseJSON, 'id_provider');
      // final providerName = _safeString(responseJSON, 'provider');
      // final memoVal = _safeString(responseJSON, 'address_provider_memo');
      // final addressProviderMemo = memoVal.isEmpty ? null : memoVal;

      final _normalizedFromNetwork = _normalizeNetworkType(responseData.networkFrom);
      final fromTag =
          _normalizedFromNetwork.isEmpty ||
              _normalizedFromNetwork == responseData.tickerFrom.toUpperCase() ||
              _normalizedFromNetwork == "Mainnet"
          ? null
          : _normalizedFromNetwork;

      final from = CryptoCurrency.safeParseCurrencyFromString(
        responseData.tickerFrom,
        tag: fromTag,
      );

      final _normalizedToNetwork = _normalizeNetworkType(responseData.networkTo);
      final toTag =
          _normalizedToNetwork.isEmpty ||
              _normalizedToNetwork == responseData.tickerFrom.toUpperCase() ||
              _normalizedFromNetwork == "Mainnet"
          ? null
          : _normalizedToNetwork;
      final to = CryptoCurrency.safeParseCurrencyFromString(responseData.tickerTo, tag: toTag);

      return Trade(
        id: id,
        provider: description,
        refundAddress: responseData.refundAddress ?? "",
        createdAt: responseData.date?.toLocal(),
        state: responseData.status,
        payoutAddress: responseData.addressUser,
        providerName: responseData.provider,
        password: responseData.password,
        providerId: responseData.idProvider,
        extraId: responseData.addressProviderMemo,
        depositAmount: Money.safeParse(responseData.amountFrom, from!),
        payoutAmount: Money.safeParse(responseData.amountTo, to!),
        fundingAddress: responseData.addressProvider,
      );
    });
  }

  Future<List<TrocadorPartners>> fetchProviders() async {
    final uri = await _getUri(providersListPath, {"api_key": apiKey});
    final response = await proxyWrapper.get(clearnetUri: uri);

    if (response.statusCode != 200) {
      throw Exception("Unexpected http status: ${response.statusCode}");
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;

    final providersJsonList = responseJSON["list"] as List<dynamic>;
    final filteredProvidersList = providersJsonList
        .map((providerJson) => TrocadorPartners.fromJson(providerJson as Map<String, dynamic>))
        .where((provider) => provider.rating != "D")
        .toList();
    filteredProvidersList.sort((a, b) => a.rating.compareTo(b.rating));
    return filteredProvidersList;
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

  String _normalizeNetworkType(String network) => switch (network.toUpperCase()) {
    "ERC20" => "ETH",
    "TRC20" => "TRX",
    "BEP20" => "BSC",
    "LIGHTNING" => "LN",
    "MATIC" => "POL",
    _ => network,
  };

  Future<Uri> _getUri(String path, Map<String, dynamic> queryParams) async {
    final uri = Uri.https(onionApiAuthority, path, queryParams);

    if (useTorOnly) {
      return uri;
    }

    try {
      await proxyWrapper.get(clearnetUri: uri);

      return uri;
    } catch (e) {
      return Uri.https(clearNetAuthority, path, queryParams);
    }
  }

  /// Safe string extraction from API response. Handles different data types.
  static String _safeString(Map<String, dynamic> m, String key, [String nullError = ""]) {
    final v = m[key];
    if (v == null) {
      return nullError;
    }
    if (v is String) {
      return v;
    }
    return v.toString();
  }
}

class TrocadorPartners {
  TrocadorPartners({
    required this.name,
    required this.rating,
    required this.insurance,
    required this.enabledMarkup,
    required this.eta,
  });

  factory TrocadorPartners.fromJson(Map<String, dynamic> json) => TrocadorPartners(
    name: json["name"] as String? ?? "",
    rating: json["rating"] as String? ?? "N/A",
    insurance: json["insurance"] as double?,
    enabledMarkup: json["enabledmarkup"] as bool?,
    eta: json["eta"] as double?,
  );
  final String name;
  final String rating;
  final double? insurance;
  final bool? enabledMarkup;
  final double? eta;
}
