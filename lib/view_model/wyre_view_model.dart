import 'package:cake_wallet/entities/wyre_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/entities/order.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:mobx/mobx.dart';

part 'wyre_view_model.g.dart';

class WyreViewModel = WyreViewModelBase with _$WyreViewModel;

abstract class WyreViewModelBase with Store {
  WyreViewModelBase(this.ordersSource, this.ordersStore,
      {@required this.walletId, @required this.address, @required this.type})
      : wyreService = WyreService(walletType: type, walletAddress: address);

  Future<String> get wyreUrl => wyreService.getWyreUrl();

  String get trackUrl => wyreService.trackUrl;

  final Box<Order> ordersSource;
  final OrdersStore ordersStore;

  final String walletId;
  final WalletType type;
  final String address;

  WyreService wyreService;

  Future<void> saveOrder(String orderId) async {
    try {
      final order = await wyreService.findOrderById(orderId);
      order.receiveAddress = address;
      order.walletId = walletId;
      await ordersSource.add(order);
      ordersStore.setOrder(order);
    } catch (e) {
      print(e.toString());
    }
  }


}
