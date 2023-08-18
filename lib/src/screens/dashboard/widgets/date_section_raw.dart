import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:intl/intl.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/utils/date_formatter.dart';

class DateSectionRaw extends StatelessWidget {
  DateSectionRaw({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final nowDate = DateTime.now();
    final diffDays = date.difference(nowDate).inDays;
    final isToday = nowDate.day == date.day &&
        nowDate.month == date.month &&
        nowDate.year == date.year;
    final dateSectionDateFormat = DateFormatter.withCurrentLocal(hasTime: false);
    var title = "";

    if (isToday) {
      title = S.of(context).today;
    } else if (diffDays == 0) {
      title = S.of(context).yesterday;
    } else if (diffDays > -7 && diffDays < 0) {
      final dateFormat = DateFormat.EEEE();
      title = dateFormat.format(date);
    } else {
      title = dateSectionDateFormat.format(date);
    }

    return Container(
        height: 35,
        alignment: Alignment.center,
        color: Colors.transparent,
        child: Text(title,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).extension<CakeTextTheme>()!.dateSectionRowColor)));
  }
}
