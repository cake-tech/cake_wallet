import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class UnspentCoinsListItem extends StatelessWidget {
  UnspentCoinsListItem({
    @required this.address,
    @required this.amount,
    @required this.isFrozen,
    @required this.note,
    @required this.isSending,
    @required this.onCheckBoxTap,
});

  final String address;
  final String amount;
  final bool isFrozen;
  final String note;
  final bool isSending;
  final Function(bool) onCheckBoxTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Theme.of(context)
            .primaryTextTheme
            .title
            .color);

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
      color: Theme.of(context).backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              address ?? 'Address',
              style: textStyle,
          ),
          Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                  amount ?? 'Amount',
                  style: textStyle,
              )
          ),
          if (isFrozen ?? false) Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Freeze',
                style: textStyle,
              )
          ),
          if (note?.isNotEmpty ?? false) Padding(
              padding: EdgeInsets.only(top: 12),
              child: AutoSizeText(
                  note,
                  style: textStyle,
                  maxLines: 1
              )
          ),
          Padding(
              padding: EdgeInsets.only(top: 12),
              child: StandardCheckbox(
                value: isSending,
                caption: 'Sending',
                onChanged: onCheckBoxTap
              )
          )
        ],
      )
    );
  }
}