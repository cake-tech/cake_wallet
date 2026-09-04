import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/sync_status.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Restored wallet connects to a node and starts syncing", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);

    await appLauncher.launchApp(testKey: "sync_status_test_app_key");

    await onboardingFlows.restoreFirstWalletFromSeed(WalletType.bitcoin);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    final appStore = getIt.get<AppStore>();

    // Reaching a syncing or synced state proves node connection over the live network.
    final synced = await homePageRobot.pumpUntil(
      () {
        final status = appStore.wallet?.syncStatus;
        return status is SyncronizingSyncStatus ||
            status is SyncingSyncStatus ||
            status is SyncedSyncStatus;
      },
      timeout: const Duration(minutes: 3),
    );

    expect(
      synced,
      true,
      reason: "Wallet never started syncing, last status: ${appStore.wallet?.syncStatus}",
    );

    await homePageRobot.confirmSyncIndicatorShown(appStore.wallet!.syncStatus.runtimeType);
  });
}
