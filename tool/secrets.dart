import 'dart:convert';
import 'dart:io';

const secretsProdPath = 'tool/.secrets-prod.json';
const secretsTestPath = 'tool/.secrets-test.json';
const outputPath = 'lib/.secrets.g.dart';

Future<void> main() async {
  final inputPath = FileSystemEntity.typeSync(secretsProdPath) !=
          FileSystemEntityType.notFound
      ? secretsProdPath
      : secretsTestPath;

  final inoutContent = File(inputPath).readAsStringSync();
  final config = json.decode(inoutContent) as Map<String, String>;
  final output =
      'const salt = \'${config["salt"]}\';\nconst key = \'${config["key"]}\';\nconst walletSalt = \'${config["walletSalt"]}\';\nconst shortKey = \'${config["shortKey"]}\';\nconst change_now_api_key = \'${config["change_now_api_key"]}\';';

  await File(outputPath).writeAsString(output);
}
