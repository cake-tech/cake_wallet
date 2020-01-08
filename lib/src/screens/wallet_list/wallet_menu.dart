import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/wallet_list/wallet_list_store.dart';
import 'package:cake_wallet/src/domain/common/wallet_description.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';

class WalletMenu {
  WalletMenu(this.context);

  final BuildContext context;

  final List<String> listItems = [
    S.current.wallet_list_load_wallet,
    S.current.show_seed,
    S.current.remove,
    S.current.rescan
  ];

  List<String> generateItemsForWalletMenu(bool isCurrentWallet) {
    final items = List<String>();

    if (!isCurrentWallet) items.add(listItems[0]);
    if (isCurrentWallet) items.add(listItems[1]);
    if (!isCurrentWallet) items.add(listItems[2]);
    if (isCurrentWallet) items.add(listItems[3]);

    return items;
  }

  void action(int index, WalletDescription wallet, bool isCurrentWallet) {
    final _walletListStore = Provider.of<WalletListStore>(context);

    switch (index) {
      case 0:
        Navigator.of(context).pushNamed(Routes.auth, arguments:
            (bool isAuthenticatedSuccessfully, AuthPageState auth) async {
          if (!isAuthenticatedSuccessfully) {
            return;
          }

          try {
            auth.changeProcessText(
                S.of(context).wallet_list_loading_wallet(wallet.name));
            await _walletListStore.loadWallet(wallet);
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
        Navigator.of(context).pushNamed(Routes.auth, arguments:
            (bool isAuthenticatedSuccessfully, AuthPageState auth) async {
          if (!isAuthenticatedSuccessfully) {
            return;
          }
          auth.close();
          await Navigator.of(context).pushNamed(Routes.seed);
        });
        break;
      case 2:
        Navigator.of(context).pushNamed(Routes.auth, arguments:
            (bool isAuthenticatedSuccessfully, AuthPageState auth) async {
          if (!isAuthenticatedSuccessfully) {
            return;
          }

          try {
            auth.changeProcessText(
                S.of(context).wallet_list_removing_wallet(wallet.name));
            await _walletListStore.remove(wallet);
            auth.close();
          } catch (e) {
            auth.changeProcessText(S
                .of(context)
                .wallet_list_failed_to_remove(wallet.name, e.toString()));
          }
        });
        break;
      case 3:
        Navigator.of(context).pushNamed(Routes.rescan);
        break;
      default:
        break;
    }
  }
}
