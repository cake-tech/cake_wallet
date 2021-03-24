import 'dart:convert';
import 'dart:io';
import 'utils/secret_key.dart';
import 'utils/utils.dart';

const configPath = 'tool/.secrets-config.json';

Future<void> main(List<String> args) async => generateSecretsConfig(args);

Future<void> generateSecretsConfig(List<String> args) async {
  final extraInfo =
      args.fold(<String, dynamic>{}, (Map<String, dynamic> acc, String arg) {
    final parts = arg.split('=');
    final key = normalizeKeyName(parts[0]);
    acc[key] = acc[key] = parts.length > 1 ? parts[1] : 1;
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

  if (configFile.existsSync()) {
    if (extraInfo['--force'] == 1) {
      await configFile.delete();
    } else {
      return;
    }
  }

  SecretKey.base.forEach((sec) {
    if (secrets[sec.name] != null) {
      return;
    }

    secrets[sec.name] = sec.generate();
  });

  final secretsJson = JsonEncoder.withIndent(' ').convert(secrets);
  await configFile.writeAsString(secretsJson);
}
