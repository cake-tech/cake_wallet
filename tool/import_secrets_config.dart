import 'dart:convert';
import 'dart:io';
import 'utils/utils.dart';

const configPath = 'tool/.secrets-config.json';
const outputPath = 'lib/.secrets.g.dart';

const ethereumConfigPath = 'tool/.ethereum-secrets-config.json';
const ethereumOutputPath = 'cw_ethereum/lib/.secrets.g.dart';

Future<void> main(List<String> args) async => importSecretsConfig();

Future<void> importSecretsConfig() async {
  final outputFile = File(outputPath);
  final input = json.decode(File(configPath).readAsStringSync()) as Map<String, dynamic>;
  final output = input.keys.fold('', (String acc, String val) => acc + generateConst(val, input));

  final ethereumOutputFile = File(ethereumOutputPath);
  final ethereumInput =
      json.decode(File(ethereumConfigPath).readAsStringSync()) as Map<String, dynamic>;
  final ethereumOutput = ethereumInput.keys
      .fold('', (String acc, String val) => acc + generateConst(val, ethereumInput));

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);

  if (ethereumOutputFile.existsSync()) {
    await ethereumOutputFile.delete();
  }

  await ethereumOutputFile.writeAsString(ethereumOutput);
}
