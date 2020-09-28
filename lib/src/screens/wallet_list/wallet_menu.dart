import 'package:cake_wallet/src/screens/wallet_list/wallet_menu_item.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/palette.dart';

class WalletMenu {
  WalletMenu(this.context, this.walletListViewModel);

  final WalletListViewModel walletListViewModel;
  final BuildContext context;

  final List<WalletMenuItem> menuItems = [
    WalletMenuItem(
        title: S.current.wallet_list_load_wallet,
        firstGradientColor: Palette.cornflower,
        secondGradientColor: Palette.royalBlue,
        image: Image.asset('assets/images/load.png',
            height: 24, width: 24, color: Colors.white)),
    WalletMenuItem(
        title: S.current.show_seed,
        firstGradientColor: Palette.moderateOrangeYellow,
        secondGradientColor: Palette.moderateOrange,
        image: Image.asset('assets/images/eye_action.png',
            height: 24, width: 24, color: Colors.white)),
    WalletMenuItem(
        title: S.current.remove,
        firstGradientColor: Palette.lightRed,
        secondGradientColor: Palette.persianRed,
        image: Image.asset('assets/images/trash.png',
            height: 24, width: 24, color: Colors.white)),
    WalletMenuItem(
        title: S.current.rescan,
        firstGradientColor: Palette.shineGreen,
        secondGradientColor: Palette.moderateGreen,
        image: Image.asset('assets/images/scanner.png',
            height: 24, width: 24, color: Colors.white))
  ];

  List<WalletMenuItem> generateItemsForWalletMenu(bool isCurrentWallet) {
    final items = List<WalletMenuItem>();

    if (!isCurrentWallet) items.add(menuItems[0]);
    if (isCurrentWallet) items.add(menuItems[1]);
    if (!isCurrentWallet) items.add(menuItems[2]);
    if (isCurrentWallet) items.add(menuItems[3]);

    return items;
  }

  Future<void> action(
      int index, WalletListItem wallet) async {
    switch (index) {
      case 0:
        await Navigator.of(context).pushNamed(Routes.auth, arguments:
            (bool isAuthenticatedSuccessfully, AuthPageState auth) async {
          if (!isAuthenticatedSuccessfully) {
            return;
          }

          try {
            auth.changeProcessText(
                S.of(context).wallet_list_loading_wallet(wallet.name));
            await walletListViewModel.loadWallet(wallet);
            auth.close();
            Navigator.of(context).pop();
          } catch (e) {
            auth.changeProcessText(S
                .of(context)
                .wallet_list_failed_to_load(wallet.name, e.toString()));
          }
        });
        break;
      case 1:
        await Navigator.of(context).pushNamed(Routes.auth, arguments:
            (bool isAuthenticatedSuccessfully, AuthPageState auth) async {
          if (!isAuthenticatedSuccessfully) {
            return;
          }
          auth.close();
          await Navigator.of(context).pushNamed(Routes.seed, arguments: false);
        });
        break;
      case 2:
        final isComfirmed = await showPopUp<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithTwoActions(
                  alertTitle: 'Remove wallet',
                  alertContent: S.of(context).confirm_delete_wallet,
                  leftButtonText: S.of(context).cancel,
                  rightButtonText: S.of(context).remove,
                  actionLeftButton: () => Navigator.of(context).pop(false),
                  actionRightButton: () => Navigator.of(context).pop(true));
            });

        if (isComfirmed == null || !isComfirmed) {
          return;
        }

        await Navigator.of(context).pushNamed(Routes.auth, arguments:
            (bool isAuthenticatedSuccessfully, AuthPageState auth) async {
          if (!isAuthenticatedSuccessfully) {
            return;
          }

          try {
            auth.changeProcessText(
                S.of(context).wallet_list_removing_wallet(wallet.name));
            await walletListViewModel.remove(wallet);
            auth.close();
          } catch (e) {
            auth.changeProcessText(S
                .of(context)
                .wallet_list_failed_to_remove(wallet.name, e.toString()));
          }
        });
        break;
      case 3:
        await Navigator.of(context).pushNamed(Routes.rescan);
        break;
      default:
        break;
    }
  }
}
