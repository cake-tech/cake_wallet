import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/stores/wallet_list/wallet_list_store.dart';
import 'package:cake_wallet/src/screens/wallet_list/wallet_menu.dart';

class WalletListPage extends BasePage {

  @override
  ObstructingPreferredSizeWidget appBar(BuildContext context) => null;

  @override
  Widget body(BuildContext context) => WalletListBody();
}

class WalletListBody extends StatefulWidget {
  @override
  WalletListBodyState createState() => WalletListBodyState();
}

class WalletListBodyState extends State<WalletListBody> {
  final moneroIcon = Image.asset('assets/images/monero.png', height: 24, width: 24);
  WalletListStore _walletListStore;

  @override
  Widget build(BuildContext context) {
    _walletListStore = Provider.of<WalletListStore>(context);

    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(top: 32),
        color: PaletteDark.menuHeader,
        child: ScrollableWithBottomSection(
            contentPadding: EdgeInsets.only(bottom: 20),
            content: Container(
              child: Observer(
                builder: (_) => ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, index) => Divider(
                        color: PaletteDark.menuHeader, height: 16),
                    itemCount: _walletListStore.wallets.length,
                    itemBuilder: (__, index) {
                      final wallet = _walletListStore.wallets[index];
                      final screenWidth = MediaQuery.of(context).size.width;

                      final isCurrentWallet =
                      _walletListStore.isCurrentWallet(wallet);

                      final walletMenu = WalletMenu(context);
                      final items = walletMenu.generateItemsForWalletMenu(isCurrentWallet);
                      final colors = walletMenu.generateColorsForWalletMenu(isCurrentWallet);
                      final images = walletMenu.generateImagesForWalletMenu(isCurrentWallet);

                      return Container(
                        height: 108,
                        width: double.infinity,
                        child: CustomScrollView(
                          scrollDirection: Axis.horizontal,
                          slivers: <Widget>[
                            SliverPersistentHeader(
                              pinned: false,
                              floating: true,
                              delegate: WalletTile(
                                  min: screenWidth - 228,
                                  max: screenWidth,
                                  image: moneroIcon,
                                  walletName: wallet.name,
                                  walletAddress: '',
                                  isCurrent: isCurrentWallet
                              ),
                            ),
                            SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {

                                    final item = items[index];
                                    final color = colors[index];
                                    final image = images[index];

                                    final content = Center(
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
                                                color: Colors.white
                                            ),
                                          )
                                        ],
                                      ),
                                    );

                                    if (index == 0) {
                                      return GestureDetector(
                                        onTap: () => walletMenu.action(
                                            walletMenu.listItems.indexOf(item), wallet, isCurrentWallet),
                                        child: Container(
                                          height: 108,
                                          width: 108,
                                          color: PaletteDark.menuHeader,
                                          child: Container(
                                            padding: EdgeInsets.only(left: 5, right: 5),
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.only(
                                                    topLeft: Radius.circular(12),
                                                    bottomLeft: Radius.circular(12)
                                                ),
                                                color: color
                                            ),
                                            child: content,
                                          ),
                                        ),
                                      );
                                    }

                                    return GestureDetector(
                                      onTap: () => walletMenu.action(
                                          walletMenu.listItems.indexOf(item), wallet, isCurrentWallet),
                                      child: Container(
                                        height: 108,
                                        width: 108,
                                        padding: EdgeInsets.only(left: 5, right: 5),
                                        color: color,
                                        child: content,
                                      ),
                                    );
                                  },
                                  childCount: items.length
                                )
                            )
                          ],
                        ),
                      );
                    }),
              ),
            ),
            bottomSection: Column(children: <Widget>[
              PrimaryIconButton(
                  onPressed: () => Navigator.of(context).pushNamed(Routes.newWallet),
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
            ])),
      )
    );
  }
}

class WalletTile extends SliverPersistentHeaderDelegate {
  WalletTile({
    @required this.min,
    @required this.max,
    @required this.image,
    @required this.walletName,
    @required this.walletAddress,
    @required this.isCurrent
  });

  final double min;
  final double max;
  final Image image;
  final String walletName;
  final String walletAddress;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {

    double opacity = 1 - shrinkOffset / (max - min);
    opacity = opacity >= 0 ? opacity : 0;

    double panelWidth = 12 * opacity;
    panelWidth = panelWidth < 12 ? 0 : 12;

    final currentColor = isCurrent
        ? Colors.white
        : PaletteDark.menuHeader;

    return Stack(
      fit: StackFit.expand,
      overflow: Overflow.visible,
      children: <Widget>[
        Positioned(
          top: 0,
          right: max - 4,
          child: Container(
            height: 108,
            width: 4,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
                color: currentColor
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 12,
          child: Container(
            height: 108,
            width: max - 16,
            padding: EdgeInsets.only(left: 20, right: 20),
            color: PaletteDark.menuHeader,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    image,
                    SizedBox(width: 10),
                    Text(
                      walletName,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Opacity(
            opacity: opacity,
            child: Container(
              height: 108,
              width: panelWidth,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        PaletteDark.walletCardTopEndSync,
                        PaletteDark.walletCardBottomEndSync
                      ]
                  )
              ),
            ),
          )
        ),
      ],
    );
  }

  @override
  double get maxExtent => max;

  @override
  double get minExtent => min;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;

}
