import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http; // very_insecure_http_do_not_use
import 'package:args/args.dart';
import './print_verbose_dummy.dart';

class TranslationChecker {
  final String ollamaBaseUrl;
  final String model;

  TranslationChecker({
    required this.ollamaBaseUrl,
    required this.model,
  });

  /// Check and correct translations line by line
  Future<void> checkTranslations({
    required String sourceArbPath,
    required String destinationArbPath,
    String? specificKey,
  }) async {
    final sourceContent = await _readArbFile(sourceArbPath);
    final destinationContent = await _readArbFile(destinationArbPath);

    final sourceMap = json.decode(sourceContent) as Map<String, dynamic>;
    final destinationMap = json.decode(destinationContent) as Map<String, dynamic>;

    printV('Found ${sourceMap.length} keys in source, ${destinationMap.length} in destination');

    final keysToProcess = specificKey != null
        ? (sourceMap.containsKey(specificKey) ? [specificKey] : <String>[])
        : sourceMap.keys.toList();

    if (specificKey != null && keysToProcess.isEmpty) {
      printV('Error: Key "$specificKey" not found in source file');
      return;
    }

    printV('Processing ${keysToProcess.length} translations...');

    int processed = 0;
    int corrected = 0;

    for (final key in keysToProcess) {
      final sourceValue = sourceMap[key];
      final destinationValue = destinationMap[key];

      if (sourceValue is String && destinationValue is String) {
        final correctedTranslation = await _checkSingleTranslation(
          key: key,
          sourceText: sourceValue,
          currentTranslation: destinationValue,
          sourceFile: sourceArbPath,
          destinationFile: destinationArbPath,
        );

        if (correctedTranslation != destinationValue) {
          destinationMap[key] = correctedTranslation;
          corrected++;
          printV('Processed: "$key" -> CORRECTED');
          printV(' - eng     : "$sourceValue"');
          printV(' - dst orig: "$destinationValue"');
          printV(' - dst new : "$correctedTranslation"');
          await _writeArbFile(destinationArbPath, destinationMap);
        } else {
          printV('Processed: "$key" -> VERIFIED');
        }
      } else {
        printV('Processed: "$key" -> SKIPPED (non-string)');
      }

      processed++;
    }

    await _writeArbFile(destinationArbPath, destinationMap);

    printV('');
    printV('Summary:');
    printV('Processed: $processed keys');
    printV('Corrected: $corrected keys');
    printV('Updated: $destinationArbPath');
  }

  Future<String> _checkSingleTranslation({
    required String key,
    required String sourceText,
    required String currentTranslation,
    required String sourceFile,
    required String destinationFile,
  }) async {
    final prompt = _createTranslationCheckPrompt(
      sourceFile: sourceFile,
      destinationFile: destinationFile,
      key: key,
      sourceText: sourceText,
      currentTranslation: currentTranslation,
    );

    try {
      final response = await _callLLM(prompt);

      // Extract JSON from the response
      final correctedTranslation = _extractJsonFromResponse(response);

      if (correctedTranslation != null && correctedTranslation != currentTranslation) {
        return correctedTranslation;
      }

      return currentTranslation;
    } catch (e) {
      printV('Error checking translation for key "$key": $e');
      return currentTranslation;
    }
  }

  String _createTranslationCheckPrompt({
    required String key,
    required String sourceText,
    required String currentTranslation,
    required String sourceFile,
    required String destinationFile,
  }) {
    return '''
You are a professional translator checking the accuracy of a translation for a cryptocurrency wallet called Cake Wallet.

source file is: ${sourceFile}, destination file is: ${destinationFile}.

Rules you must obey:
- respect company branding and style (Cake Wallet, Cake Pay, Bird Pay and other brandings stay the same no matter the language)
- be accurate and remember that Cake Wallet lets you hold cryptocurrency, so use words that are associated with cryptocurrency and wallets more preferably than words that are associated with banks.
- elements with \${value} should remain non-translated as they are used by codegen to dynamically insert the value.
- make sure that the translation that you output improves the original translation, and doesn't change the meaning of it.
- if original translation contains abbreviations, make sure to translate them as well, and do not expand them.
- Make sure to use the same capitalization as the original translation, if it is capitalized, capitalize the translation as well to keep the UI consistent.
- maintain new lines with `\n` preserved in the translation.


KEY: "$key"
SOURCE TEXT (English): "${sourceText.replaceAll("\n", "\\n")}"
CURRENT TRANSLATION: "${currentTranslation.replaceAll("\n", "\\n")}"

Please check if the current translation is accurate and natural. If it needs correction, provide the corrected version.

Before you return the JSON object, think about the translation and make sure that it is accurate and natural.

IMPORTANT: Respond with a JSON object in the exact format, you must think about the translation and at the very end you must return the JSON object with the most correct (in destination language) translation, make sure to use proper grammar, spelling and punctuation:
{
  "corrected_translation": "your corrected translation here"
}
''';
  }

