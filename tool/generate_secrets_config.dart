import 'dart:convert';
import 'dart:io';
import 'utils/secret_key.dart';
import 'utils/utils.dart';

const baseConfigPath = 'tool/.secrets-config.json';
const coreConfigPath = 'tool/.core-secrets-config.json';
const evmChainsConfigPath = 'tool/.evm-secrets-config.json';
const solanaConfigPath = 'tool/.solana-secrets-config.json';
const nanoConfigPath = 'tool/.nano-secrets-config.json';

Future<void> main(List<String> args) async => generateSecretsConfig(args);

Future<void> generateSecretsConfig(List<String> args) async {
  final extraInfo = args.fold(<String, dynamic>{}, (Map<String, dynamic> acc, String arg) {
    final parts = arg.split('=');
    final key = normalizeKeyName(parts[0]);
    acc[key] = acc[key] = parts.length > 1 ? parts[1] : 1;
    return acc;
  });

  final baseConfigFile = File(baseConfigPath);
  final coreConfigFile = File(coreConfigPath);
  final evmChainsConfigFile = File(evmChainsConfigPath);
  final solanaConfigFile = File(solanaConfigPath);
  final nanoConfigFile = File(nanoConfigPath);

  final secrets = <String, dynamic>{};

  secrets.addAll(extraInfo);
  secrets.removeWhere((key, dynamic value) {
    if (key.contains('--')) {
      return true;
    }

    return false;
  });

  if (baseConfigFile.existsSync()) {
    if (extraInfo['--force'] == 1) {
      await baseConfigFile.delete();
    } else {
      return;
    }
  }

  late String secretsJson;

  // base:
  SecretKey.base.forEach((sec) {
    if (secrets[sec.name] != null) {
      return;
    }
    secrets[sec.name] = sec.generate();
  });
  secretsJson = JsonEncoder.withIndent(' ').convert(secrets);
  await baseConfigFile.writeAsString(secretsJson);
  secrets.clear();

  // core:
  SecretKey.coreSecrets.forEach((sec) {
    if (secrets[sec.name] != null) {
      return;
    }
    secrets[sec.name] = sec.generate();
  });
  secretsJson = JsonEncoder.withIndent(' ').convert(secrets);
  await coreConfigFile.writeAsString(secretsJson);
  secrets.clear();

  // evm:
  SecretKey.evmChainsSecrets.forEach((sec) {
    if (secrets[sec.name] != null) {
      return;
    }
    secrets[sec.name] = sec.generate();
  });
  secretsJson = JsonEncoder.withIndent(' ').convert(secrets);
  await evmChainsConfigFile.writeAsString(secretsJson);
  secrets.clear();

  // solana:
  SecretKey.solanaSecrets.forEach((sec) {
    if (secrets[sec.name] != null) {
      return;
    }
    secrets[sec.name] = sec.generate();
  });
  secretsJson = JsonEncoder.withIndent(' ').convert(secrets);
  await solanaConfigFile.writeAsString(secretsJson);
  secrets.clear();

  // nano:
  SecretKey.nanoSecrets.forEach((sec) {
    if (secrets[sec.name] != null) {
      return;
    }
    secrets[sec.name] = sec.generate();
  });
  secretsJson = JsonEncoder.withIndent(' ').convert(secrets);
  await nanoConfigFile.writeAsString(secretsJson);
  secrets.clear();
}
