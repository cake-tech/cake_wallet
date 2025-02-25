import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/exchange/exchange_page.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/present_provider_picker.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../components/common_test_cases.dart';

class ExchangePageRobot {
  ExchangePageRobot(this.tester) : commonTestCases = CommonTestCases(tester);

  final WidgetTester tester;
  late CommonTestCases commonTestCases;

  Future<void> isExchangePage() async {
    await commonTestCases.isSpecificPage<ExchangePage>();
    await commonTestCases.defaultSleepTime();
  }

  void hasResetButton() {
    commonTestCases.hasText(S.current.reset);
  }

  void displaysPresentProviderPicker() {
    commonTestCases.hasType<PresentProviderPicker>();
  }

  Future<void> displayBothExchangeCards() async {
    final ExchangePage exchangeCard = tester.widget<ExchangePage>(
      find.byType(ExchangePage),
    );

    final depositKey = exchangeCard.depositKey;
    final receiveKey = exchangeCard.receiveKey;

    final depositExchangeCard = find.byKey(depositKey);
    expect(depositExchangeCard, findsOneWidget);

    final receiveExchangeCard = find.byKey(receiveKey);
    expect(receiveExchangeCard, findsOneWidget);
  }

  void confirmRightComponentsDisplayOnDepositExchangeCards() {
    ExchangePage exchangePage = tester.widget(find.byType(ExchangePage));
    final exchangeViewModel = exchangePage.exchangeViewModel;
    final depositCardPrefix = 'deposit_exchange_card';

    commonTestCases.hasValueKey('${depositCardPrefix}_title_key');
    commonTestCases.hasValueKey('${depositCardPrefix}_currency_picker_button_key');
    commonTestCases.hasValueKey('${depositCardPrefix}_selected_currency_text_key');
    commonTestCases.hasValueKey('${depositCardPrefix}_amount_textfield_key');

    exchangePage.depositKey.currentState!.changeLimits(min: '0.1');

    commonTestCases.hasValueKey('${depositCardPrefix}_min_limit_text_key');

    final initialCurrency = exchangeViewModel.depositCurrency;
    if (initialCurrency.tag != null) {
      commonTestCases.hasValueKey('${depositCardPrefix}_selected_currency_tag_text_key');
    }

    if (exchangeViewModel.hasAllAmount) {
      commonTestCases.hasValueKey('${depositCardPrefix}_send_all_button_key');
    }

    if (exchangeViewModel.isMoneroWallet) {
      commonTestCases.hasValueKey('${depositCardPrefix}_address_book_button_key');
    }

    if (exchangeViewModel.isDepositAddressEnabled) {
      commonTestCases.hasValueKey('${depositCardPrefix}_editable_address_textfield_key');
    } else {
      commonTestCases.hasValueKey('${depositCardPrefix}_non_editable_address_textfield_key');
      commonTestCases.hasValueKey('${depositCardPrefix}_copy_refund_address_button_key');
    }

    //  commonTestCases.hasValueKey('${depositCardPrefix}_max_limit_text_key');
  }

  void confirmRightComponentsDisplayOnReceiveExchangeCards() {
    ExchangePage exchangePage = tester.widget(find.byType(ExchangePage));
    final exchangeViewModel = exchangePage.exchangeViewModel;
    final receiveCardPrefix = 'receive_exchange_card';

    commonTestCases.hasValueKey('${receiveCardPrefix}_title_key');
    commonTestCases.hasValueKey('${receiveCardPrefix}_currency_picker_button_key');
    commonTestCases.hasValueKey('${receiveCardPrefix}_selected_currency_text_key');
    commonTestCases.hasValueKey('${receiveCardPrefix}_amount_textfield_key');
    commonTestCases.hasValueKey('${receiveCardPrefix}_min_limit_text_key');

    final initialCurrency = exchangeViewModel.receiveCurrency;
    if (initialCurrency.tag != null) {
      commonTestCases.hasValueKey('${receiveCardPrefix}_selected_currency_tag_text_key');
    }

    if (exchangeViewModel.hasAllAmount) {
      commonTestCases.hasValueKey('${receiveCardPrefix}_send_all_button_key');
    }

    if (exchangeViewModel.isMoneroWallet) {
      commonTestCases.hasValueKey('${receiveCardPrefix}_address_book_button_key');
    }

    commonTestCases.hasValueKey('${receiveCardPrefix}_editable_address_textfield_key');
  }

  Future<void> selectDepositCurrency(CryptoCurrency depositCurrency) async {
    final depositPrefix = 'deposit_exchange_card';
    final currencyPickerKey = '${depositPrefix}_currency_picker_button_key';
    final currencyPickerDialogKey = '${depositPrefix}_currency_picker_dialog_button_key';

    await commonTestCases.tapItemByKey(currencyPickerKey);
    commonTestCases.hasValueKey(currencyPickerDialogKey);

    ExchangePage exchangePage = tester.widget(find.byType(ExchangePage));
    final exchangeViewModel = exchangePage.exchangeViewModel;

    if (depositCurrency == exchangeViewModel.depositCurrency) {
      await commonTestCases.defaultSleepTime();
      await commonTestCases
          .tapItemByKey('picker_items_index_${depositCurrency.name}_selected_item_button_key');
      return;
    }

    await commonTestCases.enterText(depositCurrency.name, 'search_bar_widget_key');

    await commonTestCases.defaultSleepTime();

    await commonTestCases.tapItemByKey('picker_items_index_${depositCurrency.name}_button_key');
  }

