import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/address_book/sheet_page.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/rounded_icon_button.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/standard_text_form_field_widget.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class EditAddressPage extends SheetPage {
  EditAddressPage(this.list)
      : contactViewModel = list[0] as ContactViewModel,
        _formKey = GlobalKey<FormState>(),
        _oldLabel = list[2] as String,
        _initialCur = list[1] as CryptoCurrency,
        _labelController = TextEditingController(),
        _addressController = TextEditingController() {
    contactViewModel.currency = _initialCur;
    _labelController.text = _oldLabel;
    _addressController.text = contactViewModel.manual[contactViewModel.currency]?[_oldLabel] ?? '';
  }

  final List<dynamic> list;
  final ContactViewModel contactViewModel;
  final GlobalKey<FormState> _formKey;
  final String _oldLabel;
  final CryptoCurrency _initialCur;
  final TextEditingController _labelController;
  final TextEditingController _addressController;

  @override
  String get title => 'Edit Address';

  @override
  bool get resizeToAvoidBottomInset => true;

  @override
  Widget body(BuildContext context) {
    return Observer(builder: (_) {
      final selectedCurrency = contactViewModel.currency!;
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.35,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    ListTile(
                        title: Text(selectedCurrency.fullName ?? selectedCurrency.name,
                            style: Theme.of(context).textTheme.bodyMedium),
                        trailing: Icon(Icons.keyboard_arrow_down_outlined,
                            size: 24, color: Theme.of(context).colorScheme.onSurface),
                        tileColor: Theme.of(context).colorScheme.surfaceContainer,
                        dense: true,
                        visualDensity: VisualDensity(horizontal: 0, vertical: -3),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        leading: ImageUtil.getImageFromPath(
                            imagePath: selectedCurrency.iconPath ?? '', height: 24, width: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                        ),
                        onTap: () => _presentCurrencyPicker(context, contactViewModel)),
                    const SizedBox(height: 8),
                    StandardTextFormFieldWidget(
                        controller: _labelController,
                        labelText: 'Address label',
                        fillColor: Theme.of(context).colorScheme.surfaceContainer,
                        suffixIcon: RoundedIconButton(
                            icon: Icons.paste_outlined,
                            onPressed: () async {
                              final data = await Clipboard.getData(Clipboard.kTextPlain);
                              final text = data?.text ?? '';
                              if (text.trim().isEmpty) return;
                              _labelController.text = text.trim();
                            },
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(6)))),
                        validator: contactViewModel.manualAddressLabelValidator),
                    const SizedBox(height: 8),
                    StandardTextFormFieldWidget(
                        controller: _addressController,
                        labelText: S.of(context).address,
                        fillColor: Theme.of(context).colorScheme.surfaceContainer,
                        suffixIcon: RoundedIconButton(
                            icon: Icons.paste_outlined,
                            onPressed: () async {
                              final data = await Clipboard.getData(Clipboard.kTextPlain);
                              final text = data?.text ?? '';
                              if (text.trim().isEmpty) return;
                              _addressController.text = text.trim();
                            },
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(6)))),
                        validator: AddressValidator(type: contactViewModel.currency!)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: RoundedIconButton(
                            iconWidget: Image.asset('assets/images/trash_can_icon.png',
                                color: Theme.of(context).colorScheme.onErrorContainer),
                            onPressed: () async {
                              await contactViewModel.deleteManualAddress(
                                  currency: contactViewModel.currency!, label: _oldLabel);
                              if (context.mounted) Navigator.of(context).pop();
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            width: 36,
                            height: 36,
                            iconSize: 24,
                            fillColor: Theme.of(context).colorScheme.errorContainer),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            S.of(context).cancel,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!(_formKey.currentState?.validate() ?? false)) return;

                            await contactViewModel.saveManualAddress(
                              oldCurrency: _initialCur,
                              selectedCurrency: contactViewModel.currency!,
                              oldLabel: _oldLabel,
                              newLabel: _labelController.text.trim(),
                              newAddress: _addressController.text.trim(),
                            );

                            if (context.mounted) Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            S.of(context).save,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

void _presentCurrencyPicker(BuildContext context, ContactViewModel contactViewModel) {
  showPopUp<void>(
    builder: (_) => CurrencyPicker(
        selectedAtIndex: contactViewModel.currencies.indexOf(contactViewModel.currency!),
        items: contactViewModel.currencies,
        title: S.of(context).please_select,
        hintText: S.of(context).search_currency,
        onItemSelected: (Currency item) => contactViewModel.currency = item as CryptoCurrency),
    context: context,
  );
}
