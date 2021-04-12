import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/moonpay/moonpay_buy_provider.dart';
import 'package:cake_wallet/buy/wyre/wyre_buy_provider.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/view_model/buy/buy_item.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'buy_amount_view_model.dart';

part 'buy_view_model.g.dart';

class BuyViewModel = BuyViewModelBase with _$BuyViewModel;

abstract class BuyViewModelBase with Store {
  BuyViewModelBase(this.ordersSource, this.ordersStore, this.buyAmountViewModel,
      {@required this.wallet}) {
    providerList = [
      WyreBuyProvider(wallet: wallet),
      MoonPayBuyProvider(wallet: wallet)
    ];
    items = providerList.map((provider) =>
        BuyItem(provider: provider, buyAmountViewModel: buyAmountViewModel))
        .toList();
    isRunning = false;
    isDisabled = true;
  }

  final Box<Order> ordersSource;
  final OrdersStore ordersStore;
  final BuyAmountViewModel buyAmountViewModel;
  final WalletBase wallet;

  @observable
  List<BuyProvider> providerList;

  @observable
  BuyProvider selectedProvider;

  @observable
  List<BuyItem> items;

  @observable
  bool isRunning;

  @observable
  bool isDisabled;

  WalletType get type => wallet.type;

  double get doubleAmount => buyAmountViewModel.doubleAmount;

  FiatCurrency get fiatCurrency => buyAmountViewModel.fiatCurrency;

  CryptoCurrency get cryptoCurrency => walletTypeToCryptoCurrency(type);

  Future createOrder() async {
    try {
      final url = await selectedProvider
            ?.requestUrl(doubleAmount?.toString(), fiatCurrency.title);
       // FIXME: Start WebView
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> saveOrder(String orderId) async {
    try {
      final order = await selectedProvider?.findOrderById(orderId);
      await ordersSource.add(order);
      ordersStore.setOrder(order);
    } catch (e) {
      print(e.toString());
    }
  }
}