import 'package:cake_wallet/src/screens/wallet_list/widgets/wallet_menu_alert.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
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
                    final walletMenu = WalletMenu(context, widget.walletListViewModel);
                    final items =
                        walletMenu.generateItemsForWalletMenu(wallet.isCurrent);
                    final currentColor = wallet.isCurrent
                        ? Theme.of(context).accentTextTheme.subtitle.decorationColor
                        : Theme.of(context).backgroundColor;

                    return GestureDetector(
                      onTap: () {
                        showPopUp<void>(
                            context: context,
                            builder: (dialogContext) {
                              return WalletMenuAlert(
                                  wallet: wallet,
                                  walletMenu: walletMenu,
                                  items: items);
                            }
                        );
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
                                  color: currentColor
                              ),
                            ),
                            Expanded(
                                child: Container(
                                  height: tileHeight,
                                  padding: EdgeInsets.only(left: 20, right: 20),
                                  color: Theme.of(context).backgroundColor,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      _imageFor(type: wallet.type),
                                      SizedBox(width: 10),
                                      Text(
                                        wallet.name,
                                        style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).primaryTextTheme.title.color
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                            ),
                          ],
                        ),
                      )
                    );
                  }),
            ),
          ),
          bottomSection: Column(children: <Widget>[
            PrimaryImageButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(Routes.newWalletType),
              image: newWalletImage,
              text: S.of(context).wallet_list_create_new_wallet,
              color: Theme.of(context).accentTextTheme.subtitle.decorationColor,
              textColor: Theme.of(context).accentTextTheme.headline.decorationColor,
            ),
            SizedBox(height: 10.0),
            PrimaryImageButton(
                onPressed: () => Navigator.of(context)
                    .pushNamed(Routes.restoreWalletType),
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
}
