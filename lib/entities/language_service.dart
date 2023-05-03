import 'package:cake_wallet/generated/locales.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:intl/intl.dart';

class LanguageService {
  static const Map<String, String> supportedLocales = {
    'en': 'English',
    'de': 'Deutsch (German)',
    'es': 'Español (Spanish)',
    'fr': 'Français (French)',
    'hi': 'हिंदी (Hindi)',
    'ja': '日本 (Japanese)',
    'ko': '한국어 (Korean)',
    'nl': 'Nederlands (Dutch)',
    'pl': 'Polski (Polish)',
    'pt': 'Português (Portuguese)',
    'ru': 'Русский (Russian)',
    'uk': 'Українська (Ukrainian)',
    'zh': '中文 (Chinese)',
    'hr': 'Hrvatski (Croatian)',
    'it': 'Italiano (Italian)',
    'th': 'ภาษาไทย (Thai)',
    'ar': 'العربية (Arabic)',
    'tr': 'Türkçe (Turkish)',
    'my': 'မြန်မာ (Burmese)',
    'bg': 'Български (Bulgarian)',
    'cs': 'čeština (Czech)',
    'ur': 'اردو (Urdu)',
    'id': 'Bahasa Indonesia (Indonesian)',
    'ha': 'Hausa Najeriya (Nigeria)'
  };

  static const Map<String, String> localeCountryCode = {
    'en': 'usa',
    'de': 'deu',
    'es': 'esp',
    'fr': 'fra',
    'hi': 'ind',
    'ja': 'jpn',
    'ko': 'kor',
    'nl': 'nld',
    'pl': 'pol',
    'pt': 'prt',
    'ru': 'rus',
    'uk': 'ukr',
    'zh': 'chn',
    'hr': 'hrv',
    'it': 'ita',
    'th': 'tha',
    'ar': 'sau',
    'tr': 'tur',
    'my': 'mmr',
    'bg': 'bgr',
    'cs': 'czk',
    'ur': 'pak',
    'id': 'idn',
    'ha': 'hau'
  };

  static final list = <String, String> {};

  static void loadLocaleList() {
    supportedLocales.forEach((key, value) {
      if (locales.contains(key)) {
        list[key] = value;
      }
    });
  }

  static Future<String> localeDetection() async {
    var locale = await Devicelocale.currentLocale ?? '';
    locale = Intl.shortLocale(locale);

    return list.keys.contains(locale) ? locale : 'en';
  }
}
