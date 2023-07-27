import 'dart:io';
import 'dart:convert';
import 'localization/localization_constants.dart';
import 'utils/utils.dart';

const inputPath = 'res/values/';
const outputPath = 'lib/generated/';
const localizationFileName = 'i18n.dart';
const localeListFileName = 'locales.dart';
const srcDir = 'srcDir';
const defaultLocale = 'en';

Future<void> main(List<String> args) async {
  final extraInfo = args.isNotEmpty ?
  args.fold(<String, dynamic>{}, (Map<String, dynamic> acc, String arg) {
    final parts = arg.split('=');
    var key = normalizeKeyName(parts[0]);
    if (key.contains('--')) {
      key = key.substring(2);
    }
    acc[key] = parts.length > 1
        ? parts[1].isNotEmpty
          ? parts[1]
          : inputPath
        : inputPath;
    return acc;
  })
  : <String, dynamic> {srcDir : inputPath};

  final outputDir = Directory(outputPath);

  if (!outputDir.existsSync()) {
    await outputDir.create();
  }

  extraInfo.forEach((key, dynamic value) async {
    if (key != srcDir) {
      print('Wrong key: $key');
      return;
    }

    final dirPath = value as String;
    final dir = Directory(dirPath);

    if (!await dir.exists()) {
      print('Wrong directory path: $dirPath');
      return;
    }

    final localePath = <String, dynamic>{};
    await dir.list(recursive: false).forEach((element) {
      try {
        final shortLocale = element.path.split('_',)[1].split('.')[0];
        localePath[shortLocale] = element.path;
      } catch (e) {
        print('Wrong file: ${element.path}');
      }
    });

    if (!localePath.keys.contains(defaultLocale)) {
      print("Locale list doesn't contain $defaultLocale");
      return;
    }

    try {
      var output = '';
      var locales = 'const locales = [';

      output += part1;
      output += textDirectionDeclaration;

      var inputContent =
        File(localePath[defaultLocale].toString()).readAsStringSync();
      var config = json.decode(inputContent) as Map<String, dynamic>;

      output += localizedStrings(config: config, hasOverride: false);
      output += '}' + '\n\n';

      localePath.forEach((key, dynamic value) {
        inputContent = File(localePath[key].toString()).readAsStringSync();
        config = json.decode(inputContent) as Map<String, dynamic>;

        locales += "'$key', ";

        output += 'class \$$key extends S {' + '\n';
        output += '  const \$$key();' + '\n';

        if (key != defaultLocale) {
          output += textDirectionDeclaration;
          output += localizedStrings(config: config, hasOverride: true);
        }

        output += '}' + '\n\n';
      });

      output += classDeclaration;

      localePath.keys.forEach((key) {
        output += '      Locale("$key", ""),' + '\n';
      });

      output += part2;

      localePath.keys.forEach((key) {
        output += '        case "$key":' + '\n';
        output += '          S.current = const \$$key();' + '\n';
        output += '          return SynchronousFuture<S>(S.current);' + '\n';
      });

      output += part3;

      await File(outputPath + localizationFileName).writeAsString(output);

      locales += '];';

      await File(outputPath + localeListFileName).writeAsString(locales);
    } catch (e) {
      print(e.toString());
    }
  });
}

String localizedStrings({required Map<String, dynamic> config, required bool hasOverride}) {
  var output = '';

  final pattern = RegExp('[\$]{(.*?)}');

  config.forEach((key, dynamic value) {
    final matches = pattern.allMatches(value as String);

    if (hasOverride) {
      output += '  @override' + '\n';
    }

    if (matches.isEmpty) {
      output += '  String get ${key} => \"\"\"${value}\"\"\";' + '\n';
    } else {
      final set = matches.map((elem) => elem.group(1)).toSet().toList();

      output += '  String ${key}(';

      for (var elem in set) {
        if (elem == set.last) {
          output += 'String ${elem}';
        } else {
          output += 'String ${elem}, ';
        }
      }
      output += ') => \"\"\"${value}\"\"\";' + '\n';
    }
  });

  return output;
}

