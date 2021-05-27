import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/unspent_coins/widgets/unspent_coins_list_item.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class UnspentCoinsListPage extends BasePage {
  UnspentCoinsListPage({this.unspentCoinsListViewModel});

  @override
  String get title => 'Unspent coins';

  final UnspentCoinsListViewModel unspentCoinsListViewModel;

  @override
  Widget body(BuildContext context) {
    return Observer(builder: (_) => SectionStandardList(
        sectionCount: 1,
        itemCounter: (int _) => unspentCoinsListViewModel.items.length,
        itemBuilder: (_, __, index) {
          final item = unspentCoinsListViewModel.items[index];

          return GestureDetector(
              onTap: () =>
                  Navigator.of(context).pushNamed(Routes.unspentCoinsDetails,
                      arguments: item),
              child: UnspentCoinsListItem(
                address: item.address,
                amount: item.amount,
                isFrozen: item.isFrozen,
                note: item.note,
                isSending: item.isSending,
                onCheckBoxTap: (value) {print('CheckBox taped');},
              ));
        }));
  }

}