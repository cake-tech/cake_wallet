import 'package:intl/intl.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';

class DateFormatter {
  static String get currentLocalFormat {
    final isUSA = getIt.get<SettingsStore>().currentLocale == 'en_US';
    final format = isUSA ? 'yyyy.MM.dd, HH:mm' : 'dd.MM.yyyy, HH:mm';

    return format;
  }

  static DateFormat withCurrentLocal() =>
      DateFormat(currentLocalFormat, getIt.get<SettingsStore>().languageCode);
}
