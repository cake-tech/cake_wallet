import 'package:flutter/foundation.dart';
import 'package:cw_core/enumerable_item.dart';

class TradeState extends EnumerableItem<String> with Serializable<String> {
  const TradeState({@required String raw, @required String title})
      : super(raw: raw, title: title);

  @override
  bool operator ==(Object other) => other is TradeState && other.raw == raw;

  static const pending = TradeState(raw: 'pending', title: 'Pending');
  static const confirming = TradeState(raw: 'confirming', title: 'Confirming');
  static const trading = TradeState(raw: 'trading', title: 'Trading');
  static const traded = TradeState(raw: 'traded', title: 'Traded');
  static const complete = TradeState(raw: 'complete', title: 'Complete');
  static const toBeCreated =
      TradeState(raw: 'TO_BE_CREATED', title: 'To be created');
  static const unpaid = TradeState(raw: 'UNPAID', title: 'Unpaid');
  static const underpaid = TradeState(raw: 'UNDERPAID', title: 'Underpaid');
  static const paidUnconfirmed =
      TradeState(raw: 'PAID_UNCONFIRMED', title: 'Paid unconfirmed');
  static const paid = TradeState(raw: 'PAID', title: 'Paid');
  static const btcSent = TradeState(raw: 'BTC_SENT', title: 'Btc sent');
  static const timeout = TradeState(raw: 'TIMED_OUT', title: 'Timeout');
  static const notFound = TradeState(raw: 'NOT_FOUND', title: 'Not found');
  static const created = TradeState(raw: 'created', title: 'Created');
  static const finished = TradeState(raw: 'finished', title: 'Finished');
  static const waiting = TradeState(raw: 'waiting', title: 'Waiting');
  static const processing = TradeState(raw: 'processing', title: 'Processing');
  static const waitingPayment =
      TradeState(raw: 'waitingPayment', title: 'Waiting payment');
  static const waitingAuthorization =
      TradeState(raw: 'waitingAuthorization', title: 'Waiting authorization');
  static const failed = TradeState(raw: 'failed', title: 'Failed');
  static const completed = TradeState(raw: 'completed', title: 'Completed');
  static const settling = TradeState(raw: 'settling', title: 'Settlement in progress');
  static const settled = TradeState(raw: 'settled', title: 'Settlement completed');
  static TradeState deserialize({String raw}) {
    switch (raw) {
      case 'pending':
        return pending;
      case 'confirming':
        return confirming;
      case 'trading':
        return trading;
      case 'traded':
        return traded;
      case 'complete':
        return complete;
      case 'TO_BE_CREATED':
        return toBeCreated;
      case 'UNPAID':
        return unpaid;
      case 'UNDERPAID':
        return underpaid;
      case 'PAID_UNCONFIRMED':
        return paidUnconfirmed;
      case 'PAID':
        return paid;
      case 'BTC_SENT':
        return btcSent;
      case 'TIMED_OUT':
        return timeout;
      case 'created':
        return created;
      case 'finished':
        return finished;
      case 'waiting':
        return waiting;
      case 'processing':
        return processing;
      case 'waitingPayment':
        return waitingPayment;
      case 'waitingAuthorization':
        return waitingAuthorization;
      case 'failed':
        return failed;
      case 'completed':
        return completed;
      default:
        return null;
    }
  }

  @override
  int get hashCode => raw.hashCode ^ title.hashCode;
}
