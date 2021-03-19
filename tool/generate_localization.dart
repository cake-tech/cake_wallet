import 'dart:io';
import 'dart:convert';

const inputPath = 'res/values/';
const outputPath = 'lib/generated/i18n.dart';
const locales = ['en', 'de', 'es', 'hi',
                 'ja', 'ko', 'nl', 'pl',
                 'pt', 'ru', 'uk', 'zh'];

Future<void> main() async {
  var inputContent = File(inputPath + 'strings_en.arb').readAsStringSync();
  var config = json.decode(inputContent) as Map<String, dynamic>;
  var output = '';

  output += 'import \'dart:async\';' + '\n';
  output += 'import \'package:flutter/foundation.dart\';' + '\n';
  output += 'import \'package:flutter/material.dart\';' + '\n\n';
  output += 'class S implements WidgetsLocalizations {' + '\n';
  output += '  const S();' + '\n\n';
  output += '  static S current;' + '\n\n';
  output += '  static const GeneratedLocalizationsDelegate delegate =' + '\n';
  output += '    GeneratedLocalizationsDelegate();' + '\n\n';
  output += '  static S of(BuildContext context) => Localizations.of<S>(context, S);' + '\n\n';
  output += '  @override' + '\n';
  output += '  TextDirection get textDirection => TextDirection.ltr;' + '\n\n';

  output += localizedStrings(config: config, hasOverride: false);

  output += '}' + '\n\n';

  for (var locale in locales) {
    output += 'class \$$locale extends S {' + '\n';
    output += '  const \$$locale();' + '\n';

    if (locale != locales.first) {
      output += '\n' + '  @override' + '\n';
      output +=
          '  TextDirection get textDirection => TextDirection.ltr;' + '\n\n';

      inputContent = File(inputPath + 'strings_$locale.arb').readAsStringSync();
      config = json.decode(inputContent) as Map<String, dynamic>;

      output += localizedStrings(config: config, hasOverride: true);
    }

    output += '}' + '\n\n';
  }

  output += 'class GeneratedLocalizationsDelegate extends LocalizationsDelegate<S> {' + '\n';
  output += '  const GeneratedLocalizationsDelegate();' + '\n\n';
  output += '  List<Locale> get supportedLocales {' + '\n';
  output += '    return const <Locale>[' + '\n';

  for (var locale in locales) {
    output += '      Locale("$locale", ""),' + '\n';
  }

  output += '    ];' + '\n';
  output += '  }' + '\n\n';

  output += '  LocaleListResolutionCallback listResolution({Locale fallback, bool withCountry = true}) {' + '\n';
  output += '    return (List<Locale> locales, Iterable<Locale> supported) {' + '\n';
  output += '      if (locales == null || locales.isEmpty) {' + '\n';
  output += '        return fallback ?? supported.first;' + '\n';
  output += '      } else {' + '\n';
  output += '        return _resolve(locales.first, fallback, supported, withCountry);' + '\n';
  output += '      }' + '\n';
  output += '    };' + '\n';
  output += '  }' + '\n\n';

  output += '  LocaleResolutionCallback resolution({Locale fallback, bool withCountry = true}) {' + '\n';
  output += '    return (Locale locale, Iterable<Locale> supported) {' + '\n';
  output += '      return _resolve(locale, fallback, supported, withCountry);' + '\n';
  output += '    };' + '\n';
  output += '  }' + '\n\n';

  output += '  @override' + '\n';
  output += '  Future<S> load(Locale locale) {' + '\n';
  output += '    final String lang = getLang(locale);' + '\n';
  output += '    if (lang != null) {' + '\n';
  output += '      switch (lang) {' + '\n';

  for (var locale in locales) {
    output += '        case "$locale":' + '\n';
    output += '          S.current = const \$$locale();' + '\n';
    output += '          return SynchronousFuture<S>(S.current);' + '\n';
  }

  output += '        default:' + '\n';
  output += '      }' + '\n';
  output += '    }' + '\n';
  output += '    S.current = const S();' + '\n';
  output += '    return SynchronousFuture<S>(S.current);' + '\n';
  output += '  }' + '\n\n';

  output += '  @override' + '\n';
  output += '  bool isSupported(Locale locale) => _isSupported(locale, true);' + '\n\n';

  output += '  @override' + '\n';
  output += '  bool shouldReload(GeneratedLocalizationsDelegate old) => false;' + '\n\n';

  output += '  Locale _resolve(Locale locale, Locale fallback, Iterable<Locale> supported, bool withCountry) {' + '\n';
  output += '    if (locale == null || !_isSupported(locale, withCountry)) {' + '\n';
  output += '      return fallback ?? supported.first;' + '\n';
  output += '    }' + '\n\n';
  output += '    final Locale languageLocale = Locale(locale.languageCode, "");' + '\n';
  output += '    if (supported.contains(locale)) {' + '\n';
  output += '      return locale;' + '\n';
  output += '    } else if (supported.contains(languageLocale)) {' + '\n';
  output += '      return languageLocale;' + '\n';
  output += '    } else {' + '\n';
  output += '      final Locale fallbackLocale = fallback ?? supported.first;' + '\n';
  output += '      return fallbackLocale;' + '\n';
  output += '    }' + '\n';
  output += '  }' + '\n\n';

  output += '  bool _isSupported(Locale locale, bool withCountry) {' + '\n';
  output += '    if (locale != null) {' + '\n';
  output += '      for (Locale supportedLocale in supportedLocales) {' + '\n';
  output += '        if (supportedLocale.languageCode != locale.languageCode) {' + '\n';
  output += '          continue;' + '\n';
  output += '        }' + '\n';
  output += '        if (supportedLocale.countryCode == locale.countryCode) {' + '\n';
  output += '          return true;' + '\n';
  output += '        }' + '\n';
  output += '        if (true != withCountry && (supportedLocale.countryCode == null || supportedLocale.countryCode.isEmpty)) {' + '\n';
  output += '          return true;' + '\n';
  output += '        }' + '\n';
  output += '      }' + '\n';
  output += '    }' + '\n';
  output += '    return false;' + '\n';
  output += '  }' + '\n';
  output += '}' + '\n\n';

  output += 'String getLang(Locale l) => l == null' + '\n';
  output += '  ? null' + '\n';
  output += '  : l.countryCode != null && l.countryCode.isEmpty' + '\n';
  output += '    ? l.languageCode' + '\n';
  output += '    : l.toString();';

  await File(outputPath).writeAsString(output);
}

String localizedStrings({Map<String, dynamic> config, bool hasOverride}) {
  var output = '';

  final pattern = RegExp('[\$]{(.*?)}');

  for (int i = 0; i < config.length; i++) {
    final key = config.keys.elementAt(i);
    final value = config.values.elementAt(i) as String;
    final matches = pattern.allMatches(value);

    if (hasOverride) {
      output += '  @override' + '\n';
    }

    if (matches.length == 0) {
      output += '  String get ${key} => \'\'\'${value}\'\'\';' + '\n';
    } else {
      output += '  String ${key}(';
      for (var match in matches) {
        if (match.group(1) == matches.last.group(1)) {
          output += 'String ${match.group(1)}';
        } else {
          output += 'String ${match.group(1)}, ';
        }
      }
      output += ') => \'\'\'${value}\'\'\';' + '\n';
    }
  }

  return output;
}

