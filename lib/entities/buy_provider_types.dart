import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/wallet_type.dart';

enum BuyProviderType {
  AskEachTime,
  Robinhood,
  Onramper,
  DFX;

  @override
  String toString() {
    switch (this) {
      case BuyProviderType.AskEachTime:
        return S.current.ask_each_time;
      case BuyProviderType.Robinhood:
        return "Robinhood";
      case BuyProviderType.Onramper:
        return "Onramper";
      case BuyProviderType.DFX:
        return "DFX";
    }
  }

  static List<BuyProviderType> getAvailableProviders(WalletType walletType) {
    switch (walletType) {
      case WalletType.nano:
      case WalletType.banano:
        return [
          BuyProviderType.AskEachTime,
          BuyProviderType.Onramper
        ];
      case WalletType.monero:
        return [
          BuyProviderType.AskEachTime,
          BuyProviderType.Onramper,
          BuyProviderType.DFX
        ];
      case WalletType.bitcoin:
      case WalletType.ethereum:
        return [
          BuyProviderType.AskEachTime,
          BuyProviderType.Onramper,
          BuyProviderType.DFX,
          BuyProviderType.Robinhood
        ];
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
      return [
        BuyProviderType.AskEachTime,
        BuyProviderType.Onramper,
        BuyProviderType.Robinhood
      ];
      default:
        return [];
    }
  }
}
