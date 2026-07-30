import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/sync_status.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/test_wallets.dart";
import "../robots/home_page_robot.dart";
import "../robots/new_dashboard_robot.dart";
import "onboarding_flows.dart";

/// Journeys only the funds suites use, they restore wallets that hold real funds.
class FundsFlows {
  FundsFlows(this.tester)
      : _onboardingFlows = OnboardingFlows(tester),
        _dashboardRobot = NewDashboardRobot(tester),
        _homePageRobot = HomePageRobot(tester);

  final WidgetTester tester;
  final OnboardingFlows _onboardingFlows;
  final NewDashboardRobot _dashboardRobot;
  final HomePageRobot _homePageRobot;

  bool _hasRestoredAnyWallet = false;

  /// Restores the chain's funded wallets one by one until one has a spendable balance.
  ///
  /// Returns true with that wallet open, false when every funded wallet of the chain
  /// came up empty so the caller can report the chain and move on.
  Future<bool> openFundedWallet(WalletType type) async {
    final seeds = TestWallets.fundedSeedsFor(type);

    for (int index = 0; index < seeds.length; index++) {
      tester.printToConsole("Trying funded wallet ${index + 1}/${seeds.length} for ${type.name}");

      if (_hasRestoredAnyWallet) {
        await _dashboardRobot.openWalletsTab();
        await _onboardingFlows.restoreAdditionalWalletFromWalletList(type, seed: seeds[index]);
      } else {
        await _onboardingFlows.restoreFirstWalletFromSeed(type, seed: seeds[index]);
      }

      _hasRestoredAnyWallet = true;

      await _dashboardRobot.isDisplayed();
      await _homePageRobot.isDisplayed();

      if (await _hasSpendableBalance()) {
        return true;
      }

      tester.printToConsole("Wallet ${index + 1} for ${type.name} has no spendable balance");
    }

    return false;
  }

  /// Waits for a spendable balance, a wallet that finishes syncing and still shows
  /// nothing is treated as drained so the next seed gets its turn quickly.
  Future<bool> _hasSpendableBalance({Duration timeout = const Duration(minutes: 5)}) async {
    final appStore = getIt.get<AppStore>();
    final endTime = DateTime.now().add(timeout);
    DateTime? syncedSince;

    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 250));

      final wallet = appStore.wallet;

      if (wallet == null) {
        continue;
      }

      if (wallet.balance.values.any((balance) => balance.available.sign > 0)) {
        return true;
      }

      // A short grace period after syncing lets the balance observables catch up.
      if (wallet.syncStatus is SyncedSyncStatus) {
        syncedSince ??= DateTime.now();

        if (DateTime.now().difference(syncedSince) > const Duration(seconds: 15)) {
          return false;
        }
      } else {
        syncedSince = null;
      }
    }

    return false;
  }
}
