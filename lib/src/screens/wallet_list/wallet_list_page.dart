import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/screens/wallet_list/widgets/wallet_menu_alert.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/screens/wallet_list/wallet_menu.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class WalletListPage extends BasePage {
  WalletListPage({this.walletListViewModel});

  final WalletListViewModel walletListViewModel;

  @override
  Widget body(BuildContext context) =>
      WalletListBody(walletListViewModel: walletListViewModel);
}

class WalletListBody extends StatefulWidget {
  WalletListBody({this.walletListViewModel});

  final WalletListViewModel walletListViewModel;

  @override
  WalletListBodyState createState() => WalletListBodyState();
}

class WalletListBodyState extends State<WalletListBody> {
  final moneroIcon =
      Image.asset('assets/images/monero_logo.png', height: 24, width: 24);
  final bitcoinIcon =
      Image.asset('assets/images/bitcoin.png', height: 24, width: 24);
  final scrollController = ScrollController();
  final double tileHeight = 60;
  Flushbar<void> _progressBar;

  @override
  Widget build(BuildContext context) {
    final newWalletImage = Image.asset('assets/images/new_wallet.png',
        height: 12,
        width: 12,
        color: Theme.of(context).accentTextTheme.headline.decorationColor);
    final restoreWalletImage = Image.asset('assets/images/restore_wallet.png',
        height: 12,
        width: 12,
        color: Theme.of(context).primaryTextTheme.title.color);

    return SafeArea(
        child: Container(
      padding: EdgeInsets.only(top: 16),
      child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(bottom: 20),
          content: Container(
            child: Observer(
              builder: (_) => ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, index) => Divider(
                      color: Theme.of(context).backgroundColor, height: 32),
                  itemCount: widget.walletListViewModel.wallets.length,
                  itemBuilder: (__, index) {
                    final wallet = widget.walletListViewModel.wallets[index];
                    final currentColor = wallet.isCurrent
                        ? Theme.of(context)
                            .accentTextTheme
                            .subtitle
                            .decorationColor
                        : Theme.of(context).backgroundColor;
                    final row = GestureDetector(
                        onTap: () async {
                          if (wallet.isCurrent) {
                            return;
                          }

                          final confirmed = await showPopUp<bool>(
                              context: context,
                              builder: (dialogContext) {
                                // FIXME:
                                return AlertWithTwoActions(
                                    alertTitle: 'Change current wallet',
                                    alertContent:
                                        'Do you want to change current wallet to ${wallet.name} ?',
                                    leftButtonText: S.of(context).cancel,
                                    rightButtonText: S.of(context).change,
                                    actionLeftButton: () =>
                                        Navigator.of(context).pop(false),
                                    actionRightButton: () =>
                                        Navigator.of(context).pop(true));
                              }) ?? false;

                          if (confirmed) {
                            await _loadWallet(wallet);
                          }
                        },
                        child: Container(
                          height: tileHeight,
                          width: double.infinity,
                          child: Row(
                            children: <Widget>[
                              Container(
                                height: tileHeight,
                                width: 4,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(4),
                                        bottomRight: Radius.circular(4)),
                                    color: currentColor),
                              ),
                              Expanded(
                                child: Container(
                                  height: tileHeight,
                                  padding: EdgeInsets.only(left: 20, right: 20),
                                  color: Theme.of(context).backgroundColor,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      _imageFor(type: wallet.type),
                                      SizedBox(width: 10),
                                      Text(
                                        wallet.name,
                                        style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context)
                                                .primaryTextTheme
                                                .title
                                                .color),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ));

                    return wallet.isCurrent
                        ? row
                        : Slidable(
                            key: Key('${wallet.key}'),
                            actionPane: SlidableDrawerActionPane(),
                            child: row,
                            secondaryActions: <Widget>[
                                IconSlideAction(
                                  caption: S.of(context).delete,
                                  color: Colors.red,
                                  icon: CupertinoIcons.delete,
                                  onTap: () async => _removeWallet(wallet),
                                )
                              ]);
                  }),
            ),
          ),
          bottomSection: Column(children: <Widget>[
            PrimaryImageButton(
              onPressed: () => _generateNewWallet(),
              image: newWalletImage,
              text: S.of(context).wallet_list_create_new_wallet,
              color: Theme.of(context).accentTextTheme.subtitle.decorationColor,
              textColor:
                  Theme.of(context).accentTextTheme.headline.decorationColor,
            ),
            SizedBox(height: 10.0),
            PrimaryImageButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.restoreWallet),
                image: restoreWalletImage,
                text: S.of(context).wallet_list_restore_wallet,
                color: Theme.of(context).accentTextTheme.caption.color,
                textColor: Theme.of(context).primaryTextTheme.title.color)
          ])),
    ));
  }

  Image _imageFor({WalletType type}) {
    switch (type) {
      case WalletType.bitcoin:
        return bitcoinIcon;
      case WalletType.monero:
        return moneroIcon;
      default:
        return null;
    }
  }

  Future<void> _loadWallet(WalletListItem wallet) async {
    await Navigator.of(context).pushNamed(Routes.auth, arguments:
        (bool isAuthenticatedSuccessfully, AuthPageState auth) async {
      if (!isAuthenticatedSuccessfully) {
        return;
      }

      try {
        auth.changeProcessText(
            S.of(context).wallet_list_loading_wallet(wallet.name));
        await widget.walletListViewModel.loadWallet(wallet);
        auth.hideProgressText();
        auth.close();
        Navigator.of(context).pop();
      } catch (e) {
        auth.changeProcessText(S
            .of(context)
            .wallet_list_failed_to_load(wallet.name, e.toString()));
      }
    });
  }

  Future<void> _removeWallet(WalletListItem wallet) async {
    await Navigator.of(context).pushNamed(Routes.auth, arguments:
        (bool isAuthenticatedSuccessfully, AuthPageState auth) async {
      if (!isAuthenticatedSuccessfully) {
        return;
      }

      try {
        auth.changeProcessText(
            S.of(context).wallet_list_removing_wallet(wallet.name));
        await widget.walletListViewModel.remove(wallet);
      } catch (e) {
        auth.changeProcessText(S
            .of(context)
            .wallet_list_failed_to_remove(wallet.name, e.toString()));
      }

      auth.close();
    });
  }

  Future<void> _generateNewWallet() async {
    try {
      changeProcessText('Creating new wallet'); // FIXME: Unnamed constant
      await widget.walletListViewModel.walletNewVM.create(options: 'English'); // FIXME: Unnamed constant
      hideProgressText();
      await Navigator.of(context).pushNamed(Routes.seed, arguments: true);
    } catch(e) {
      changeProcessText('Error: ${e.toString()}');
    }
  }

  void changeProcessText(String text) {
    _progressBar = createBar<void>(text, duration: null)
      ..show(context);
  }

  void hideProgressText() {
    _progressBar?.dismiss();
    _progressBar = null;
  }
}
