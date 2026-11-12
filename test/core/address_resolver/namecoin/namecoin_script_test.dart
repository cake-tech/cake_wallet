import 'dart:convert';

import 'package:cake_wallet/core/address_resolver/namecoin/namecoin_script.dart';
import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const name = 'd/testls';

  group('name index script', () {
    test('matches the verified ElectrumX Namecoin index and scripthash', () {
      expect(
        hex.encode(NamecoinScript.buildNameIndexScript(name)),
        '5308642f746573746c73006d756a',
      );
      expect(
        NamecoinScript.scriptHash(name),
        'b519574e96740a4b3627674a0708e71a73e654a95117fc828b8e177a0579ab42',
      );
    });
  });

  group('verbose transaction decoding', () {
    test('decodes NAME_UPDATE', () {
      final transaction = verboseTransaction(
        '53${_push(name)}${_push('{"btc":"bc1-main"}')}6d756a',
      );

      final result = NamecoinScript.fromVerboseTransaction(transaction, name);
      expect(result?.name, name);
      expect(result?.value, '{"btc":"bc1-main"}');
    });

    test('decodes a consensus-compatible NAME_FIRSTUPDATE', () {
      // NAME_FIRSTUPDATE "d/testls" "nonce" "hello" OP_2DROP OP_2DROP OP_RETURN
      final transaction = verboseTransaction(
        '5208642f746573746c73056e6f6e63650568656c6c6f6d6d6a',
      );

      final result = NamecoinScript.fromVerboseTransaction(transaction, name);
      expect(result?.name, name);
      expect(result?.value, 'hello');
    });

    test('finds the requested name among other transaction outputs', () {
      final transaction = {
        'vout': [
          verboseTransaction('53${_push('d/other')}${_push('wrong')}6d756a')['vout']![0],
          verboseTransaction('53${_push(name)}${_push('right')}6d756a')['vout']![0],
        ],
      };

      expect(NamecoinScript.fromVerboseTransaction(transaction, name)?.value, 'right');
      expect(NamecoinScript.fromVerboseTransaction(transaction, 'd/missing'), isNull);
    });

    test('rejects malformed scripts and transactions', () {
      final malformedScripts = [
        '',
        '00',
        '53',
        '5308642f746573746c73',
        '53${_push(name)}${_push('value')}6d6d6a',
        '52${_push(name)}${_push('nonce')}${_push('value')}6d756a',
        'zz',
        '53${_push(name)}${_push('value', declaredLength: 20)}6d756a',
      ];

      for (final script in malformedScripts) {
        expect(
          NamecoinScript.fromVerboseTransaction(verboseTransaction(script), name),
          isNull,
          reason: script,
        );
      }

      expect(NamecoinScript.fromVerboseTransaction({}, name), isNull);
      expect(NamecoinScript.fromVerboseTransaction({'vout': 'invalid'}, name), isNull);
    });

    test('rejects non-UTF8 values instead of returning replacement characters', () {
      final transaction = verboseTransaction('53${_push(name)}01ff6d756a');
      expect(NamecoinScript.fromVerboseTransaction(transaction, name), isNull);
    });
  });
}

Map<String, dynamic> verboseTransaction(String scriptHex) => {
      'vout': [
        {
          'scriptPubKey': {'hex': scriptHex},
        },
      ],
    };

String _push(String value, {int? declaredLength}) {
  final bytes = utf8.encode(value);
  final length = declaredLength ?? bytes.length;
  if (length > 0xff) throw ArgumentError('Test push is too long');
  return '${length.toRadixString(16).padLeft(2, '0')}${hex.encode(bytes)}';
}
