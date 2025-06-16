import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/addresses_expansion_tile_widget.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class EditAddressPage extends BasePage {
  EditAddressPage({required this.contactViewModel})
      : _formKey = GlobalKey<FormState>(),
        manualAddress = contactViewModel.manualAddressesByCurrency[contactViewModel.initialCurrency]
                ?[contactViewModel.manualLabel] ??
            '',
        _labelController = TextEditingController(),
        _manualAddressController = TextEditingController() {
    _labelController.text = contactViewModel.manualLabel;
    _manualAddressController.text = contactViewModel.isNewAddress ? '' : manualAddress ?? '';

    _labelController.addListener(() => contactViewModel.manualLabel = _labelController.text);

    _manualAddressController
        .addListener(() => contactViewModel.manualAddress = _manualAddressController.text);
  }

  @override
  String get title => contactViewModel.isNewAddress ? 'Add Address' : 'Edit Address';

  final ContactViewModel contactViewModel;
  final GlobalKey<FormState> _formKey;
  final TextEditingController _labelController;
  final TextEditingController _manualAddressController;
  final String? manualAddress;

  Widget _circleIcon(
      {required BuildContext context,
      required IconData icon,
      required VoidCallback onPressed,
      ShapeBorder? shape,
      double? width,
      double? height,
      double? iconSize,
      Color? fillColor}) {
    final colorScheme = Theme.of(context).colorScheme;
    return RawMaterialButton(
      onPressed: onPressed,
      fillColor: fillColor ?? colorScheme.surfaceContainerHighest,
      elevation: 0,
      constraints: BoxConstraints.tightFor(width: width ?? 24, height: height ?? 24),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: shape ?? const CircleBorder(),
      child: Icon(icon, size: iconSize ?? 14, color: colorScheme.onSurface),
    );
  }

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
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
                        size: 24, color: theme.colorScheme.onSurface),
                    tileColor: fillColor,
                    dense: true,
                    visualDensity: VisualDensity(horizontal: 0, vertical: -3),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    leading: ImageUtil.getImageFromPath(
                        imagePath: initialCurrency.iconPath ?? '', height: 24, width: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    onTap: () => _presentCurrencyPicker(context, contactViewModel),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _labelController,
                    decoration: InputDecoration(
                        isDense: true,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        labelText: 'Address label',
                        labelStyle: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: Theme.of(context).hintColor),
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: Theme.of(context).hintColor),
                        fillColor: fillColor,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                            borderSide: BorderSide(color: theme.colorScheme.outline)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _circleIcon(
                              context: context,
                              icon: Icons.copy_all_outlined,
                              onPressed: () {},
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(6)))),
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 34,
                          maxWidth: 34,
                          minHeight: 24,
                          maxHeight: 24,
                        )),
                    style: theme.textTheme.bodyMedium,
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _manualAddressController,
                    decoration: InputDecoration(
                        isDense: true,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        labelText: 'Address',
                        labelStyle: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: Theme.of(context).hintColor),
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: Theme.of(context).hintColor),
                        fillColor: fillColor,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                            borderSide: BorderSide(color: theme.colorScheme.outline)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _circleIcon(
                              context: context,
                              icon: Icons.copy_all_outlined,
                              onPressed: () {},
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(6)))),
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 34,
                          maxWidth: 34,
                          minHeight: 24,
                          maxHeight: 24,
                        )),
                    style: theme.textTheme.bodyMedium,
                    onChanged: (value) {},
                    validator: AddressValidator(type: contactViewModel.currency),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    if (!contactViewModel.isNewAddress)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _circleIcon(
                            context: context,
                            icon: Icons.delete_outline_rounded,
                            onPressed: () async {
                              contactViewModel.deleteManualAddress(
                                  initialCurrency, contactViewModel.manualLabel);
                              contactViewModel.updateManualAddress();
                              await contactViewModel.save();
                              contactViewModel.reset();
                              _manualAddressController.clear();
                              Navigator.of(context, rootNavigator: true).pop();
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
                          contactViewModel.reset();
                          _labelController.clear();
                          _manualAddressController.clear();
                          Navigator.of(context, rootNavigator: true).pop();
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
                          contactViewModel.updateManualAddress();
                          await contactViewModel.save();

                          if (context.mounted && contactViewModel.state is! FailureState) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
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
