import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../core/app_launcher.dart";
import "../core/funds_outcome.dart";
import "../core/test_config.dart";
import "../core/test_wallets.dart";
import "../flows/auth_flows.dart";
import "../flows/funds_flows.dart";
import "../robots/home_page_robot.dart";
import "../robots/new_send_page_robot.dart";
import "../robots/new_swap_page_robot.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  integrationTest("Create a real swap and broadcast its deposit", (tester) async {
    final appLauncher = AppLauncher(tester);
    final fundsFlows = FundsFlows(tester);
    final authFlows = AuthFlows(tester);
    final homePageRobot = HomePageRobot(tester);
    final sendRobot = NewSendPageRobot(tester);
    final swapRobot = NewSwapPageRobot(tester);

    if (!TestConfig.shouldSpend("swap")) {
      tester.printToConsole("FLOWS excludes swap, skipping");
      return;
    }

    final walletTypes = TestConfig.fundedWalletTypesUnderTest;

    expect(walletTypes.isNotEmpty, true, reason: "No funded wallet seeds configured");

    final type = TestConfig.swapDepositType(walletTypes);

    expect(
      walletTypes,
      contains(type),
      reason: "SWAP_FROM=${type.name} is not among the funded wallets under test",
    );

    await appLauncher.launchApp(testKey: "swap_funds_test_app_key");

    final opened = await fundsFlows.openFundedWallet(type);

    expect(
      opened,
      true,
      reason: "${type.name}: none of the ${TestWallets.fundedWalletsFor(type).length} funded "
          "wallets has a spendable balance, top them up before the next run",
    );

    final appStore = getIt.get<AppStore>();
    expect(appStore.wallet?.type, type);

    await homePageRobot.openSwapSheet();
    await swapRobot.isDisplayed();

    if (TestConfig.swapReceive.isNotEmpty) {
      await swapRobot.chooseReceiveCurrency(CryptoCurrency.fromString(TestConfig.swapReceive));
    }

    await swapRobot.enterMinimumViableDepositAmount();
    final payoutAddress = await swapRobot.enterTestReceiveAddress();
    await swapRobot.confirmQuoteReceived();
    await swapRobot.confirmSwapButtonEnabled();

    await swapRobot.tapSwapButton();

    await authFlows.authenticateWithPin(required: false);

    await swapRobot.confirmTradeCreated();
    swapRobot.confirmPayoutAddress(payoutAddress);

    await sendRobot.swipeToConfirm();
    await swapRobot.confirmDepositCommitted();

    await homePageRobot.isDisplayed();

    tester.printToConsole("FUNDS_SWAP_OK: ${type.name}");
    FundsOutcome.ok(tester, type.name, "trade created and deposit broadcast");
  });
}
