import 'package:translator/translator.dart';

import 'arb_file_utils.dart';
import 'translation_constants.dart';

final translator = GoogleTranslator();

Future<void> appendTranslation(String lang, String key, String text) async {
  final fileName = getArbFileName(lang);
  final translation = await getTranslation(text, lang);

  appendStringToArbFile(fileName, key, translation);
}

Future<void> appendTranslations(String lang, Map<String, String> defaults) async {
  final fileName = getArbFileName(lang);
  final translations = <String, String>{};

  for (var key in defaults.keys) {
    final value = defaults[key]!;
    final translation = await getTranslation(value, lang);

    translations[key] = translation;
  }

  appendStringsToArbFile(fileName, translations);
}

Future<String> getTranslation(String text, String lang) async {
  if (lang == defaultLang) return text;

  final regExp = RegExp(r'{(.*?)}');
  final placeholder = regExp.allMatches(text).map((e) => text.substring(e.start, e.end)).toList();

  var translation = (await translator.translate(text, from: defaultLang, to: lang)).text;
  final translatedPlaceholders = regExp.allMatches(translation).toList();

  translatedPlaceholders.asMap().forEach((index, value) {
    translation = translation.replaceRange(value.start, value.end, placeholder[index]);
  });

  return translation;
}

