import 'package:cake_wallet/buy/onramper/onramper_buy_provider.dart';
import 'package:cake_wallet/buy/robinhood/robinhood_buy_provider.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/cupertino.dart';

typedef LaunchProviderFunction = Future<void> Function(BuildContext);

class BuyProviderType {
  final String name;
  final String? lightIcon;
  final String? darkIcon;
  final LaunchProviderFunction? launchProvider;

  const BuyProviderType(
      {required this.name, this.lightIcon, this.darkIcon, this.launchProvider});

  @override
  String toString() {
    return name;
  }

  static List<BuyProviderType> all() {
    return [askEachTime, robinhood, onramper, dfx];
  }

  static BuyProviderType askEachTime = BuyProviderType(
    name: 'Ask each time',
  );

  static BuyProviderType robinhood = BuyProviderType(
      name: "Robinhood Connect",
      lightIcon: 'assets/images/robinhood_light.png',
      darkIcon: 'assets/images/robinhood_dark.png',
      launchProvider: (context) async =>
          await getIt.get<RobinhoodBuyProvider>().launchProvider(context));
  static BuyProviderType onramper = BuyProviderType(
    name: "Onramper",
    lightIcon: 'assets/images/onramper_light.png',
    darkIcon: 'assets/images/onramper_dark.png',
    launchProvider: (context) async =>
        await getIt.get<OnRamperBuyProvider>().launchProvider(context),
  );
  static BuyProviderType dfx = BuyProviderType(
      name: "DFX Connect",
      lightIcon: 'assets/images/dfx_light.png',
      darkIcon: 'assets/images/dfx_dark.png',
      launchProvider: (context) async =>
          await getIt.get<OnRamperBuyProvider>().launchProvider(context));

  static List<BuyProviderType> getAvailableProviders(WalletType walletType) {
    switch (walletType) {
      case WalletType.nano:
      case WalletType.banano:
        return [askEachTime, onramper];
      case WalletType.monero:
        return [askEachTime, onramper, dfx];
      case WalletType.bitcoin:
      case WalletType.ethereum:
        return [askEachTime, onramper, dfx, robinhood];
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
        return [askEachTime, onramper, robinhood];
      default:
        return [];
    }
  }

  String get description {
    switch (name) {
      case "Robinhood Connect":
        return S.current.robinhood_option_description;
      case "Onramper":
        return S.current.onramper_option_description;
      case "DFX Connect":
        return S.current.dfx_option_description;
      default:
        return "";
    }
  }
}
