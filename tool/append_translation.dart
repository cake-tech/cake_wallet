import 'utils/translation/arb_file_utils.dart';
import 'utils/translation/translation_constants.dart';
import 'utils/translation/translation_utils.dart';

void main(List<String> args) async {
  if (args.length != 2) {
    throw Exception(
        'Insufficient arguments!\n\nTry to run `./append_translation.dart greetings "Hello World!"`');
  }

  final name = args.first;
  final text = args.last;

  print('Appending "$name": "$text"');

  // add translation to all languages:
  for (var lang in langs) {
    final fileName = getArbFileName(lang);
    final translation = await getTranslation(text, lang);

    appendStringToArbFile(fileName, name, translation);
  }

  print('Alphabetizing all files...');
  
  for (var lang in langs) {
    final fileName = getArbFileName(lang);
    alphabetizeArbFile(fileName);
  }

  print('Done!');
}