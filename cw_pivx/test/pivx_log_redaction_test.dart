import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Paths below are repo-root relative; `flutter test` runs with the package
  // directory as CWD, so hop up one level in that case.
  final repoRoot = Directory.current.path.endsWith('cw_pivx') ? '..' : '.';

  group('PIVX sensitive log redaction', () {
    final filesToScan = <String>[
      'cw_bitcoin/lib/electrum.dart',
      'cw_pivx/lib/src/pending_pivx_shielded_transaction.dart',
      'cw_pivx/lib/src/pivx_wallet.dart',
      'cw_pivx/lib/src/pivx_wallet_service.dart',
      'cw_pivx/lib/src/sapling/pivx_sapling_electrumx.dart',
      'cw_pivx/lib/src/sapling/sapling_factories.dart',
      'cw_pivx/lib/src/sapling/sapling_note_storage.dart',
      'lib/view_model/send/send_view_model.dart',
    ];

    final statementStart = RegExp(r'\b(?:print|printV)\s*\(');
    final interpolation = RegExp(r'\$[A-Za-z_{]|toString\(\)');
    final sensitiveTerms = RegExp(
      r'\b(seed|mnemonic|rseed|nullifier|cmu|witness|txid|anchor|'
      r'address|balance|note|value|position|ciphertext|commitment)\b',
      caseSensitive: false,
    );

    // Statements reviewed as sanitized: they interpolate only counts, enum
    // reason/source codes, retry numbers, or booleans, never key, note,
    // commitment, witness-node, or address material. Any edit to these lines
    // changes the statement text and must be re-reviewed here.
    final reviewedSanitizedStatements = <String>{
      r"printV( '[PIVX Sapling] Witness path has non-canonical node at index $invalidIndex; canonical_original=$originalCanonical/${path.length}, canonical_reversed=$reversedCanonical/${reversedPath.length}');",
      r"printV('[PIVX Sapling] Witness accepted via $source');",
      r"printV( '[PIVX Sapling] Witness attempt $label $retry/$retries failed: $reason');",
      r"printV('[PIVX Sapling] Witness source summary: $witnessSourceSummary');",
      r"printV( '[PIVX Sapling] Witness path shape: count=${witness.path.length}, first_chars=$firstPathLength, total_chars=${witnessHex.length}, hex=$isHexPath');",
    };

    String collectStatement(List<String> lines, int startIndex) {
      final buffer = StringBuffer(lines[startIndex].trim());
      for (var i = startIndex + 1;
          i < lines.length && !buffer.toString().contains(');');
          i++) {
        buffer.write(' ${lines[i].trim()}');
      }
      return buffer.toString();
    }

    test('does not interpolate sensitive PIVX/Sapling metadata into logs', () {
      final violations = <String>[];

      for (final path in filesToScan) {
        final file = File('$repoRoot/$path');
        expect(file.existsSync(), isTrue, reason: 'Missing scanned file $path');

        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (!statementStart.hasMatch(lines[i])) continue;

          final statement = collectStatement(lines, i);
          if (interpolation.hasMatch(statement) &&
              sensitiveTerms.hasMatch(statement) &&
              !reviewedSanitizedStatements.contains(statement)) {
            violations.add('$path:${i + 1}: $statement');
          }
        }
      }

      expect(violations, isEmpty);
    });

    test('invalid PIVX mnemonic errors stay generic', () {
      final service = File('$repoRoot/cw_pivx/lib/src/pivx_wallet_service.dart')
          .readAsStringSync();

      expect(service, contains("throw Exception('Invalid PIVX mnemonic')"));
      expect(service, isNot(contains('Invalid mnemonic:')));
      expect(service, isNot(contains(r'${credentials.mnemonic}')));
    });
  });
}
