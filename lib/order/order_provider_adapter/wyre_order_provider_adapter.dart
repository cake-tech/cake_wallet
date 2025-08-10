import 'package:cake_wallet/buy/wyre/wyre_buy_provider.dart';
import 'package:cake_wallet/cake_pay/src/models/cake_pay_order.dart';
import 'package:cake_wallet/order/order.dart';
import 'package:cake_wallet/order/order_provider.dart';
import 'package:cw_core/wallet_base.dart';

class WyreOrderProviderAdapter implements OrderProvider {
  WyreOrderProviderAdapter({required WalletBase wallet})
      : _wyreProvider = WyreBuyProvider(wallet: wallet);

  final WyreBuyProvider _wyreProvider;

  @override
  Future<Order> findOrderById(String id, {CakePayPaymentMethod? paymentMethod}) =>
      _wyreProvider.findOrderById(id);

  @override
  String get title => _wyreProvider.title;

  @override
  String get trackUrl => _wyreProvider.trackUrl;
}
