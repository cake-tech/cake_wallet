import 'package:cake_wallet/generated/locales.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:intl/intl.dart';

class LanguageService {
  static const Map<String, String> supportedLocales = {
    'en': 'English',
    'de': 'Deutsch (German)',
    'es': 'Español (Spanish)',
    'fr': 'Français (French)',
    'gn': 'Guarani (Guarani)',
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
    'yo': 'Yorùbá (Yoruba)',
    'ha': 'Hausa Najeriya (Nigeria)',
    'tl': 'Filipino (Tagalog)',
    'hy': 'Հայերեն (Armenian)',
    'vi': 'Tiếng Việt (Vietnamese)',
  };

  static const Map<String, String> localeCountryCode = {
    'en': 'usa',
    'de': 'deu',
    'es': 'esp',
    'fr': 'fra',
    'gn': 'grn',
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
    'yo': 'nga',
    'ha': 'hau',
    'tl': 'phl',
    'hy': 'arm',
    'vi': 'vnm',
  };

  static final list = <String, String>{};

  static const defaultLocale = 'en';

  static void loadLocaleList() {
    supportedLocales.forEach((key, value) {
      if (locales.contains(key)) {
        list[key] = value;
      }
    });
  }

  static Future<String> localeDetection() async {
    try {
        var locale = await Devicelocale.currentLocale ?? '';
        locale = Intl.shortLocale(locale);

        if (list.keys.contains(locale)) {
            return locale;
        }
        return LanguageService.defaultLocale;
    } catch(_) {
        return LanguageService.defaultLocale;
    }
  }
}
