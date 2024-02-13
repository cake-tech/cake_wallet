import 'dart:async';
import 'dart:convert';

import 'package:cake_wallet/buy/onramper/onramper_buy_provider.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/provider_types.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/buy/buy_item.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

import 'buy_amount_view_model.dart';

part 'buy_view_model.g.dart';

class BuyViewModel = BuyViewModelBase with _$BuyViewModel;

abstract class BuyViewModelBase with Store {
  BuyViewModelBase(this.ordersSource, this.ordersStore, this.settingsStore, this.buyAmountViewModel,
      {required this.wallet})
      : orderId = '';

  final Box<Order> ordersSource;
  final OrdersStore ordersStore;
  final SettingsStore settingsStore;
  final BuyAmountViewModel buyAmountViewModel;
  final WalletBase wallet;

  String orderId;

  ProviderType? selectedProviderType;

  WalletType get type => wallet.type;

  double get doubleAmount => buyAmountViewModel.doubleAmount;

  @computed
  FiatCurrency get fiatCurrency => buyAmountViewModel.fiatCurrency;

  CryptoCurrency get cryptoCurrency => walletTypeToCryptoCurrency(type);

  Future<void> saveOrder(String orderId, {int? onRamperPartnerRaw}) async {
    try {
      final String jsonSource = json.encode({
        'id': orderId,
        'transferId': orderId,
        'createdAt': DateTime.now().toIso8601String(),
        'amount': doubleAmount.toString(),
        'receiveAddress': 'address123',
        'walletId': wallet.id,
        'providerRaw': ProvidersHelper.serialize(selectedProviderType ?? ProviderType.askEachTime),
        'onramperPartnerRaw': onRamperPartnerRaw,
        'stateRaw': 'created',
        'from': fiatCurrency.title,
        'to': cryptoCurrency.title,
      }).toString();

      final order = Order.fromJSON(jsonSource);

      await ordersSource.add(order);
      ordersStore.setOrder(order);
    } catch (e) {
      print(e.toString());
    }
  }

  void processProviderUrl({required String urlStr}) async {
    if (selectedProviderType == null) return;

    final orderId = extractInfoFromUrl(urlStr, selectedProviderType!);
    final onRamperPartner = determineOnRamperPartner(urlStr);
    final onRamperPartnerRaw = onRamperPartner != null ? onRamperPartner.index : null;

    if (orderId != null && orderId.isNotEmpty && orderId != this.orderId) {
      this.orderId = orderId;
      await saveOrder(orderId, onRamperPartnerRaw: onRamperPartnerRaw);
    }
  }

  String? extractInfoFromUrl(String url, ProviderType providerType) {
    final config = providerUrlConfigs[providerType];
    if (config == null) return null;

    for (var entry in config.parameterKeywords.entries) {
      final keywords = entry.value;
      final startKeyword = keywords['start'];
      final endKeyword = keywords['end'];

      if (startKeyword != null) {
        final startIndex = url.indexOf(startKeyword);
        if (startIndex != -1) {
          final start = startIndex + startKeyword.length;
          int end = endKeyword != null ? url.indexOf(endKeyword, start) : url.length;
          end = end == -1 ? url.length : end;
          return url.substring(start, end);
        }
      }
    }

    return null;
  }

  OnRamperPartner? determineOnRamperPartner(String url) {
    if (url.contains('guardarian')) {
      return OnRamperPartner.guardarian;
    } else if (url.contains('paybis')) {
      return OnRamperPartner.paybis;
    } else if (url.contains('utpay')) {
      return OnRamperPartner.utorg;
    }
    return null;
  }

  final Map<ProviderType, ProviderUrlConfig> providerUrlConfigs = {
    ProviderType.onramper: ProviderUrlConfig(
      name: ProviderType.onramper.title,
      parameterKeywords: {
        'guardarian': {
          'start': 'tid=',
          'end': '&',
        },
        'paybis': {
          'start': 'requestId=',
          'end': '&',
        },
        'utpay': {
          'start': '/order/',
          'end': '/',
        },
      },
    ),
  };
}

class ProviderUrlConfig {
  final String name;
  final Map<String, Map<String, String?>> parameterKeywords;

  ProviderUrlConfig({required this.name, required this.parameterKeywords});
}
