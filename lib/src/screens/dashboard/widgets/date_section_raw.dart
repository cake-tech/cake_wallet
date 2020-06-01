import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';

class DateSectionRaw extends StatelessWidget {
  DateSectionRaw({this.date});

  static final nowDate = DateTime.now();
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final diffDays = date.difference(nowDate).inDays;
    final isToday = nowDate.day == date.day &&
        nowDate.month == date.month &&
        nowDate.year == date.year;
    final settingsStore = Provider.of<SettingsStore>(context);
    final currentLanguage = settingsStore.languageCode;
    final dateSectionDateFormat = settingsStore.getCurrentDateFormat(
          formatUSA: "yyyy MMM d",
          formatDefault: "d MMM yyyy");
    var title = "";

    if (isToday) {
      title = S.of(context).today;
    } else if (diffDays == 0) {
      title = S.of(context).yesterday;
    } else if (diffDays > -7 && diffDays < 0) {
      final dateFormat = DateFormat.EEEE(currentLanguage);
      title = dateFormat.format(date);
    } else {
      title = dateSectionDateFormat.format(date);
    }

    return Container(
      height: 36,
      padding: EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
      alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          border: Border.all(
            width: 1,
            color: Theme.of(context).backgroundColor
          ),
        ),
      child: Text(title,
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).primaryTextTheme.headline.color
          ))
    );
  }
}
