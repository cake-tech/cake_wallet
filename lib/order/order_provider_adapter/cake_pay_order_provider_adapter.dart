import 'package:cake_wallet/cake_pay/src/models/cake_pay_order.dart';
import 'package:cake_wallet/cake_pay/src/services/cake_pay_service.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/order/order.dart';
import 'package:cake_wallet/order/order_provider.dart';
import 'package:cake_wallet/order/order_provider_description.dart';
import 'package:cake_wallet/order/order_source_description.dart';
import 'package:cw_core/wallet_base.dart';

class CakePayOrderProviderAdapter implements OrderProvider {
  CakePayOrderProviderAdapter({
    required this.wallet,
    required this.cakePayService,
  });

  final WalletBase wallet;
  final CakePayService cakePayService;

  @override
  String get title => 'Cake Pay';

  @override
  String get trackUrl => '';

  @override
  Future<(Order, Object?)> findOrderById(String id) async {
    final cakePayOrder = await cakePayService.findOrderById(orderId: id);
    final cards = cakePayOrder.cards;
    final order = Order(
      id: cakePayOrder.orderId,
      state: determineState(cakePayOrder.status),
      transferId: '',
      createdAt: DateTime.now(),
      amount: '',
      receiveAmount: cakePayOrder.totalReceiveAmount,
      quantity: cakePayOrder.quantity.toString(),
      receiveAddress: '',
      walletId: wallet.id,
      from: '',
      to: cakePayOrder.fiatCurrencyCode,
      source: OrderSourceDescription.order,
      giftCardProvider: OrderProviderDescription.cakePay,
    );
    return (order, cards);
  }

  TradeState determineState(String state) {
    final swapState = switch (state) {
      'new' => TradeState.pending,
      'expired_but_still_pending' => TradeState.overdue,
      'expired' => TradeState.expired,
      'failed' => TradeState.failed,
      'paid' => TradeState.paid,
      'paid_partial' => TradeState.underpaid,
      'pending_purchase' => TradeState.processing,
      'purchase_processing' => TradeState.processing,
      'purchased' => TradeState.confirmed,
      'pending_email' => TradeState.awaiting,
      'complete' => TradeState.complete,
      'pending_refund' => TradeState.refund,
      'refunded' => TradeState.refunded,
      _ => TradeState.notFound
    };

    return swapState;
  }
}
