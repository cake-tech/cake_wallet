import 'package:cake_wallet/order/order.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';

class OrderListItem extends ActionListItem {
  OrderListItem({
    required this.order,
    required this.settingsStore,
    required super.key,
  });

  final Order order;
  final SettingsStore settingsStore;

  BalanceDisplayMode get displayMode => settingsStore.balanceDisplayMode;

  String get orderFormattedAmount =>
      displayMode == BalanceDisplayMode.hiddenBalance ? '---' : order.amountFormatted();

  String get orderFormattedReceiveAddress =>
      displayMode == BalanceDisplayMode.hiddenBalance ? '---' : order.receiveAmount ?? '';

  @override
  DateTime get date => order.createdAt;
}