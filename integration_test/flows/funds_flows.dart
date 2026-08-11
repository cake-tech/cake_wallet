import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/sync_status.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter/material.dart";

import "../core/test_wallets.dart";
import "../robots/home_page_robot.dart";
import "../robots/new_dashboard_robot.dart";
import "onboarding_flows.dart";

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

  // Returns false once every funded wallet of the chain has come up empty.
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

  Future<bool> returnToHome({int maxPops = 6}) async {
    for (int attempt = 0; attempt <= maxPops; attempt++) {
      if (await _homePageRobot.pumpUntil(
        () => tester.any(find.byKey(const ValueKey("home_page_wallet_name_text_key"))),
        timeout: const Duration(seconds: 3),
      )) {
        return true;
      }

      try {
        await _homePageRobot.dismissModal();
      } catch (e) {
        tester.printToConsole("Nothing left to pop while returning home: $e");
        break;
      }
    }

    return tester.any(find.byKey(const ValueKey("home_page_wallet_name_text_key")));
  }

  // A wallet that finishes syncing and still shows nothing counts as drained, waiting out
  // the full timeout on an empty wallet would cost us the whole run.
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
