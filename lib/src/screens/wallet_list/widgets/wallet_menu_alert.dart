import 'dart:ui';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/wallet_list/wallet_menu.dart';
import 'package:cake_wallet/src/screens/wallet_list/wallet_menu_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';

class WalletMenuAlert extends StatelessWidget {
  WalletMenuAlert({
    @required this.wallet,
    @required this.walletMenu,
    @required this.items
  });

  final WalletListItem wallet;
  final WalletMenu walletMenu;
  final List<WalletMenuItem> items;
  final closeButton = Image.asset('assets/images/close.png',
    color: Palette.darkBlueCraiola,
  );

  @override
  Widget build(BuildContext context) {
    return AlertBackground(
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
                left: 24,
                right: 24,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              child: Container(
                color: Theme.of(context).textTheme.body2.decorationColor,
                padding: EdgeInsets.only(left: 24),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, _) => Container(
                    height: 1,
                    color: Theme.of(context).accentTextTheme.subhead.backgroundColor,
                  ),
                  itemBuilder: (_, index) {
                    final item = items[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        walletMenu.action(
                            walletMenu.menuItems.indexOf(item),
                            wallet);
                      },
                      child: Container(
                        height: 60,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(4)),
                                  gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        item.firstGradientColor,
                                        item.secondGradientColor
                                      ]
                                  )
                              ),
                              child: Center(
                                child: item.image,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                    color: Theme.of(context).primaryTextTheme.title.color,
                                    fontSize: 18,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.none
                                ),
                              )
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          AlertCloseButton(image: closeButton)
        ],
      ),
    );
  }
}