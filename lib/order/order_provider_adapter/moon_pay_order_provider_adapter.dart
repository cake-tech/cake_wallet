import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:cake_wallet/buy/moonpay/moonpay_provider.dart';
import 'package:cake_wallet/cake_pay/src/models/cake_pay_order.dart';
import 'package:cake_wallet/order/order.dart';
import 'package:cake_wallet/order/order_provider.dart';
import 'package:cake_wallet/order/order_source_description.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/wallet_base.dart';

class MoonPayOrderProviderAdapter implements OrderProvider {
  MoonPayOrderProviderAdapter(
      {required AppStore appStore, required WalletBase wallet, bool isTestEnvironment = false})
      : _inner = MoonPayProvider(
          appStore: appStore,
          wallet: wallet,
          isTestEnvironment: isTestEnvironment,
        ),
        _wallet = wallet;

  final MoonPayProvider _inner;
  final WalletBase _wallet;

  @override
  String get title => 'MoonPay';

  @override
  String get trackUrl => _inner.trackUrl;

  @override
  Future<Order> findOrderById(String id, {CakePayPaymentMethod? paymentMethod}) async {
    final buyOrder = await _inner.findOrderById(id);
    return Order(
      id: buyOrder.id,
      transferId: buyOrder.transferId,
      createdAt: buyOrder.createdAt,
      amount: buyOrder.amount,
      receiveAmount: buyOrder.receiveAmount,
      receiveAddress: _wallet.walletAddresses.address,
      walletId: _wallet.id,
      from: buyOrder.from,
      to: buyOrder.to,
      state: buyOrder.state,
      source: OrderSourceDescription.buy,
      buyProvider: BuyProviderDescription.moonPay,
    );
  }
}
