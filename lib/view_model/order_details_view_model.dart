import 'dart:async';
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/onramper/onramper_buy_provider.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/entities/provider_types.dart';
import 'package:cake_wallet/utils/date_formatter.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/trade_details/track_trade_list_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cw_core/wallet_base.dart';

part 'order_details_view_model.g.dart';

class OrderDetailsViewModel = OrderDetailsViewModelBase
    with _$OrderDetailsViewModel;

abstract class OrderDetailsViewModelBase with Store {
  OrderDetailsViewModelBase({required WalletBase wallet, required Order orderForDetails})
  : items = ObservableList<StandartListItem>(), 
    order = orderForDetails {
   if (order.provider != null) {
     order.provider == ProviderType.onramper
         ? _provider = OnRamperBuyProvider(wallet: wallet, partner: order.onramperPartner)
         : _provider = ProvidersHelper.getProviderByType(order.provider!);
    }
    _updateItems();
    _updateOrder();
    timer = Timer.periodic(Duration(seconds: 20), (_) async => _updateOrder());
  }

  @observable
  Order order;

  @observable
  ObservableList<StandartListItem> items;

  BuyProvider? _provider;

  Timer? timer;

  @action
  Future<void> _updateOrder() async {
    try {
      final updatedOrder = await _provider!.findOrderById(order.transferId);

        updatedOrder.from = order.from;
        updatedOrder.to = order.to;
        updatedOrder.receiveAddress = order.receiveAddress;
        updatedOrder.walletId = order.walletId;
          updatedOrder.providerRaw = order.provider != null
              ? ProvidersHelper.serialize(order.provider!) : null;
        order = updatedOrder;
        _updateItems();
    } catch (e) {
      print(e.toString());
    }
  }

  void _updateItems() {
    final dateFormat = DateFormatter.withCurrentLocal();
    items.clear();
    items.addAll([
      StandartListItem(
          title: 'Transfer ID',
          value: order.transferId),
      StandartListItem(
          title: S.current.trade_details_state,
          value: order.state != null
              ? order.state.toString()
              : S.current.trade_details_fetching),
    ]);

    items.add(
      StandartListItem(
          title: 'Buy provider',
          value: order.provider?.title ?? '')
    );

    if(_provider != null) {
      if(_provider!.trackUrl.isNotEmpty  && order.transferId.isNotEmpty) {
        final buildURL = _provider!.trackUrl + '${order.transferId}';
        items.add(
            TrackTradeListItem(
                title: 'Track',
                value: buildURL,
                onTap: () {
                  try {
                    launchUrl(Uri.parse(buildURL));
                  } catch (e) {}
                }
            )
        );
      }
    }

    items.add(
        StandartListItem(
            title: S.current.trade_details_created_at,
            value: dateFormat.format(order.createdAt).toString())
    );

    items.add(
        StandartListItem(
            title: S.current.trade_details_pair,
            value: '${order.from} → ${order.to}')
    );
  }
}