import 'dart:async';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/utils/date_formatter.dart';
import 'package:cake_wallet/view_model/wyre_view_model.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/trade_details/track_trade_list_item.dart';
import 'package:url_launcher/url_launcher.dart';

part 'order_details_view_model.g.dart';

class OrderDetailsViewModel = OrderDetailsViewModelBase
    with _$OrderDetailsViewModel;

abstract class OrderDetailsViewModelBase with Store {
  OrderDetailsViewModelBase({this.wyreViewModel, Order orderForDetails}) {
    order = orderForDetails;

    items = ObservableList<StandartListItem>();

    _updateItems();

    _updateOrder();

    _timer = Timer.periodic(Duration(seconds: 20), (_) async => _updateOrder());
  }

  @observable
  Order order;

  @observable
  ObservableList<StandartListItem> items;

  WyreViewModel wyreViewModel;

  Timer _timer;

  @action
  Future<void> _updateOrder() async {
    try {
      final updatedOrder =
            await wyreViewModel.wyreService.findOrderById(order.id);

      updatedOrder.receiveAddress = order.receiveAddress;
      updatedOrder.walletId = order.walletId;
      order = updatedOrder;

      _updateItems();
    } catch (e) {
      print(e.toString());
    }
  }

  void _updateItems() {
    final dateFormat = DateFormatter.withCurrentLocal();
    final buildURL =
        wyreViewModel.trackUrl + '${order.transferId}';

    items?.clear();

    items.addAll([
      StandartListItem(
          title: 'Transfer ID',
          value: order.transferId),
      StandartListItem(
          title: S.current.trade_details_state,
          value: order.state != null
              ? order.state.toString()
              : S.current.trade_details_fetching),
      TrackTradeListItem(
          title: 'Track',
          value: buildURL,
          onTap: () {
            launch(buildURL);
          }),
      StandartListItem(
          title: S.current.trade_details_created_at,
          value: dateFormat.format(order.createdAt).toString()),
      StandartListItem(
          title: S.current.trade_details_pair,
          value: '${order.from} → ${order.to}')
    ]);
  }
}