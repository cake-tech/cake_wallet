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
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/screens/wallet_list/wallet_menu.dart';
import 'package:cake_wallet/src/screens/wallet_list/widgets/wallet_tile.dart';

class WalletListPage extends BasePage {

  @override
  Color get backgroundColor => PaletteDark.historyPanel;

  @override
  Widget body(BuildContext context) => WalletListBody();
}

class WalletListBody extends StatefulWidget {
  @override
  WalletListBodyState createState() => WalletListBodyState();
}

class WalletListBodyState extends State<WalletListBody> {
  final moneroIcon = Image.asset('assets/images/monero.png', height: 24, width: 24);
  final newWalletImage = Image.asset('assets/images/new_wallet.png', height: 12, width: 12, color: PaletteDark.historyPanel);
  final restoreWalletImage = Image.asset('assets/images/restore_wallet.png', height: 12, width: 12, color: Colors.white);
  WalletListStore _walletListStore;
  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final walletStore = Provider.of<WalletStore>(context);
    _walletListStore = Provider.of<WalletListStore>(context);

    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(top: 16),
        color: PaletteDark.historyPanel,
        child: ScrollableWithBottomSection(
            contentPadding: EdgeInsets.only(bottom: 20),
            content: Container(
              child: Observer(
                builder: (_) => ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, index) => Divider(
                        color: PaletteDark.historyPanel, height: 16),
                    itemCount: _walletListStore.wallets.length,
                    itemBuilder: (__, index) {
                      final wallet = _walletListStore.wallets[index];
                      final screenWidth = MediaQuery.of(context).size.width;

                      final isCurrentWallet =
                      _walletListStore.isCurrentWallet(wallet);

                      String shortAddress = '';

                      if (isCurrentWallet) {
                        shortAddress = walletStore.subaddress.address;
                        shortAddress = shortAddress.replaceRange(4, shortAddress.length - 4, '...');
                      }

                      final walletMenu = WalletMenu(context);
                      final items = walletMenu.generateItemsForWalletMenu(isCurrentWallet);
                      final colors = walletMenu.generateColorsForWalletMenu(isCurrentWallet);
                      final images = walletMenu.generateImagesForWalletMenu(isCurrentWallet);

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
                                  image: moneroIcon,
                                  walletName: wallet.name,
                                  walletAddress: shortAddress,
                                  isCurrent: isCurrentWallet
                              ),
                            ),
                            SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {

                                    final item = items[index];
                                    final color = colors[index];
                                    final image = images[index];

                                    final radius = index == 0 ? 12.0 : 0.0;

                                    return GestureDetector(
                                      onTap: () {
                                        scrollController.animateTo(0.0, duration: Duration(milliseconds: 500), curve: Curves.fastOutSlowIn);
                                        walletMenu.action(
                                            walletMenu.listItems.indexOf(item), wallet, isCurrentWallet);
                                      },
                                      child: Container(
                                        height: 108,
                                        width: 108,
                                        color: PaletteDark.historyPanel,
                                        child: Container(
                                          padding: EdgeInsets.only(left: 5, right: 5),
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(radius),
                                                  bottomLeft: Radius.circular(radius)
                                              ),
                                              color: color
                                          ),
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
                                                      color: Colors.white
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
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
              PrimaryImageButton(
                onPressed: () => Navigator.of(context).pushNamed(Routes.newWalletType),
                image: newWalletImage,
                text: S.of(context).wallet_list_create_new_wallet,
                color: Colors.white,
                textColor: PaletteDark.historyPanel),
              SizedBox(height: 10.0),
              PrimaryImageButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.restoreWalletOptions),
                image: restoreWalletImage,
                text: S.of(context).wallet_list_restore_wallet,
                color: PaletteDark.historyPanelButton,
                textColor: Colors.white)
            ])),
      )
    );
  }
}