  Future<String> _callLLM(String prompt) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'model': model,
      'prompt': prompt,
      'stream': false,
      'options': {
        'temperature': 0.3,
        'num_predict': 1000,
      }
    });

    final response = await http.post(
      Uri.parse('$ollamaBaseUrl/api/generate'),
      headers: headers,
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Ollama API error: ${response.statusCode} - ${response.body}');
    }

    final data = json.decode(response.body);
    return data['response'] as String;
  }

  String? _extractJsonFromResponse(String response) {
    try {
      // Find JSON object in the response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');

      if (jsonStart == -1 || jsonEnd == -1 || jsonStart >= jsonEnd) {
        printV('No valid JSON found in LLM response');
        return null;
      }

      final jsonText = response.substring(jsonStart, jsonEnd + 1);
      final parsed = json.decode(jsonText) as Map<String, dynamic>;

      return parsed['corrected_translation'] as String?;
    } catch (e) {
      printV('Error extracting JSON from LLM response: $e');
      return null;
    }
  }

  Future<String> _readArbFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('ARB file not found: $path');
    }
    return await file.readAsString();
  }

  Future<void> _writeArbFile(String path, Map<String, dynamic> content) async {
    final file = File(path);
    final prettyJson = const JsonEncoder.withIndent('  ').convert(content);
    await file.writeAsString(prettyJson, flush: true);
  }
}

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('source', abbr: 's', help: 'Path to source ARB file (e.g., ./res/values/strings_en.arb)', mandatory: true)
    ..addOption('destination', abbr: 'd', help: 'Path to destination ARB file (e.g., ./res/values/strings_pl.arb)', mandatory: true)
    ..addOption('key', abbr: 'k', help: 'Translate only this specific key (optional)')
    ..addOption('ollama-url', help: 'Ollama server URL (default: http://localhost:11434)', defaultsTo: 'http://localhost:11434')
    ..addOption('model', help: 'Ollama model name (default: gpt-oss:120b)', defaultsTo: 'gpt-oss:120b')
    ..addFlag('help', abbr: 'h', help: 'Show this help message', negatable: false);

  try {
    final results = parser.parse(args);

    if (results['help'] as bool) {
      printV(parser.usage);
      return;
    }

    final sourcePath = results['source'] as String;
    final destinationPath = results['destination'] as String;
    final specificKey = results['key'] as String?;
    final ollamaUrl = results['ollama-url'] as String;
    final model = results['model'] as String;

    if (!File(sourcePath).existsSync()) {
      printV('Error: Source ARB file not found: $sourcePath');
      exit(1);
    }

    if (!File(destinationPath).existsSync()) {
      printV('Error: Destination ARB file not found: $destinationPath');
      exit(1);
    }

    printV('Translation Checker');
    printV('Source: $sourcePath');
    printV('Destination: $destinationPath');
    printV('Ollama URL: $ollamaUrl');
    printV('Model: $model');
    if (specificKey != null) {
      printV('Key: $specificKey');
    }
    printV('');

    final checker = TranslationChecker(
      ollamaBaseUrl: ollamaUrl,
      model: model,
    );

    await checker.checkTranslations(
      sourceArbPath: sourcePath,
      destinationArbPath: destinationPath,
      specificKey: specificKey,
    );

  } catch (e) {
    printV('Error: $e');
    printV('Run with --help for more information.');
    exit(1);
  }
}
