import 'package:cake_wallet/core/address_resolver/namecoin/namecoin_electrumx_client.dart';
import 'package:cake_wallet/core/address_resolver/namecoin/namecoin_record.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/tor/disabled.dart';
import 'package:flutter_test/flutter_test.dart';

const _runLiveTest = bool.fromEnvironment('NAMECOIN_LIVE_TEST');

void main() {
  setUpAll(() => CakeTor.instance = CakeTorDisabled());

  test(
    'resolves d/mstrofnone to its configured BTC address through public ElectrumX servers',
    () async {
      final lookup = await NamecoinElectrumXClient().resolve('d/mstrofnone');

      expect(lookup, isNotNull);
      expect(lookup!.name, 'd/mstrofnone');
      expect(lookup.height, greaterThan(0));
      expect(lookup.expiresIn, greaterThan(0));
      expect(
        NamecoinRecord.parseAddresses(lookup.value, currencies: const [CryptoCurrency.btc]),
        const {CryptoCurrency.btc: 'bc1qz68dnj5qffnu03mm3a8uhy778anmfgdumas4uk'},
      );

      // Keep the confirmed transaction visible in live-test logs without making
      // future, legitimate name updates fail solely because its txid changed.
      printV('Resolved ${lookup.name} at ${lookup.txid}:${lookup.height}');
    },
    timeout: const Timeout(Duration(minutes: 2)),
    skip: !_runLiveTest,
  );
}
