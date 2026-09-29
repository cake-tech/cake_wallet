import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../../tool/generate_secrets_config.dart' as generator;
import '../../../tool/utils/secret_key.dart';

void main() {
  test('public generator retains only the Pegaroute proxy URL, never either API-key spelling', () async {
    final directory = await Directory.systemTemp.createTemp('pegaroute-public-config-fixture-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/synthetic.json');
    final field = SecretKey.base.singleWhere((key) => key.name == 'pegarouteApiBaseUrl');
    expect(SecretKey.base.where((key) => generator.removedClientSecretKeys.contains(key.name)), isEmpty);
    // Synthetic values only. Do not invoke main or inspect any local configuration.
    await generator.writeConfig(file, [field], existingSecrets: {
      'pegaRouteApiKey': 'synthetic-retired-value',
      'pegarouteApiKey': 'synthetic-retired-value',
      'pegarouteApiBaseUrl': 'https://offline.invalid',
      'unrelated': 'preserve-this-fixture-value',
    });
    final result = jsonDecode(await file.readAsString()) as Map;
    expect(result, {'pegarouteApiBaseUrl': 'https://offline.invalid',
      'unrelated': 'preserve-this-fixture-value'});
  });
}
