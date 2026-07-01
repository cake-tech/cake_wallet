import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';

class MainActions {
  final String Function(BuildContext context) name;
  final String image;
  final Key key;
  final bool Function(DashboardViewModel viewModel)? isEnabled;
  final bool Function(DashboardViewModel viewModel)? canShow;
  final Future<void> Function(BuildContext context, DashboardViewModel viewModel) onTap;

  MainActions._({
    required this.name,
    required this.image,
    required this.key,
    this.isEnabled,
    this.canShow,
    required this.onTap,
  });

  static List<MainActions> all = [
    showWalletsAction,
    receiveAction,
    swapAction,
    sendAction,
    tradeAction,
  ];

  static MainActions showWalletsAction = MainActions._(
    name: (context) => S.of(context).wallets,
    image: 'assets/images/wallet_icon.png',
    key: ValueKey('dashboard_page__wallet_list_button_key'),
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      Navigator.pushNamed(
        context,
        Routes.walletList,
        arguments: (BuildContext context) =>
            Navigator.of(context).pushNamedAndRemoveUntil(Routes.dashboard, (route) => false),
      );
    },
  );

  static MainActions receiveAction = MainActions._(
    name: (context) => S.of(context).receive,
    image: 'assets/images/receive.png',
    key: ValueKey('dashboard_page_receive_action_button_key'),
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      Navigator.pushNamed(context, Routes.addressPage);
    },
  );

  static MainActions swapAction = MainActions._(
    name: (context) => S.of(context).swap,
    image: 'assets/images/swap.png',
    key: ValueKey('dashboard_page_swap_action_button_key'),
    isEnabled: (viewModel) => viewModel.isEnabledSwapAction,
    canShow: (viewModel) => viewModel.hasSwapAction,
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      if (viewModel.isEnabledSwapAction) {
        await Navigator.of(context).pushNamed(Routes.exchange);
      }
    },
  );

  static MainActions sendAction = MainActions._(
    name: (context) => S.of(context).send,
    image: 'assets/images/send2.png',
    key: ValueKey('dashboard_page_send_action_button_key'),
    isEnabled: (viewModel) => viewModel.canSend,
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      Navigator.pushNamed(context, Routes.send);
    },
  );

  static MainActions tradeAction = MainActions._(
    name: (context) => S.of(context).buy,
    image: 'assets/images/buy.png',
    key: ValueKey('dashboard_page_buy_action_button_key'),
    isEnabled: (viewModel) => viewModel.isEnabledTradeAction,
    canShow: (viewModel) => viewModel.hasTradeAction,
    onTap: (BuildContext context, DashboardViewModel viewModel) async {
      if (!viewModel.isEnabledTradeAction) return;
      await Navigator.of(context).pushNamed(Routes.buySellPage, arguments: false);
    },
  );
}
