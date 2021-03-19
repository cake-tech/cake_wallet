import 'dart:io';
import 'dart:convert';

const inputPath = 'res/values/';
const outputPath = 'lib/generated/i18n.dart';
const locales = ['en', 'de', 'es', 'hi',
                 'ja', 'ko', 'nl', 'pl',
                 'pt', 'ru', 'uk', 'zh'];
const header = """
import \'dart:async\';
import \'package:flutter/foundation.dart\';
import \'package:flutter/material.dart\';

class S implements WidgetsLocalizations {
  const S();

  static S current;

  static const GeneratedLocalizationsDelegate delegate =
    GeneratedLocalizationsDelegate();

  static S of(BuildContext context) => Localizations.of<S>(context, S);  
""";

const textDirectionDeclaration = """
      
  @override
  TextDirection get textDirection => TextDirection.ltr;
  
""";

const classDeclaration = """
class GeneratedLocalizationsDelegate extends LocalizationsDelegate<S> {
  const GeneratedLocalizationsDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
""";

const middle = """
    ];
  }

  LocaleListResolutionCallback listResolution({Locale fallback, bool withCountry = true}) {
    return (List<Locale> locales, Iterable<Locale> supported) {
      if (locales == null || locales.isEmpty) {
        return fallback ?? supported.first;
      } else {
        return _resolve(locales.first, fallback, supported, withCountry);
      }
    };
  }

  LocaleResolutionCallback resolution({Locale fallback, bool withCountry = true}) {
    return (Locale locale, Iterable<Locale> supported) {
      return _resolve(locale, fallback, supported, withCountry);
    };
  }

  @override
  Future<S> load(Locale locale) {
    final String lang = getLang(locale);
    if (lang != null) {
      switch (lang) {
""";

const end = """
        default:
      }
    }
    S.current = const S();
    return SynchronousFuture<S>(S.current);
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale, true);

  @override
  bool shouldReload(GeneratedLocalizationsDelegate old) => false;

  Locale _resolve(Locale locale, Locale fallback, Iterable<Locale> supported, bool withCountry) {
    if (locale == null || !_isSupported(locale, withCountry)) {
      return fallback ?? supported.first;
    }

    final Locale languageLocale = Locale(locale.languageCode, "");
    if (supported.contains(locale)) {
      return locale;
    } else if (supported.contains(languageLocale)) {
      return languageLocale;
    } else {
      final Locale fallbackLocale = fallback ?? supported.first;
      return fallbackLocale;
    }
  }

  bool _isSupported(Locale locale, bool withCountry) {
    if (locale != null) {
      for (Locale supportedLocale in supportedLocales) {
        if (supportedLocale.languageCode != locale.languageCode) {
          continue;
        }
        if (supportedLocale.countryCode == locale.countryCode) {
          return true;
        }
        if (true != withCountry && (supportedLocale.countryCode == null || supportedLocale.countryCode.isEmpty)) {
          return true;
        }
      }
    }
    return false;
  }
}

String getLang(Locale l) => l == null
  ? null
  : l.countryCode != null && l.countryCode.isEmpty
    ? l.languageCode
    : l.toString();
""";

Future<void> main() async {
  var inputContent = File(inputPath + 'strings_en.arb').readAsStringSync();
  var config = json.decode(inputContent) as Map<String, dynamic>;
  var output = '';

  output += header;
  output += textDirectionDeclaration;
  output += localizedStrings(config: config, hasOverride: false);
  output += '}' + '\n\n';

  for (var locale in locales) {
    output += 'class \$$locale extends S {' + '\n';
    output += '  const \$$locale();' + '\n';

    if (locale != locales.first) {
      output += textDirectionDeclaration;

      inputContent = File(inputPath + 'strings_$locale.arb').readAsStringSync();
      config = json.decode(inputContent) as Map<String, dynamic>;

      output += localizedStrings(config: config, hasOverride: true);
    }

    output += '}' + '\n\n';
  }

  output += classDeclaration;

  for (var locale in locales) {
    output += '      Locale("$locale", ""),' + '\n';
  }

  output += middle;

  for (var locale in locales) {
    output += '        case "$locale":' + '\n';
    output += '          S.current = const \$$locale();' + '\n';
    output += '          return SynchronousFuture<S>(S.current);' + '\n';
  }

  output += end;

  await File(outputPath).writeAsString(output);
}

String localizedStrings({Map<String, dynamic> config, bool hasOverride}) {
  var output = '';

  final pattern = RegExp('[\$]{(.*?)}');

  config.forEach((key, dynamic value) {
    final matches = pattern.allMatches(value as String);

    if (hasOverride) {
      output += '  @override' + '\n';
    }

    if (matches.isEmpty) {
      output += '  String get ${key} => \"\"\"${value}\"\"\";' + '\n';
    } else {
      final set = matches.map((elem) => elem.group(1)).toSet().toList();

      output += '  String ${key}(';

      for (var elem in set) {
        if (elem == set.last) {
          output += 'String ${elem}';
        } else {
          output += 'String ${elem}, ';
        }
      }
      output += ') => \"\"\"${value}\"\"\";' + '\n';
    }
  });

  return output;
}

