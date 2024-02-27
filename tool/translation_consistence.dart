import 'dart:io';

import 'utils/translation/arb_file_utils.dart';
import 'utils/translation/translation_constants.dart';
import 'utils/translation/translation_utils.dart';

void main(List<String> args) async {
  print('Checking Consistency of all arb-files. Default: $defaultLang');

  final doFix = args.contains("--fix");

  if (doFix)
    print('Auto fixing enabled!\n');
  else
    print('Auto fixing disabled!\nRun with arg "--fix" to enable autofix\n');

  final fileName = getArbFileName(defaultLang);
  final file = File(fileName);
  final arbObj = readArbFile(file);

  for (var lang in langs) {
    final fileName = getArbFileName(lang);
    final missingKeys = getMissingKeysInArbFile(fileName, arbObj.keys);
    if (missingKeys.isNotEmpty) {
      final missingDefaults = <String, String>{};

      missingKeys.forEach((key) {
        print('Missing in "$lang": "$key"');
        if (doFix)
          missingDefaults[key] = arbObj[key] as String;
      });

      if (missingDefaults.isNotEmpty) {
        await appendTranslations(lang, missingDefaults);
        alphabetizeArbFile(fileName);
      }
    }
  }
}
