import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/chainflip/chainflip_api_schema.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/flashnet/flashnet_api_schema.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/utils/list_extension.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_zano/zano_wallet_api.dart";

class FlashnetExchangeProvider extends ExchangeProvider
    implements TransactionRegistrationExchangeProvider {

  static const baseUrl = "orchestration.flashnet.xyz";
  static const limitsPath = "/v1/orchestration/limits";
  static const quotePath = "/v1/orchestration/quote";
  static const apiKey = secrets.flashnetClientKey;
  static const slippageBps = 50;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.flashnet;

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;


  @override
  Future<ExchangeLimits> fetchLimits({required CryptoCurrency from, required CryptoCurrency to, required bool isFixedRateMode}) async {
    final req = FlashnetLimitsRequest(
      sourceAsset: _normalizeCurrency(from),
      destinationAsset: _normalizeCurrency(to),
      sourceChain: _chainFor(from),
      destinationChain: _chainFor(to)
    );

    final resp = await proxyWrapper.get(clearnetUri: Uri.https(baseUrl, limitsPath, req.toJson()));
    if(resp.statusCode < 200 || resp.statusCode > 299) {
      throw Exception("status code: ${resp.statusCode}");
    }
    final respData = FlashnetLimitsResponse.fromJson(jsonDecode(resp.body));



    final routeLimits = respData.routes
        .map((item) => isFixedRateMode ? item.limits.exactOut : item.limits.exactIn)
        .where((item) => item.supported);

    if(routeLimits.isEmpty) {
      throw Exception("no routes");
    }

    final limitsCurrency = isFixedRateMode ? to : from;


    final Money? minAmount;
    final Money? maxAmount;

    final minAmounts = routeLimits
        .map((item) => item.requestAmount!.minAmountSmallest);
    if (minAmounts.any((item) => item == null)) {
      minAmount = null;
    } else {
      minAmount = minAmounts
          .map((item) => Money.safeParse(item, limitsCurrency, isBaseUnit: true))
          .min;
    }


    final maxAmounts = routeLimits
        .map((item) => item.requestAmount!.maxAmountSmallest);
    if (maxAmounts.any((item) => item == null)) {
      maxAmount = null;
    } else {
      maxAmount = maxAmounts
          .map((item) => Money.safeParse(item, limitsCurrency, isBaseUnit: true))
          .max;
    }

    return ExchangeLimits(min: minAmount, max: maxAmount);
  }

  @override
  Future<ProviderRate> fetchRate({required Money from, required CryptoCurrency to, required bool isFixedRate}) async {
    final req = FlashnetEstimateRequest(sourceChain: _chainFor(from.currency as CryptoCurrency),
        sourceAsset: _normalizeCurrency(from.currency as CryptoCurrency),
        destinationChain: _chainFor(to),
        destinationAsset: _normalizeCurrency(to),
        amount: from.toStringWithPrecision(useBaseUnit: true),
        amountMode: isFixedRate ? .exactOut : .exactIn,
        deliveryMode: isFixedRate ? .fixed : .variable,
        slippageBps: 50,
    );

    final resp = await proxyWrapper.get(clearnetUri: Uri.https(baseUrl, quotePath, req.toJson()));
    if(resp.statusCode < 200 || resp.statusCode > 299) {
      throw Exception("status code: ${resp.statusCode}");
    }
    final respData = FlashnetEstimateResponse.fromJson(jsonDecode(resp.body));


    return ProviderRate(provider: description,
        rate: ExchangeRate.fromAmounts(
            from, Money.parse(respData.estimatedOut, to, isBaseUnit: true)),
        limits: await fetchLimits(
            from: from.currency as CryptoCurrency, to: to, isFixedRateMode: isFixedRate));
  }


  @override
  Future<Trade> createTrade({required TradeRequest request}) {
    // TODO: implement createTrade
    throw UnimplementedError();
  }


  @override
  Future<Trade> findTradeById({required String id}) {
    // TODO: implement findTradeById
    throw UnimplementedError();
  }


  @override
  Future<void> registerTransaction(String txHash) {
    // TODO: implement registerTransaction
    throw UnimplementedError();
  }



  @override
  String get title => description.title;

  String _normalizeCurrency(CryptoCurrency currency) => switch (currency.title.toUpperCase()) {
    "USDC.E" => "USDC.e",
    "USDE" => "USDe",
    "CBBTC" => "cbBTC",
    "TBTC" => "tBTC",
    final title => title,
  };

  FlashnetChain _chainFor(CryptoCurrency currency) => currency.tag != null
      ? _normalizeTag(currency.tag!)
      : _normalizeTitleToChain(currency.title);

  FlashnetChain _normalizeTag(String tag) => switch (tag.toUpperCase()) {
    "ETH" => FlashnetChain.ethereum,
    "BSC" => FlashnetChain.bsc,
    "POL" => FlashnetChain.polygon,
    "ARB" => FlashnetChain.arbitrum,
    "BASE" => FlashnetChain.base,
    "AVAXC" => FlashnetChain.avalanche,
    "SOL" => FlashnetChain.solana,
    "TRX" => FlashnetChain.tron,
    "LN" => FlashnetChain.lightning,
    "ZEC" => FlashnetChain.zcash,
    _ => throw Exception("unsupported chain"),
  };

  FlashnetChain _normalizeTitleToChain(String title) => switch (title.toUpperCase()) {
    "BTC" => FlashnetChain.bitcoin,
    "ETH" => FlashnetChain.ethereum,
    "LTC" => FlashnetChain.litecoin,
    "XMR" => FlashnetChain.monero,
    "ZEC" => FlashnetChain.zcash,
    "XRP" => FlashnetChain.xrp,
    "TON" => FlashnetChain.ton,
    "SOL" => FlashnetChain.solana,
    "TRX" => FlashnetChain.tron,
    _ => throw Exception("unsupported chain"),
  };

  String? _normalizeChainToTag(FlashnetChain chain) => switch (chain) {
    FlashnetChain.ethereum => "ETH",
    FlashnetChain.bsc => "BSC",
    FlashnetChain.polygon => "POL",
    FlashnetChain.arbitrum => "ARB",
    FlashnetChain.base => "BASE",
    FlashnetChain.avalanche => "AVAXC",
    FlashnetChain.solana => "SOL",
    FlashnetChain.tron => "TRX",
    FlashnetChain.lightning => "LN",
    _ => null,
  };

  CryptoCurrency _normalizeToCurrency(FlashnetChain? chain, String asset) {


    final title = asset.toUpperCase();
    final tag = chain == null ? null : _normalizeChainToTag(chain);

    return CryptoCurrency.safeParseCurrencyFromString(title, tag: tag == title ? null : tag)!;
  }


}
