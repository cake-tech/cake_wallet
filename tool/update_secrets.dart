import 'dart:convert';
import 'dart:io';
import 'generate_new_secrets.dart';
import 'import_secrets_config.dart';
import 'utils/utils.dart';

const configPath = 'tool/.secrets-config.json';

Future<void> main(List<String> args) async {
  await updateSecretsConfig(args);
  await importSecretsConfig();
}

Future<void> updateSecretsConfig(List<String> args) async {
  final extraInfo =
      args.fold(<String, dynamic>{}, (Map<String, dynamic> acc, String arg) {
    final parts = arg.split('=');
    final key = normalizeKeyName(parts[0]);
    acc[key] = parts.length > 1 ? parts[1] : 1;
    return acc;
  });

  final configFile = File(configPath);
  final secrets = <String, dynamic>{};

  secrets.addAll(extraInfo);
  secrets.removeWhere((key, dynamic value) {
    if (key.contains('--')) {
      return true;
    }

    return false;
  });

  final fileConfig =
      json.decode(configFile.readAsStringSync()) as Map<String, dynamic>;
  fileConfig.forEach((key, dynamic value) {
    if (secrets[key] == null) {
      secrets[key] = value;
    }
  });

  final secretsJson = JsonEncoder.withIndent(' ').convert(secrets);
  await configFile.writeAsString(secretsJson);
  await generateSecrets(args);
}
