import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/dfx/dfx_buy_provider.dart';
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
}

extension ProviderTypeName on ProviderType {
  String get title {
    switch (this) {
      case ProviderType.askEachTime:
        return 'Ask each time';
      case ProviderType.robinhood:
        return 'Robinhood Connect';
      case ProviderType.dfx:
        return 'DFX.swiss';
      case ProviderType.onramper:
        return 'Onramper';
      case ProviderType.moonpay:
        return 'MoonPay';
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
    }
  }
}

class ProvidersHelper {
  static List<ProviderType> getAvailableBuyProviderTypes(WalletType walletType) {
    switch (walletType) {
      case WalletType.nano:
      case WalletType.banano:
      case WalletType.wownero:
        return [ProviderType.askEachTime, ProviderType.onramper];
      case WalletType.monero:
        return [ProviderType.askEachTime, ProviderType.onramper, ProviderType.dfx];
      case WalletType.bitcoin:
      case WalletType.polygon:
      case WalletType.ethereum:
        return [
          ProviderType.askEachTime,
          ProviderType.onramper,
          ProviderType.dfx,
          ProviderType.robinhood,
          ProviderType.moonpay,
        ];
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
        return [ProviderType.askEachTime, ProviderType.onramper, ProviderType.robinhood, ProviderType.moonpay];
      case WalletType.solana:
        return [ProviderType.askEachTime, ProviderType.onramper, ProviderType.robinhood];
      case WalletType.tron:
        return [
          ProviderType.askEachTime,
          ProviderType.onramper,
          ProviderType.robinhood,
          ProviderType.moonpay,
        ];
      case WalletType.none:
      case WalletType.haven:
        return [];
    }
  }

  static List<ProviderType> getAvailableSellProviderTypes(WalletType walletType) {
    switch (walletType) {
      case WalletType.bitcoin:
      case WalletType.ethereum:
      case WalletType.polygon:
        return [
          ProviderType.askEachTime,
          ProviderType.onramper,
          ProviderType.moonpay,
          ProviderType.dfx,
        ];
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
        return [ProviderType.askEachTime, ProviderType.moonpay];
      case WalletType.solana:
        return [
          ProviderType.askEachTime,
          ProviderType.onramper,
          ProviderType.robinhood,
          ProviderType.moonpay,
        ];
      case WalletType.tron:
        return [
          ProviderType.askEachTime,
          ProviderType.robinhood,
          ProviderType.moonpay,
        ];
      case WalletType.monero:
      case WalletType.nano:
      case WalletType.banano:
      case WalletType.none:
      case WalletType.haven:
      case WalletType.wownero:
        return [];
    }
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
      case ProviderType.askEachTime:
        return null;
    }
  }
}
