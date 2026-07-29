# Integration tests

End to end tests that drive the real app on a device. They run on an Android emulator in CI
for every pull request into `dev`, and the funds suites run manually before releases.

## Architecture

Four layers, each one only talks to the layer below it:

```
suites/        the runnable tests, one file per user journey
  tier0/       offline capable, no network assertions, the hard PR gate
  tier1/       needs live network (nodes, swap providers), non blocking on PRs
funds_suites/  moves real funds, only ever run by the manual funds workflow
flows/         multi screen journeys shared between suites (onboarding, auth, wallet list)
robots/        one class per screen, knows that screen's keys and assertions
core/          the harness: BaseRobot primitives, AppLauncher, TestConfig, TestWallets
```

Supporting pieces:

- `test_driver/integration_test.dart` is the standard flutter drive driver.
- `integration_test_runner.sh` discovers and runs suites, see Running locally.
- `.github/workflows/integration_tests.yml` is the PR gate,
  `reusable-integration-test.yml` holds the shared build and emulator pipeline.

## Running locally

Prerequisites, one time:

1. A generated `lib/.secrets.g.dart` with the `*TestWalletSeeds` values populated.
2. App config for the cakewallet flavor:
   `cd scripts/android && source ./app_env.sh cakewallet && ./app_config.sh`
3. Compiled vector assets: `./compile_graphics.sh` plus the assets/images pass the CI
   workflow runs (see "Compile assets/images graphics" in reusable-integration-test.yml).
4. Native libs in `android/app/src/main/jniLibs/` for monero, wownero and zano
   (prebuilts from the pinned monero_c release).
5. `~/.cargo/bin` on PATH so gradle can build the breez rust crate.

Run one suite against a booted emulator:

```
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/suites/tier0/onboarding_create_test.dart \
  --dart-define=CI_BUILD=true -d <device-id>
```

Run a whole tier through the runner:

```
TEST_TIER=tier0 FLUTTER_DEVICE=<device-id> ./integration_test_runner.sh
```

Runner knobs (environment variables): `SUITE_DIR`, `TEST_TIER` (tier0, tier1, all),
`PLATFORM` (android, linux, auto), `FLUTTER_DEVICE`, `RETRY_COUNT`, `EXTRA_DART_DEFINES`,
`REMOVE_DATA_DIRECTORY=N` to keep app data between suites.

Test knobs (dart defines): `TEST_WALLET_TYPES=all` runs every available wallet type,
a comma separated list of type names runs just those, unset runs the representative set
(solana, ethereum, bitcoin, monero).

## Which tier does my test go in

- Creates wallets, navigates screens, checks local state: **tier0**.
- Needs a node, a provider API or any live network response: **tier1**.
- Signs and broadcasts a real transaction: **funds_suites**, never anywhere else.

tier0 blocks merges. tier1 runs on every PR but reports without blocking until it has a
stable history. funds_suites run only from the manual funds workflow.

## Adding a test for your feature

1. Give the widgets your test touches stable keys, inline in the widget:
   `key: ValueKey('<page>_<element>_key')`. Keys go on the widget the test taps or reads,
   never on AnimatedSwitcher children where the key is the animation identity.
2. Create or extend the robot for the screen in `robots/`. One robot per screen, it
   extends `BaseRobot` and implements `isDisplayed()`. Robots own every finder for their
   screen, suites never call `find` directly.
3. If the journey spans several screens, add a flow to `flows/` composing the robots.
4. Copy `integration_test/templates/example_feature_test.dart.example` into the right
   tier directory, rename it to `<feature>_test.dart` and fill it in. The runner only
   picks up files ending in `_test.dart`.
5. Run it twice locally against an emulator before pushing.

## Harness rules

- Suites use `integrationTest` from `core/app_launcher.dart`, not `testWidgets`. It contains
  background async errors from app networking that would otherwise fail the test, awaited
  assertion failures still fail the test normally.
- No `sleep` or fixed delays, use `pumpUntilFound` and `pumpUntil` with a timeout.
- No `pumpAndSettle` in new code, screens with endless animations never settle,
  use the bounded `settle()` from BaseRobot.
- No `find.text` on localized strings, keys only. Wallet names and addresses are data,
  matching on those is fine.
- `.secrets.g.dart` is only imported by `core/test_wallets.dart`.
- Every suite starts from a fresh install, the runner wipes app data between suites.
- Reading a view model through the page widget for a state assertion is fine, driving
  the app through view models instead of the UI is not.

## Secrets

Test wallet seeds and receive addresses live in `lib/.secrets.g.dart` under names like
`solanaTestWalletSeeds`, defined in `tool/utils/secret_key.dart` and reachable through
`TestWallets`. CI injects the real values from the `MAIN_SECRETS_FILE` repository secret.
Funded wallet seeds for the funds suites use `<type>FundedWalletSeeds` names and come from
the environment scoped `FUNDS_SECRETS_FILE` secret, they never exist on PR builds.

Adding a new test secret means adding it in `tool/utils/secret_key.dart`, mapping it in
`TestWallets` and asking the team lead to add the value to the CI secret.

## Flakiness playbook

- A timeout in `pumpUntilFound` throws with the finder description and takes a best
  effort screenshot. Check the uploaded `integration-test-logs` artifact in CI.
- The app's own error handling ignores missing `.svg.vec` assets by design, the harness
  filters those too. Any other FlutterError fails the test, that is intentional.
- Monero and wownero load native libraries on first open, give their steps generous
  timeouts rather than retries.
- A suite that fails once in CI retries once with wiped app data. A red gate means the
  same suite failed twice in a row.
