import 'dart:async';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/dashboard/desktop_widgets/desktop_wallet_selection_dropdown.dart';
import 'package:cake_wallet/src/screens/dashboard/desktop_widgets/desktop_dashboard_view.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/yat_emoji_id.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/balance_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/main.dart';

class DesktopDashboardPage extends BasePage {
  DesktopDashboardPage({
    required this.balancePage,
    required this.walletViewModel,
    required this.addressListViewModel,
  });

  @override
  Color get backgroundLightColor =>
      currentTheme.type == ThemeType.bright ? Colors.transparent : Colors.white;

  @override
  Color get backgroundDarkColor => Colors.transparent;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            Theme.of(context).accentColor,
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).primaryColor,
          ], begin: Alignment.topRight, end: Alignment.bottomLeft)),
          child: scaffold);

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  Widget? leading(BuildContext context) => getIt<DesktopWalletSelectionDropDown>();

  @override
  Widget middle(BuildContext context) {
    return SyncIndicator(
        dashboardViewModel: walletViewModel,
        onTap: () => Navigator.of(context, rootNavigator: true).pushNamed(Routes.connectionSync));
  }

  @override
  Widget trailing(BuildContext context) {
    return Image.asset('assets/images/desktop_menu.png', color: Theme.of(context).highlightColor);
  }

  final BalancePage balancePage;
  final DashboardViewModel walletViewModel;
  final WalletAddressListViewModel addressListViewModel;

  bool _isEffectsInstalled = false;
  StreamSubscription<bool>? _onInactiveSub;

  @override
  Widget body(BuildContext context) {
    _setEffects(context);

    return DesktopDashboardView(balancePage);
  }

  void _setEffects(BuildContext context) async {
    if (_isEffectsInstalled) {
      return;
    }
    _isEffectsInstalled = true;

    autorun((_) async {
      if (!walletViewModel.isOutdatedElectrumWallet) {
        return;
      }

      await Future<void>.delayed(Duration(seconds: 1));
      await showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
                alertTitle: S.of(context).pre_seed_title,
                alertContent: S.of(context).outdated_electrum_wallet_description,
                buttonText: S.of(context).understand,
                buttonAction: () => Navigator.of(context).pop());
          });
    });

    var needToPresentYat = false;
    var isInactive = false;

    _onInactiveSub = rootKey.currentState!.isInactive.listen((inactive) {
      isInactive = inactive;

      if (needToPresentYat) {
        Future<void>.delayed(Duration(milliseconds: 500)).then((_) {
          showPopUp<void>(
              context: navigatorKey.currentContext!,
              builder: (_) => YatEmojiId(walletViewModel.yatStore.emoji));
          needToPresentYat = false;
        });
      }
    });

    walletViewModel.yatStore.emojiIncommingStream.listen((String emoji) {
      if (!_isEffectsInstalled || emoji.isEmpty) {
        return;
      }

      needToPresentYat = true;
    });
  }
}
