import 'package:cake_wallet/entities/wyre_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/entities/order.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:mobx/mobx.dart';

part 'wyre_view_model.g.dart';

class WyreViewModel = WyreViewModelBase with _$WyreViewModel;

abstract class WyreViewModelBase with Store {
  WyreViewModelBase(this.ordersSource, this.ordersStore,
      {@required this.wyreService});

  Future<String> get wyreUrl => wyreService.getWyreUrl();

  String get trackUrl => wyreService.trackUrl;

  final Box<Order> ordersSource;
  final OrdersStore ordersStore;

  final WyreService wyreService;

  Future<void> saveOrder(String orderId) async {
    try {
      final order = await wyreService.findOrderById(orderId);
      await ordersSource.add(order);
      ordersStore.setOrder(order);
    } catch (e) {
      print(e.toString());
    }
  }
}