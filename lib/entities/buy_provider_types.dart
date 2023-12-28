import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/dfx/dfx_buy_provider.dart';
import 'package:cake_wallet/buy/onramper/onramper_buy_provider.dart';
import 'package:cake_wallet/buy/robinhood/robinhood_buy_provider.dart';
import 'package:cake_wallet/di.dart';
import 'package:cw_core/wallet_type.dart';

enum BuyProviderType {
  askEachTime,
  robinhood,
  dfx,
  onramper,
}

extension BuyProviderTypeName on BuyProviderType {
  String get name {
    switch (this) {
      case BuyProviderType.askEachTime:
        return 'Ask each time';
      case BuyProviderType.robinhood:
        return 'Robinhood Connect';
      case BuyProviderType.dfx:
        return 'DFX Connect';
      case BuyProviderType.onramper:
        return 'Onramper';
      default:
        return this.toString().split('.').last;
    }
  }

  String get id {
    switch (this) {
      case BuyProviderType.askEachTime:
        return 'ask_each_time_provider';
      case BuyProviderType.robinhood:
        return 'robinhood_connect_provider';
      case BuyProviderType.dfx:
        return 'dfx_connect_provider';
      case BuyProviderType.onramper:
        return 'onramper_provider';
      default:
        return this.toString().split('.').last.replaceAll('.', '_')
            .toLowerCase() + '_provider';
    }
  }
}

class BuyProviderHelper {
  static List<BuyProviderType> getAvailableBuyProviderTypes(
      WalletType walletType) {
    switch (walletType) {
      case WalletType.nano:
      case WalletType.banano:
        return [BuyProviderType.askEachTime, BuyProviderType.onramper];
      case WalletType.monero:
        return [
          BuyProviderType.askEachTime,
          BuyProviderType.onramper,
          BuyProviderType.dfx
        ];
      case WalletType.bitcoin:
      case WalletType.ethereum:
        return [
          BuyProviderType.askEachTime,
          BuyProviderType.onramper,
          BuyProviderType.dfx,
          BuyProviderType.robinhood
        ];
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
        return [
          BuyProviderType.askEachTime,
          BuyProviderType.onramper,
          BuyProviderType.robinhood
        ];
      default:
        return [];
    }
  }

  static List<BuyProviderType> getAvailableSellProviderTypes(
      WalletType walletType) {
    switch (walletType) {
      case WalletType.nano:
      case WalletType.banano:
        return [BuyProviderType.askEachTime];
      case WalletType.monero:
        return [BuyProviderType.askEachTime, BuyProviderType.dfx];
      case WalletType.bitcoin:
      case WalletType.ethereum:
        return [BuyProviderType.askEachTime, BuyProviderType.dfx];
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
        return [BuyProviderType.askEachTime];
      default:
        return [];
    }
  }

  static BuyProvider? getProviderByType(BuyProviderType type) {
    switch (type) {
      case BuyProviderType.robinhood:
        return getIt.get<RobinhoodBuyProvider>();
      case BuyProviderType.dfx:
        return getIt.get<DFXBuyProvider>();
      case BuyProviderType.onramper:
        return getIt.get<OnRamperBuyProvider>();
      case BuyProviderType.askEachTime:
        return null;
    }
  }
}
