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

  // Basic duplicate detection for entries like "  package_name:" within
  // pubspec_base.yaml. If a duplicate is found, fail the script so it can be
  // fixed before continuing the build.
  final dependencyPattern = RegExp(r'^\s{2}([a-zA-Z0-9_]+):');
  final seen = <String>{};
  final duplicates = <String>{};

  for (final line in pubspecBaseContent.split('\n')) {
    final match = dependencyPattern.firstMatch(line);
    if (match != null) {
      final name = match.group(1)!;
      if (!seen.add(name)) {
        duplicates.add(name);
      }
    }
  }

  if (duplicates.isNotEmpty) {
    stderr.writeln('Duplicate dependencies found: ${duplicates.join(', ')}');
    exitCode = 1;
    return;
  }

  final pubSpecContent =  pubspecDescriptionContent + '\n\n' + pubspecBaseContent;
  final outputPubspec = File(outputPubspecPath);

  if (outputPubspec.existsSync()) {
    await outputPubspec.delete();
  }

  await outputPubspec.writeAsString(pubSpecContent);
}
