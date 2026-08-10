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

New robots extend `BaseRobot`. The older onboarding robots still hold a `CommonTestCases`
instead, which is the same idea with a weaker waiting story, migrate one over whenever you
touch it.

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
3. Rename the app, every run wipes its data between suites:

   ```
   printf 'id=com.cakewallet.test_local\nname=local\n' > android/app.properties
   ```

   Step 2 writes the real `com.cakewallet.cake_wallet` id, and clearing that package takes
   your own wallets with it. CI does this same rename after app_config for the same reason.
   The runner refuses to clear a package that is not named for testing.
4. Compiled vector assets, both passes:

   ```
   ./compile_graphics.sh
   while read -r dir; do
     dart run vector_graphics_compiler --input-dir "$dir" --out-dir "$dir"
   done < <(find assets/images -type d)
   ```

   `compile_graphics.sh` does not cover `assets/images`, and those `.svg.vec` files are
   neither committed nor ignored, so a fresh checkout has none of them. Without this the
   app throws "Unable to load asset" on the welcome screen and the first suite fails.
5. Native libs in `android/app/src/main/jniLibs/` for monero, wownero and zano
   (prebuilts from the pinned monero_c release).
6. `~/.cargo/bin` on PATH so gradle can build the breez rust crate.

If the build sits at 0% CPU for minutes, close Android Studio or stop its Gradle daemon,
two daemons on this project deadlock on the same locks.

Re-run steps 2 to 4 after every merge from dev. The chain proxies in `lib/<chain>/<chain>.dart`
are generated and gitignored, so a merge that adds a call like `bitcoin!.hasSelectedLightning`
leaves them behind and the build fails on a method that looks like it should exist. Step 2
also rewrites `android/app.properties` with the real app id, so redo step 3 alongside it.

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

`SUITE_DIR` also takes a single file, which is what you want while iterating on one suite:

