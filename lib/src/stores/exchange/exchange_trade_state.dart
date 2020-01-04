import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/domain/exchange/trade.dart';

abstract class ExchangeTradeState {}

class ExchangeTradeStateInitial extends ExchangeTradeState {}

class TradeIsCreating extends ExchangeTradeState {}

class TradeIsCreatedSuccessfully extends ExchangeTradeState {
  final Trade trade;

  TradeIsCreatedSuccessfully({@required this.trade});
}

class TradeIsCreatedFailure extends ExchangeTradeState {
  final String error;

  TradeIsCreatedFailure({@required this.error});
}