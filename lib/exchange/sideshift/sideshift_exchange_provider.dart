import 'dart:convert';
import 'package:cake_wallet/exchange/sideshift/sideshift_request.dart';
import 'package:cake_wallet/exchange/trade_not_found_exeption.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/exchange/exchange_pair.dart';
import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/trade_not_created_exeption.dart';

class SideShiftExchangeProvider extends ExchangeProvider {
  SideShiftExchangeProvider({this.trade})
      : super(pairList: [
          ExchangePair(from: CryptoCurrency.xmr, to: CryptoCurrency.btc),
          ExchangePair(from: CryptoCurrency.btc, to: CryptoCurrency.xmr)
        ]);

  static const apiUri = 'https://sideshift.ai/api/v1';
  static const accountId = secrets.sideshiftAccountId;
  static const _pairsSuffix = '/pairs/';
  static const _quoteSuffix = '/quotes';
  static const _orderSuffix = '/orders';

  String quoteId;

  Trade trade;

  @override
  String get title => 'SideShift.ai';

  @override
  bool get isAvailable => true;

  @override
  ExchangeProviderDescription get description =>
      ExchangeProviderDescription.sideshift;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<Limits> fetchLimits(
      {CryptoCurrency from, CryptoCurrency to, bool isFixedRateMode}) async {
    final symbol =
        transcribeCurrencyCode(from) + '/' + transcribeCurrencyCode(to);
    final url = apiUri + _pairsSuffix + symbol;

    final pairsResponse = await get(url);

    final pairsResponseJSON =
        json.decode(pairsResponse.body) as Map<String, dynamic>;
    final min = pairsResponseJSON["min"] as String;
    final max = pairsResponseJSON["max"] as String;

    return Limits(min: double.parse(min), max: double.parse(max));
  }

  @override
  Future<Trade> createTrade(
      {TradeRequest request, bool isFixedRateMode}) async {
    final orderUrl = apiUri + _orderSuffix;
    final _request = request as SideShiftRequest;

    if (isFixedRateMode) {
      final fixedOrderBody = {
        "type": "fixed",
        "quoteId": quoteId,
        "settleAddress": _request.settleAddress,
        "refundAddress": _request.refundAddress
      };

      final fixedOrderResponse = await post(orderUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(fixedOrderBody));

      handleCreateOrderError(fixedOrderResponse);

      final fixedOrderResponseJSON =
          json.decode(fixedOrderResponse.body) as Map<String, dynamic>;

      return Trade(
          id: fixedOrderResponseJSON["id"] as String,
          from: _request.depositMethod,
          to: _request.settleMethod,
          amount: _request.depositAmount,
          provider: description,
          inputAddress:
              fixedOrderResponseJSON["depositAddress"]["address"] as String,
          extraId: fixedOrderResponseJSON["depositAddress"]["memo"] as String,
          refundAddress: _request.refundAddress,
          createdAt: DateTime.now(),
          state: TradeState.created);
    }
  }

  @override
  Future<Trade> findTradeById({@required String id}) async {
    final url = apiUri + _orderSuffix + '/' + id;
    final ordersResponse = await get(url);

    handleTradeNotFoundError(id, ordersResponse);

    final ordersResponseJSON =
        json.decode(ordersResponse.body) as Map<String, dynamic>;

    final expiredAt =
        DateTime.parse(ordersResponseJSON["expiresAtISO"] as String).toLocal();
    final depositMethodId = ordersResponseJSON["depositMethodId"] as String;
    final from = CryptoCurrency.fromString(depositMethodId);
    final settleMethodId = ordersResponseJSON["settleMethodId"] as String;
    final to = CryptoCurrency.fromString(settleMethodId);
    final inputAddress =
        ordersResponseJSON["depositAddress"]["address"] as String;
    final expired = expiredAt.isBefore(DateTime.now());
    final deposit = ordersResponseJSON["deposits"] as List;
    final status = deposit.isNotEmpty ? deposit[0]["status"] as String : 'created';
    final state = status == 'created' && expired ? 'expired' : status;
    final settleTx =
        deposit.isNotEmpty ? deposit[0]["settleTx"] as Map<String, dynamic> : null;
    final outputTransaction =
        settleTx != null ? settleTx["txHash"] as String : null;
    final amount = trade.amount;

    return Trade(
      id: id,
      from: from,
      to: to,
      provider: description,
      inputAddress: inputAddress,
      amount: amount,
      state: TradeState.deserialize(raw: state),
      expiredAt: expiredAt,
      outputTransaction: outputTransaction,
    );
  }

  @override
  Future<double> calculateAmount(
      {CryptoCurrency from,
      CryptoCurrency to,
      final double amount,
      bool isFixedRateMode,
      bool isReceiveAmount}) async {
    final quoteUrl = apiUri + _quoteSuffix;

    final quoteBody = {
      'depositMethod': transcribeCurrencyCode(from),
      'settleMethod': transcribeCurrencyCode(to),
      'depositAmount': amount.toString()
    };

    final quoteResponse = await post(quoteUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(quoteBody));

    final quoteResponseJSON =
        json.decode(quoteResponse.body) as Map<String, dynamic>;

    quoteId = quoteResponseJSON["id"].toString();

    return double.parse(quoteResponseJSON['settleAmount'].toString());
  }

  void handleCreateOrderError(Response response) {
    if (response.statusCode != 200 && response.statusCode != 201) {
      if (response.statusCode == 400) {
        final responseJSON = json.decode(response.body) as Map<String, dynamic>;
        final error = responseJSON["error"]["message"] as String;

        throw TradeNotCreatedException(description, description: error);
      }

      throw TradeNotCreatedException(description);
    }
  }

  void handleTradeNotFoundError(String id, Response response) {
    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        final ordersResponseJSON =
            json.decode(response.body) as Map<String, dynamic>;
        final error = ordersResponseJSON["error"]["message"] as String;

        throw TradeNotFoundException(id,
            provider: description, description: error);
      }

      throw TradeNotFoundException(id, provider: description);
    }
  }

  String transcribeCurrencyCode(CryptoCurrency currencyCode) {
    return currencyCode.toString().toLowerCase();
  }
}
