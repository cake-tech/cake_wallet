import 'package:cake_wallet/buy/moonpay/moonpay_buy_provider.dart';
import 'package:cake_wallet/buy/onramper/onramper_buy_provider.dart';
import 'package:cake_wallet/buy/payfura/payfura_buy_provider.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MainActions {
  final String Function(BuildContext context) name;
  final String image;

  final bool Function(DashboardViewModel viewModel)? isEnabled;
  final bool Function(DashboardViewModel viewModel)? canShow;
  final Future<void> Function(BuildContext context, DashboardViewModel viewModel) onTap;

  MainActions._({
    required this.name,
    required this.image,
    this.isEnabled,
    this.canShow,
    required this.onTap,
  });

  static List<MainActions> all = [
    buyAction,
    receiveAction,
    exchangeAction,
    sendAction,
    sellAction,
  ];

  static MainActions buyAction = MainActions._(
    name: (context) => S.of(context).buy,
    image: 'assets/images/buy.png',
    isEnabled: (viewModel) => viewModel.isEnabledBuyAction,
    canShow: (viewModel) => viewModel.hasBuyAction,
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      final walletType = viewModel.type;

      switch (walletType) {
        case WalletType.bitcoin:
        case WalletType.litecoin:
          if (viewModel.isEnabledBuyAction) {
            final uri = getIt.get<OnRamperBuyProvider>().requestUrl();
            if (DeviceInfo.instance.isMobile) {
              Navigator.of(context)
                  .pushNamed(Routes.webViewPage, arguments: [S.of(context).buy, uri]);
            } else {
              await launchUrl(uri);
            }
          }
          break;
        case WalletType.monero:
          if (viewModel.isEnabledBuyAction) {
            if (DeviceInfo.instance.isMobile) {
              Navigator.of(context).pushNamed(Routes.payfuraPage);
            } else {
              final uri = getIt.get<PayfuraBuyProvider>().requestUrl();
              await launchUrl(uri);
            }
          }
          break;
        default:
          await showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                    alertTitle: S.of(context).buy,
                    alertContent: S.of(context).buy_alert_content,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop());
              });
      }
    },
  );

  static MainActions receiveAction = MainActions._(
    name: (context) => S.of(context).receive,
    image: 'assets/images/received.png',
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      Navigator.pushNamed(context, Routes.addressPage);
    },
  );

  static MainActions exchangeAction = MainActions._(
    name: (context) => S.of(context).exchange,
    image: 'assets/images/transfer.png',
    isEnabled: (viewModel) => viewModel.isEnabledExchangeAction,
    canShow: (viewModel) => viewModel.hasExchangeAction,
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      if (viewModel.isEnabledExchangeAction) {
        await Navigator.of(context).pushNamed(Routes.exchange);
      }
    },
  );

  static MainActions sendAction = MainActions._(
    name: (context) => S.of(context).send,
    image: 'assets/images/upload.png',
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      Navigator.pushNamed(context, Routes.send);
    },
  );

  static MainActions sellAction = MainActions._(
    name: (context) => S.of(context).sell,
    image: 'assets/images/sell.png',
    isEnabled: (viewModel) => viewModel.isEnabledSellAction,
    canShow: (viewModel) => viewModel.hasSellAction,
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      final walletType = viewModel.type;

      switch (walletType) {
        case WalletType.bitcoin:
        case WalletType.litecoin:
          if (viewModel.isEnabledSellAction) {
            final moonPaySellProvider = MoonPaySellProvider();
            final uri = await moonPaySellProvider.requestUrl(
              currency: viewModel.wallet.currency,
              refundWalletAddress: viewModel.wallet.walletAddresses.address,
              settingsStore: viewModel.settingsStore,
            );
            if (DeviceInfo.instance.isMobile) {
              Navigator.of(context).pushNamed(Routes.webViewPage,
                  arguments: [S.of(context).sell, uri]);
            } else {
              await launchUrl(uri);
            }
          }

          break;
        default:
          await showPopUp<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithOneAction(
                  alertTitle: S.of(context).sell,
                  alertContent: S.of(context).sell_alert_content,
                  buttonText: S.of(context).ok,
                  buttonAction: () => Navigator.of(context).pop());
            },
          );
      }
    },
  );
}
