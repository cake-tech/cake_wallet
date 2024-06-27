import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/exchange/exchange_page.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/exchange_card.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/present_provider_picker.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../components/common_checks.dart';

class ExchangePageRobot {
  ExchangePageRobot(this.tester) : commonTestCases = CommonTestCases(tester);

  final WidgetTester tester;
  late CommonTestCases commonTestCases;

  Future<void> isExchangePage() async {
    await commonTestCases.isSpecificPage<ExchangePage>();
  }

  void hasTitle() {
    // commonTestCases.hasText(S.current.exchange);
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

    await commonTestCases.scrollUntilVisible(
      'picker_items_index_${depositCurrency.name}_button_key',
      'picker_scrollbar_key',
    );
    await commonTestCases.defaultSleepTime();

    await commonTestCases.tapItemByKey('picker_items_index_${depositCurrency.name}_button_key');
    await commonTestCases.defaultSleepTime();
  }

  Future<void> selectReceiveCurrency(CryptoCurrency receiveCurrency) async {
    final receivePrefix = 'receive_exchange_card';
    final currencyPickerKey = '${receivePrefix}_currency_picker_button_key';
    final currencyPickerDialogKey = '${receivePrefix}_currency_picker_dialog_button_key';

    await commonTestCases.tapItemByKey(currencyPickerKey);

    commonTestCases.hasValueKey(currencyPickerDialogKey);

    await commonTestCases.scrollUntilVisible(
      'picker_items_index_${receiveCurrency.name}_button_key',
      'picker_scrollbar_key',
    );
    await commonTestCases.defaultSleepTime();

    await commonTestCases.tapItemByKey('picker_items_index_${receiveCurrency.name}_button_key');
    await commonTestCases.defaultSleepTime();
  }

  Future<void> enterDepositAddress(String depositAddress) async {
    final amountTextField = find.byKey(ValueKey('deposit_exchange_card_amount_textfield_key'));
  }

  Future<void> enterReceiveAddress(String receiveAddress) async {}
}
