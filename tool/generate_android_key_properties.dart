import 'dart:io';

const outputPath = 'android/key.properties';

Future<void> main(List<String> args) async {
  final output = args.fold('', (String acc, String arg) => acc + arg + '\n');
  final outputFile = File(outputPath);

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);
}
