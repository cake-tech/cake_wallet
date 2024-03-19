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
  moonpaySell,
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
      case ProviderType.moonpaySell:
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
      case ProviderType.moonpaySell:
        return 'moonpay_provider';
    }
  }
}

class ProvidersHelper {
  static List<ProviderType> getAvailableBuyProviderTypes(WalletType walletType) {
    switch (walletType) {
      case WalletType.nano:
      case WalletType.banano:
        return [ProviderType.askEachTime, ProviderType.onramper];
      case WalletType.monero:
        return [ProviderType.askEachTime, ProviderType.onramper, ProviderType.dfx];
      case WalletType.bitcoin:
      case WalletType.ethereum:
        return [
          ProviderType.askEachTime,
          ProviderType.onramper,
          ProviderType.dfx,
          ProviderType.robinhood,
        ];
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
        return [ProviderType.askEachTime, ProviderType.onramper, ProviderType.robinhood];
      case WalletType.polygon:
        return [ProviderType.askEachTime, ProviderType.onramper, ProviderType.dfx];
      case WalletType.solana:
        return [ProviderType.askEachTime, ProviderType.onramper, ProviderType.robinhood];
      case WalletType.none:
      case WalletType.haven:
        return [];
    }
  }

  static List<ProviderType> getAvailableSellProviderTypes(WalletType walletType) {
    switch (walletType) {
      case WalletType.bitcoin:
      case WalletType.ethereum:
        return [
          ProviderType.askEachTime,
          ProviderType.onramper,
          ProviderType.moonpaySell,
          ProviderType.dfx,
        ];
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
        return [ProviderType.askEachTime, ProviderType.moonpaySell];
      case WalletType.polygon:
        return [ProviderType.askEachTime, ProviderType.onramper, ProviderType.dfx];
      case WalletType.solana:
        return [
          ProviderType.askEachTime,
          ProviderType.onramper,
          ProviderType.robinhood,
          ProviderType.moonpaySell,
        ];
      case WalletType.monero:
      case WalletType.nano:
      case WalletType.banano:
      case WalletType.none:
      case WalletType.haven:
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
      case ProviderType.askEachTime:
        return null;
      case ProviderType.moonpaySell:
        return getIt.get<MoonPaySellProvider>();
    }
  }
}
