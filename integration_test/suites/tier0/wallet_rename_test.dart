import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";
import "../../robots/wallet_edit_page_robot.dart";
import "../../robots/wallet_list_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("A wallet can be renamed, but not onto a name already in use", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);
    final walletListRobot = WalletListPageRobot(tester);
    final walletEditRobot = WalletEditPageRobot(tester);

    const renamedTo = "Renamed Test Wallet";

    await appLauncher.launchApp(testKey: "wallet_rename_test_app_key");

    await onboardingFlows.createFirstWallet(WalletType.solana);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    final appStore = getIt.get<AppStore>();
    final renamedWallet = appStore.wallet!.name;

    // The wallet you are in has no edit button, so a second wallet has to be opened before
    // the first one can be edited at all.
    await dashboardRobot.openWalletsTab();
    await onboardingFlows.createAdditionalWalletFromWalletList(WalletType.ethereum);

    await homePageRobot.isDisplayed();

    final openWallet = appStore.wallet!.name;

    expect(openWallet, isNot(renamedWallet), reason: "The second wallet never became the open one");

    await dashboardRobot.openWalletsTab();
    await walletListRobot.isDisplayed();

    await walletListRobot.openEditFor(renamedWallet);
    await walletEditRobot.isDisplayed();

    // Two wallets under one name is what the check exists to stop, since the name is how
    // every screen after this tells them apart.
    await walletEditRobot.enterName(openWallet);
    await walletEditRobot.save();

    await walletEditRobot.expectNameTakenRefusal();
    await walletEditRobot.dismissNameTakenRefusal();

    await walletEditRobot.enterName(renamedTo);
    await walletEditRobot.save();

    await walletListRobot.isDisplayed();

    final renamed = await walletListRobot.pumpUntil(() => walletListRobot.hasWallet(renamedTo));

    expect(renamed, true, reason: "The list never showed $renamedTo after the rename was saved");

    expect(
      walletListRobot.hasWallet(renamedWallet),
      false,
      reason: "The list still shows $renamedWallet next to the name it was renamed to",
    );

    final stored = await WalletInfo.getAll();
    final names = stored.map((wallet) => wallet.name).toList();

    expect(names, contains(renamedTo));
    expect(names, isNot(contains(renamedWallet)));

    expect(
      appStore.wallet?.name,
      openWallet,
      reason: "Renaming another wallet changed which one is open",
    );
  });
}
