import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../core/test_wallets.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/contact_robot.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";
import "../../robots/new_send_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("A contact picked on the send screen fills in its own address", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final contactRobot = ContactRobot(tester);
    final sendRobot = NewSendPageRobot(tester);

    const contactName = "Send Book Contact";
    final contactAddress = TestWallets.receiveAddressFor(WalletType.solana);

    await appLauncher.launchApp(testKey: "send_from_address_book_test_app_key");

    await onboardingFlows.createFirstWallet(WalletType.solana);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    await dashboardRobot.openContactsTab();
    await contactRobot.isDisplayed();

    await contactRobot.openAddContact();
    await contactRobot.enterName(contactName);
    await contactRobot.chooseCurrency("sol");
    await contactRobot.enterAddress(contactAddress);
    await contactRobot.save();

    await contactRobot.isDisplayed();

    await dashboardRobot.openHomeTab();
    await homePageRobot.isDisplayed();

    await homePageRobot.openSendSheet();
    await sendRobot.isDisplayed();

    await sendRobot.pickContactFromAddressBook(contactName);

    expect(
      sendRobot.enteredAddress(),
      contactAddress,
      reason: "The send screen was filled with an address the contact does not hold",
    );
  });
}
