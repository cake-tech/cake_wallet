import 'dart:async';
import 'dart:convert';

import 'package:cake_wallet/buy/onramper/onramper_buy_provider.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/provider_types.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'buy_view_model.g.dart';

class BuyViewModel = BuyViewModelBase with _$BuyViewModel;

abstract class BuyViewModelBase with Store {
  BuyViewModelBase(this.ordersSource, this.ordersStore, this.settingsStore, {required this.wallet})
      : orderId = '';

  final Box<Order> ordersSource;
  final OrdersStore ordersStore;
  final SettingsStore settingsStore;
  final WalletBase wallet;

  String orderId;

  ProviderType? selectedProviderType;

  bool? isBuyAction;

  WalletType get type => wallet.type;

  @computed
  FiatCurrency get fiatCurrency => settingsStore.fiatCurrency;

  Future<void> saveOrder(String orderId,
      {int? onRamperPartnerRaw,
      String? fiatCurrency,
      String? cryptoCurrency,
      String? fiatAmount,
      String? cryptoAmount}) async {
    bool isBuyAction = this.isBuyAction ?? true;

    final formattedCryptoCurrency =
        cryptoCurrency != null && cryptoCurrency.isNotEmpty
            ? CryptoCurrency.fromString(cryptoCurrency) : null;

    final orderData = {
      'id': orderId,
      'transferId': orderId,
      'createdAt': DateTime.now().toIso8601String(),
      'amount': isBuyAction ? fiatAmount ?? '' : cryptoAmount ?? '',
      'receiveAddress': '',
      'walletId': wallet.id,
      'providerRaw': ProvidersHelper.serialize(selectedProviderType ?? ProviderType.askEachTime),
      'onramperPartnerRaw': onRamperPartnerRaw,
      'from': isBuyAction ? fiatCurrency : formattedCryptoCurrency?.title,
      'to': isBuyAction ? formattedCryptoCurrency?.title : fiatCurrency,
    };

    try {
      final String jsonSource = json.encode(orderData).toString();

      final order = Order.fromJSON(jsonSource);

      await ordersSource.add(order);
      ordersStore.setOrder(order);
    } catch (e) {
      print(e.toString());
    }
  }

  void processProviderUrl({required String urlStr}) async {
    if (selectedProviderType == null) return;

    final orderId = extractInfoFromUrl(
        urlStr, selectedProviderType!, providerUrlOrderIdConfigs[selectedProviderType!]);
    final onRamperPartner = determineOnRamperPartner(urlStr);
    final onRamperPartnerRaw = onRamperPartner != null ? onRamperPartner.index : null;

    if (orderId != null && orderId.isNotEmpty && orderId != this.orderId) {
      final fiatCurrency = extractInfoFromUrl(
          urlStr, selectedProviderType!, providerUrlFiatCurrencyConfigs[selectedProviderType!]);
      final cryptoCurrency = extractInfoFromUrl(
          urlStr, selectedProviderType!, providerUrlCryptoCurrencyConfigs[selectedProviderType!]);
      final fiatAmount = extractInfoFromUrl(
          urlStr, selectedProviderType!, providerUrlFiatAmountConfigs[selectedProviderType!]);
      final cryptoAmount = extractInfoFromUrl(
          urlStr, selectedProviderType!, providerUrlCryptoAmountConfigs[selectedProviderType!]);
      this.orderId = orderId;
      await saveOrder(orderId,
          onRamperPartnerRaw: onRamperPartnerRaw,
          fiatCurrency: fiatCurrency,
          cryptoCurrency: cryptoCurrency,
          fiatAmount: fiatAmount,
          cryptoAmount: cryptoAmount);
    }
  }

  String? extractInfoFromUrl(String url, ProviderType providerType, ProviderUrlConfig? config) {
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
    } else if (url.contains('alchemypay')) {
      return OnRamperPartner.alchemypay;
    } else if (url.contains('sardine')) {
      return OnRamperPartner.sardine;
    }
    return null;
  }

  final Map<ProviderType, ProviderUrlConfig> providerUrlOrderIdConfigs = {
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
        'alchemypay': {
          'start': 'merchantOrderNo=',
          'end': '&',
        },
        'sardine': {
          'start': 'client_token=',
          'end': null,
        },
      },
    ),
  };

  final Map<ProviderType, ProviderUrlConfig> providerUrlFiatCurrencyConfigs = {
    ProviderType.onramper: ProviderUrlConfig(
      name: ProviderType.onramper.title,
      parameterKeywords: {
        'alchemypay': {
          'start': 'fiat=',
          'end': '&',
        },
        'sardine': {
          'start': 'fixed_fiat_currency=',
          'end': '&',
        },
      },
    ),
  };

  final Map<ProviderType, ProviderUrlConfig> providerUrlCryptoCurrencyConfigs = {
    ProviderType.onramper: ProviderUrlConfig(
      name: ProviderType.onramper.title,
      parameterKeywords: {
        'alchemypay': {
          'start': 'crypto=',
          'end': '&',
        },
        'sardine': {
          'start': 'fixed_asset_type=',
          'end': '&',
        },
      },
    ),
  };

  final Map<ProviderType, ProviderUrlConfig> providerUrlFiatAmountConfigs = {
    ProviderType.onramper: ProviderUrlConfig(
      name: ProviderType.onramper.title,
      parameterKeywords: {
        'alchemypay': {
          'start': 'fiatAmount=',
          'end': '&',
        },
        'sardine': {
          'start': 'fixed_fiat_amount=',
          'end': '&',
        },
      },
    ),
  };

  final Map<ProviderType, ProviderUrlConfig> providerUrlCryptoAmountConfigs = {
    ProviderType.onramper: ProviderUrlConfig(
      name: ProviderType.onramper.title,
      parameterKeywords: {
        'alchemypay': {
          'start': 'cryptoAmount=',
          'end': '&',
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
