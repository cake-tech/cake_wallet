import 'dart:io';

const pubspecBasePath = 'pubspec_base.yaml';
const pubspecDescriptionPath = 'pubspec_description.yaml';
const outputPubspecPath = 'pubspec.yaml';

Future<void> main(List<String> args) async {
  final pubspecBase = File(pubspecBasePath);
  final pubspecDescription = File(pubspecDescriptionPath);

  if (!pubspecBase.existsSync() || !pubspecDescription.existsSync()) {
    throw("$pubspecBasePath or $pubspecDescriptionPath doesn't exists");
  }

  final pubspecBaseContent = await pubspecBase.readAsString();
  final pubspecDescriptionContent = await pubspecDescription.readAsString();
  final pubSpecContent =  pubspecDescriptionContent + '\n\n' + pubspecBaseContent;
  final outputPubspec = File(outputPubspecPath);

  if (outputPubspec.existsSync()) {
    await outputPubspec.delete();
  }

  await outputPubspec.writeAsString(pubSpecContent);
}
