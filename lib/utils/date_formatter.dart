import 'package:intl/intl.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';

class DateFormatter {
  static String currentLocalFormat({bool hasTime = true}) {
    final isUSA = getIt.get<SettingsStore>().languageCode.toLowerCase() == 'en';
    final format =
        isUSA ? usaStyleFormat(hasTime) : regularStyleFormat(hasTime);

    return format;
  }

  static DateFormat withCurrentLocal({bool hasTime = true}) => DateFormat(
      currentLocalFormat(hasTime: hasTime),
      getIt.get<SettingsStore>().languageCode);

  static String usaStyleFormat(bool hasTime) =>
      hasTime ? 'yyyy.MM.dd, HH:mm' : 'yyyy.MM.dd';

  static String regularStyleFormat(bool hasTime) =>
      hasTime ? 'dd.MM.yyyy, HH:mm' : 'dd.MM.yyyy';
}
