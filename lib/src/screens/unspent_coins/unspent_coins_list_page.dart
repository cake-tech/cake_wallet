import 'package:cake_wallet/bitcoin_cash/bitcoin_cash.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/unspent_coins/widgets/unspent_coins_list_item.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class UnspentCoinsListPage extends BasePage {
  UnspentCoinsListPage({required this.unspentCoinsListViewModel});

  @override
  String get title => S.current.unspent_coins_title;

  final UnspentCoinsListViewModel unspentCoinsListViewModel;

  @override
  Widget body(BuildContext context) => UnspentCoinsListForm(unspentCoinsListViewModel);
}

class UnspentCoinsListForm extends StatefulWidget {
  UnspentCoinsListForm(this.unspentCoinsListViewModel);

  final UnspentCoinsListViewModel unspentCoinsListViewModel;

  @override
  UnspentCoinsListFormState createState() => UnspentCoinsListFormState(unspentCoinsListViewModel);
}

class UnspentCoinsListFormState extends State<UnspentCoinsListForm> {
  UnspentCoinsListFormState(this.unspentCoinsListViewModel);

  final UnspentCoinsListViewModel unspentCoinsListViewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Observer(
            builder: (_) => ListView.separated(
                itemCount: unspentCoinsListViewModel.items.length,
                separatorBuilder: (_, __) => SizedBox(height: 15),
                itemBuilder: (_, int index) {
                  return Observer(builder: (_) {
                    final item = unspentCoinsListViewModel.items[index];
                    final address = unspentCoinsListViewModel.wallet.type == WalletType.bitcoinCash
                        ? bitcoinCash!.getCashAddrFormat(item.address)
                        : item.address;

                    return GestureDetector(
                        onTap: () => Navigator.of(context).pushNamed(Routes.unspentCoinsDetails,
                            arguments: [item, unspentCoinsListViewModel]),
                        child: UnspentCoinsListItem(
                            note: item.note,
                            amount: item.amount,
                            address: address,
                            isSending: item.isSending,
                            isFrozen: item.isFrozen,
                            isChange: item.isChange,
                            onCheckBoxTap: item.isFrozen
                                ? null
                                : () async {
                                    item.isSending = !item.isSending;
                                    await unspentCoinsListViewModel.saveUnspentCoinInfo(item);
                                  }));
                  });
                })));
  }
}
