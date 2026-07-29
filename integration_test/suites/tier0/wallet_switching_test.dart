import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/onboarding_flows.dart";
import "../../flows/wallet_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Switching wallets loads the selected wallet", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final walletFlows = WalletFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);

    await appLauncher.launchApp(testKey: "wallet_switching_test_app_key");

    await onboardingFlows.createFirstWallet(WalletType.solana);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    final appStore = getIt.get<AppStore>();
    final firstWalletName = appStore.wallet!.name;

    await dashboardRobot.openWalletsTab();
    await onboardingFlows.createAdditionalWalletFromWalletList(WalletType.ethereum);

    await homePageRobot.isDisplayed();

    final secondWalletName = appStore.wallet!.name;
    expect(appStore.wallet?.type, WalletType.ethereum);

    tester.printToConsole("Switching back to $firstWalletName");

    await walletFlows.switchToWallet(firstWalletName);

    // The wallet change reaction resets the dashboard to the home tab with the new wallet.
    await homePageRobot.isDisplayed();
    await homePageRobot.hasWalletName(firstWalletName);

    expect(appStore.wallet?.type, WalletType.solana);
    expect(appStore.wallet?.name, firstWalletName);

    tester.printToConsole("Switching forward to $secondWalletName");

    await walletFlows.switchToWallet(secondWalletName);

    await homePageRobot.isDisplayed();
    await homePageRobot.hasWalletName(secondWalletName);

    expect(appStore.wallet?.type, WalletType.ethereum);
  });
}
