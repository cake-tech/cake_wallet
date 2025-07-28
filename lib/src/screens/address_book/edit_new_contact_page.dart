import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/address_book/sheet_page.dart';
import 'package:cake_wallet/src/widgets/rounded_icon_button.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/standard_text_form_field_widget.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class EditNewContactPage extends SheetPage {
  EditNewContactPage({
    required this.selectedParsedAddress,
    required this.contactViewModel,
  })  : _formKey = GlobalKey<FormState>(),
        _contactNameController = TextEditingController(),
        _labelController = TextEditingController(),
        _addressController = TextEditingController() {
    _contactNameController.text = _isExisting
        ? contactViewModel.record!.profileName
        : selectedParsedAddress.profileName.isEmpty
            ? selectedParsedAddress.handle
            : selectedParsedAddress.profileName;

    contactViewModel.currency =
        _isManualFlow ? selectedParsedAddress.manualAddressByCurrencyMap?.keys.firstOrNull : null;

    if (_isManualFlow && contactViewModel.currency != null) {
      _addressController.text =
          selectedParsedAddress.manualAddressByCurrencyMap?[contactViewModel.currency!] ?? '';
    } else if (_isPlainFlow) {
      _addressController.text = selectedParsedAddress.description;
    }

    _currencyPicked = contactViewModel.currency != null;
  }

  final ParsedAddress selectedParsedAddress;
  final ContactViewModel contactViewModel;

  final GlobalKey<FormState> _formKey;
  final TextEditingController _contactNameController;
  final TextEditingController _labelController;
  final TextEditingController _addressController;

  bool _currencyPicked = false;

  bool get _isExisting => contactViewModel.record != null;

  bool get _isHandleFlow =>
      selectedParsedAddress.addressSource != AddressSource.contact &&
      selectedParsedAddress.addressSource != AddressSource.notParsed;

  bool get _isPlainFlow => selectedParsedAddress.addressSource == AddressSource.notParsed;

  bool get _isManualFlow => selectedParsedAddress.addressSource == AddressSource.contact;

  @override
  String? get title => _isExisting
      ? _isHandleFlow
          ? 'New contact info from handle'
          : 'New manual address'
      : 'New contact';

  @override
  bool get resizeToAvoidBottomInset => true;

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final showAddrFields = !_isHandleFlow;
    return SizedBox(
      height: showAddrFields
          ? MediaQuery.of(context).size.height * .45
          : MediaQuery.of(context).size.height * .35,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                _isExisting
                    ? _isHandleFlow
                        ? 'auto-detected from ${selectedParsedAddress.addressSource.label}'
                        : 'Review & save manual address'
                    : 'Choose a contact name and icon',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconBox(theme),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                        controller: _contactNameController,
                        readOnly: _isExisting,
                        decoration: InputDecoration(
                          isDense: true,
                          isCollapsed: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          labelText: 'Address group name',
                          fillColor: theme.colorScheme.surfaceContainer,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        ),
                        validator: contactViewModel.contactNameValidator),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (showAddrFields)
                Column(
                  children: [
                    Observer(
                      builder: (_) {
                        String? Function(CryptoCurrency?) currencyValidator =
                            (c) => c == null ? 'Please pick a currency' : null;

                        return FormField<CryptoCurrency>(
                          initialValue: contactViewModel.currency,
                          validator: currencyValidator,
                          builder: (field) {
                            final currency = field.value;
                            final hasError = field.hasError;
                            final scheme = Theme.of(context).colorScheme;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      width: 1.3,
                                      color: hasError ? scheme.error : Colors.transparent,
                                    ),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                    leading: currency == null
                                        ? null
                                        : ImageUtil.getImageFromPath(
                                            imagePath: currency.iconPath ?? '',
                                            height: 24,
                                            width: 24,
                                          ),
                                    title: Text(
                                      currency?.fullName ?? currency?.name ?? 'Choose currency',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    trailing: Icon(Icons.keyboard_arrow_down_outlined,
                                        color: scheme.onSurface),
                                    onTap: () async {
                                      final picked = await _presentCurrencyPicker(context);
                                      if (picked != null) {
                                        contactViewModel.currency = picked;
                                        field.didChange(picked); // refresh validator below
                                        _currencyPicked = true;
                                      }
                                    },
                                  ),
                                ),
                                if (hasError)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, left: 12),
                                    child: Text(field.errorText!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: scheme.error)),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    StandardTextFormFieldWidget(
                      controller: _labelController,
                      labelText: 'Address label',
                      fillColor: theme.colorScheme.surfaceContainer,
                      validator: contactViewModel.manualAddressLabelValidator,
                      suffixIcon: _pasteButton(() async {
                        _labelController.text = await _clipboardText;
                      }),
                    ),
                    const SizedBox(height: 8),
                    Observer(
                      builder: (_) {
                        final cur = contactViewModel.currency;
                        final String? Function(String?)? addrValidator =
                            cur == null ? null : AddressValidator(type: cur).call;

                        return StandardTextFormFieldWidget(
                          controller: _addressController,
                          labelText: S.of(context).address,
                          fillColor: theme.colorScheme.surfaceContainer,
                          validator: addrValidator,
                          suffixIcon: _pasteButton(() async {
                            _addressController.text = await _clipboardText;
                          }),
                        );
                      },
                    ),
                  ],
                ),
              const Spacer(),
              _nextButton(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBox(ThemeData theme) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, maxWidth: 44, minHeight: 44, maxHeight: 44),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 1),
            child: Column(
              children: [
                ImageUtil.getImageFromPath(
                  imagePath: selectedParsedAddress.profileImageUrl,
                  height: 24,
                  width: 24,
                  borderRadius: 30,
                ),
                const SizedBox(height: 1),
                Text('Icon',
                    style:
                        theme.textTheme.labelSmall?.copyWith(fontSize: 8, color: theme.hintColor))
              ],
            ),
          ),
        ),
      );

  Widget _pasteButton(Future<void> Function() setText) => RoundedIconButton(
        icon: Icons.paste_outlined,
        onPressed: setText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      );

  Widget _nextButton(BuildContext context) => LoadingPrimaryButton(
        text: 'Next',
        width: 150,
        height: 40,
        onPressed: () async {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          if (!_isHandleFlow && !_currencyPicked) return;

          if (_isExisting) {
            final record = contactViewModel.record!;

            if (_isManualFlow || _isPlainFlow) {
              final cur = contactViewModel.currency;

              if (cur == null) {
                return;
              }

              final label = _labelController.text.trim();
              final newAddr = _addressController.text.trim();
              final exists = record.manual[cur]?.containsKey(label) ?? false;

              if (exists) {
                await contactViewModel.saveManualAddress(
                  oldCurrency: cur,
                  selectedCurrency: cur,
                  oldLabel: label,
                  newLabel: label,
                  newAddress: newAddr,
                );
              } else {
                record.setManualAddress(cur, label, newAddr);
              }
            } else {
              final key = '${selectedParsedAddress.addressSource.label}'
                      '-${selectedParsedAddress.handle}'
                  .trim();
              for (final e in selectedParsedAddress.parsedAddressByCurrencyMap.entries) {
                record.setParsedAddress(key, e.key, e.key.title, e.value.trim());
              }
            }

            record.original
              ..lastChange = DateTime.now()
              ..save();

            if (!context.mounted) return;
            Navigator.of(context).pop();
            Navigator.pushReplacementNamed(
              context,
              Routes.contactPage,
              arguments: record,
            );
            return;
          }

          final localImg = await ImageUtil.saveAvatarLocally(selectedParsedAddress.profileImageUrl);

          ParsedAddress payload;
          if (_isHandleFlow) {
            payload = selectedParsedAddress.copyWith(
              profileName: _contactNameController.text.trim(),
            );
          } else {
            final selectedCurrency = contactViewModel.currency;
            if (selectedCurrency == null) return;
            payload = ParsedAddress(
              parsedAddressByCurrencyMap: const {},
              manualAddressByCurrencyMap: {
                selectedCurrency: _addressController.text.trim(),
              },
              addressSource: AddressSource.contact,
              handle: '',
              profileName: _contactNameController.text.trim(),
              profileImageUrl: selectedParsedAddress.profileImageUrl,
              description: '',
            );
          }

          final newContact = Contact.fromParsed(payload, localImage: localImg);
          contactViewModel.box.add(newContact);
          final record = ContactRecord(contactViewModel.box, newContact);
          if (!context.mounted) return;
          Navigator.pushReplacementNamed(
            context,
            Routes.contactPage,
            arguments: record,
          );
        },
        color: Theme.of(context).colorScheme.primary,
        textColor: Theme.of(context).colorScheme.onPrimary,
        isLoading: false,
        isDisabled: false,
      );

  Future<CryptoCurrency?> _presentCurrencyPicker(BuildContext context) async {
    CryptoCurrency? currency;
    await showPopUp<CryptoCurrency?>(
      context: context,
      builder: (_) => CurrencyPicker(
        selectedAtIndex: _currencyPicked && contactViewModel.currency != null
            ? contactViewModel.currencies.indexOf(contactViewModel.currency!)
            : 0,
        items: contactViewModel.currencies,
        title: S.of(context).please_select,
        hintText: S.of(context).search_currency,
        onItemSelected: (Currency item) {
          currency = item as CryptoCurrency;
        },
      ),
    );
    return currency;
  }

  Future<String> get _clipboardText async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text?.trim() ?? '';
  }
}
