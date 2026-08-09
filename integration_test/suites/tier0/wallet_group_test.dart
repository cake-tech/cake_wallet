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

  integrationTest("A wallet added to an existing seed shares it and both stay reachable",
      (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final walletFlows = WalletFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);

    // A group is one seed across different chains. The page deliberately hides wallets of the
    // type being created, since the same seed cannot back two wallets of one type.
    const firstType = WalletType.solana;
    const secondType = WalletType.ethereum;

    await appLauncher.launchApp(testKey: "wallet_group_test_app_key");

    await onboardingFlows.createFirstWallet(firstType);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    final appStore = getIt.get<AppStore>();
    final firstWalletName = appStore.wallet!.name;
    final sharedSeed = appStore.wallet!.seed;

    expect(sharedSeed, isNotNull, reason: "The first wallet has no seed to share");

    await dashboardRobot.openWalletsTab();

    await onboardingFlows.createWalletInGroupOf(secondType, firstWalletName);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    final secondWalletName = appStore.wallet!.name;

    expect(
      secondWalletName,
      isNot(firstWalletName),
      reason: "Adding to a group opened the wallet that was already there",
    );

    expect(appStore.wallet?.type, secondType);

    // Sharing the seed is what makes it a group rather than two unrelated wallets, and it is
    // the part that would silently be wrong if the wrong mnemonic were passed along.
    expect(
      appStore.wallet!.seed,
      sharedSeed,
      reason: "The wallet added to the group derived its own seed instead of sharing one",
    );

    // Both are now under one group in the list, so the first is only reachable by opening
    // that group. This is the path a wallet outside a group never exercises.
    await walletFlows.switchToWallet(firstWalletName);

    await homePageRobot.isDisplayed();
    await homePageRobot.hasWalletName(firstWalletName);

    expect(appStore.wallet?.seed, sharedSeed);
  });
}
