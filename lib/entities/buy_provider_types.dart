// import 'package:cake_wallet/buy/dfx/dfx_buy_provider.dart';
// import 'package:cake_wallet/buy/moonpay/moonpay_buy_provider.dart';
// import 'package:cake_wallet/buy/onramper/onramper_buy_provider.dart';
// import 'package:cake_wallet/buy/robinhood/robinhood_buy_provider.dart';
// import 'package:cake_wallet/di.dart';
// import 'package:cw_core/wallet_type.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:intl/intl.dart';
//
// typedef LaunchProviderFunction = Future<void> Function(BuildContext, bool);
//
// class BuyProviderType {
//   final String name;
//   final String? lightIcon;
//   final String? darkIcon;
//   final LaunchProviderFunction? launchProvider;
//
//   const BuyProviderType(
//       {required this.name, this.lightIcon, this.darkIcon, this.launchProvider});
//
//
//   static List<BuyProviderType> getAvailableBuyProviders(WalletType walletType) {
//     switch (walletType) {
//       case WalletType.nano:
//       case WalletType.banano:
//         return [askEachTime, onramper];
//       case WalletType.monero:
//         return [askEachTime, onramper, dfx];
//       case WalletType.bitcoin:
//       case WalletType.ethereum:
//         return [askEachTime, onramper, dfx, robinhood];
//       case WalletType.litecoin:
//       case WalletType.bitcoinCash:
//         return [askEachTime, onramper, robinhood];
//       default:
//         return [];
//     }
//   }
//
//   static List<BuyProviderType> getAvailableSellProviders(
//       WalletType walletType) {
//     switch (walletType) {
//       case WalletType.nano:
//       case WalletType.banano:
//         return [askEachTime];
//       case WalletType.monero:
//         return [askEachTime, dfx, moonPay];
//       case WalletType.bitcoin:
//       case WalletType.ethereum:
//         return [askEachTime, dfx, moonPay];
//       case WalletType.litecoin:
//       case WalletType.bitcoinCash:
//         return [askEachTime, moonPay];
//       default:
//         return [];
//     }
//   }
// }