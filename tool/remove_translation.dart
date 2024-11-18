import 'dart:convert';
import 'dart:io';

import 'utils/translation/arb_file_utils.dart';
import 'utils/translation/translation_constants.dart';
import 'utils/translation/translation_utils.dart';

/// flutter packages pub run tool/remove_translation.dart "hello_world"

void main(List<String> args) async {
  if (args.length < 1) {
    throw Exception(
        'Insufficient arguments!\n\nTry to run `./remove_translation.dart "greetings"`');
  }

  final name = args.first;

  print('Removing key "$name" from all language files...');

  // Remove translation key from all languages:
  for (var lang in langs) {
    final fileName = getArbFileName(lang);
    await removeKeyFromArbFile(fileName, name);
  }

  print('Alphabetizing all files...');

  for (var lang in langs) {
    final fileName = getArbFileName(lang);
    alphabetizeArbFile(fileName);
  }

  print('Done!');
}

/// Removes a key from the specified ARB file.
Future<void> removeKeyFromArbFile(String fileName, String key) async {
  final file = File(fileName);

  if (!await file.exists()) {
    throw Exception('File not found: $fileName');
  }

  // Read and parse the ARB file content
  final content = await file.readAsString();
  final Map<String, dynamic> arbData = json.decode(content) as Map<String, dynamic>;

  if (!arbData.containsKey(key)) {
    print('Key "$key" does not exist in $fileName.');
    return;
  }

  // Remove the key from the ARB data
  arbData.remove(key);

  // Write the updated content back to the file
  final updatedContent = const JsonEncoder.withIndent('  ').convert(arbData);
  await file.writeAsString(updatedContent);

  print('Key "$key" removed from $fileName.');
}