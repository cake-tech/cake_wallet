import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/wallet_type.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";
import "../../robots/new_wallet_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("A wallet name already in use is refused", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final newWalletPageRobot = NewWalletPageRobot(tester);

    const walletType = WalletType.solana;

    await appLauncher.launchApp(testKey: "duplicate_wallet_name_test_app_key");

    await onboardingFlows.createFirstWallet(walletType);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    final existingName = getIt.get<AppStore>().wallet!.name;

    await dashboardRobot.openWalletsTab();

    await onboardingFlows.startCreatingWalletFromWalletList(walletType);

    await newWalletPageRobot.enterWalletName(existingName);
    await newWalletPageRobot.onNextButtonPressed();

    await newWalletPageRobot.expectNameRejected();
  });
}
