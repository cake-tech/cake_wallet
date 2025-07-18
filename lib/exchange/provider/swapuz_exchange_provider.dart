import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_not_created_exception.dart';
import 'package:cake_wallet/exchange/trade_not_found_exception.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/utils/currency_pairs_utils.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';

class SwapuzExchangeProvider extends ExchangeProvider {
  SwapuzExchangeProvider() : super(pairList: supportedPairs(_notSupported));

  static const List<CryptoCurrency> _notSupported = [
    CryptoCurrency.tbtc,
    CryptoCurrency.usdt, // OMNI usdt
    CryptoCurrency.xhv,
    CryptoCurrency.xag,
    CryptoCurrency.xau,
    CryptoCurrency.xaud,
    CryptoCurrency.xbtc,
    CryptoCurrency.xcad,
    CryptoCurrency.xchf,
    CryptoCurrency.xcny,
    CryptoCurrency.xeur,
    CryptoCurrency.xgbp,
    CryptoCurrency.xjpy,
    CryptoCurrency.xnok,
    CryptoCurrency.xnzd,
    CryptoCurrency.xusd,
    CryptoCurrency.btt,
    CryptoCurrency.bttc,
    CryptoCurrency.firo,
    CryptoCurrency.sc,
    CryptoCurrency.zaddr,
    CryptoCurrency.zec,
    CryptoCurrency.xvg,
    CryptoCurrency.btcln,
    CryptoCurrency.ftm,
    CryptoCurrency.gusd,
    CryptoCurrency.gtc,
    CryptoCurrency.banano,
    CryptoCurrency.kaspa,
    CryptoCurrency.wow,
    CryptoCurrency.zano,
    CryptoCurrency.deuro,
    CryptoCurrency.usdcpoly,
  ];

