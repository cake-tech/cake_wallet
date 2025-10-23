import 'package:cake_wallet/order/order_provider_description.dart';
import 'package:cake_wallet/order/order_source_description.dart';
import 'package:cake_wallet/view_model/dashboard/order_list_item.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';

part 'order_filter_store.g.dart';

class OrderFilterStore = OrderFilterStoreBase with _$OrderFilterStore;

abstract class OrderFilterStoreBase with Store {
  OrderFilterStoreBase() : displayCakePay = true;

  @observable
  bool displayCakePay;

  @computed
  bool get displayAllOrders => displayCakePay;

  @action
  void toggleDisplayOrder(OrderProviderDescription provider) {
    switch (provider) {
      case OrderProviderDescription.cakePay:
        displayCakePay = !displayCakePay;
        break;
    }
  }

  List<OrderListItem> filtered({
    required List<OrderListItem> orders,
    required WalletBase wallet,
  }) {
    final walletOrders =
    orders.where((item) => item.order.walletId == wallet.id).toList();

    final cakePayOrders = walletOrders.where((item) {
      final order = item.order;
      final isOrderSource = order.source == OrderSourceDescription.order;
      final isCakePay = order.orderProvider == OrderProviderDescription.cakePay;
      return isOrderSource && isCakePay;
    }).toList();

    if (!displayCakePay) return <OrderListItem>[];
    return cakePayOrders;
  }
}