import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';

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
    receiveAction,
    exchangeAction,
    sendAction,
    tradeAction,
  ];

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

  static MainActions tradeAction = MainActions._(
    name: (context) => '${S.of(context).sell} / ${S.of(context).buy}',
    image: 'assets/images/buy_sell.png',
    isEnabled: (viewModel) => viewModel.isEnabledSellAction || viewModel.isEnabledBuyAction,
    canShow: (viewModel) => viewModel.hasSellAction || viewModel.hasBuyAction,
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      if (!viewModel.isEnabledSellAction && !viewModel.isEnabledBuyAction) {
        return;
      }

      // final defaultSellProvider = viewModel.defaultSellProvider;
      // try {
      //   defaultSellProvider != null
      //       ? await defaultSellProvider.launchProvider(context, false)
      //       : await Navigator.of(context).pushNamed(Routes.buySellPage, arguments: false);
      // } catch (e) {
      //   await _showErrorDialog(context, defaultSellProvider.toString(), e.toString());
      // }
      await Navigator.of(context).pushNamed(Routes.buySellPage, arguments: false);
    },
  );

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