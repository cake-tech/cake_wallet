import "package:cake_wallet/solana/solana.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "exchange_provider_suite.dart";
import "fakes.dart";
import "mocks/chainflip_mock.dart";
import "mocks/changenow_mock.dart";
import "mocks/exolix_mock.dart";
import "mocks/jupiter_mock.dart";
import "mocks/letsexchange_mock.dart";
import "mocks/near_intents_mock.dart";
import "mocks/stealthex_mock.dart";
import "mocks/swapsxyz_mock.dart";
import "mocks/swaptrade_mock.dart";
import "mocks/trocador_mock.dart";
import "mocks/xoswap_mock.dart";

/// Runs the same suite against every provider, each wired to its own mocked api.
///
/// The mocks under `mocks/` answer with fixed rates and fixed trade bodies, so the limits,
/// rates and trades below are exact values rather than "something plausible". The real api
/// shapes live in `test/exchange/fixtures/` and are covered by the schema tests; these
/// bodies are trimmed down copies of them with round numbers.
void main() {
  setUpAll(() {});

  final scenarios = <ProviderScenario>[
    chainflipScenario(),
    changeNowScenario(),
    exolixScenario(),
    jupiterScenario(),
    letsExchangeScenario(),
    nearIntentsScenario(),
    stealthExScenario(),
    swapsXyzScenario(),
    swapTradeScenario(),
    trocadorScenario(),
    xoSwapScenario(),
  ];

  for (final scenario in scenarios) {
    runExchangeProviderSuite(scenario);
  }
}
