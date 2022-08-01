import 'package:intl/intl.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';

class DateFormatter {
  static String currentLocalFormat({bool hasTime = true, bool reverse = false}) {
    final isUSA = getIt.get<SettingsStore>().languageCode.toLowerCase() == 'en';
    final format =
        isUSA ? usaStyleFormat(hasTime, reverse) : regularStyleFormat(hasTime, reverse);

    return format;
  }

  static DateFormat withCurrentLocal({bool hasTime = true, bool reverse = false}) => DateFormat(
      currentLocalFormat(hasTime: hasTime, reverse: reverse),
      getIt.get<SettingsStore>().languageCode);

  static String usaStyleFormat(bool hasTime, bool reverse) =>
      hasTime ? (reverse ? 'HH:mm  yyyy.MM.dd' : 'yyyy.MM.dd, HH:mm') : 'yyyy.MM.dd';

  static String regularStyleFormat(bool hasTime, bool reverse) =>
      hasTime ? (reverse ? 'HH:mm  dd.MM.yyyy' : 'dd.MM.yyyy, HH:mm') : 'dd.MM.yyyy';
}
