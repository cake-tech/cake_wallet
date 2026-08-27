import 'package:cw_core/history_source.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/action_list_item.dart';
import 'package:cake_wallet/order/order_provider_description.dart';
import 'package:cake_wallet/order/order_source_description.dart';
import "package:cake_wallet/order/order.dart";
import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';

part 'order_filter_store.g.dart';

class OrderFilterStore = OrderFilterStoreBase with _$OrderFilterStore;

abstract class OrderFilterStoreBase with Store implements HistoryFilters {
  OrderFilterStoreBase(this._appStore) : displayCakePay = true;

  final AppStore _appStore;

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

  /// Whether one order passes the wallet and provider filters.
  @override
  bool relevant(HistoryListItem item) {
    if (item is! Order || item.walletId != _appStore.wallet?.id) {
      return false;
    }

    final isOrderSource = item.source == OrderSourceDescription.order;
    final isCakePay = item.orderProvider == OrderProviderDescription.cakePay;

    return displayCakePay && isOrderSource && isCakePay;
  }


  List<Order> filtered({required List<Order> orders}) => orders.where(relevant).toList();
}
