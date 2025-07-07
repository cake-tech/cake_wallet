import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/address_book/sheet_page.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/rounded_icon_button.dart';
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
        _contactNameController =
        TextEditingController(text: contactViewModel.record?.name ?? ''),
        _labelController = TextEditingController(),
        _addressController = TextEditingController() {
    if (selectedParsedAddress.parsedAddressByCurrencyMap.isNotEmpty) {
      final cur = selectedParsedAddress.parsedAddressByCurrencyMap.keys.first;
      contactViewModel.currency = cur;
      _labelController.text = cur.title;
      _addressController.text =
      selectedParsedAddress.parsedAddressByCurrencyMap[cur]!;
      _currencyPicked = true;
    } else if (selectedParsedAddress.manualAddressByCurrencyMap?.isNotEmpty ==
        true) {
      final entry =
          selectedParsedAddress.manualAddressByCurrencyMap!.entries.first;
      contactViewModel.currency = entry.key;
      _labelController.text = entry.key.title;
      _addressController.text = entry.value;
      _currencyPicked = true;
    } else if (selectedParsedAddress.addressSource == AddressSource.notParsed) {
      _labelController.text = '';
      _addressController.text = selectedParsedAddress.handle;
      _currencyPicked = false;
    }
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
  bool get _isPlainFlow =>
      selectedParsedAddress.addressSource == AddressSource.notParsed;
  bool get _isManualFlow =>
      selectedParsedAddress.addressSource == AddressSource.contact;

  @override
  String? get title => _isExisting ? 'New address' : 'New contact';

  @override
  bool get resizeToAvoidBottomInset => true;

  @override
  Widget body(BuildContext context) {
    final theme = Theme.of(context);
    final showAddrFields = !_isExisting;
    return SizedBox(
      height: MediaQuery.of(context).size.height * .60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Text(
              _isHandleFlow
                  ? 'Contact info auto-detected from ${selectedParsedAddress.addressSource.label}'
                  : _isPlainFlow
                  ? 'Review & save address'
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      labelText: 'Address group name',
                      fillColor: theme.colorScheme.surfaceContainer,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                    ),
                    validator: (v) =>
                    v!.trim().isEmpty ? 'Name cannot be empty' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (showAddrFields)
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Observer(builder: (_) {
                      final cc = contactViewModel.currency;
                      return ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(
                            horizontal: 0, vertical: -3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12),
                        tileColor: theme.colorScheme.surfaceContainer,
                        leading: _currencyPicked
                            ? ImageUtil.getImageFromPath(
                            imagePath: cc.iconPath ?? '',
                            height: 24,
                            width: 24)
                            : const SizedBox(width: 24),
                        title: Text(
                          _currencyPicked
                              ? cc.fullName ?? cc.name
                              : 'Choose currency',
                          style: theme.textTheme.bodyMedium,
                        ),
                        trailing: Icon(Icons.keyboard_arrow_down_outlined,
                            color: theme.colorScheme.onSurface),
                        onTap: () => _presentCurrencyPicker(context),
                      );
                    }),
                    const SizedBox(height: 8),
                    StandardTextFormFieldWidget(
                      controller: _labelController,
                      labelText: 'Address label',
                      fillColor: theme.colorScheme.surfaceContainer,
                      readOnly: _isExisting,
                      addressValidator: _isExisting
                          ? null
                          : (v) =>
                      v == null || v.trim().isEmpty
                          ? 'Label required'
                          : null,
                      suffixIcon: _pasteButton(() async {
                        _labelController.text = await _clipboardText;
                      }),
                    ),
                    const SizedBox(height: 8),
                    StandardTextFormFieldWidget(
                      controller: _addressController,
                      labelText: S.of(context).address,
                      fillColor: theme.colorScheme.surfaceContainer,
                      readOnly: _isExisting,
                      addressValidator: null,
                      suffixIcon: _pasteButton(() async {
                        _addressController.text = await _clipboardText;
                      }),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            _nextButton(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(ThemeData theme) => ConstrainedBox(
    constraints: const BoxConstraints(
        minWidth: 44, maxWidth: 44, minHeight: 44, maxHeight: 44),
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
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontSize: 8, color: theme.hintColor))
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
      if (!_isHandleFlow &&
          !(_formKey.currentState?.validate() ?? false)) return;
      if (!_isHandleFlow && !_currencyPicked) return;

      if (_isExisting) {
        final record = contactViewModel.record!;

        if (_isManualFlow || _isPlainFlow) {
          record.setManualAddress(
            contactViewModel.currency,
            _labelController.text.trim(),
            _addressController.text.trim(),
          );
        } else {
          final key =
          '${selectedParsedAddress.addressSource.label}-${selectedParsedAddress.handle}'
              .trim();
          record.setParsedAddress(
            key,
            contactViewModel.currency,
            _labelController.text.trim(),
            _addressController.text.trim(),
          );
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

      final localImg = await ImageUtil.saveAvatarLocally(
          selectedParsedAddress.profileImageUrl);

      ParsedAddress payload;

      if (_isHandleFlow) {
        payload = selectedParsedAddress.copyWith(
          profileName: _contactNameController.text.trim(),
        );
      } else {
        payload = ParsedAddress(
          parsedAddressByCurrencyMap: const {},
          manualAddressByCurrencyMap: {
            contactViewModel.currency: _addressController.text.trim(),
          },
          addressSource: AddressSource.contact,
          handle: '',
          profileName: _contactNameController.text.trim(),
          profileImageUrl: selectedParsedAddress.profileImageUrl,
          description: '',
        );
      }

      final newContact =
      Contact.fromParsed(payload, localImage: localImg);
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

  void _presentCurrencyPicker(BuildContext context) {
    showPopUp<void>(
      context: context,
      builder: (_) => CurrencyPicker(
        selectedAtIndex: _currencyPicked
            ? contactViewModel.currencies
            .indexOf(contactViewModel.currency)
            : 0,
        items: contactViewModel.currencies,
        title: S.of(context).please_select,
        hintText: S.of(context).search_currency,
        onItemSelected: (Currency item) {
          contactViewModel.currency = item as CryptoCurrency;
          _labelController.text = contactViewModel.currency.title;
          _currencyPicked = true;
        },
      ),
    );
  }

  Future<String> get _clipboardText async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text?.trim() ?? '';
  }
}