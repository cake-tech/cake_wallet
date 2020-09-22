import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
// import 'package:cake_wallet/src/stores/wallet_list/wallet_list_store.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/palette.dart';

class WalletMenu {
  WalletMenu(this.context, this.walletListViewModel);

  final WalletListViewModel walletListViewModel;
  final BuildContext context;

  final List<String> listItems = [
    S.current.wallet_list_load_wallet,
    S.current.show_seed,
    S.current.remove,
    S.current.rescan
  ];

  final List<Color> firstColors = [
    Palette.cornflower,
    Palette.moderateOrangeYellow,
    Palette.lightRed,
    Palette.shineGreen
  ];

  final List<Color> secondColors = [
    Palette.royalBlue,
    Palette.moderateOrange,
    Palette.persianRed,
    Palette.moderateGreen
  ];

  final List<Image> listImages = [
    Image.asset('assets/images/load.png',
        height: 24, width: 24, color: Colors.white),
    Image.asset('assets/images/eye_action.png',
        height: 24, width: 24, color: Colors.white),
    Image.asset('assets/images/trash.png',
        height: 24, width: 24, color: Colors.white),
    Image.asset('assets/images/scanner.png',
        height: 24, width: 24, color: Colors.white)
  ];

  List<String> generateItemsForWalletMenu(bool isCurrentWallet) {
    final items = List<String>();

    if (!isCurrentWallet) items.add(listItems[0]);
    if (isCurrentWallet) items.add(listItems[1]);
    if (!isCurrentWallet) items.add(listItems[2]);
    if (isCurrentWallet) items.add(listItems[3]);

    return items;
  }

  List<Color> generateColorsForWalletMenu(bool isCurrentWallet) {
    final colors = <Color>[];

    if (!isCurrentWallet) {
      colors.add(firstColors[0]);
      colors.add(secondColors[0]);
    }
    if (isCurrentWallet) {
      colors.add(firstColors[1]);
      colors.add(secondColors[1]);
    }
    if (!isCurrentWallet) {
      colors.add(firstColors[2]);
      colors.add(secondColors[2]);
    }
    if (isCurrentWallet) {
      colors.add(firstColors[3]);
      colors.add(secondColors[3]);
    }

    return colors;
  }

  List<Image> generateImagesForWalletMenu(bool isCurrentWallet) {
    final images = <Image>[];

    if (!isCurrentWallet) images.add(listImages[0]);
    if (isCurrentWallet) images.add(listImages[1]);
    if (!isCurrentWallet) images.add(listImages[2]);
    if (isCurrentWallet) images.add(listImages[3]);

    return images;
  }

  Future<void> action(
      int index, WalletListItem wallet, bool isCurrentWallet) async {
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
        final isComfirmed = await showDialog<bool>(
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
