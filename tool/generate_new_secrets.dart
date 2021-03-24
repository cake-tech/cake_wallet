import 'generate_secrets_config.dart';
import 'import_secrets_config.dart';

const configPath = 'tool/.secrets-config.json';
const outputPath = 'lib/.secrets.g.dart';

Future<void> main(List<String> args) async => generateSecrets(args);

Future<void> generateSecrets(List<String> args) async {
  await generateSecretsConfig(args);
  await importSecretsConfig();
}