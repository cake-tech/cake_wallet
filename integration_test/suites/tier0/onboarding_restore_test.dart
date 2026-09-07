import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../core/test_config.dart";
import "../../core/test_wallets.dart";
import "../../flows/onboarding_flows.dart";
import "../../robots/home_page_robot.dart";
import "../../robots/new_dashboard_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Restore a wallet from seed for each configured wallet type", (tester) async {
    final appLauncher = AppLauncher(tester);
    final onboardingFlows = OnboardingFlows(tester);
    final dashboardRobot = NewDashboardRobot(tester);
    final homePageRobot = HomePageRobot(tester);

    await appLauncher.launchApp(testKey: "onboarding_restore_test_app_key");

    final walletTypes = TestConfig.walletTypesUnderTest;
    final firstType = walletTypes.first;

    tester.printToConsole("Restoring first wallet: ${firstType.name}");

    await onboardingFlows.restoreFirstWalletFromSeed(firstType);

    await dashboardRobot.isDisplayed();
    await homePageRobot.isDisplayed();

    final appStore = getIt.get<AppStore>();
    expect(appStore.wallet?.type, firstType);

    await homePageRobot.hasWalletName(appStore.wallet!.name);

    await _expectRestoredTheRightWallet(homePageRobot, appStore, firstType);

    for (final type in walletTypes.skip(1)) {
      tester.printToConsole("Restoring additional wallet: ${type.name}");

      await dashboardRobot.openWalletsTab();

      await onboardingFlows.restoreAdditionalWalletFromWalletList(type);

      await dashboardRobot.isDisplayed();
      await homePageRobot.isDisplayed();

      expect(appStore.wallet?.type, type);

      await homePageRobot.hasWalletName(appStore.wallet!.name);

      await _expectRestoredTheRightWallet(homePageRobot, appStore, type);
    }
  });
}

Future<void> _expectRestoredTheRightWallet(
  HomePageRobot robot,
  AppStore appStore,
  WalletType type,
) async {
  final expectedAddress = TestWallets.receiveAddressFor(type);

  if (expectedAddress.isEmpty) {
    robot.tester.printToConsole("No known address for ${type.name}, derivation not verified");
    return;
  }

  final settled = await robot.pumpUntil(
    () {
      final addresses = appStore.wallet?.walletAddresses;

      if (addresses == null) {
        return false;
      }

      return addresses.address == expectedAddress ||
          addresses.addressesMap.containsKey(expectedAddress) ||
          addresses.allAddressesMap.containsKey(expectedAddress);
    },
    timeout: const Duration(seconds: 60),
  );

  expect(
    settled,
    true,
    reason: "${type.name} restored from a known seed derived "
        "${appStore.wallet?.walletAddresses.address} and does not know $expectedAddress",
  );
}
