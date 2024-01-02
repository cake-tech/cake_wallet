import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/moonpay/moonpay_provider.dart';
import 'package:cake_wallet/buy/wyre/wyre_buy_provider.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/buy/buy_item.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
import 'buy_amount_view_model.dart';

part 'buy_view_model.g.dart';

class BuyViewModel = BuyViewModelBase with _$BuyViewModel;

abstract class BuyViewModelBase with Store {
  BuyViewModelBase(this.ordersSource, this.ordersStore, this.settingsStore,
      this.buyAmountViewModel, {required this.wallet})
  : isRunning = false,
    isDisabled = true,
    isShowProviderButtons = false,
    items = <BuyItem>[] {
    _fetchBuyItems();
  }

  final Box<Order> ordersSource;
  final OrdersStore ordersStore;
  final SettingsStore settingsStore;
  final BuyAmountViewModel buyAmountViewModel;
  final WalletBase wallet;

  @observable
  BuyProvider? selectedProvider;

  @observable
  List<BuyItem> items;

  @observable
  bool isRunning;

  @observable
  bool isDisabled;

  @observable
  bool isShowProviderButtons;

  WalletType get type => wallet.type;

  double get doubleAmount => buyAmountViewModel.doubleAmount;

  @computed
  FiatCurrency get fiatCurrency => buyAmountViewModel.fiatCurrency;

  CryptoCurrency get cryptoCurrency => walletTypeToCryptoCurrency(type);

  Future <String> fetchUrl() async {
    String _url = '';

    try {
      _url = await selectedProvider!.requestUrl(doubleAmount.toString(), fiatCurrency.title);
    } catch (e) {
      print(e.toString());
    }

    return _url;
  }

  Future<void> saveOrder(String orderId) async {
    try {
      final order = await selectedProvider!.findOrderById(orderId);
      order.from = fiatCurrency.title;
      order.to = cryptoCurrency.title;
      await ordersSource.add(order);
      ordersStore.setOrder(order);
    } catch (e) {
      print(e.toString());
    }
  }

  void reset() {
    buyAmountViewModel.amount = '';
    selectedProvider = null;
  }

  Future<void> _fetchBuyItems() async {
    final List<BuyProvider> _providerList = [];

    if (wallet.type == WalletType.bitcoin) {
      _providerList.add(WyreBuyProvider(wallet: wallet));
    }

    var isMoonPayEnabled = false;
    try {
      isMoonPayEnabled = await MoonPayBuyProvider.onEnabled();
    } catch (e) {
      isMoonPayEnabled = false;
      print(e.toString());
    }

    if (isMoonPayEnabled) {
      _providerList.add(MoonPayBuyProvider(wallet: wallet));
    }

    items = _providerList.map((provider) =>
        BuyItem(provider: provider, buyAmountViewModel: buyAmountViewModel))
        .toList();
  }
}