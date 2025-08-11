import 'dart:async';

import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:cake_wallet/cake_pay/src/models/cake_pay_order.dart';
import 'package:cake_wallet/cake_pay/src/services/cake_pay_service.dart';
import 'package:cake_wallet/core/utilities.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/order/order.dart';
import 'package:cake_wallet/order/order_provider.dart';
import 'package:cake_wallet/order/order_provider_adapter/cake_pay_order_provider_adapter.dart';
import 'package:cake_wallet/order/order_provider_adapter/wyre_order_provider_adapter.dart';
import 'package:cake_wallet/order/order_provider_description.dart';
import 'package:cake_wallet/order/order_source_description.dart';
import 'package:cake_wallet/src/screens/order_details/cake_pay_detail_list_card_item.dart';
import 'package:cake_wallet/src/screens/trade_details/track_trade_list_item.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_status_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/utils/date_formatter.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher.dart';

part 'order_details_view_model.g.dart';

class OrderDetailsViewModel = OrderDetailsViewModelBase with _$OrderDetailsViewModel;

abstract class OrderDetailsViewModelBase with Store {
  OrderDetailsViewModelBase({
    required WalletBase wallet,
    required Order orderForDetails,
    required this.cakePayService,
    required this.orders,
  })  : items = ObservableList<StandartListItem>(),
        order = orderForDetails {
    switch (order.source) {
      case OrderSourceDescription.buy:
        if (order.buyProvider == BuyProviderDescription.wyre) {
          _provider = WyreOrderProviderAdapter(wallet: wallet);
        } else if (order.buyProvider == BuyProviderDescription.moonPay) {
          //_provider = MoonPayOrderProviderAdapter(appStore: null /* provide if needed */, wallet: wallet);
        }
        break;

      case OrderSourceDescription.order:
        if (order.orderProvider == OrderProviderDescription.cakePay) {
          _provider = CakePayOrderProviderAdapter(wallet: wallet, cakePayService: cakePayService);
        }
        break;
    }

    _updateItems();
    _updateOrder();
    timer = Timer.periodic(const Duration(seconds: 20), (_) async => _updateOrder());
  }

  @observable
  Order order;

  @observable
  ObservableList<StandartListItem> items;

  final CakePayService cakePayService;
  final Box<Order> orders;
  OrderProvider? _provider;
  List<OrderCard> cards = [];

  Timer? timer;

  @action
  Future<void> _updateOrder() async {
    try {
      if (_provider == null) return;

      final updatedOrderObj = await _provider!.findOrderById(order.id);
      final updatedOrder = updatedOrderObj.$1;

      if (_provider is CakePayOrderProviderAdapter) {
        cards = updatedOrderObj.$2 as List<OrderCard>? ?? [];
      }

      final existing = orders.values.firstWhereOrNull((e) => e.id == updatedOrder.id);
      if (existing != null) {
        existing.stateRaw = updatedOrder.stateRaw;
        await existing.save();

        order = existing;
      } else {
        await orders.add(updatedOrder);
        order = updatedOrder;
      }

      _updateItems();
    } catch (e) {
      printV(e.toString());
    }
  }

  void _updateItems() {
    final dateFormat = DateFormatter.withCurrentLocal();
    items.clear();

    items.add(
        DetailsListStatusItem(title: S.current.trade_details_state, value: order.state.toString()));

    if (_provider is CakePayOrderProviderAdapter) {
      items.add(CakePayDetailsListCardItem(
        title: '',
        value: '',
        id: order.id,
        createdAt: dateFormat.format(order.createdAt),
        price: order.receiveAmount,
        quantity: order.quantity,
        from: order.from ?? '',
        to: order.to ?? '',
        cards: cards,
        onTap: (BuildContext context) {
          Clipboard.setData(ClipboardData(text: '${order.id}'));
          showBar<void>(context, S.of(context).copied_to_clipboard);
        },
      ));
    }

    items.add(StandartListItem(title: 'Order provider', value: _provider?.title ?? ''));

    final trackUrl = _provider?.trackUrl ?? '';
    if (trackUrl.isNotEmpty) {
      final buildURL = trackUrl + '${order.transferId}';
      items.add(TrackTradeListItem(
          title: S.current.track,
          value: buildURL,
          onTap: () async {
            try {
              final uri = Uri.parse(buildURL);
              if (await canLaunchUrl(uri))
                await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (e) {}
          }));
    }
  }
}
