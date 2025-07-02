import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/address_book/sheet_page.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/rounded_icon_button.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/standard_text_form_field_widget.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class EditAddressPage extends SheetPage {
  EditAddressPage({required this.contactViewModel})
      : _formKey = GlobalKey<FormState>(),
        _labelController = TextEditingController(text: contactViewModel.label),
        _addressController = TextEditingController(text: contactViewModel.address) {
    _labelController.addListener(() => contactViewModel.label = _labelController.text);
    _addressController.addListener(() => contactViewModel.address = _addressController.text);
  }

  @override
  String get title => contactViewModel.isAddressEdit ? 'Edit Address' : 'Add Address';

  final ContactViewModel contactViewModel;
  final GlobalKey<FormState> _formKey;
  final TextEditingController _labelController;
  final TextEditingController _addressController;

  @override
  Widget body(BuildContext context) {
    final fillColor = currentTheme.isDark
        ? CustomThemeColors.backgroundGradientColorDark.withAlpha(100)
        : CustomThemeColors.backgroundGradientColorLight;

    return Observer(builder: (_) {
      final initialCurrency = contactViewModel.currency;
      return Padding(
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
                      title: Text(initialCurrency.fullName ?? initialCurrency.name,
                          style: Theme.of(context).textTheme.bodyMedium),
                      trailing: Icon(Icons.keyboard_arrow_down_outlined,
                          size: 24, color: Theme.of(context).colorScheme.onSurface),
                      tileColor: fillColor,
                      dense: true,
                      visualDensity: VisualDensity(horizontal: 0, vertical: -3),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      leading: ImageUtil.getImageFromPath(
                          imagePath: initialCurrency.iconPath ?? '', height: 24, width: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                      ),
                      onTap: () => _presentCurrencyPicker(context, contactViewModel)),
                  const SizedBox(height: 8),
                  StandardTextFormFieldWidget(
                    controller: _labelController,
                    labelText: 'Address label',
                    fillColor: fillColor,
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
                    addressValidator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Label cannot be empty';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  StandardTextFormFieldWidget(
                      controller: _addressController,
                      labelText: S.of(context).address,
                      fillColor: fillColor,
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
                      addressValidator: AddressValidator(type: contactViewModel.currency)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    if (contactViewModel.isAddressEdit)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: RoundedIconButton(
                            iconWidget: Image.asset(
                              'assets/images/trash_can_icon.png',
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                            onPressed: () async {
                              await contactViewModel.deleteCurrentAddress();
                              if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            width: 40,
                            height: 40,
                            iconSize: 30,
                            fillColor: Theme.of(context).colorScheme.errorContainer),
                      ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: fillColor,
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
                          if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
                            return;
                          }
                          if (contactViewModel.mode == ContactEditMode.manualAddress) {
                            await contactViewModel.saveManualAddress();
                          } else {
                            await contactViewModel.saveParsedAddress();
                          }
                          if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
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
      );
    });
  }
}

void _presentCurrencyPicker(BuildContext context, ContactViewModel contactViewModel) {
  showPopUp<void>(
    builder: (_) => CurrencyPicker(
        selectedAtIndex: contactViewModel.currencies.indexOf(contactViewModel.currency),
        items: contactViewModel.currencies,
        title: S.of(context).please_select,
        hintText: S.of(context).search_currency,
        onItemSelected: (Currency item) => contactViewModel.currency = item as CryptoCurrency),
    context: context,
  );
}
