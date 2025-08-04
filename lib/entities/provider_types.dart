import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/dfx/dfx_buy_provider.dart';
import 'package:cake_wallet/buy/kryptonim/kryptonim.dart';
import 'package:cake_wallet/buy/meld/meld_buy_provider.dart';
import 'package:cake_wallet/buy/moonpay/moonpay_provider.dart';
import 'package:cake_wallet/buy/onramper/onramper_buy_provider.dart';
import 'package:cake_wallet/buy/robinhood/robinhood_buy_provider.dart';
import 'package:cake_wallet/di.dart';

enum ProviderType { robinhood, dfx, onramper, moonpay, meld, kriptonim }

extension ProviderTypeName on ProviderType {
  String get title {
    switch (this) {
      case ProviderType.robinhood:
        return 'Robinhood Connect';
      case ProviderType.dfx:
        return 'DFX.swiss';
      case ProviderType.onramper:
        return 'Onramper';
      case ProviderType.moonpay:
        return 'MoonPay';
      case ProviderType.meld:
        return 'Meld';
      case ProviderType.kriptonim:
        return 'Kriptonim';
    }
  }

  String get id {
    switch (this) {
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
      case ProviderType.kriptonim:
        return 'kriptonim_provider';
    }
  }
}

class ProvidersHelper {
  static List<ProviderType> getAvailableBuyProviderTypes() => [
    ProviderType.robinhood,
    ProviderType.dfx,
    ProviderType.onramper,
    ProviderType.moonpay,
    ProviderType.kriptonim
  ];

  static List<ProviderType> getAvailableSellProviderTypes() => [
    // ProviderType.robinhood, // ToDo: (Konsti) Enable once fixed in Exchange Helper, but still waiting for new Docs
    ProviderType.dfx,
    ProviderType.onramper,
    ProviderType.moonpay,
    ProviderType.kriptonim
  ];

  static BuyProvider getProviderByType(ProviderType type) {
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
        return getIt.get<MeldBuyProvider>();
      case ProviderType.kriptonim:
        return getIt.get<KryptonimBuyProvider>();
      }
  }
}
