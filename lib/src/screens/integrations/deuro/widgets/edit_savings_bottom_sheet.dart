import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/receive/widgets/currency_input_field.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/view_model/integrations/deuro_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class EditSavingsBottomSheet extends BaseBottomSheet {
  EditSavingsBottomSheet(this.dEuroViewModel, {required super.titleText});

  final _amountController = TextEditingController();
  final DEuroViewModel dEuroViewModel;

  @override
  Widget contentWidget(BuildContext context) => Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: CurrencyAmountTextField(
              hasUnderlineBorder: true,
              borderWidth: 1.0,
              selectedCurrency: CryptoCurrency.deuro.name.toUpperCase(),
              amountFocusNode: null,
              amountController: _amountController,
              tag: CryptoCurrency.deuro.tag,
              isAmountEditable: true,
            ),
          ),
        ],
      );

  @override
  Widget footerWidget(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
        child: LoadingPrimaryButton(
          onPressed: () => dEuroViewModel.prepareSavingsEdit(_amountController.text, true),
          text: S.of(context).confirm,
          color: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
          isLoading: false,
          isDisabled: false,
        ),
      );
}
