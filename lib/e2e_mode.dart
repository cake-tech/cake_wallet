import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/utils/feature_flag.dart";
import "package:cake_wallet/view_model/wallet_restore_view_model.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/scheduler.dart";
import "package:flutter/semantics.dart";
import "package:flutter/widgets.dart";
import "package:shared_preferences/shared_preferences.dart";

/// E2E launch mode (QA handoff Phase 1b).
///
/// Compiled in only with `--dart-define=E2E_MODE=true` **and** the dev-options
/// gate (`FeatureFlag.hasDevOptions`, which defaults off in release builds),
/// so none of this can reach a release binary.
///
/// What it does when enabled:
///  * forces the UI to English regardless of the stored language;
///  * compresses animations (`E2E_ANIMATION_SCALE`, default `0.01`) so drivers
///    never wait on them;
///  * calls `SemanticsBinding.ensureSemantics()` so the accessibility tree the
///    e2e driver reads exists even on physical devices (iOS builds semantics
///    only while an accessibility service is active otherwise);
///  * optionally boots straight into a fixture wallet instead of onboarding:
///    `--dart-define=E2E_FIXTURE_SEED=...` supplied at build time from a
///    secure env var (never committed), with `E2E_FIXTURE_NAME`,
///    `E2E_FIXTURE_TYPE` (default `bitcoin`) and `E2E_FIXTURE_PIN`
///    (default `0801`) overrides.
class E2EMode {
  E2EMode._();

  static const bool enabled = bool.fromEnvironment("E2E_MODE") && FeatureFlag.hasDevOptions;

  static const String fixtureSeed = String.fromEnvironment("E2E_FIXTURE_SEED");
  static const String fixtureName =
      String.fromEnvironment("E2E_FIXTURE_NAME", defaultValue: "QA fixture");
  static const String fixtureType =
      String.fromEnvironment("E2E_FIXTURE_TYPE", defaultValue: "bitcoin");
  static const String fixturePin =
      String.fromEnvironment("E2E_FIXTURE_PIN", defaultValue: "0801");

  /// Animation time dilation; animations take animationScale × real time.
  /// (`double.fromEnvironment` does not exist, so parse the define as text.)
  static const String _animationScaleRaw =
      String.fromEnvironment("E2E_ANIMATION_SCALE", defaultValue: "0.01");
  static double get animationScale => double.tryParse(_animationScaleRaw) ?? 0.01;

  /// Called once early in `runAppWithZone`, after the binding is initialized.
  static void applyLaunchSettings() {
    if (!enabled) {
      return;
    }
    // Under a widget-test binding (integration_test / flutter drive) the test
    // framework OWNS time and semantics: it fails every test if timeDilation is
    // left changed (`debugAssertNoTimeDilation`) or a SemanticsHandle is still
    // outstanding at teardown (`_verifySemanticsHandlesWereDisposed`). Tests
    // pump their own time and call `tester.ensureSemantics()` when they need it,
    // so this launch path applies only to real-app runs (agent-device driving
    // physical devices / simulators). Detected by name to avoid importing
    // flutter_test from lib/.
    final binding = WidgetsBinding.instance;
    if (binding.runtimeType.toString().contains("Test")) {
      return;
    }
    timeDilation = animationScale;
    SemanticsBinding.instance.ensureSemantics();
  }

  /// Called after the first frame so the authentication reaction
  /// (`on_authentication_state_change`) can navigate to the dashboard once the
  /// fixture wallet exists. Restores the fixture wallet and its PIN only on a
  /// fresh install — an app that is already onboarded is left untouched.
  static Future<void> bootstrapFixtureWallet() async {
    if (!enabled || fixtureSeed.isEmpty) {
    return;
  }

    final prefs = getIt<SharedPreferences>();
    if (prefs.getString(PreferencesKey.currentWalletName) != null) {
      return;
    }

    await getIt<AuthService>().setPassword(fixturePin);
    getIt<SettingsStore>().pinCodeLength = fixturePin.length;

    final type = WalletType.values.firstWhere(
      (t) => t.name == fixtureType,
      orElse: () => WalletType.bitcoin,
    );

    final restore = getIt<WalletRestoreViewModel>(param1: type, param2: null);
    final options = <String, dynamic>{"name": fixtureName, "seed": fixtureSeed};

    // The seed-restore credential builders for these types require an explicit
    // derivation; the rest restore from the seed alone.
    if (type == WalletType.bitcoin) {
      options["derivationInfo"] = DerivationInfo(
        derivationType: DerivationType.bip39,
        derivationPath: "m/84'/0'/0'",
        description: "Standard BIP84 native segwit",
        scriptType: "p2wpkh",
      );
    } else if (type == WalletType.litecoin) {
      options["derivationInfo"] = DerivationInfo(
        derivationType: DerivationType.bip39,
        derivationPath: "m/84'/2'/0'",
        description: "Standard BIP84 native segwit",
        scriptType: "p2wpkh",
      );
    }

    await restore.create(options: options);
  }
}
