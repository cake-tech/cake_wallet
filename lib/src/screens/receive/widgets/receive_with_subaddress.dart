import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/subaddress_list/subaddress_list_store.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/screens/receive/widgets/address_widget.dart';

class ReceiveWithSubaddress extends StatefulWidget {
  @override
  ReceiveWithSubaddressState createState() => ReceiveWithSubaddressState();
}

class ReceiveWithSubaddressState extends State<ReceiveWithSubaddress> {

  @override
  Widget build(BuildContext context) {
    final walletStore = Provider.of<WalletStore>(context);
    final subaddressListStore = Provider.of<SubaddressListStore>(context);

    final currentColor = Theme.of(context).selectedRowColor;
    final notCurrentColor = Theme.of(context).scaffoldBackgroundColor;

    return SafeArea(
        child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(35.0),
                  color: Theme.of(context).backgroundColor,
                  child: AddressWidget(isSubaddress: true)
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                        child: Container(
                          color: Theme.of(context).accentTextTheme.headline.color,
                          child: Column(
                            children: <Widget>[
                              ListTile(
                                title: Text(
                                  S.of(context).subaddresses,
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      color: Theme.of(context)
                                          .primaryTextTheme
                                          .headline
                                          .color),
                                ),
                                trailing: Container(
                                  width: 28.0,
                                  height: 28.0,
                                  decoration: BoxDecoration(
                                      color: Theme.of(context).selectedRowColor,
                                      shape: BoxShape.circle),
                                  child: InkWell(
                                    onTap: () => Navigator.of(context)
                                        .pushNamed(Routes.newSubaddress),
                                    borderRadius: BorderRadius.all(Radius.circular(14.0)),
                                    child: Icon(
                                      Icons.add,
                                      color: Palette.violet,
                                      size: 22.0,
                                    ),
                                  ),
                                ),
                              ),
                              Divider(
                                color: Theme.of(context).dividerTheme.color,
                                height: 1.0,
                              )
                            ],
                          ),
                        ))
                  ],
                ),
                Observer(builder: (_) {
                  return ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: subaddressListStore.subaddresses.length,
                      separatorBuilder: (context, i) {
                        return Divider(
                          color: Theme.of(context).dividerTheme.color,
                          height: 1.0,
                        );
                      },
                      itemBuilder: (context, i) {
                        return Observer(builder: (_) {
                          final subaddress = subaddressListStore.subaddresses[i];
                          final isCurrent =
                              walletStore.subaddress.address == subaddress.address;
                          final label = subaddress.label.isNotEmpty
                              ? subaddress.label
                              : subaddress.address;

                          return InkWell(
                            onTap: () => walletStore.setSubaddress(subaddress),
                            child: Container(
                              color: isCurrent ? currentColor : notCurrentColor,
                              child: Column(children: <Widget>[
                                ListTile(
                                  title: Text(
                                    label,
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        color: Theme.of(context)
                                            .primaryTextTheme
                                            .headline
                                            .color),
                                  ),
                                )
                              ]),
                            ),
                          );
                        });
                      });
                })
              ],
            )));
  }
}