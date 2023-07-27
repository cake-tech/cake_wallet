import 'dart:async';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/view_model/dashboard/order_list_item.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/store/settings_store.dart';

part 'orders_store.g.dart';

class OrdersStore = OrdersStoreBase with _$OrdersStore;

abstract class OrdersStoreBase with Store {
  OrdersStoreBase({required this.ordersSource,
    required this.settingsStore})
    : orders = <OrderListItem>[],
      orderId = '' {
    _onOrdersChanged =
        ordersSource.watch().listen((_) async => await updateOrderList());
    updateOrderList();
  }

  Box<Order> ordersSource;

  SettingsStore settingsStore;

  StreamSubscription<BoxEvent>? _onOrdersChanged;

  @observable
  List<OrderListItem> orders;

  @observable
  Order? order;

  @observable
  String orderId;

  @action
  void setOrder(Order order) => this.order = order;

  @action
  Future updateOrderList() async => orders =
      ordersSource.values.map((order) => OrderListItem(
          order: order,
          settingsStore: settingsStore)).toList();
}