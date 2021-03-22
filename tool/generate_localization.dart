import 'dart:io';
import 'dart:convert';
import 'localization/locale_list.dart';
import 'localization/localization_constants.dart';

const inputPath = 'res/values/';
const outputPath = 'lib/generated/i18n.dart';

Future<void> main() async {
  var output = '';

  output += part1;
  output += textDirectionDeclaration;

  for (var locale in locales) {
    final inputContent = File(inputPath + 'strings_$locale.arb').readAsStringSync();
    final config = json.decode(inputContent) as Map<String, dynamic>;

    if (locale == locales.first) {
      output += localizedStrings(config: config, hasOverride: false);
      output += '}' + '\n\n';
    }

    output += 'class \$$locale extends S {' + '\n';
    output += '  const \$$locale();' + '\n';

    if (locale != locales.first) {
      output += textDirectionDeclaration;
      output += localizedStrings(config: config, hasOverride: true);
    }

    output += '}' + '\n\n';
  }

  output += classDeclaration;

  for (var locale in locales) {
    output += '      Locale("$locale", ""),' + '\n';
  }

  output += part2;

  for (var locale in locales) {
    output += '        case "$locale":' + '\n';
    output += '          S.current = const \$$locale();' + '\n';
    output += '          return SynchronousFuture<S>(S.current);' + '\n';
  }

  output += part3;

  await File(outputPath).writeAsString(output);
}

String localizedStrings({Map<String, dynamic> config, bool hasOverride}) {
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

