import "package:cw_core/wallet_type.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../core/test_wallets.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/contact_robot.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("A saved contact keeps the address it was given", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final contactRobot = ContactRobot(tester);

    const contactName = "Integration Test Contact";
    final contactAddress = TestWallets.receiveAddressFor(WalletType.solana);

    await appLauncher.launchApp(testKey: "address_book_test_app_key");

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

    contactRobot.expectContactSaved(contactName, contactAddress);
  });
}
