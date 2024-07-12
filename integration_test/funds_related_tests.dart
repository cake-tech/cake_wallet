import 'package:cake_wallet/main.dart' as app;
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'robots/auth_page_robot.dart';
import 'robots/dashboard_page_robot.dart';
import 'robots/disclaimer_page_robot.dart';
import 'robots/exchange_confirm_page_robot.dart';
import 'robots/exchange_page_robot.dart';
import 'robots/exchange_trade_page_robot.dart';
import 'robots/new_wallet_type_page_robot.dart';
import 'robots/restore_from_seed_or_key_robot.dart';
import 'robots/restore_options_page_robot.dart';
import 'robots/setup_pin_code_robot.dart';
import 'robots/welcome_page_robot.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  DisclaimerPageRobot disclaimerPageRobot;
  WelcomePageRobot welcomePageRobot;
  SetupPinCodeRobot setupPinCodeRobot;
  RestoreOptionsPageRobot restoreOptionsPageRobot;
  NewWalletTypePageRobot newWalletTypePageRobot;
  RestoreFromSeedOrKeysPageRobot restoreFromSeedOrKeysPageRobot;
  DashboardPageRobot dashboardPageRobot;
  ExchangePageRobot exchangePageRobot;
  ExchangeConfirmPageRobot exchangeConfirmPageRobot;
  AuthPageRobot authPageRobot;
  ExchangeTradePageRobot exchangeTradePageRobot;

  group('Startup Test', () {
    testWidgets('Test for Exchange flow using Restore Wallet - Exchanging USDT(Sol) to SOL',
        (tester) async {
      authPageRobot = AuthPageRobot(tester);
      welcomePageRobot = WelcomePageRobot(tester);
      exchangePageRobot = ExchangePageRobot(tester);
      setupPinCodeRobot = SetupPinCodeRobot(tester);
      dashboardPageRobot = DashboardPageRobot(tester);
      disclaimerPageRobot = DisclaimerPageRobot(tester);
      exchangeTradePageRobot = ExchangeTradePageRobot(tester);
      newWalletTypePageRobot = NewWalletTypePageRobot(tester);
      restoreOptionsPageRobot = RestoreOptionsPageRobot(tester);
      exchangeConfirmPageRobot = ExchangeConfirmPageRobot(tester);
      restoreFromSeedOrKeysPageRobot = RestoreFromSeedOrKeysPageRobot(tester);

      final pin = [0, 8, 0, 1];

      // String testAmount = '0.08';
      String testAmount = '8';
      CryptoCurrency testReceiveCurrency = CryptoCurrency.sol;
      CryptoCurrency testDepositCurrency = CryptoCurrency.usdtSol;

      WalletType testWalletType = WalletType.solana;
      String testWalletName = 'Integrated Testing Wallet';
      String testWalletAddress = 'An2Y2fsUYKfYvN1zF89GAqR1e6GUMBg3qA83Y5ZWDf8L';

      await app.main();
      await tester.pumpAndSettle();

      // --------- Disclaimer Page ------------
      // Tap checkbox to accept disclaimer
      await disclaimerPageRobot.tapDisclaimerCheckbox();

      // Tap accept button
      await disclaimerPageRobot.tapAcceptButton();

      // --------- Welcome Page ---------------
      await welcomePageRobot.navigateToRestoreWalletPage();

      // ----------- Restore Options Page -----------
      // Route to restore from seeds page to continue flow
      await restoreOptionsPageRobot.navigateToRestoreFromSeedsPage();

      // ----------- SetupPinCode Page -------------
      // Confirm initial defaults - Widgets to be displayed etc
      await setupPinCodeRobot.isSetupPinCodePage();

      await setupPinCodeRobot.enterPinCode(pin, true);
      await setupPinCodeRobot.enterPinCode(pin, false);
      await setupPinCodeRobot.tapSuccessButton();

      // ----------- NewWalletType Page -------------
      // Confirm scroll behaviour works properly
      await newWalletTypePageRobot.findParticularWalletTypeInScrollableList(WalletType.solana);

      // Select a wallet and route to next page
      await newWalletTypePageRobot.selectWalletType(testWalletType);
      await newWalletTypePageRobot.onNextButtonPressed();

      // ----------- RestoreFromSeedOrKeys Page -------------
      await restoreFromSeedOrKeysPageRobot.enterWalletNameText(testWalletName);
      await restoreFromSeedOrKeysPageRobot.enterSeedPhraseForWalletRestore(secrets.seeds);
      await restoreFromSeedOrKeysPageRobot.onRestoreWalletButtonPressed();

      // ----------- RestoreFromSeedOrKeys Page -------------
      await dashboardPageRobot.navigateToExchangePage();

      // ----------- Exchange Page -------------
      await exchangePageRobot.isExchangePage();
      exchangePageRobot.hasResetButton();
      await exchangePageRobot.displayBothExchangeCards();
      exchangePageRobot.confirmRightComponentsDisplayOnDepositExchangeCards();
      exchangePageRobot.confirmRightComponentsDisplayOnReceiveExchangeCards();

      await exchangePageRobot.selectDepositCurrency(testDepositCurrency);
      await exchangePageRobot.selectReceiveCurrency(testReceiveCurrency);

      await exchangePageRobot.enterDepositAmount(testAmount);
      await exchangePageRobot.enterDepositRefundAddress(depositAddress: testWalletAddress);

      await exchangePageRobot.enterReceiveAddress(testWalletAddress);

      await exchangePageRobot.onExchangeButtonPressed();

      await exchangePageRobot.handleErrors(testAmount);

      final onAuthPage = authPageRobot.onAuthPage();
      if (onAuthPage) {
        await authPageRobot.enterPinCode(pin, false);
      }

      // ----------- Exchange Confirm Page -------------
      await exchangeConfirmPageRobot.isExchangeConfirmPage();

      exchangeConfirmPageRobot.confirmComponentsOfTradeDisplayProperly();
      await exchangeConfirmPageRobot.confirmCopyTradeIdToClipBoardWorksProperly();
      await exchangeConfirmPageRobot.onSavedTradeIdButtonPressed();

      // ----------- Exchange Trade Page -------------
      await exchangeTradePageRobot.isExchangeTradePage();
      exchangeTradePageRobot.hasInformationDialog();
      await exchangeTradePageRobot.onGotItButtonPressed();

      await exchangeTradePageRobot.onConfirmSendingButtonPressed();

      await exchangeTradePageRobot.handleSendSuccessOrFailure();

      await exchangeTradePageRobot.onSendButtonOnConfirmSendingDialogPressed();
    });
  });
}
