import 'package:cake_wallet/src/domain/common/wallet_description.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/src/stores/wallet_list/wallet_list_store.dart';
import 'package:cake_wallet/generated/i18n.dart';

class WalletMenu {

  final BuildContext context;
  final List<String> listItems = [
    S.current.wallet_list_load_wallet,
    S.current.show_seed,
    S.current.remove,
    S.current.rescan
  ];

  WalletMenu(this.context);

  List<String>generateItemsForWalletMenu(bool isCurrentWallet) {
    List<String> items = new List<String>();

    if (!isCurrentWallet) items.add(listItems[0]);
    if (isCurrentWallet) items.add(listItems[1]);
    if (!isCurrentWallet) items.add(listItems[2]);
    if (isCurrentWallet) items.add(listItems[3]);

    return items;
  }

  void action(int index, WalletDescription wallet, bool isCurrentWallet) {
    WalletListStore _walletListStore = Provider.of<WalletListStore>(context);

    switch (index) {
      case 0:
        Navigator.of(context).pushNamed(Routes.auth,
            arguments: (isAuthenticatedSuccessfully, auth) async {
              if (!isAuthenticatedSuccessfully) {
                return;
              }

              try {
                auth.changeProcessText(S.of(context).wallet_list_loading_wallet(wallet.name));
                await _walletListStore.loadWallet(wallet);
                auth.close();
                Navigator.of(context).pop();
              } catch (e) {
                auth.changeProcessText(
                    S.of(context).wallet_list_failed_to_load(wallet.name, e.toString()));
              }
        });
        break;
      case 1:
        Navigator.of(context).pushNamed(Routes.auth,
            arguments: (isAuthenticatedSuccessfully, auth) async {
              if (!isAuthenticatedSuccessfully) {
                return;
              }
              auth.close();
              Navigator.of(context).pushNamed(Routes.seed);
        });
        break;
      case 2:
        Navigator.of(context).pushNamed(Routes.auth,
            arguments: (isAuthenticatedSuccessfully, auth) async {
              if (!isAuthenticatedSuccessfully) {
                return;
              }

              try {
                auth.changeProcessText(S.of(context).wallet_list_removing_wallet(wallet.name));
                await _walletListStore.remove(wallet);
                auth.close();
              } catch (e) {
                auth.changeProcessText(
                    S.of(context).wallet_list_failed_to_remove(wallet.name, e.toString()));
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