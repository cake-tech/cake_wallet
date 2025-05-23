import 'print_verbose_dummy.dart';
import 'utils/translation/arb_file_utils.dart';
import 'utils/translation/translation_constants.dart';
import 'utils/translation/translation_utils.dart';

/// dart run tool/append_translation.dart "hello_world" "Hello World!"

void main(List<String> args) async {
  if (args.length < 2) {
    throw Exception(
        'Insufficient arguments!\n\nTry to run `./append_translation.dart "greetings" "Hello World!"`');
  }

  final name = args.first;
  final text = args[1];
  final force = args.last == "--force";

  printV('Appending "$name": "$text"');

  // add translation to all languages:
  for (var lang in langs) {
    final fileName = getArbFileName(lang);
    final translation = await getTranslation(text, lang);

    appendStringToArbFile(fileName, name, translation, force: force);
  }

  printV('Alphabetizing all files...');
  
  for (var lang in langs) {
    final fileName = getArbFileName(lang);
    alphabetizeArbFile(fileName);
  }

  printV('Done!');
}