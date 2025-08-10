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
  Future<Order> findOrderById(String id, {CakePayPaymentMethod? paymentMethod}) async {
    final order = await cakePayService.findOrderById(orderId: id);
    final paymentData = CakePayOrder.getPaymentDataFor(method: paymentMethod, order: order);

    return Order(
        id: order.orderId,
        state: TradeState.deserialize(raw: order.status),
        transferId: order.externalId ?? '',
        from: CakePayOrder.getCurrencyCodeFromPaymentMethod(paymentMethod!),
        to: order.fiatCurrencyCode,
        createdAt: DateTime.now(),
        amount: paymentData?.amount ?? '',
        receiveAmount: order.totalReceiveAmount,
        receiveAddress: paymentData?.address ?? '',
        source: OrderSourceDescription.order,
        giftCardProvider: OrderProviderDescription.cakePay,
        walletId: wallet.id);
  }
}
