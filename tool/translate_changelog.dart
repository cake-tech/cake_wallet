import 'dart:convert';
import 'dart:io';

import 'print_verbose_dummy.dart';
import 'utils/translation/translation_constants.dart';
import 'utils/translation/translation_utils.dart';

const changelogsFilePath = "./assets/new-ui/changelog/text";

/// Names Google Translate must leave alone. Without this it turned "Ledger" into an accounting
/// ledger in 11 languages, translated "BTC Map", and made "spend sats" "spend sessions" in German.
/// Add new brand and product names here when a changelog mentions them.
const doNotTranslate = ["BitBox02 Nova", "BTC Map", "MoonPay", "Arbitrum", "Ledger", "sats"];

final _doNotTranslatePattern =
    RegExp(doNotTranslate.map((name) => "\\b${RegExp.escape(name)}\\b").join("|"));
final _placeholderPattern = RegExp(r"[{｛]\s*([^{}｛｝]*?)\s*[}｝]");

/// Translates [text] keeping every [doNotTranslate] name in English, trying in order:
/// 1. the plain sentence, which reads best, when Google leaves the names alone;
/// 2. each name as a placeholder that still shows the word ("{MoonPay} on {Arbitrum}"), so Google
///    can put it in the right place, though it sometimes translates the word anyway;
/// 3. numbered placeholders, which Google never touches but can't place: "{0} on {1}" came out
///    as "Arbitrum on MoonPay" in Hindi, so only when the text has a single name.
/// If none keeps the names, the English text is used and a warning is printed.
Future<String> translateKeepingNames(String text, String lang) async {
  final names = _doNotTranslatePattern.allMatches(text).map((match) => match[0]!).toSet();
  if (names.isEmpty || text.contains("{")) {
    return getTranslation(text, lang);
  }

  final plain = await getTranslation(text, lang);
  if (_translated(text, plain) && _keepsNames(text, plain)) {
    return plain;
  }

  try {
    final named = _restorePlaceholders(
      await _googleTranslate(
        text.replaceAllMapped(_doNotTranslatePattern, (match) => "{${match[0]}}"),
        lang,
      ),
      _nameFor,
    );
    if (_translated(text, named) && _keepsNames(text, named)) {
      return named;
    }

    if (names.length == 1) {
      var next = 0;
      final numbered = _restorePlaceholders(
        await _googleTranslate(
          text.replaceAllMapped(_doNotTranslatePattern, (_) => "{${next++}}"),
          lang,
        ),
        (placeholder) => int.tryParse(placeholder) == null ? null : names.single,
      );
      if (_keepsNames(text, numbered)) {
        return numbered;
      }
    }
  } catch (e) {
    print("$lang, $text, $e");
    return text;
  }

  print("$lang: couldn't keep ${names.join(", ")} in English, so this stays English: $text");
  return text;
}

Future<String> _googleTranslate(String text, String lang) async =>
    (await translator.translate(text, from: defaultLang, to: lang)).text;

/// Replaces each `{…}` (or full-width `｛…｝`) placeholder with [restore]'s result for its
/// content, leaving it in place when [restore] returns null.
String _restorePlaceholders(String translation, String? Function(String placeholder) restore) =>
    translation.replaceAllMapped(_placeholderPattern, (match) => restore(match[1]!) ?? match[0]!);

String? _nameFor(String placeholder) {
  for (final name in doNotTranslate) {
    if (name.toLowerCase() == placeholder.toLowerCase()) {
      return name;
    }
  }
  return null;
}

/// Whether Google translated [source]; it sometimes returns a short title like "Zcash on Ledger"
/// unchanged. A text made only of names, like "BTC Map", is meant to stay as it is.
bool _translated(String source, String translation) =>
    translation != source || source.replaceAll(_doNotTranslatePattern, "").trim().isEmpty;

/// Whether [translation] has no placeholders left and every name as often as [source] does.
bool _keepsNames(String source, String translation) =>
    !_placeholderPattern.hasMatch(translation) &&
    doNotTranslate.every(
      (name) => name.allMatches(source).length == name.allMatches(translation).length,
    );

void main() async {
  final List<dynamic> defaultLangChangelog =
      jsonDecode(await File("$changelogsFilePath/changelog_$defaultLang.json").readAsString())
          as List<dynamic>;

  int currentLang = 0;
  for (final lang in langs) {
    int currentItem = 0;
    if (lang == defaultLang) continue;
    List<Map<String, String>> out = [];
    for (final item in defaultLangChangelog) {
      final itemMap = item as Map<String, dynamic>;

      late final String newTitle;
      late final String newDescription;

      if (itemMap.containsKey("title") &&
          itemMap["title"] is String &&
          (itemMap["title"]! as String).isNotEmpty) {
        newTitle = await translateKeepingNames((itemMap["title"]! as String), lang);
      } else {
        newTitle = "";
      }

      if (itemMap.containsKey("description") &&
          itemMap["description"] is String &&
          (itemMap["description"]! as String).isNotEmpty) {
        newDescription = await translateKeepingNames((itemMap["description"]! as String), lang);
      } else {
        newDescription = "";
      }

      out.add({
        if (itemMap["icon"] != null) "icon": itemMap["icon"] as String,
        if (itemMap["title"] != null) "title": newTitle,
        if (itemMap["description"] != null) "description": newDescription,
      });

      currentItem++;
      print(
          "\r$currentLang/${langs.length} langs done, $currentItem/${defaultLangChangelog.length} items done");
    }
    currentLang++;
    await File("$changelogsFilePath/changelog_$lang.json").writeAsString(jsonEncode(out));
  }
}
