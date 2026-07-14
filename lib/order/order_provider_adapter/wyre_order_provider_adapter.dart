import 'package:cake_wallet/buy/wyre/wyre_buy_provider.dart';
import 'package:cake_wallet/order/order.dart';
import 'package:cake_wallet/order/order_provider.dart';
import 'package:cw_core/wallet_base.dart';

class WyreOrderProviderAdapter implements OrderProvider {
  WyreOrderProviderAdapter({required WalletBase wallet})
      : _wyreProvider = WyreBuyProvider(wallet: wallet);

  final WyreBuyProvider _wyreProvider;

  @override
  Future<(Order, Object?)> findOrderById(String id) async {
    final order = await _wyreProvider.findOrderById(id);
    return (order, null);
  }

  @override
  String get title => _wyreProvider.title;

  @override
  String get trackUrl => _wyreProvider.trackUrl;
}
