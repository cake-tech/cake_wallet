import 'package:cake_wallet/src/screens/transaction_details/textfield_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/widgets/textfield_list_row.dart';
import 'package:cake_wallet/src/screens/unspent_coins/widgets/unspent_coins_switch_row.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_details_view_model.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_switch_item.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/standart_list_row.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';

class UnspentCoinsDetailsPage extends BasePage {
  UnspentCoinsDetailsPage({this.unspentCoinsDetailsViewModel});

  @override
  String get title => S.current.unspent_coins_details_title;

  final UnspentCoinsDetailsViewModel unspentCoinsDetailsViewModel;

  @override
  Widget body(BuildContext context) {
    return SectionStandardList(
        sectionCount: 1,
        itemCounter: (int _) => unspentCoinsDetailsViewModel.items.length,
        itemBuilder: (_, __, index) {
          final item = unspentCoinsDetailsViewModel.items[index];

          if (item is StandartListItem) {
            return StandartListRow(
                title: '${item.title}:',
                value: item.value);
          }

          if (item is TextFieldListItem) {
            return TextFieldListRow(
              title: item.title,
              value: item.value,
              onSubmitted: item.onSubmitted,
            );
          }

          if (item is UnspentCoinsSwitchItem) {
            return Observer(builder: (_) => UnspentCoinsSwitchRow(
              title: item.title,
              switchValue: item.switchValue(),
              onSwitchValueChange: item.onSwitchValueChange
            ));
          }

          return null;
        });
  }
}