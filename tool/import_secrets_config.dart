import 'dart:convert';
import 'dart:io';
import 'utils/utils.dart';

const configPath = 'tool/.secrets-config.json';
const outputPath = 'lib/.secrets.g.dart';

Future<void> main(List<String> args) async => importSecretsConfig();

Future<void> importSecretsConfig() async {
  final outputFile = File(outputPath);
  final input = json.decode(File(configPath).readAsStringSync())
          as Map<String, dynamic> ??
      <String, dynamic>{};
  final output = input.keys
      .fold('', (String acc, String val) => acc + generateConst(val, input));

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);
}
