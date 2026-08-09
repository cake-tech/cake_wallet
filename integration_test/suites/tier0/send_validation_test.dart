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

    // A wallet created here has never held anything, which is the point, nothing this suite
    // does can move funds even if an assertion is wrong.
    await onboardingFlows.createFirstWallet(walletType);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    await homePageRobot.openSendSheet();
    await sendRobot.isDisplayed();

    // Nothing filled in. The form validator rejects it before the screen builds anything, and
    // with a single recipient it says so on the field rather than in a dialog, so what
    // matters here is that no transaction comes out of it.
    await sendRobot.tapSendButton();
    await sendRobot.expectNoTransactionBuilt();

    // test that no transaction is built when the address is wrong or cannot be parsed
    await sendRobot.enterAddress("not-a-real-address");
    await sendRobot.enterAmount("0.0001");
    await sendRobot.tapSendButton();

    await sendRobot.expectNoTransactionBuilt();

    // Nothing has ever been in this wallet. Whether it is still counting or has counted and
    // come up short, the screen has to stop here and say which.
    await sendRobot.enterAddress(TestWallets.receiveAddressFor(walletType));
    await sendRobot.enterAmount("0.0001");
    await sendRobot.tapSendButton();

    await sendRobot.expectNoTransactionBuilt();

    await sendRobot.dismissModal();
    await homePageRobot.isDisplayed();
  });
}
