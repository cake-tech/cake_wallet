import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cake_wallet/.secrets.g.dart' as secrets;

// 1. Configuration
const _fiatApiClearNetAuthority = 'fiat-api.cakewallet.com';
const _fiatApiPath = '/v2/rates';
const _apiKey = secrets.fiatApiKey;

// 2. Define Lists
const List<String> cryptoCurrencies = [
  'btc',
  'ltc',
  'xmr',
  'bch',
  'doge',
  'eth',
  'pol',
  'sol',
  'xno',
  'trx',
  'dcr',
  'zano',
  'wow',
  'arb',
  'usdt',
  'pepe',
  'zec',
  'bnb',
  'xrp',
  'ada',
  'avax',
  'shib',
  'ton',
  'dot',
  'link',
  'uni',
  'near',
  'atom',
  'xlm',
  'stx',
  'kas',
  'dai',
];

const List<String> fiatCurrencies = [
  'usd',
  'eur',
  'aud',
  'gbp',
  'jpy',
  'cad',
  'chf',
  'cny',
  'inr',
  'brl',
  'zar',
  'mxn',
  'krw',
  'hkd',
  'sgd',
  'nzd',
  'sek',
  'try'
];

void main() {
  // --- A. Setup the Output File ---
  final logFile = File('fiat-check-output.txt');
  // Write a header to start fresh (overwrite old file)
  logFile.writeAsStringSync('--- Starting Verified Price Check at ${DateTime.now()} ---\n');

  // --- B. Run App in a Zone to Capture Prints ---
  runZoned(
    () async {
      print('--- Starting Verified Price Check ---');

      final Map<String, List<String>> workingPairs = {};
      final Map<String, List<String>> failedPairs = {};
      final client = http.Client();

      try {
        for (final crypto in cryptoCurrencies) {
          workingPairs[crypto] = [];
          failedPairs[crypto] = [];

          for (final fiat in fiatCurrencies) {
            // Clean ticker logic
            String cleanCrypto = crypto.split(".").first;

            final Map<String, String> queryParams = {
              'interval_count': '1',
              'base': cleanCrypto,
              'quote': fiat,
            };

            final uri = Uri.https(_fiatApiClearNetAuthority, _fiatApiPath, queryParams);
            bool isSuccess = false;
            String logPrefix = "❌";
            String logMessage = "";

            try {
              final response = await client.get(uri, headers: {"x-api-key": _apiKey});

              if (response.statusCode == 200) {
                final data = jsonDecode(response.body) as Map<String, dynamic>;
                final Map<String, dynamic> results = data['results'] as Map<String, dynamic>? ?? {};
                final Map<String, dynamic> errors = data['errors'] as Map<String, dynamic>? ?? {};

                if (results.isNotEmpty && errors.isEmpty) {
                  isSuccess = true;
                  logPrefix = "✅";
                  final price = results.values.first;
                  logMessage = "${cleanCrypto.toUpperCase()}/${fiat.toUpperCase()} = $price";
                } else {
                  isSuccess = false;
                  logPrefix = "❌";
                  logMessage =
                      "${cleanCrypto.toUpperCase()}/${fiat.toUpperCase()} returned empty results or error.";
                }
              } else {
                logMessage =
                    "${cleanCrypto.toUpperCase()}/${fiat.toUpperCase()} HTTP ${response.statusCode}";
              }
            } catch (e) {
              logMessage = "${cleanCrypto.toUpperCase()}/${fiat.toUpperCase()} Error: $e";
            }

            // Print immediate status (Captured by Zone)
            print('$logPrefix $logMessage');

            // Aggregate
            if (isSuccess) {
              workingPairs[crypto]!.add(fiat);
            } else {
              failedPairs[crypto]!.add(fiat);
            }

            // 50ms delay to prevent rate limiting
            await Future.delayed(Duration(milliseconds: 50));
          }
        }
      } finally {
        client.close();
      }

      // --- FINAL SUMMARY ---
      print('\n\n=== SUMMARY ===\n');

      // Print Successful
      workingPairs.forEach((crypto, fiats) {
        if (fiats.isNotEmpty) {
          print('✅ ${crypto.toUpperCase()}: ${fiats.join(", ")}');
        }
      });

      print('\n--------------------------------------------------\n');

      // Print Failed
      failedPairs.forEach((crypto, fiats) {
        if (fiats.isNotEmpty) {
          print('❌ ${crypto.toUpperCase()}: ${fiats.join(", ")}');
        }
      });

      print('\n=== DONE ===');
    },

    // --- C. The Interceptor ---
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        // 1. Print to Standard Console
        parent.print(zone, line);

        // 2. Append to Text File
        // We use Sync to ensure data isn't lost if the script crashes
        logFile.writeAsStringSync('$line\n', mode: FileMode.append);
      },
    ),
  );
}
