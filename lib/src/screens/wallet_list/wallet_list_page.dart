import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/screens/wallet_list/wallet_menu.dart';
import 'package:cake_wallet/src/screens/wallet_list/widgets/wallet_tile.dart';

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
      Image.asset('assets/images/monero.png', height: 24, width: 24);
  final bitcoinIcon =
      Image.asset('assets/images/bitcoin.png', height: 24, width: 24);
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final newWalletImage = Image.asset('assets/images/new_wallet.png',
        height: 12, width: 12, color: Palette.oceanBlue);
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
                      color: Theme.of(context).backgroundColor, height: 16),
                  itemCount: widget.walletListViewModel.wallets.length,
                  itemBuilder: (__, index) {
                    final wallet = widget.walletListViewModel.wallets[index];
                    final screenWidth = MediaQuery.of(context).size.width;
                    final walletMenu = WalletMenu(context, widget.walletListViewModel);
                    final items =
                        walletMenu.generateItemsForWalletMenu(wallet.isCurrent);
                    final colors = walletMenu
                        .generateColorsForWalletMenu(wallet.isCurrent);
                    final images = walletMenu
                        .generateImagesForWalletMenu(wallet.isCurrent);

                    return Container(
                      height: 108,
                      width: double.infinity,
                      child: CustomScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: scrollController,
                        slivers: <Widget>[
                          SliverPersistentHeader(
                            pinned: false,
                            floating: true,
                            delegate: WalletTile(
                                min: screenWidth - 228,
                                max: screenWidth,
                                image: _imageFor(type: wallet.type),
                                walletName: wallet.name,
                                walletAddress: '', //shortAddress,
                                isCurrent: wallet.isCurrent),
                          ),
                          SliverList(
                              delegate:
                                  SliverChildBuilderDelegate((context, index) {
                            final item = items[index];
                            final color = colors[index];
                            final image = images[index];

                            final radius = index == 0 ? 12.0 : 0.0;

                            return GestureDetector(
                              onTap: () {
                                scrollController.animateTo(0.0,
                                    duration: Duration(milliseconds: 500),
                                    curve: Curves.fastOutSlowIn);
                                walletMenu.action(
                                    walletMenu.listItems.indexOf(item),
                                    wallet,
                                    wallet.isCurrent);
                              },
                              child: Container(
                                height: 108,
                                width: 108,
                                color: Theme.of(context).backgroundColor,
                                child: Container(
                                  padding: EdgeInsets.only(left: 5, right: 5),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(radius),
                                          bottomLeft: Radius.circular(radius)),
                                      color: color),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        image,
                                        SizedBox(height: 5),
                                        Text(
                                          item,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }, childCount: items.length))
                        ],
                      ),
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
              color: Colors.white,
              textColor: Palette.oceanBlue,
              borderColor: Palette.oceanBlue,
            ),
            SizedBox(height: 10.0),
            PrimaryImageButton(
                onPressed: () => Navigator.of(context)
                    .pushNamed(Routes.restoreWalletType),
                image: restoreWalletImage,
                text: S.of(context).wallet_list_restore_wallet,
                color: Theme.of(context).primaryTextTheme.overline.color,
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
