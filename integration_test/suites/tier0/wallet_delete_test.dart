import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/auth_flows.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";
import "../../robots/wallet_edit_page_robot.dart";
import "../../robots/wallet_list_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Deleting a wallet takes it off the list and out of storage", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final authFlows = AuthFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final walletListRobot = WalletListPageRobot(tester);
    final walletEditRobot = WalletEditPageRobot(tester);

    await appLauncher.launchApp(testKey: "wallet_delete_test_app_key");

    await onboardingFlows.createFirstWallet(WalletType.solana);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    final appStore = getIt.get<AppStore>();
    final deletedWallet = appStore.wallet!.name;

    await dashboardRobot.openWalletsTab();
    await onboardingFlows.createAdditionalWalletFromWalletList(WalletType.ethereum);

    await homePageRobot.isDisplayed();

    final keptWallet = appStore.wallet!.name;

    expect(keptWallet, isNot(deletedWallet), reason: "The second wallet never became the open one");

    await dashboardRobot.openWalletsTab();
    await walletListRobot.isDisplayed();

    await walletListRobot.openEditFor(deletedWallet);
    await walletEditRobot.isDisplayed();

    await walletEditRobot.tapDelete();
    await authFlows.authenticateWithPin(required: false);

    await walletEditRobot.confirmDelete();

    await walletListRobot.isDisplayed();

    final removed = await walletListRobot.pumpUntil(
      () => !walletListRobot.hasWallet(deletedWallet),
      timeout: const Duration(minutes: 1),
    );

    expect(removed, true, reason: "$deletedWallet is still on the list after being deleted");

    expect(
      walletListRobot.hasWallet(keptWallet),
      true,
      reason: "Deleting $deletedWallet took $keptWallet with it",
    );

    final stored = await WalletInfo.getAll();
    final names = stored.map((wallet) => wallet.name).toList();

    expect(names, isNot(contains(deletedWallet)));
    expect(names, contains(keptWallet));

    expect(
      appStore.wallet?.name,
      keptWallet,
      reason: "Deleting another wallet changed which one is open",
    );
  });
}
