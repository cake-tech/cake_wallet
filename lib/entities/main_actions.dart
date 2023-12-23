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

  static MainActions buyAction = MainActions._(
    name: (context) => S.of(context).buy,
    image: 'assets/images/buy.png',
    isEnabled: (viewModel) => viewModel.isEnabledBuyAction,
    canShow: (viewModel) => viewModel.hasBuyAction,
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      if (!viewModel.isEnabledBuyAction) {
        await _showErrorDialog(
            context, S.of(context).buy, S.of(context).unsupported_asset);
        return;
      }

      final defaultBuyProvider = viewModel.defaultBuyProvider;
      try {
        await _launchProviderByType(context, true, defaultBuyProvider);
      } catch (e) {
        await _showErrorDialog(context, defaultBuyProvider.toString(), e.toString());
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
      if (!viewModel.isEnabledSellAction) {
        await _showErrorDialog(
            context, S.of(context).sell, S.of(context).unsupported_asset);
        return;
      }

      final defaultSellProvider = viewModel.defaultSellProvider;
      try {
        await _launchProviderByType(context, false, defaultSellProvider);
      } catch (e) {
        await _showErrorDialog(context, defaultSellProvider.name, e.toString());
      }
    },
  );

  static final Map<BuyProviderType, Future<void> Function(BuildContext, bool)>
      _providerLaunchActions = {
    BuyProviderType.askEachTime: (context, isBuyAction) =>
        Navigator.pushNamed(context, Routes.buySellPage, arguments: isBuyAction),
    BuyProviderType.onramper: (context, _) =>
        getIt.get<OnRamperBuyProvider>().launchProvider(context),
    BuyProviderType.robinhood: (context, _) =>
        getIt.get<RobinhoodBuyProvider>().launchProvider(context),
    BuyProviderType.dfx: (context, isBuyAction) =>
        getIt.get<DFXBuyProvider>().launchProvider(context, isBuyAction),
  };

  static Future<void> _launchProviderByType(BuildContext context,
      bool isBuyAction, BuyProviderType providerType) async {
    final action = _providerLaunchActions[providerType];
    if (action != null) {
      await action(context, isBuyAction);
    } else {
      throw UnsupportedError('Unsupported buy provider type');
    }
  }

  static Future<void> _showErrorDialog(
      BuildContext context, String title, String errorMessage) async {
    await showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertWithOneAction(
          alertTitle: title,
          alertContent: errorMessage,
          buttonText: S.of(context).ok,
          buttonAction: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}
