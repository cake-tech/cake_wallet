import "package:cake_wallet/routes.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/manage_nodes_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";
import "../../robots/new_settings_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // tier1 because the node list is speed tested against the live nodes as soon as the page
  // opens, so this needs the network even though switching itself is local.
  integrationTest("Switching nodes changes which one the wallet is pointed at", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final settingsRobot = NewSettingsPageRobot(tester);
    final nodesRobot = ManageNodesPageRobot(tester);

    await appLauncher.launchApp(testKey: "node_switching_test_app_key");

    await onboardingFlows.createFirstWallet(WalletType.solana);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    await homePageRobot.openSettingsSheet();
    await settingsRobot.isDisplayed();

    await settingsRobot.openRow(Routes.manageNodes);
    await nodesRobot.isDisplayed();

    final before = nodesRobot.currentNodeUri();

    expect(before, isNotEmpty, reason: "The wallet started with no node at all");

    await nodesRobot.switchToAnotherNode();

    // Which node a wallet talks to decides what it sees, so a switch that quietly does not
    // take leaves the user on a node they think they left.
    expect(
      nodesRobot.currentNodeUri(),
      isNot(before),
      reason: "The node was confirmed but the wallet is still pointed at $before",
    );
  });
}
