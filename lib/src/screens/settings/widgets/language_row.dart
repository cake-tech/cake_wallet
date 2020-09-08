import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';

class LanguageRow extends StandardListRow {
  LanguageRow({@required String title, @required this.isSelected, @required Function(BuildContext context) handler}) :
        super(title: title, isSelected: isSelected, onTap: handler);

  @override
  final bool isSelected;

  @override
  Widget buildCenter(BuildContext context, {@required bool hasLeftOffset}) {
    return Expanded(
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          if (hasLeftOffset) SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: titleColor(context)))
        ]));
  }

  @override
  Widget buildTrailing(BuildContext context) =>
      isSelected
          ? Icon(Icons.done, color: Palette.blueCraiola)
          : Offstage();
}