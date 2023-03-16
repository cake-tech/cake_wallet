import 'package:cake_wallet/core/email_validator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/src/screens/receive/widgets/anonpay_currency_input_field.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/anon_invoice_page_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class AnonInvoiceForm extends StatelessWidget {
  AnonInvoiceForm({
    super.key,
    required this.formKey,
    required this.anonInvoicePageViewModel,
    required this.isInvoice,
  })  : _nameController = TextEditingController(),
        _amountController = TextEditingController(),
        _emailController = TextEditingController(),
        _descriptionController = TextEditingController() {
    _nameController.text = anonInvoicePageViewModel.receipientName;
    _descriptionController.text = anonInvoicePageViewModel.description;
    _emailController.text = anonInvoicePageViewModel.receipientEmail;  
    _nameController.addListener(() {
      anonInvoicePageViewModel.receipientName = _nameController.text;
    });
    _amountController.addListener(() {
      anonInvoicePageViewModel.amount = _amountController.text;
    });
    _emailController.addListener(() {
      anonInvoicePageViewModel.receipientEmail = _emailController.text;
    });
    _descriptionController.addListener(() {
      anonInvoicePageViewModel.description = _descriptionController.text;
    });
  }

  final TextEditingController _amountController;
  final TextEditingController _nameController;
  final TextEditingController _emailController;
  final TextEditingController _descriptionController;
  final AnonInvoicePageViewModel anonInvoicePageViewModel;
  final _depositAmountFocus = FocusNode();
  final GlobalKey<FormState> formKey;
  final bool isInvoice;

  @override
  Widget build(BuildContext context) {
    return Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              isInvoice ? S.of(context).invoice_details : S.of(context).donation_link_details,
              style: textMediumSemiBold(),
            ),
            if (isInvoice)
              Observer(builder: (_) {
                return AnonpayCurrencyInputField(
                  onTapPicker: () => _presentPicker(context),
                  controller: _amountController,
                  focusNode: _depositAmountFocus,
                  maxAmount: anonInvoicePageViewModel.maximum?.toString() ?? '...',
                  minAmount: anonInvoicePageViewModel.minimum?.toString() ?? '...',
                  selectedCurrency: anonInvoicePageViewModel.selectedCurrency,
                );
              }),
            SizedBox(
              height: 24,
            ),
            BaseTextFormField(
              controller: _nameController,
              borderColor: Theme.of(context).accentTextTheme.headline6!.backgroundColor,
              suffixIcon: SizedBox(width: 36),
              hintText: S.of(context).optional_name,
              placeholderTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).accentTextTheme.headline1!.decorationColor!,
              ),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              validator: null,
            ),
            SizedBox(
              height: 24,
            ),
            BaseTextFormField(
              controller: _descriptionController,
              borderColor: Theme.of(context).accentTextTheme.headline6!.backgroundColor,
              suffixIcon: SizedBox(width: 36),
              hintText: S.of(context).optional_description,
              placeholderTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).accentTextTheme.headline1!.decorationColor!,
              ),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              validator: null,
            ),
            SizedBox(height: 24),
            BaseTextFormField(
              controller: _emailController,
              borderColor: Theme.of(context).accentTextTheme.headline6!.backgroundColor,
              suffixIcon: SizedBox(width: 36),
              keyboardType: TextInputType.emailAddress,
              hintText: S.of(context).optional_email_hint,
              placeholderTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).accentTextTheme.headline1!.decorationColor!,
              ),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              validator: EmailValidator(),
            ),
            SizedBox(
              height: 52,
            ),
          ],
        ));
  }

  void _presentPicker(BuildContext context) {
    showPopUp<void>(
      builder: (_) => CurrencyPicker(
        selectedAtIndex: anonInvoicePageViewModel.selectedCurrencyIndex,
        items: anonInvoicePageViewModel.currencies,
        hintText: S.of(context).search_currency,
        isMoneroWallet: false,
        isConvertFrom: false,
        onItemSelected: anonInvoicePageViewModel.selectCurrency,
      ),
      context: context,
    );
  }
}