  Future<void> selectReceiveCurrency(CryptoCurrency receiveCurrency) async {
    final receivePrefix = 'receive_exchange_card';
    final currencyPickerKey = '${receivePrefix}_currency_picker_button_key';
    final currencyPickerDialogKey = '${receivePrefix}_currency_picker_dialog_button_key';

    await commonTestCases.tapItemByKey(currencyPickerKey);
    commonTestCases.hasValueKey(currencyPickerDialogKey);

    ExchangePage exchangePage = tester.widget(find.byType(ExchangePage));
    final exchangeViewModel = exchangePage.exchangeViewModel;

    if (receiveCurrency == exchangeViewModel.receiveCurrency) {
      await commonTestCases
          .tapItemByKey('picker_items_index_${receiveCurrency.name}_selected_item_button_key');
      return;
    }

    await commonTestCases.enterText(receiveCurrency.name, 'search_bar_widget_key');

    await commonTestCases.defaultSleepTime();

    await commonTestCases.tapItemByKey('picker_items_index_${receiveCurrency.name}_button_key');
  }

  Future<void> enterDepositAmount(String amount) async {
    await commonTestCases.enterText(amount, 'deposit_exchange_card_amount_textfield_key');
  }

  Future<void> enterDepositRefundAddress({String? depositAddress}) async {
    ExchangePage exchangePage = tester.widget(find.byType(ExchangePage));
    final exchangeViewModel = exchangePage.exchangeViewModel;

    if (exchangeViewModel.isDepositAddressEnabled && depositAddress != null) {
      await commonTestCases.enterText(
          depositAddress, 'deposit_exchange_card_editable_address_textfield_key');
    }
  }

  Future<void> enterReceiveAddress(String receiveAddress) async {
    await commonTestCases.enterText(
      receiveAddress,
      'receive_exchange_card_editable_address_textfield_key',
    );
    await commonTestCases.defaultSleepTime();
  }

  Future<void> onExchangeButtonPressed() async {
    await commonTestCases.tapItemByKey('exchange_page_exchange_button_key');
    await commonTestCases.defaultSleepTime();
  }

  bool hasMaxLimitError() {
    final maxErrorText = find.text(S.current.error_text_input_above_maximum_limit);

    bool hasMaxError = maxErrorText.tryEvaluate();

    return hasMaxError;
  }

  bool hasMinLimitError() {
    final minErrorText = find.text(S.current.error_text_input_below_minimum_limit);

    bool hasMinError = minErrorText.tryEvaluate();

    return hasMinError;
  }

  bool hasTradeCreationFailureError() {
    final tradeCreationFailureDialogButton =
        find.byKey(ValueKey('exchange_page_trade_creation_failure_dialog_button_key'));

    bool hasTradeCreationFailure = tradeCreationFailureDialogButton.tryEvaluate();
    tester.printToConsole('Trade not created error: $hasTradeCreationFailure');
    return hasTradeCreationFailure;
  }

  Future<void> onTradeCreationFailureDialogButtonPressed() async {
    await commonTestCases.tapItemByKey('exchange_page_trade_creation_failure_dialog_button_key');
  }

  /// Handling Trade Failure Errors or errors shown through the Failure Dialog.
  ///
  /// Simulating the user's flow and response when this error comes up.
  /// Examples are:
  /// - No provider can handle this trade error,
  /// - Trade amount below limit error.
  Future<void> _handleTradeCreationFailureErrors() async {
    bool isTradeCreationFailure = false;

    isTradeCreationFailure = hasTradeCreationFailureError();

    int maxRetries = 20;
    int retries = 0;

    while (isTradeCreationFailure && retries < maxRetries) {
      await tester.pump();

      await onTradeCreationFailureDialogButtonPressed();

      await commonTestCases.defaultSleepTime(seconds: 5);

      await onExchangeButtonPressed();

      isTradeCreationFailure = hasTradeCreationFailureError();
      retries++;
    }
  }

  /// Handles the min limit error.
  ///
  /// Simulates the user's flow and response when it comes up.
  ///
  /// Has a max retry of 20 times.
  Future<void> _handleMinLimitError(String initialAmount) async {
    bool isMinLimitError = false;

    isMinLimitError = hasMinLimitError();

    double amount;

    amount = double.parse(initialAmount);

    int maxRetries = 20;
    int retries = 0;

    while (isMinLimitError && retries < maxRetries) {
      amount++;
      tester.printToConsole('Amount: $amount');

      enterDepositAmount(amount.toString());

      await commonTestCases.defaultSleepTime();

      await onExchangeButtonPressed();

      isMinLimitError = hasMinLimitError();

      retries++;
    }

    if (retries >= maxRetries) {
      tester.printToConsole('Max retries reached for minLimit Error. Exiting loop.');
    }
  }

  /// Handles the max limit error.
  ///
  /// Simulates the user's flow and response when it comes up.
  ///
  /// Has a max retry of 20 times.
  Future<void> _handleMaxLimitError(String initialAmount) async {
    bool isMaxLimitError = false;

    isMaxLimitError = hasMaxLimitError();

    double amount;

    amount = double.parse(initialAmount);

    int maxRetries = 20;
    int retries = 0;

    while (isMaxLimitError && retries < maxRetries) {
      amount++;
      tester.printToConsole('Amount: $amount');

      enterDepositAmount(amount.toString());

      await commonTestCases.defaultSleepTime();

      await onExchangeButtonPressed();

      isMaxLimitError = hasMaxLimitError();

      retries++;
    }

    if (retries >= maxRetries) {
      tester.printToConsole('Max retries reached for maxLimit Error. Exiting loop.');
    }
  }

  Future<void> handleErrors(String initialAmount) async {
    await tester.pumpAndSettle();

    await _handleMinLimitError(initialAmount);

    await _handleMaxLimitError(initialAmount);

    await _handleTradeCreationFailureErrors();

    await commonTestCases.defaultSleepTime();
  }
}
