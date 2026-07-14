import 'dart:convert';
import 'dart:io';
import 'utils/utils.dart';

const configPath = 'tool/.secrets-config.json';
const outputPath = 'lib/.secrets.g.dart';

const evmChainsConfigPath = 'tool/.evm-secrets-config.json';
const evmChainsOutputPath = 'cw_evm/lib/.secrets.g.dart';

const solanaConfigPath = 'tool/.solana-secrets-config.json';
const solanaOutputPath = 'cw_solana/lib/.secrets.g.dart';

const tronConfigPath = 'tool/.tron-secrets-config.json';
const tronOutputPath = 'cw_tron/lib/.secrets.g.dart';

const bitcoinConfigPath = 'tool/.bitcoin-secrets-config.json';
const bitcoinOutputPath = 'cw_bitcoin/lib/.secrets.g.dart';

const nanoConfigPath = 'tool/.nano-secrets-config.json';
const nanoOutputPath = 'cw_nano/lib/.secrets.g.dart';

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

  final solanaOutputFile = File(solanaOutputPath);
  final solanaInput =
      json.decode(File(solanaConfigPath).readAsStringSync()) as Map<String, dynamic>;
  final solanaOutput =
      solanaInput.keys.fold('', (String acc, String val) => acc + generateConst(val, solanaInput));

  final tronOutputFile = File(tronOutputPath);
  final tronInput = json.decode(File(tronConfigPath).readAsStringSync()) as Map<String, dynamic>;
  final tronOutput =
      tronInput.keys.fold('', (String acc, String val) => acc + generateConst(val, tronInput));

  final nanoOutputFile = File(nanoOutputPath);
  final nanoInput = json.decode(File(nanoConfigPath).readAsStringSync()) as Map<String, dynamic>;
  final nanoOutput =
      nanoInput.keys.fold('', (String acc, String val) => acc + generateConst(val, nanoInput));

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);

  if (evmChainsOutputFile.existsSync()) {
    await evmChainsOutputFile.delete();
  }

  await evmChainsOutputFile.writeAsString(evmChainsOutput);

  if (solanaOutputFile.existsSync()) {
    await solanaOutputFile.delete();
  }

  await solanaOutputFile.writeAsString(solanaOutput);

  if (tronOutputFile.existsSync()) {
    await tronOutputFile.delete();
  }

  await tronOutputFile.writeAsString(tronOutput);

  if (nanoOutputFile.existsSync()) {
    await nanoOutputFile.delete();
  }

  await nanoOutputFile.writeAsString(nanoOutput);
}
