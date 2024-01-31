import 'dart:convert';
import 'dart:io';
import 'utils/utils.dart';

const configPath = 'tool/.secrets-config.json';
const outputPath = 'lib/.secrets.g.dart';

const evmChainsConfigPath = 'tool/.evm-secrets-config.json';
const evmChainsOutputPath = 'cw_evm/lib/.secrets.g.dart';

Future<void> main(List<String> args) async => importSecretsConfig();

Future<void> importSecretsConfig() async {
  final outputFile = File(outputPath);
  final input = json.decode(File(configPath).readAsStringSync()) as Map<String, dynamic>;
  final output = input.keys.fold('', (String acc, String val) => acc + generateConst(val, input));

  final evmChainsOutputFile = File(evmChainsOutputPath);
  final evmChainsInput =
      json.decode(File(evmChainsConfigPath).readAsStringSync()) as Map<String, dynamic>;
  final evmChainsOutput = evmChainsInput.keys
      .fold('', (String acc, String val) => acc + generateConst(val, evmChainsInput));

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);

  if (evmChainsOutputFile.existsSync()) {
    await evmChainsOutputFile.delete();
  }

  await evmChainsOutputFile.writeAsString(evmChainsOutput);
}
