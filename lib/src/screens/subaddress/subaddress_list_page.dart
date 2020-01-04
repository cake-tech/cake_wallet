import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/subaddress_list/subaddress_list_store.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class SubaddressListPage extends BasePage {
  bool get isModalBackButton => true;
  String get title => S.current.subaddress_title;
  AppBarStyle get appBarStyle => AppBarStyle.withShadow;

  SubaddressListPage();

  @override
  Widget body(BuildContext context) {
    final walletStore = Provider.of<WalletStore>(context);
    final subaddressListStore = Provider.of<SubaddressListStore>(context);

    final currentColor = Theme.of(context).selectedRowColor;
    final notCurrentColor = Theme.of(context).backgroundColor;

    return Container(
        padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
        child: Observer(
          builder: (_) => ListView.separated(
              separatorBuilder: (_, __) => Divider(
                    color: Theme.of(context).dividerTheme.color,
                    height: 1.0,
                  ),
              itemCount: subaddressListStore.subaddresses == null
                  ? 0
                  : subaddressListStore.subaddresses.length,
              itemBuilder: (BuildContext context, int index) {
                final subaddress = subaddressListStore.subaddresses[index];
                final isCurrent =
                    walletStore.subaddress.address == subaddress.address;
                final label = subaddress.label != null
                    ? subaddress.label
                    : subaddress.address;

                return InkWell(
                  onTap: () => Navigator.of(context).pop(subaddress),
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
              }),
        ));
  }
}
