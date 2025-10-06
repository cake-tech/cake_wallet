import 'package:cake_wallet/core/email_validator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/src/screens/receive/widgets/anonpay_currency_input_field.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
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
    required this.amountController,
    required this.nameController,
    required this.emailController,
    required this.descriptionController,
    required this.depositAmountFocus,
  })  : _nameFocusNode = FocusNode(),
        _emailFocusNode = FocusNode(),
        _descriptionFocusNode = FocusNode() {
    amountController.text = anonInvoicePageViewModel.amount;
    nameController.text = anonInvoicePageViewModel.receipientName;
    descriptionController.text = anonInvoicePageViewModel.description;
    emailController.text = anonInvoicePageViewModel.receipientEmail;
  }

  final TextEditingController amountController;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController descriptionController;
  final AnonInvoicePageViewModel anonInvoicePageViewModel;
  final FocusNode depositAmountFocus;
  final FocusNode _nameFocusNode;
  final FocusNode _emailFocusNode;
  final FocusNode _descriptionFocusNode;
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (isInvoice)
            Observer(
              builder: (_) {
                return AnonpayCurrencyInputField(
                  onTapPicker: () => _presentPicker(context),
                  controller: amountController,
                  focusNode: depositAmountFocus,
                  maxAmount: anonInvoicePageViewModel.maximum?.toString() ?? '...',
                  minAmount: anonInvoicePageViewModel.minimum?.toString() ?? '...',
                  selectedCurrency: anonInvoicePageViewModel.selectedCurrency,
                );
              },
            ),
          SizedBox(height: 24),
          BaseTextFormField(
            hasUnderlineBorder: true,
            controller: nameController,
            focusNode: _nameFocusNode,
            suffixIcon: SizedBox(width: 36),
            hintText: S.of(context).optional_name,
            textInputAction: TextInputAction.next,
            placeholderTextStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            validator: null,
          ),
          SizedBox(height: 24),
          BaseTextFormField(
            hasUnderlineBorder: true,
            controller: descriptionController,
            focusNode: _descriptionFocusNode,
            textInputAction: TextInputAction.next,
            suffixIcon: SizedBox(width: 36),
            hintText: S.of(context).optional_description,
            placeholderTextStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            validator: null,
          ),
          SizedBox(height: 24),
          BaseTextFormField(
            hasUnderlineBorder: true,
            controller: emailController,
            textInputAction: TextInputAction.next,
            focusNode: _emailFocusNode,
            suffixIcon: SizedBox(width: 36),
            keyboardType: TextInputType.emailAddress,
            hintText: S.of(context).optional_email_hint,
            placeholderTextStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            validator: EmailValidator(),
          ),
          SizedBox(height: 52),
        ],
      ),
    );
  }

  void _presentPicker(BuildContext context) {
    showPopUp<void>(
      builder: (_) => CurrencyPicker(
        selectedAtIndex: anonInvoicePageViewModel.selectedCurrencyIndex,
        items: anonInvoicePageViewModel.currencies,
        hintText: S.of(context).search_currency,
        onItemSelected: anonInvoicePageViewModel.selectCurrency,
      ),
      context: context,
    );
  }
}
