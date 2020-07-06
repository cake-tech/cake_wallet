import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/standart_list_row.dart';
import 'package:cake_wallet/view_model/wallet_keys_view_model.dart';

class WalletKeysPage extends BasePage {
  WalletKeysPage(this.walletKeysViewModel);

  @override
  String get title => S.current.wallet_keys;

  final WalletKeysViewModel walletKeysViewModel;

  @override
  Widget body(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
        child: Observer(
          builder: (_) {
            return ListView.separated(
                separatorBuilder: (context, index) => Container(
                      height: 1,
                      padding: EdgeInsets.only(left: 24),
                      color: Theme.of(context)
                          .accentTextTheme
                          .title
                          .backgroundColor,
                      child: Container(
                        height: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                itemCount: walletKeysViewModel.items.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = walletKeysViewModel.items[index];

                  return GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: item.value));
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text(
                          S.of(context).copied_key_to_clipboard(item.title),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ));
                    },
                    child: StandartListRow(
                      title: item.title + ':',
                      value: item.value,
                    ),
                  );
                });
          },
        ));
  }
}
