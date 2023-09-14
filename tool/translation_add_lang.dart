import 'dart:io';

import 'utils/translation/arb_file_utils.dart';
import 'utils/translation/translation_constants.dart';
import 'utils/translation/translation_utils.dart';

void main(List<String> args) async {
  if (args.length != 1) {
    throw Exception(
        'Insufficient arguments!\n\nTry to run `./translation_add_lang.dart langCode`');
  }

  final targetLang = args.first;

  final fileName = getArbFileName(defaultLang);
  final file = File(fileName);
  final arbObj = readArbFile(file);

  final targetFileName = getArbFileName(targetLang);
  final targetKeys = arbObj.keys;

  final targetFile = File(targetFileName);
  targetFile.createSync(exclusive: true);
  targetFile.writeAsStringSync("{}");

  final translations = Map<String, String>();
  for (var targetKey in targetKeys) {
    final srcString = arbObj[targetKey] as String;
    final translation = await getTranslation(srcString, targetLang);

    translations[targetKey] = translation;
  }

  appendStringsToArbFile(targetFileName, translations);
  print("Success! Please add your Language Code to lib/entities/language_service.dart");
}
