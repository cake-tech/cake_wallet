import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";
import "../../robots/new_receive_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Receive sheet shows the opened wallet's own address", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final receiveRobot = NewReceivePageRobot(tester);

    const walletType = WalletType.solana;

    await appLauncher.launchApp(testKey: "receive_address_test_app_key");

    // Restoring a known seed keeps the derived address deterministic across runs.
    await onboardingFlows.restoreFirstWalletFromSeed(walletType);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    final expectedAddress = getIt.get<AppStore>().wallet!.walletAddresses.address;
    expect(expectedAddress.isNotEmpty, true);

    await homePageRobot.openReceiveSheet();

    await receiveRobot.isDisplayed();
    await receiveRobot.confirmAddressMatches(expectedAddress);

    await receiveRobot.dismissModal();
    await homePageRobot.isDisplayed();
  });
}
