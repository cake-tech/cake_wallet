import "package:cw_core/wallet_type.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../core/test_wallets.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";
import "../../robots/new_send_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Send screen refuses what it cannot send", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final sendRobot = NewSendPageRobot(tester);

    const walletType = WalletType.solana;

    await appLauncher.launchApp(testKey: "send_validation_test_app_key");

    await onboardingFlows.createFirstWallet(walletType);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    await homePageRobot.openSendSheet();
    await sendRobot.isDisplayed();

    // test that nothing happens when there's no address or amount filled in
    await sendRobot.tapSendButton();
    await sendRobot.expectNoTransactionBuilt();

    // test that no transaction is built when the address is wrong or cannot be parsed
    await sendRobot.enterAddress("not-a-real-address");
    await sendRobot.enterAmount("0.0001");
    await sendRobot.tapSendButton();

    await sendRobot.expectNoTransactionBuilt();

    // test that no transaction is built even if the address is valid but no balance
    await sendRobot.enterAddress(TestWallets.receiveAddressFor(walletType));
    await sendRobot.enterAmount("0.0001");
    await sendRobot.tapSendButton();

    await sendRobot.expectNoTransactionBuilt();

    await sendRobot.dismissModal();
    await homePageRobot.isDisplayed();
  });
}
