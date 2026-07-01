import 'package:cake_wallet/exchange/trade.dart';

abstract class ExchangeTradeState {}

class ExchangeTradeStateInitial extends ExchangeTradeState {}

class TradeIsCreating extends ExchangeTradeState {}

class TradeIsCreatedSuccessfully extends ExchangeTradeState {
  TradeIsCreatedSuccessfully({required this.trade});

  final Trade trade;
}

class TradeIsCreatedFailure extends ExchangeTradeState {
  TradeIsCreatedFailure({required this.title, required this.error});

  final String title;
  final String error;
}
