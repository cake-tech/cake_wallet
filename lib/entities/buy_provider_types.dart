import 'package:cake_wallet/generated/i18n.dart';

enum BuyProviderType {
  AskEachTime,
  Robinhood,
  MoonPay,
  Onramper;

  @override
  String toString() {
    switch (this) {
      case BuyProviderType.AskEachTime:
        return S.current.ask_each_time;
      case BuyProviderType.Robinhood:
        return "Robinhood";
      case BuyProviderType.MoonPay:
        return "MoonPay";
      case BuyProviderType.Onramper:
        return "Onramper";
    }
  }
}
