import "dart:convert";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/swaptrade/swaptrade_api_schema.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_not_created_exception.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/proxy_wrapper.dart";

class SwapTradeExchangeProvider extends ExchangeProvider {
  SwapTradeExchangeProvider({super.proxyWrapper});

  static const markup = secrets.swapTradeExchangeMarkup;

  static const apiAuthority = "api.swaptrade.io";
  static const getRate = "/api/swap/get-rate";
  static const getCoins = "/api/swap/get-coins";
  static const createOrder = "/api/swap/create-order";
  static const order = "/api/swap/order";

  @override
  String get title => "SwapTrade";

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => false;

  @override
  bool get supportsMemoOrDestinationTag => false;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.swapTrade;

  static const _headers = <String, String>{"Content-Type": "application/json"};

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<ExchangeLimits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
      final uri = Uri.https(apiAuthority, getCoins);
      final response = await proxyWrapper.get(clearnetUri: uri);

      final responseJSON = SwapTradeCoinsResponse.fromJson(json.decode(response.body) as Map<String, dynamic>);

      if (response.statusCode != 200) {
        throw Exception("Unexpected http status: ${response.statusCode}");
      }

      final coinsInfo = responseJSON.data;

      if(coinsInfo == null){
        throw Exception("coin unsupported");
      }

      final normalized = _normalizeCurrency(from);
      final coin = coinsInfo.firstWhere(
            (c) => (c.id.toUpperCase()) == normalized,
          );

      return ExchangeLimits(
          min: Money.tryParse(coin.min, from), max: Money.tryParse(coin.max, from));
  }

  @override
  Future<ProviderRate> fetchRate(
      {required Money from,
      required CryptoCurrency to,
      required bool isFixedRate,
      }) async {
      if (isFixedRate) {
        throw Exception("fixed rate unsupported");
      }
      if (from.currency == CryptoCurrency.btcln || to == CryptoCurrency.btcln) {
        throw Exception("lightning not supported");
      }

      final body = SwapTradeGetRateRequest(
        coinSend: _normalizeCurrency(from.currency as CryptoCurrency),
        coinReceive: _normalizeCurrency(to),
        amount: from.amount.toString(),
      );

      final uri = Uri.https(apiAuthority, getRate);
      final response = await proxyWrapper.post(
        clearnetUri: uri,
        body: json.encode(body),
        headers: _headers,
      );

      final responseBody = SwapTradeRateResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>);

      if (response.statusCode != 200) {
        throw Exception("Unexpected http status: ${response.statusCode}");
      }

      final rate = responseBody.data?.price;
      return ProviderRate(provider: description,
          rate: ExchangeRate(base: from.currency, quote: Money.parse(rate, to)),
          limits: await fetchLimits(
              from: from.currency as CryptoCurrency, to: to, isFixedRateMode: isFixedRate));
  }

  @override
  Future<Trade> createTrade({
    required TradeRequest request,
  }) async {

      final body = SwapTradeCreateOrderRequest(
          coinSend: _normalizeCurrency(request.depositCurrency),
          coinSendNetwork: _networkFor(request.depositCurrency),
          coinReceive: _normalizeCurrency(request.payoutCurrency),
          coinReceiveNetwork: _networkFor(request.payoutCurrency),
          amountSend: request.depositAmount.cryptoAmount.toString(),
          recipient: request.payoutAddress.address,
          markup: double.parse(markup),
          refundAddress: request.refundAddress
      );

      final uri = Uri.https(apiAuthority, createOrder);
      final response = await proxyWrapper.post(
        clearnetUri: uri,
        body: json.encode(body),
        headers: _headers,
      );

      final responseBody = SwapTradeOrderResponse.fromJson(json.decode(response.body) as Map<String, dynamic>);

      if (response.statusCode == 400 || responseBody.success == false) {
        final errorsList = responseBody.errors ?? [];
        final error = errorsList.firstOrNull?.msg ?? responseBody.toString();
        throw TradeNotCreatedException(description, description: error);
      }

      if (response.statusCode != 200) {
        throw Exception("Unexpected http status: ${response.statusCode}");
      }

      final responseData = responseBody.data;

      return Trade(
        id: responseData!.orderId,
        fundingAddress: responseData.serverAddress,
        provider: description,
        createdAt: DateTime.now(),
        state: TradeState.created,
        payoutAddress: request.payoutAddress.address,
        refundAddress: request.refundAddress,
        depositAmount: Money.parse(responseData.amountSend??0, request.depositCurrency),
        payoutAmount: Money.parse(responseData.amountReceive??0,request.payoutCurrency)
      );
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
      final body = SwapTradeOrderRequest(orderId: id);

      final uri = Uri.https(apiAuthority, order);
      final response = await proxyWrapper.post(
        clearnetUri: uri,
        body: json.encode(body),
        headers: _headers,
      );

      final responseBody = SwapTradeOrderResponse.fromJson(json.decode(response.body) as Map<String, dynamic>);

      if (response.statusCode == 400 || responseBody.success == false) {
        final error = responseBody.errors?.firstOrNull?.msg.toString();
        throw TradeNotCreatedException(description, description: error??"");
      }

      if (response.statusCode != 200) {
        throw Exception("Unexpected http status: ${response.statusCode}");
      }

      final responseData = responseBody.data!;

      return Trade(
        id: responseData.orderId,
        provider: description,
        state: responseData.status,
        memo: responseData.memo,
        createdAt: responseData.createdAt,
        depositAmount: Money.parse(responseData.amountSend,
            CryptoCurrency.safeParseCurrencyFromString(responseData.coinSend)!),
        payoutAmount: Money.parse(responseData.amountReceive,
            CryptoCurrency.safeParseCurrencyFromString(responseData.coinReceive)!),
        fundingAddress: responseData.serverAddress,
        payoutAddress: responseData.recipient,
        refundAddress: "",
      );
  }

  String _normalizeCurrency(CryptoCurrency currency) {
    switch (currency) {
      default:
        return currency.title.toUpperCase();
    }
  }

  String _networkFor(CryptoCurrency currency) {
    final network = switch (currency) {
      CryptoCurrency.eth => "ETH",
      CryptoCurrency.bnb => "BNB_BSC",
      CryptoCurrency.usdterc20 => "USDT_ERC20",
      CryptoCurrency.usdttrc20 => "TRX_USDT_S2UZ",
      CryptoCurrency.usdtbsc => "USDT_BSC",
      CryptoCurrency.sol => "SOL",
      CryptoCurrency.btc => "BTC",
      CryptoCurrency.xmr => "XMR",
      CryptoCurrency.ltc => "LTC",
      CryptoCurrency.ada => "ADA",
      CryptoCurrency.bch => "BCH",
      CryptoCurrency.zec => "ZEC",
      _ => currency.title.toUpperCase(),
    };
    return network;
  }
}
