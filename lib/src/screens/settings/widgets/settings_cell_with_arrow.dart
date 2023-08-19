import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';

class SettingsCellWithArrow extends StandardListRow {
  SettingsCellWithArrow({required String title, required Function(BuildContext context)? handler})
      : super(title: title, isSelected: false, onTap: handler);

  @override
  Widget buildTrailing(BuildContext context) => Image.asset('assets/images/select_arrow.png',
      color: Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor);
}
