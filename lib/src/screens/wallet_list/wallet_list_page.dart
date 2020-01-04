import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/domain/common/wallet_description.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/stores/wallet_list/wallet_list_store.dart';
import 'package:cake_wallet/src/screens/wallet_list/wallet_menu.dart';
import 'package:cake_wallet/src/widgets/picker.dart';

class WalletListPage extends BasePage {
  bool get isModalBackButton => true;
  String get title => S.current.wallet_list_title;
  AppBarStyle get appBarStyle => AppBarStyle.withShadow;

  @override
  Widget body(BuildContext context) => WalletListBody();
}

class WalletListBody extends StatefulWidget {
  WalletListBodyState createState() => WalletListBodyState();
}

class WalletListBodyState extends State<WalletListBody> {
  WalletListStore _walletListStore;

  void presetMenuForWallet(WalletDescription wallet, bool isCurrentWallet,
      BuildContext bodyContext) {
    final walletMenu = WalletMenu(bodyContext);
    List<String> items = walletMenu.generateItemsForWalletMenu(isCurrentWallet);

    showDialog(
      context: bodyContext,
      builder: (_) => Picker(
          items: items,
          selectedAtIndex: -1,
          title: S.of(context).wallet_menu,
          onItemSelected: (item) => walletMenu.action(
              walletMenu.listItems.indexOf(item), wallet, isCurrentWallet)),
    );
  }

  @override
  Widget build(BuildContext context) {
    _walletListStore = Provider.of<WalletListStore>(context);

    return ScrollableWithBottomSection(
        content: Container(
          padding: EdgeInsets.all(20),
          child: Observer(
            builder: (_) => ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, index) => Divider(
                    color: Theme.of(context).dividerTheme.color, height: 1.0),
                itemCount: _walletListStore.wallets.length,
                itemBuilder: (__, index) {
                  final wallet = _walletListStore.wallets[index];
                  final isCurrentWallet =
                      _walletListStore.isCurrentWallet(wallet);

                  return InkWell(
                      onTap: () =>
                          presetMenuForWallet(wallet, isCurrentWallet, context),
                      child: Container(
                          padding: EdgeInsets.only(left: 10.0, right: 10.0),
                          child: ListTile(
                              title: Text(
                                wallet.name,
                                style: TextStyle(
                                    color: isCurrentWallet
                                        ? Palette.cakeGreen
                                        : Theme.of(context)
                                            .primaryTextTheme
                                            .headline
                                            .color,
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w600),
                              ),
                              trailing: isCurrentWallet
                                  ? Icon(
                                      Icons.check,
                                      color: Palette.cakeGreen,
                                      size: 20.0,
                                    )
                                  : null)));
                }),
          ),
        ),
        bottomSection: Column(children: <Widget>[
          PrimaryIconButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(Routes.newWallet),
              iconData: Icons.add,
              color: Theme.of(context).primaryTextTheme.button.backgroundColor,
              borderColor:
                  Theme.of(context).primaryTextTheme.button.decorationColor,
              iconColor: Palette.violet,
              iconBackgroundColor: Theme.of(context).primaryIconTheme.color,
              text: S.of(context).wallet_list_create_new_wallet),
          SizedBox(height: 10.0),
          PrimaryIconButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(Routes.restoreWalletOptions),
              iconData: Icons.refresh,
              text: S.of(context).wallet_list_restore_wallet,
              color: Theme.of(context).accentTextTheme.button.backgroundColor,
              borderColor:
                  Theme.of(context).accentTextTheme.button.decorationColor,
              iconColor: Theme.of(context).primaryTextTheme.caption.color,
              iconBackgroundColor: Theme.of(context).accentIconTheme.color)
        ]));
  }
}
