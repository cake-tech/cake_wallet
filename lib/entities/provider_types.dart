import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/dfx/dfx_buy_provider.dart';
import 'package:cake_wallet/buy/meld/meld_provider.dart';
import 'package:cake_wallet/buy/moonpay/moonpay_provider.dart';
import 'package:cake_wallet/buy/onramper/onramper_buy_provider.dart';
import 'package:cake_wallet/buy/robinhood/robinhood_buy_provider.dart';
import 'package:cake_wallet/di.dart';
import 'package:cw_core/wallet_type.dart';

enum ProviderType {
  askEachTime,
  robinhood,
  dfx,
  onramper,
  moonpay,
  meld,
}

extension ProviderTypeName on ProviderType {
  String get title {
    switch (this) {
      case ProviderType.askEachTime:
        return 'Ask each time';
      case ProviderType.robinhood:
        return 'Robinhood Connect';
      case ProviderType.dfx:
        return 'DFX Connect';
      case ProviderType.onramper:
        return 'Onramper';
      case ProviderType.moonpay:
        return 'MoonPay';
      case ProviderType.meld:
        return 'Meld';
    }
  }

  String get id {
    switch (this) {
      case ProviderType.askEachTime:
        return 'ask_each_time_provider';
      case ProviderType.robinhood:
        return 'robinhood_connect_provider';
      case ProviderType.dfx:
        return 'dfx_connect_provider';
      case ProviderType.onramper:
        return 'onramper_provider';
      case ProviderType.moonpay:
        return 'moonpay_provider';
      case ProviderType.meld:
        return 'meld_provider';
    }
  }
}

class ProvidersHelper {
  static List<ProviderType> getAvailableBuyProviderTypes(WalletType walletType) {
    final providers = <ProviderType>[];
    for (final providerType in ProviderType.values) {
      final dynamic p = getProviderTypeByType(providerType);
      final supportedWalletTypes = p.getSupportedWalletTypes(true) as List<WalletType>;
      if (supportedWalletTypes.contains(walletType)) {
        providers.add(providerType);
      }
    }
    return providers;
  }

  static List<ProviderType> getAvailableSellProviderTypes(WalletType walletType) {
    final providers = <ProviderType>[];
    for (final providerType in ProviderType.values) {
      final dynamic p = getProviderTypeByType(providerType);
      final supportedWalletTypes = p.getSupportedWalletTypes(false) as List<WalletType>;
      if (supportedWalletTypes.contains(walletType)) {
        providers.add(providerType);
      }
    }
    return providers;
  }

  static BuyProvider? getProviderByType(ProviderType type) {
    switch (type) {
      case ProviderType.robinhood:
        return getIt.get<RobinhoodBuyProvider>();
      case ProviderType.dfx:
        return getIt.get<DFXBuyProvider>();
      case ProviderType.onramper:
        return getIt.get<OnRamperBuyProvider>();
      case ProviderType.moonpay:
        return getIt.get<MoonPayProvider>();
      case ProviderType.meld:
        return getIt.get<MeldProvider>();
      case ProviderType.askEachTime:
        return null;
    }
  }

  static Type? getProviderTypeByType(ProviderType type) {
    switch (type) {
      case ProviderType.robinhood:
        return RobinhoodBuyProvider;
      case ProviderType.dfx:
        return DFXBuyProvider;
      case ProviderType.onramper:
        return OnRamperBuyProvider;
      case ProviderType.moonpay:
        return MoonPayProvider;
      case ProviderType.meld:
        return MeldProvider;
      case ProviderType.askEachTime:
        return null;
    }
  }
}