```bash
SUITE_DIR=integration_test/suites/tier0/fiat_currency_test.dart ./integration_test_runner.sh
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

## What is covered today

Twenty eight suites. Add a line here when you add one.

### tier0, no network needed

| Suite | What it proves |
| --- | --- |
| `onboarding_create_test` | A wallet can be created for every configured type, and the app lands on the dashboard with that wallet open |
| `onboarding_restore_test` | A wallet restores from seed for every configured type, and the restored wallet reports the seed it was given |
| `invalid_seed_test` | A seed the wallet cannot parse leaves the user on the restore screen with nothing created |
| `duplicate_wallet_name_test` | A name already taken is refused instead of quietly overwriting the wallet holding it |
| `wallet_group_test` | A wallet added to an existing seed shares that seed, and both wallets stay reachable through the group |
| `wallet_switching_test` | Picking another wallet in the list actually loads it, down to the balance and address on screen |
| `wallet_rename_test` | A wallet can be renamed, and cannot be renamed onto a name another wallet already holds |
| `wallet_delete_test` | Deleting a wallet takes it off the list and out of storage, and leaves the others alone |
| `receive_address_test` | The receive sheet shows an address the opened wallet owns, not a leftover from the previous one |
| `seed_confirmation_test` | The seed and keys the app displays are the ones the opened wallet holds |
| `show_keys_auth_test` | The seed and keys page turns away a wrong pin and opens for the right one |
| `change_pin_test` | A changed pin is the one that opens what the old pin used to guard |
| `send_validation_test` | The send screen refuses an empty address, a malformed one, an empty amount and more than the balance |
| `address_book_test` | A saved contact keeps the address it was given |
| `send_from_address_book_test` | A contact picked on the send screen fills in the address that was saved for it |
| `settings_nav_test` | Every settings row opens its page and backs out of it |
| `language_test` | Changing the language changes what the settings screen shows |
| `fiat_currency_test` | Turning the fiat api off hides the currency setting, turning it back on returns it and the currency can be changed |

### tier1, needs a node or a provider

| Suite | What it proves |
| --- | --- |
| `sync_status_test` | A restored wallet reaches a node and starts syncing rather than sitting at connecting |
| `node_switching_test` | Confirming another node repoints the wallet at it |
| `transaction_history_test` | A wallet with known transactions renders them, both in the home preview and the full list |
| `transaction_details_test` | Tapping a transaction opens the details of that transaction and not another one |
| `swap_quote_test` | The swap sheet reaches a provider and returns a real quote, no trade is created |
| `monero_legacy_seed_test` | A 25 word monero seed restores through the legacy path, which takes a seed type and a restore height the polyseed path never asks for |

### funds_suites, manual workflow only

| Suite | What it proves |
| --- | --- |
| `send_dry_run_test` | Every funded chain builds and signs a transaction, then throws it away without broadcasting |
| `send_funds_test` | A real self transaction is broadcast on every funded chain |
| `swap_dry_run_test` | A real deposit is priced end to end, stopping before the trade is created |
| `swap_funds_test` | A swap is created and its deposit broadcast |

The two dry runs need funded seeds because a quote and a signed transaction both depend on a
real balance, but neither spends anything. `SPEND=true` is what lets the two that do spend
past their guard.

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
6. Add it to the table above.

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

Adding a new test secret means adding it in `tool/utils/secret_key.dart`, mapping it in
`TestWallets` and asking the team lead to add the value to the CI secret.

The slack report uses two more repository secrets, `SLACK_TESTS_TOKEN` and
`SLACK_TESTS_CHANNEL`, which is a channel id rather than a webhook. Both the PR gate and
the funds workflow report through them, so every test result lands in one channel.

That is a separate slack app from the one behind `SLACK_APP_TOKEN`, which uploads apks to
the builds channel. They are split so each token carries only what it needs, `chat:write`
for this one and the file scopes for that one, and so the name on a message says which of
the two sent it. A post coming back `missing_scope` means the app is short the
`chat:write` scope or was never reinstalled after it was added.

## Funds suites

`funds_suites/` restore funded wallets and move real funds: a small self send on every
funded chain, and one real swap with its deposit broadcast. They only run from the manual
`Funds Integration Tests` workflow, which the team lead dispatches from the Actions tab
before a release. Nothing gates the dispatch, anyone who can run workflows in the repo can
start a funds run, so treat it as a deliberate release step and not a routine check.

Funded seeds live in the `FUNDS_SECRETS_FILE` secret, a base64 encoded replacement for
`integration_test/core/funded_wallets.dart` mapping wallet type names to that chain's
funded seed phrases, at least two wallets per chain:

```dart
const Map<String, List<String>> fundedWalletSeeds = {
  "solana": ["first wallet seed words ...", "second wallet seed words ..."],
  "ethereum": ["first wallet seed words ...", "second wallet seed words ..."],
};
```

The suites restore a chain's funded wallets one by one and use the first that shows a
spendable balance, a wallet that finishes syncing while still empty counts as drained.
A chain where every funded wallet is empty fails with a message asking for a top up.

The checked in default is an empty map and must stay empty. Only the funds workflow turns
on `write_funds_secrets`, and that input is the one thing keeping funded seeds out of a PR
build now that no environment scopes the secret. In auto mode the suites discover every
chain present in the map, so funding a new chain only means adding its entry to the
secret. The dispatch inputs narrow a run to specific flows or chains, and per chain send
amounts are tuned in `TestConfig._fundsSendAmounts`. The swap suite enters an amount just
above the provider minimum, the first funded chain's balance has to cover that minimum
plus fees.

## How CI runs them

The PR gate runs on GitHub hosted runners, the self-hosted android builders have no
usable KVM so the emulator cannot start there. Moving back is a one line change to
`runs-on` in `reusable-integration-test.yml` once a KVM capable builder exists.

tier0 and tier1 each get their own emulator step and upload their logs separately, so a
runner that dies during tier1 cannot take the gate's own results with it. The gradle heap
is capped before the test phase because the daemon and the emulator together were
exhausting the runner.

Every run posts to slack. The message names each tier's counts, its duration and any suite
that failed, and the full list of what passed goes in a reply on the same message so the
channel keeps the short version. It needs `SLACK_APP_TOKEN` and `SLACK_TESTS_CHANNEL`, and
without either the step logs a notice and skips rather than failing the gate. Cancelled
runs stay quiet, since superseded runs are cancelled on purpose. The report is built from
the `SUMMARY_FILE` each tier writes, so anything the runner counts is available to it.

Two environment quirks are worth knowing when a build fails in CI but not locally: the
deps docker image regenerates the mweb ffi bindings with an ffigen too old for the current
compiler and its rsync overwrites `cw_mweb/pubspec.yaml`, so the workflow restores that
file and regenerates the bindings itself. And `assets/images` svgs need compiling to
`.vec`, which `compile_graphics.sh` does not cover.

## Flakiness playbook

- A timeout in `pumpUntilFound` throws with the finder description. Diagnose through the
  `integration-test-logs` artifact in CI, it holds the run log and a final logcat dump.
  Screenshots do not work on Android without surface conversion, do not rely on them.
- The app's own error handling ignores missing `.svg.vec` assets by design, the harness
  filters those too. Any other FlutterError fails the test, that is intentional.
- Monero and wownero load native libraries on first open, give their steps generous
  timeouts rather than retries.
- A suite that fails once in CI retries once with wiped app data. A red gate means the
  same suite failed twice in a row.
- `wallet_switching_test` fails intermittently, roughly one run in three locally. The first
  thing thrown is `entry.currentState == _RouteLifecycle.popping` out of the navigator, from
  the flushbar the wallet list uses as its loading bar being taken off the navigator twice.
  Every `!_debugLocked` after that is the fallout, including the one during teardown that
  actually fails the suite. The bar is a route of its own and another_flushbar documents
  that dismissing one that is not the top route is unsupported, so the fix belongs in how
  the wallet list shows loading progress rather than in the suite.
