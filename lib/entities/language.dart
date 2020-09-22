import 'package:flutter/material.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:intl/intl.dart';

const Map<String, String> languages = {
  'en': 'English',
  'de': 'Deutsch (German)',
  'es': 'Español (Spanish)',
  'hi': 'हिंदी (Hindi)',
  'ja': '日本 (Japanese)',
  'ko': '한국어 (Korean)',
  'nl': 'Nederlands (Dutch)',
  'pl': 'Polski (Polish)',
  'pt': 'Português (Portuguese)',
  'ru': 'Русский (Russian)',
  'uk': 'Українська (Ukrainian)',
  'zh': '中文 (Chinese)'
};

class Language with ChangeNotifier {
  Language(this._currentLanguage);

  String _currentLanguage;

  String getCurrentLanguage() => _currentLanguage;

  void setCurrentLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
  }

  static Future<String> localeDetection() async {
    var locale = await Devicelocale.currentLocale;
    locale = Intl.shortLocale(locale);

    return languages.keys.contains(locale) ? locale : 'en';
  }
}