import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
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
    final dateSectionDateFormat = DateFormat("d MMM", currentLanguage);
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

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Center(
          child: Text(title,
              style: TextStyle(fontSize: 16, color: Palette.wildDarkBlue))),
    );
  }
}
