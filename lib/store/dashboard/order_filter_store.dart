import "package:cake_wallet/order/order.dart";
import "package:cake_wallet/order/order_provider_description.dart";
import "package:cake_wallet/order/order_source_description.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/history_source.dart";

class OrderFilterStore extends HistoryFilters {
  OrderFilterStore(this._appStore) : displayCakePay = true;

  final AppStore _appStore;

  bool displayCakePay;

  bool get displayAllOrders => displayCakePay;

  void toggleDisplayOrder(OrderProviderDescription provider) {
    switch (provider) {
      case OrderProviderDescription.cakePay:
        displayCakePay = !displayCakePay;
        break;
    }
  }

  static const _cakePay = "Cake Pay";

  @override
  List<HistoryFilter> get filters =>
      [HistoryFilter(key: _cakePay, caption: _cakePay, value: displayCakePay)];

  @override
  void toggleFilter(HistoryFilter filter) =>
      toggleDisplayOrder(OrderProviderDescription.cakePay);

  @override
  void setAllFilters({required bool value}) => displayCakePay = value;

  @override
  bool relevant(HistoryListItem item) {
    if (item is! Order || item.walletId != _appStore.wallet?.id) {
      return false;
    }

    final isOrderSource = item.source == OrderSourceDescription.order;
    final isCakePay = item.orderProvider == OrderProviderDescription.cakePay;

    return displayCakePay && isOrderSource && isCakePay;
  }


}
