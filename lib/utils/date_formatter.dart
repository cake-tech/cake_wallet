import 'package:cake_wallet/generated/i18n.dart';
import 'package:intl/intl.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';

class DateFormatter {
  static String currentLocalFormat({bool hasTime = true, bool reverse = false}) {
    // final isUSA = getIt.get<SettingsStore>().languageCode.toLowerCase() == 'en';
    // final format = isUSA ? usaStyleFormat(hasTime, reverse) : regularStyleFormat(hasTime, reverse);

    return hasTime ? (reverse ? "HH:mm  MMMM d, yyyy" : "MMMM d, yyyy, HH:mm") : "MMMM d, yyyy";
  }

  static DateFormat withCurrentLocal({bool hasTime = true, bool reverse = false}) => DateFormat(
      currentLocalFormat(hasTime: hasTime, reverse: reverse),
      getIt.get<SettingsStore>().languageCode);

  static String usaStyleFormat(bool hasTime, bool reverse) =>
      hasTime ? (reverse ? 'HH:mm  yyyy.MM.dd' : 'yyyy.MM.dd, HH:mm') : 'yyyy.MM.dd';

  static String regularStyleFormat(bool hasTime, bool reverse) =>
      hasTime ? (reverse ? 'HH:mm  dd.MM.yyyy' : 'dd.MM.yyyy, HH:mm') : 'dd.MM.yyyy';

  static String convertDateTimeToReadableString(DateTime date) {
    final nowDate = DateTime.now();
    final diffDays = date.difference(nowDate).inDays;
    final isToday =
        nowDate.day == date.day && nowDate.month == date.month && nowDate.year == date.year;
    final dateSectionDateFormat = withCurrentLocal(hasTime: false);
    var title = "";

    if (isToday) {
      title = S.current.today;
    } else if (diffDays == 0) {
      title = S.current.yesterday;
    } else if (diffDays > -7 && diffDays < 0) {
      final dateFormat = DateFormat.EEEE();
      title = dateFormat.format(date);
    } else {
      title = dateSectionDateFormat.format(date);
    }

    return title;
  }

  static String formatTransactionDate(DateTime date, String localeName) {
    final time = DateFormat.Hm(localeName);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(date.year, date.month, date.day);
    final daysAgo = today.difference(thatDay).inDays;

    final timeStr = time.format(date);

    if (daysAgo == 0) {
      return timeStr;
    }

    if (daysAgo == 1) {
      return "${S.current.yesterday}, $timeStr";
    }

    if (daysAgo < 7) {
      final weekday = DateFormat.EEEE(localeName).format(date);
      return "$weekday, $timeStr";
    }

    if (date.year == now.year) {
      final dayMonth = DateFormat("d MMMM", localeName).format(date);
      return "$dayMonth, $timeStr";
    }

    final full = DateFormat("d MMM yyyy", localeName).format(date);
    return "$full, $timeStr";
  }
}
