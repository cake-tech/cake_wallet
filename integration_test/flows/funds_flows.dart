import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/sync_status.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/test_config.dart";
import "../core/test_wallets.dart";
import "../robots/home_page_robot.dart";
import "../robots/new_dashboard_robot.dart";
import "../robots/new_send_page_robot.dart";
import "onboarding_flows.dart";

class FundsFlows {
  FundsFlows(this.tester)
      : _onboardingFlows = OnboardingFlows(tester),
        _dashboardRobot = NewDashboardRobot(tester),
        _homePageRobot = HomePageRobot(tester),
        _sendRobot = NewSendPageRobot(tester);

  final WidgetTester tester;
  final OnboardingFlows _onboardingFlows;
  final NewDashboardRobot _dashboardRobot;
  final HomePageRobot _homePageRobot;
  final NewSendPageRobot _sendRobot;

  bool _hasRestoredAnyWallet = false;

  Future<bool> openFundedWallet(WalletType type) async {
    final wallets = TestWallets.fundedWalletsFor(type);

    for (int index = 0; index < wallets.length; index++) {
      final wallet = wallets[index];

      tester.printToConsole("Trying funded wallet ${index + 1}/${wallets.length} for ${type.name}");

      if (_hasRestoredAnyWallet) {
        await _dashboardRobot.openWalletsTab();

        final isWalletListReady = await _dashboardRobot.pumpUntil(
          () =>
              tester.any(find.byKey(const ValueKey("wallet_list_page_restore_wallet_button_key"))),
          timeout: const Duration(seconds: 60),
        );

        expect(
          isWalletListReady,
          true,
          reason: "The wallet list restore button didn't show before ${type.name}, "
              "Currently have: ${_dashboardRobot.describeScreen()} on screen",
        );

        await _onboardingFlows.restoreAdditionalWalletFromWalletList(
          type,
          seed: wallet.seed,
          passphrase: wallet.passphrase,
        );
      } else {
        await _onboardingFlows.restoreFirstWalletFromSeed(
          type,
          seed: wallet.seed,
          passphrase: wallet.passphrase,
        );
      }

      _hasRestoredAnyWallet = true;

      await _waitForDashboard(type);
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
        () => _isHomeInFront,
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

    return _isHomeInFront;
  }

  Future<void> _waitForDashboard(WalletType type) async {
    final reached = await _dashboardRobot.pumpUntil(
      () => tester.any(find.byKey(const ValueKey("new_dashboard_page_key"))),
      timeout: TestConfig.walletSyncBudget,
    );

    if (reached) {
      return;
    }

    final status = getIt.get<AppStore>().wallet?.syncStatus;
    final stillSyncing = status is SyncingSyncStatus || status is SyncronizingSyncStatus;

    throw TestFailure(
      stillSyncing
          ? "${type.name} never became ready to send, it is still syncing (${status.runtimeType})"
          : "${type.name} never reached the dashboard, its status was ${status.runtimeType}",
    );
  }

  bool get _isHomeInFront => _homePageRobot.isInFront && !_sendRobot.isSendFlowOpen;

  Future<bool> _hasSpendableBalance({Duration timeout = TestConfig.walletSyncBudget}) async {
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
