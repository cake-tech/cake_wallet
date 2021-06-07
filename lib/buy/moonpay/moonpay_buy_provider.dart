import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cake_wallet/buy/buy_exception.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/buy/buy_amount.dart';
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

class MoonPayBuyProvider extends BuyProvider {
  MoonPayBuyProvider({WalletBase wallet, bool isTestEnvironment = false})
      : super(wallet: wallet, isTestEnvironment: isTestEnvironment) {
      baseUrl = isTestEnvironment ? _baseTestUrl : _baseProductUrl;
  }

  static const _baseTestUrl = 'https://buy-staging.moonpay.com';
  static const _baseProductUrl = 'https://buy.moonpay.com';
  static const _apiUrl = 'https://api.moonpay.com';
  static const _currenciesSuffix = '/v3/currencies';
  static const _quoteSuffix = '/buy_quote';
  static const _transactionsSuffix = '/v1/transactions';
  static const _ipAddressSuffix = '/v4/ip_address';
  static const _apiKey = secrets.moonPayApiKey;
  static const _secretKey = secrets.moonPaySecretKey;

  @override
  String get title => 'MoonPay';

  @override
  BuyProviderDescription get description => BuyProviderDescription.moonPay;

  String get currencyCode =>
    walletTypeToCryptoCurrency(walletType).title.toLowerCase();

  @override
  String get trackUrl => baseUrl + '/transaction_receipt?transactionId=';

  String baseUrl;

  @override
  Future<String> requestUrl(String amount, String sourceCurrency) async {
    final enabledPaymentMethods =
        'credit_debit_card%2Capple_pay%2Cgoogle_pay%2Csamsung_pay'
        '%2Csepa_bank_transfer%2Cgbp_bank_transfer%2Cgbp_open_banking_payment';

    final suffix = '?apiKey=' + _apiKey + '&currencyCode=' +
        currencyCode + '&enabledPaymentMethods=' + enabledPaymentMethods +
        '&walletAddress=' + walletAddress +
        '&baseCurrencyCode=' + sourceCurrency.toLowerCase() +
        '&baseCurrencyAmount=' + amount + '&lockAmount=true' +
        '&showAllCurrencies=false' + '&showWalletAddressForm=false';

    final originalUrl = baseUrl + suffix;

    final messageBytes = utf8.encode(suffix);
    final key = utf8.encode(_secretKey);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(messageBytes);
    final signature = base64.encode(digest.bytes);
    final urlWithSignature = originalUrl +
          '&signature=${Uri.encodeComponent(signature)}';

    return isTestEnvironment ? originalUrl : urlWithSignature;
  }

  @override
  Future<BuyAmount> calculateAmount(String amount, String sourceCurrency) async {
    final url = _apiUrl + _currenciesSuffix + '/$currencyCode' +
        _quoteSuffix + '/?apiKey=' + _apiKey +
        '&baseCurrencyAmount=' + amount +
        '&baseCurrencyCode=' + sourceCurrency.toLowerCase();

    final response = await get(url);

    if (response.statusCode != 200) {
      throw BuyException(
          description: description,
          text: 'Quote is not found!');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final sourceAmount = responseJSON['totalAmount'] as double;
    final destAmount = responseJSON['quoteCurrencyAmount'] as double;
    final minSourceAmount = responseJSON['baseCurrency']['minAmount'] as int;

    return BuyAmount(
        sourceAmount: sourceAmount,
        destAmount: destAmount,
        minAmount: minSourceAmount);
  }

  @override
  Future<Order> findOrderById(String id) async {
    final url = _apiUrl + _transactionsSuffix + '/$id' +
        '?apiKey=' + _apiKey;

    final response = await get(url);

    if (response.statusCode != 200) {
      throw BuyException(
          description: description,
          text: 'Transaction $id is not found!');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final status = responseJSON['status'] as String;
    final state = TradeState.deserialize(raw: status);
    final createdAtRaw = responseJSON['createdAt'] as String;
    final createdAt = DateTime.parse(createdAtRaw).toLocal();
    final amount = responseJSON['quoteCurrencyAmount'] as double;

    return Order(
        id: id,
        provider: description,
        transferId: id,
        state: state,
        createdAt: createdAt,
        amount: amount.toString(),
        receiveAddress: walletAddress,
        walletId: walletId
    );
  }

  static Future<bool> onEnabled() async {
    final url = _apiUrl + _ipAddressSuffix + '?apiKey=' + _apiKey;
    var isBuyEnable = false;

    final response = await get(url);

    try {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      isBuyEnable = responseJSON['isBuyAllowed'] as bool;
    } catch (e) {
      isBuyEnable = false;
      print(e.toString());
    }

    return isBuyEnable;
  }
}