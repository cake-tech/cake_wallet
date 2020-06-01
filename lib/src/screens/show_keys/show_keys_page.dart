import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_keys_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/standart_list_row.dart';

class ShowKeysPage extends BasePage {
  @override
  String get title => S.current.wallet_keys;

  @override
  Widget body(BuildContext context) {
    final walletKeysStore = Provider.of<WalletKeysStore>(context);

    return Container(
        padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
        child: Observer(
          builder: (_) {
            final keysMap = {
              S.of(context).view_key_public: walletKeysStore.publicViewKey,
              S.of(context).spend_key_private: walletKeysStore.privateSpendKey
            };

            if (walletKeysStore.privateViewKey.isNotEmpty) {
              keysMap[S.of(context).view_key_private] =
                  walletKeysStore.privateViewKey;
            }

            if (walletKeysStore.publicSpendKey.isNotEmpty) {
              keysMap[S.of(context).spend_key_public] =
                  walletKeysStore.publicSpendKey;
            }

            return ListView.separated(
                separatorBuilder: (context, index) => Container(
                  height: 1,
                  padding: EdgeInsets.only(left: 24),
                  color: Theme.of(context).accentTextTheme.title.backgroundColor,
                  child: Container(
                    height: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                itemCount: keysMap.length,
                itemBuilder: (BuildContext context, int index) {
                  final key = keysMap.keys.elementAt(index);
                  final value = keysMap.values.elementAt(index);

                  final isDrawTop = index == 0 ? true : false;
                  final isDrawBottom = index == keysMap.length - 1 ? true : false;

                  return GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text(
                          S.of(context).copied_key_to_clipboard(key),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ));
                    },
                    child: StandartListRow(
                      title: key + ':',
                      value: value,
                      isDrawTop: isDrawTop,
                      isDrawBottom: isDrawBottom,
                    ),
                  );
                });
          },
        ));
  }
}
