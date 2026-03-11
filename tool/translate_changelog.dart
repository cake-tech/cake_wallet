import 'dart:convert';
import 'dart:io';

import 'print_verbose_dummy.dart';
import 'utils/translation/translation_constants.dart';
import 'utils/translation/translation_utils.dart';

const changelogsFilePath = "./assets/new-ui/changelog/text";

void main() async {
  final List<dynamic> defaultLangChangelog = jsonDecode(
          await File("$changelogsFilePath/changelog_$defaultLang.json").readAsString())
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
        newTitle = await getTranslation((itemMap["title"]! as String), lang);
      } else {
        newTitle = "";
      }

      if (itemMap.containsKey("description") &&
          itemMap["description"] is String &&
          (itemMap["description"]! as String).isNotEmpty) {
        newDescription = await getTranslation((itemMap["description"]! as String), lang);
      } else {
        newDescription = "";
      }

      out.add({
        "icon": itemMap["icon"]! as String,
        "title": newTitle,
        "description": newDescription,
      });

      currentItem++;
      printV(
          "\r$currentLang/${langs.length} langs done, $currentItem/${defaultLangChangelog.length} items done");
    }
    currentLang++;
    await File("$changelogsFilePath/changelog_$lang.json")
        .writeAsString(jsonEncode(out));
  }
}
