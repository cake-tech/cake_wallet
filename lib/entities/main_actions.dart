import 'package:cake_wallet/buy/dfx/dfx_buy_provider.dart';
import 'package:cake_wallet/buy/moonpay/moonpay_buy_provider.dart';
import 'package:cake_wallet/buy/onramper/onramper_buy_provider.dart';
import 'package:cake_wallet/buy/robinhood/robinhood_buy_provider.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/buy_provider_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/device_info.dart';
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
  final Future<void> Function(
      BuildContext context, DashboardViewModel viewModel) onTap;

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

  static final Map<BuyProviderType, Future<void> Function(BuildContext)>
  _providerLaunchActions = {
    BuyProviderType.askEachTime: (context) =>
        Navigator.pushNamed(context, Routes.buy, arguments: S.current.buy),
    BuyProviderType.onramper: (context) =>
        getIt.get<OnRamperBuyProvider>().launchProvider(context),
    BuyProviderType.robinhood: (context) =>
        getIt.get<RobinhoodBuyProvider>().launchProvider(context),
    BuyProviderType.dfx: (context) =>
        getIt.get<DFXBuyProvider>().launchProvider(context),
    // Add other providers here
  };

  static Future<void> _launchProviderByType(
      BuildContext context, BuyProviderType providerType) async {
    final action = _providerLaunchActions[providerType];
    if (action != null) {
      await action(context);
    } else {
      throw UnsupportedError('Unsupported buy provider type');
    }
  }

  static Future<void> _showErrorDialog(
      BuildContext context, String errorMessage) async {
    await showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertWithOneAction(
          alertTitle: S.of(context).buy,
          alertContent: errorMessage,
          buttonText: S.of(context).ok,
          buttonAction: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  static MainActions buyAction = MainActions._(
    name: (context) => S.of(context).buy,
    image: 'assets/images/buy.png',
    isEnabled: (viewModel) => viewModel.isEnabledBuyAction,
    canShow: (viewModel) => viewModel.hasBuyAction,
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      if (!viewModel.isEnabledBuyAction) {
        await _showErrorDialog(context, S.of(context).unsupported_asset);
        return;
      }

      final defaultBuyProvider = viewModel.defaultBuyProvider;
      try {
        await _launchProviderByType(context, defaultBuyProvider);
      } catch (e) {
        await _showErrorDialog(context, e.toString());
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
        case WalletType.ethereum:
        case WalletType.polygon:
        case WalletType.bitcoinCash:
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
                  alertContent: S.of(context).unsupported_asset,
                  buttonText: S.of(context).ok,
                  buttonAction: () => Navigator.of(context).pop());
            },
          );
      }
    },
  );
}
