// import 'dart:convert';
// import 'dart:io';
//
// import 'package:translator/translator.dart';
//
// const defaultLang = "en";
// const langs = [
//   "ar", "bg", "cs", "de", "en", "es", "fr", "ha", "hi", "hr", "id", "it",
//   "ja", "ko", "my", "nl", "pl", "pt", "ru", "th", "tr", "uk", "ur", "yo",
//   "zh-cn" // zh, but Google Translate uses zh-cn for Chinese (Simplified)
// ];
// final translator = GoogleTranslator();
//
// void main(List<String> args) async {
//   if (args.length != 2) {
//     throw Exception(
//         'Insufficient arguments!\n\nTry to run `./append_translation.dart greetings "Hello World!"`');
//   }
//
//   final name = args.first;
//   final text = args.last;
//
//   print('Appending "$name": "$text"');
//
//   for (var lang in langs) {
//     final fileName = getFileName(lang);
//     final translation = await getTranslation(text, lang);
//
//     appendArbFile(fileName, name, translation);
//   }
// }
//
// void appendArbFile(String fileName, String name, String text) {
//   final file = File(fileName);
//   final inputContent = file.readAsStringSync();
//   final arbObj = json.decode(inputContent) as Map<String, dynamic>;
//
//   if (arbObj.containsKey(name)) {
//     print("String $name already exists in $fileName!");
//     return;
//   }
//
//   arbObj.addAll({name: text});
//
//   final outputContent = json
//       .encode(arbObj)
//       .replaceAll('","', '",\n  "')
//       .replaceAll('{"', '{\n  "')
//       .replaceAll('"}', '"\n}')
//       .replaceAll('":"', '": "');
//
//   file.writeAsStringSync(outputContent);
// }
//
//
// Future<String> getTranslation(String text, String lang) async {
//   if (lang == defaultLang) return text;
//   return (await translator.translate(text, from: defaultLang, to: lang)).text;
// }
//
// String getFileName(String lang) {
//   final shortLang = lang
//       .split("-")
//       .first;
//   return "./res/values/strings_$shortLang.arb";
// }
