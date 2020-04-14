import 'package:cake_wallet/src/stores/sync/sync_store.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/palette.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';

class WalletCard extends StatefulWidget {
  @override
  WalletCardState createState() => WalletCardState();
}

class WalletCardState extends State<WalletCard> {
  final _syncingObserverKey = GlobalKey();
  final triangleButton = Image.asset('assets/images/triangle.png');

  final List<Color> colorsSync = [PaletteDark.walletCardTopEndSync, PaletteDark.walletCardBottomEndSync];
  double cardWidth;
  double screenWidth;
  double opacity;

  @override
  void initState() {
    cardWidth = 0;
    screenWidth = 0;
    opacity = 0;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
  }

  void afterLayout(dynamic _) {
    screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      cardWidth = screenWidth;
      opacity = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final syncStore = Provider.of<SyncStore>(context);
    final walletStore = Provider.of<WalletStore>(context);

    return Container(
      width: double.infinity,
      height: 220,
      alignment: Alignment.centerRight,
      child: AnimatedContainer(
        alignment: Alignment.centerLeft,
        width: cardWidth,
        height: 220,
        duration: Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
            gradient: LinearGradient(
                colors: [PaletteDark.walletCardTopStartSync.withOpacity(opacity),
                         PaletteDark.walletCardBottomStartSync.withOpacity(opacity)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter
            )
        ),
        child: screenWidth > 0 && cardWidth == screenWidth
        ? InkWell(
          onTap: (){print('TAP');},
          child: Observer(
            key: _syncingObserverKey,
            builder: (_) {
              final status = syncStore.status;
              final statusText = status.title();
              final progress = syncStore.status.progress();
              //final isFialure = status is FailedSyncStatus;

              var descriptionText = '';

              if (status is SyncingSyncStatus) {
                descriptionText = S
                    .of(context)
                    .Blocks_remaining(
                    syncStore.status.toString());
              }

              if (status is FailedSyncStatus) {
                descriptionText = S
                    .of(context)
                    .please_try_to_connect_to_another_node;
              }

              return Container(
                width: cardWidth,
                height: 220,
                child: Stack(
                  children: <Widget>[
                    Container(
                      height: 220,
                      width: progress * cardWidth,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                          gradient: LinearGradient(
                              colors: colorsSync,
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter
                          )
                      ),
                    ),
                    Positioned(
                        left: 20,
                        right: 20,
                        top: 30,
                        bottom: 30,
                        child: Container(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      InkWell(
                                        onTap: (){print('TAP 2');},
                                        child: Row(
                                          children: <Widget>[
                                            Text(
                                              walletStore.name,
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            triangleButton
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        walletStore.account.label,
                                        style: TextStyle(
                                            fontSize: 12
                                        ),
                                      )
                                    ],
                                  ),
                                  Text(
                                      walletStore.account.label
                                  )
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        statusText,
                                        style: TextStyle(
                                          fontSize: 12
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        descriptionText,
                                        style: TextStyle(
                                          fontSize: 14
                                        ),
                                      )
                                    ],
                                  ),
                                  Text(
                                      walletStore.account.label
                                  )
                                ],
                              )
                            ],
                          ),
                        )
                    )
                  ],
                ),
              );
            },
          )
        )
        : Offstage(),
      ),
    );
  }
}