  // API Configuration
  static const baseApiUrl = 'api.swapuz.com';
  static const getRatePath = '/api/Home/v1/rate';
  static const createOrderPath = '/api/Home/v1/order';
  static const getOrderPath = '/api/Order/uid/';
  static const getLimitsPath = '/api/Home/getLimits';
  final partnerApiKey = secrets.swapuzApiKey;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<Trade> createTrade({
    required TradeRequest request,
    required bool isFixedRateMode,
    required bool isSendAll,
  }) async {
    try {
      var body = <String, dynamic>{
        'from': request.fromCurrency.title,
        'to': request.toCurrency.title,
        'fromNetwork': _normalizeNetwork(request.fromCurrency),
        'toNetwork': _normalizeNetwork(request.toCurrency),
        'address': request.toAddress,
        'amount': request.fromAmount,
        'modeCurs': isFixedRateMode ? 'fix' : 'float',
        'refundAddress': request.refundAddress,
      };

      final uri = Uri.https(baseApiUrl, createOrderPath);
      final response = await ProxyWrapper().post(
        clearnetUri: uri,
        headers: _buildHeaders(),
        body: json.encode(body),
      );

      final responseBody = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 400) {
        final error = responseBody['message'] as String;
        throw TradeNotCreatedException(description, description: error);
      }

      if (response.statusCode != 200) {
        throw Exception('Unexpected http status: ${response.statusCode}');
      }

      final result = responseBody['result'] as Map<String, dynamic>;

      return Trade(
        id: result["uid"] as String,
        from: request.fromCurrency,
        to: request.toCurrency,
        provider: description,
        inputAddress: result["addressFrom"] as String,
        amount: result["amount"].toString(),
        receiveAmount: result["amountResult"].toString(),
        createdAt: DateTime.parse(result["createDate"] as String),
        expiredAt: DateTime.parse(result["finishPayment"] as String? ?? ''),
        state: TradeState.created,
        payoutAddress: request.toAddress,
        refundAddress: result["addressRefund"] as String?,
        isSendAll: isSendAll,
        txId: result["withdrawalTransactionID"] as String?,
        memo: result["memoFrom"] as String?,
        extraId: result["extraIdReceive"] as String?,
        outputTransaction: result["wTxId"] as String?,
      );
    } catch (e) {
      printV("error creating trade: ${e.toString()}");
      throw TradeNotCreatedException(description, description: e.toString());
    }
  }

  @override
  ExchangeProviderDescription get description =>
      ExchangeProviderDescription.swapuz;

  @override
  Future<Limits> fetchLimits({
    required from,
    required to,
    required bool isFixedRateMode,
  }) async {
    try {
      final params = <String, dynamic>{
        'coin': from.title,
      };
      final uri = Uri.https(baseApiUrl, getLimitsPath, params);
      final response = await ProxyWrapper().get(
        clearnetUri: uri,
        headers: _buildHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Unexpected http status: ${response.statusCode}');
      }

      final responseBody = json.decode(response.body) as Map<String, dynamic>;

      if (responseBody['result'] == null) {
        throw Exception('No limits data received from API');
      }

      final result = responseBody['result'] as Map<String, dynamic>;
      return Limits(
        min: double.parse(result['minAmount'].toString()),
        max: double.parse(result['maxAmount'].toString()),
      );
    } catch (e) {
      printV("error fetching limits: ${e.toString()}");
      return Limits(min: 0, max: 0);
    }
  }

  @override
  Future<double> fetchRate({
    required from,
    required to,
    required double amount,
    required bool isFixedRateMode,
    required bool isReceiveAmount,
  }) async {
    try {
      if (amount == 0) return 0.0;

      final params = <String, dynamic>{
        'from': from.title,
        'to': to.title,
        'fromNetwork': _normalizeNetwork(from),
        'toNetwork': _normalizeNetwork(to),
        'amount': amount.toString(),
        'mode': isFixedRateMode ? 'fix' : 'float',
      };

      final uri = Uri.https(baseApiUrl, getRatePath, params);
      final response = await ProxyWrapper().get(
        clearnetUri: uri,
        headers: _buildHeaders(),
      );

      if (response.statusCode != 200) {
        printV("error fetching rate: ${response.body}");
        throw Exception('Unexpected http status: ${response.statusCode}');
      }

      final responseBody = json.decode(response.body) as Map<String, dynamic>;

      if (responseBody['result'] == null) {
        throw Exception('No rate data received from API');
      }

      final result = responseBody['result'] as Map<String, dynamic>;

      double rate = double.parse(result['rate'].toString());
      return rate;
    } catch (e) {
      printV("error fetching rate: ${e.toString()}");
      return 0.0;
    }
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    try {
      final uri = Uri.https(baseApiUrl, '$getOrderPath$id');
      final response = await ProxyWrapper().get(
        clearnetUri: uri,
        headers: _buildHeaders(),
      );

      if (response.statusCode != 200) {
        throw TradeNotFoundException(id, provider: description);
      }

      final responseBody = json.decode(response.body) as Map<String, dynamic>;

      if (responseBody['result'] == null) {
        throw TradeNotFoundException(id, provider: description);
      }

      final responseResult = responseBody['result'] as Map<String, dynamic>;
      return Trade(
        id: responseResult['uid'] as String,
        from: CryptoCurrency.fromString(
            responseResult['from']['shortName'] as String),
        to: CryptoCurrency.fromString(
            responseResult['to']['shortName'] as String),
        provider: description,
        inputAddress: responseResult['addressFrom'] as String,
        amount: responseResult['amount'].toString(),
        payoutAddress: responseResult['addressTo'] as String,
        state: _deserializeSwapuzStatus(
          statusCode: responseResult['status'] as int,
        ),
        receiveAmount: responseResult['amountResult'].toString(),
        memo: responseResult['memoFrom'] as String?,
        extraId: responseResult['extraIdReceive'] as String?,
        createdAt:
            DateTime.parse(responseResult['createDate'] as String? ?? ''),
        expiredAt: DateTime.parse(
            responseResult['finishPayment'] as String? ?? ''),
        refundAddress: responseResult['addressRefund'] as String?,
        txId: responseResult['withdrawalTransactionID'] as String?,
        outputTransaction: responseResult['withdrawalTransactionID'] as String?,
      );
    } catch (e) {
      printV("error finding trade by ID: ${e.toString()}");
      throw TradeNotFoundException(id, provider: description);
    }
  }

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  String get title => 'Swapuz';

  /// Maps Swapuz API status codes to TradeState enums
  TradeState _deserializeSwapuzStatus({required int statusCode}) {
    switch (statusCode) {
      case 0:
        return TradeState.unpaid;
      case 1:
        return TradeState.paidUnconfirmed;
      case 2:
      case 3:
      case 4:
        return TradeState.exchanging;
      case 5:
        return TradeState.sending;
      case 6:
        return TradeState.confirmed;
      case 10:
        return TradeState.overdue;
      case 11:
        return TradeState.refund;
      case 12:
      case 13:
        return TradeState.failed;
      default:
        return TradeState.notFound;
    }
  }

  Map<String, String> _buildHeaders() {
    return {
      'Api-key': partnerApiKey,
      'Content-Type': 'application/json',
    };
  }

  String _normalizeNetwork(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.nano:
        return 'NANO';
      case CryptoCurrency.avaxc:
        return 'CCHAIN';
      case CryptoCurrency.rune:
        return 'THORCHAIN';
      case CryptoCurrency.rvn:
        return 'RAVENCOIN';
      case CryptoCurrency.arb:
        return 'ARBITRUM';
      default:
        return currency.tag != null ? currency.tag! : currency.title;
    }
  }
}
