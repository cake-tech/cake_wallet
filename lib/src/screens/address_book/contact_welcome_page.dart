import 'dart:async';

import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/rounded_icon_button.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/standard_text_form_field_widget.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _InputMode { handle, address }

class NewContactWelcomePage extends BasePage {
  NewContactWelcomePage({required this.onSearch, this.handleOnly = false, this.existingContact});

  final Future<List<ParsedAddress>> Function(String query) onSearch;
  final bool handleOnly;
  final ContactRecord? existingContact;

  @override
  Widget body(BuildContext context) => NewContactWelcomePageBody(
      currentTheme: currentTheme,
      onSearch: onSearch,
      handleOnly: handleOnly,
      existingContact: existingContact);
}

class NewContactWelcomePageBody extends StatefulWidget {
  const NewContactWelcomePageBody(
      {required this.currentTheme,
      required this.onSearch,
      required this.handleOnly,
      required this.existingContact});

  final MaterialThemeBase currentTheme;
  final Future<List<ParsedAddress>> Function(String query) onSearch;
  final bool handleOnly;
  final ContactRecord? existingContact;

  @override
  State<NewContactWelcomePageBody> createState() => _NewContactWelcomePageBodyState();
}

class _NewContactWelcomePageBodyState extends State<NewContactWelcomePageBody> {
  _InputMode _mode = _InputMode.handle;

  CryptoCurrency _selectedCurrency = CryptoCurrency.btc;

  final _handleCtl = TextEditingController();
  final _addressCtl = TextEditingController();

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _debouncer = Duration(milliseconds: 700);
  Timer? _debounceTimer;
  List<ParsedAddress> _results = [];
  bool _isSearching = false;
  ParsedAddress? _selected;
  String _typedAddress = '';

  final String contentImage = 'assets/images/add_contact_coins_img.png';
  final String contentText =
      'Contacts allows you to create a profile with multiple addresses, as well as detect them automatically from social media profiles. Start by entering a social handle or an address manually';

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debouncer, () async {
      if (query.trim().isEmpty) {
        setState(() => _results = []);
        return;
      }
      setState(() => _isSearching = true);
      try {
        final res = await widget.onSearch(query);
        if (mounted) setState(() => _results = res);
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _pickCurrency() {
    _focusNode.unfocus();
    showPopUp<void>(
      context: context,
      builder: (_) => CurrencyPicker(
        selectedAtIndex: CryptoCurrency.all.indexOf(_selectedCurrency),
        items: CryptoCurrency.all,
        title: S.of(context).please_select,
        hintText: S.of(context).search_currency,
        onItemSelected: (Currency c) => setState(() {
          _selectedCurrency = c as CryptoCurrency;
        }),
      ),
    );
  }

  Widget _currencyPrefix(BuildContext ctx) {
    final txtStyle = Theme.of(ctx).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600);

    return InkWell(
      splashFactory: NoSplash.splashFactory,
      onTap: _pickCurrency,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            border: Border.all(
              color: Theme.of(ctx).colorScheme.outline,
              width: 1,
            )),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ImageUtil.getImageFromPath(
              imagePath: _selectedCurrency.iconPath ?? '',
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 6),
            Text(_selectedCurrency.name.toUpperCase(), style: txtStyle),
            const Icon(Icons.keyboard_arrow_down_sharp, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _segmentedSwitcher(BuildContext ctx) {
    if (widget.handleOnly) return const SizedBox.shrink();
    final txt = Theme.of(ctx).textTheme.bodyMedium;
    final seg = (_InputMode m, String label) => ButtonSegment<_InputMode>(
          value: m,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _mode == m ? 1 : 0,
                child: const Icon(Icons.check_circle, size: 16),
              ),
              const SizedBox(width: 16),
              Text(label, style: txt),
            ],
          ),
        );

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<_InputMode>(
          segments: [seg(_InputMode.handle, 'handle'), seg(_InputMode.address, 'address')],
          selected: <_InputMode>{_mode},
          showSelectedIcon: false,
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            minimumSize: const WidgetStatePropertyAll(Size.fromHeight(44)),
            padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
          ),
          onSelectionChanged: (s) {
            final next = s.first;
            setState(() {
              _mode = next;

              if (next == _InputMode.address) {
                _selected = null;
                _results.clear();
                _isSearching = false;
                _debounceTimer?.cancel();
              } else {
                _handleChanged(_handleCtl.text);
              }
            });
          }),
    );
  }

  Widget _buildInputField() {
    final fillColor = widget.currentTheme.isDark
        ? CustomThemeColors.backgroundGradientColorDark
        : CustomThemeColors.backgroundGradientColorLight;

    final isHandleMode = widget.handleOnly ? true : _mode == _InputMode.handle;
    final hasDropdown = _results.isNotEmpty || _isSearching;

    final radius = BorderRadius.vertical(
      top: const Radius.circular(12),
      bottom: hasDropdown ? Radius.zero : const Radius.circular(12),
    );

    final outline = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide.none,
    );

    return StandardTextFormFieldWidget(
      focusNode: _focusNode,
      controller: isHandleMode ? _handleCtl : _addressCtl,
      labelText: isHandleMode ? 'Enter handle' : 'Enter address',
      fillColor: fillColor,
      onChanged: isHandleMode ? _handleChanged : (v) => setState(() => _typedAddress = v.trim()),
      prefixIcon: isHandleMode
          ? SizedBox(height: 50)
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: _currencyPrefix(context),
            ),
      prefixIconConstraints: isHandleMode
          ? const BoxConstraints(
              minWidth: 12,
              maxWidth: 12,
              minHeight: 50,
              maxHeight: 50,
            )
          : null,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 32,
        maxWidth: 40,
        minHeight: 30,
        maxHeight: 30,
      ),
      suffixIcon: RoundedIconButton(
        icon: Icons.paste_outlined,
        iconSize: 20,
        width: 38,
        height: 36,
        onPressed: () async {
          final data = await Clipboard.getData(Clipboard.kTextPlain);
          final text = data?.text?.trim() ?? '';
          if (text.isEmpty) return;

          final isHandleMode = widget.handleOnly || _mode == _InputMode.handle;

          if (isHandleMode) {
            _handleCtl.text = text;
            _handleChanged(text);
          } else {
            _addressCtl.text = text;
            setState(() => _typedAddress = text);
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      ),
      addressValidator: AddressValidator(type: _selectedCurrency),
      outline: outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final fillColor = widget.currentTheme.isDark
        ? CustomThemeColors.backgroundGradientColorDark
        : CustomThemeColors.backgroundGradientColorLight;

    final hasDropdown = _results.isNotEmpty || _isSearching;

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        reverse: true,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ImageUtil.getImageFromPath(
                  imagePath: contentImage,
                  fit: BoxFit.contain,
                  height: 120,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  contentText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge!,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 16),
                      child: SizedBox(width: double.infinity, child: _segmentedSwitcher(context)),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(),
                    if (hasDropdown)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 85),
                        decoration: BoxDecoration(
                            color: fillColor,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            )),
                        child: _isSearching
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : ParsedAddressListWidget(
                                items: _results,
                                fillColor: fillColor,
                                selected: _selected,
                                onItemSelected: (selected) {
                                  setState(() {
                                    _selected = (_selected == selected) ? null : selected;
                                  });
                                  _focusNode.unfocus();
                                },
                              ),
                      ),
                    widget.handleOnly || _mode == _InputMode.handle
                        ? InkWell(
                            splashFactory: NoSplash.splashFactory,
                            onTap: () {
                              _focusNode.unfocus();
                              Navigator.of(context).pushNamed(Routes.supportedHandlesPage);
                            },
                            child: SizedBox(
                              height: 36,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                child: Row(
                                  children: [
                                    Text('View supported handles',
                                        style: Theme.of(context).textTheme.bodyMedium),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_ios,
                                        size: 14,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(height: 36),
                  ],
                ),
              ),
              Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 8),
                  child: LoadingPrimaryButton(
                    text: S.of(context).seed_language_next,
                    onPressed: () {
                      _focusNode.unfocus();
                      if (_mode == _InputMode.handle) {
                        Navigator.pushNamed(
                          context,
                          Routes.editNewContactGroupPage,
                          arguments: [_selected!, widget.existingContact],
                        );
                        _selected = null;
                      } else {
                        final parsed = ParsedAddress(
                          parsedAddressByCurrencyMap: {},
                          manualAddressByCurrencyMap: {
                            _selectedCurrency: _typedAddress.trim(),
                          },
                          addressSource: AddressSource.contact,
                          handle: '',
                          profileName: '',
                          profileImageUrl: 'assets/images/profile.png',
                          description: '',
                        );

                        Navigator.pushNamed(
                          context,
                          Routes.editNewContactGroupPage,
                          arguments: [parsed, null],
                        );
                      }
                    },
                    color: Theme.of(context).colorScheme.primary,
                    width: 150,
                    height: 40,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                    isLoading: false,
                    isDisabled: widget.handleOnly
                        ? _selected == null || _isSearching
                        : (_mode == _InputMode.handle
                            ? _selected == null || _isSearching
                            : _typedAddress.isEmpty),
                  )),
            ],
          ),
        ),
      );
    });
  }
}

class ParsedAddressListWidget extends StatelessWidget {
  const ParsedAddressListWidget(
      {super.key,
      required this.items,
      required this.fillColor,
      this.onItemSelected,
      this.selected});

  final List<ParsedAddress> items;
  final Color fillColor;
  final ParsedAddress? selected;
  final ValueChanged<ParsedAddress>? onItemSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final src = items[index];
        return ListTile(
          title: Text(src.addressSource.label, style: Theme.of(context).textTheme.bodyLarge),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ImageUtil.getImageFromPath(
                  imagePath: src.profileImageUrl, height: 24, width: 24, borderRadius: 12),
              const SizedBox(width: 6),
              ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120, minWidth: 80),
                  child: Text(src.handle, style: Theme.of(context).textTheme.bodyLarge)),
              const SizedBox(width: 6),
              SizedBox(
                  width: 24,
                  height: 24,
                  child: selected == src
                      ? Icon(Icons.check_circle,
                          size: 20, color: Theme.of(context).colorScheme.primary)
                      : Icon(Icons.circle_outlined,
                          size: 20, color: Theme.of(context).colorScheme.primary)),
            ],
          ),
          tileColor: fillColor,
          dense: true,
          visualDensity: VisualDensity(horizontal: 0, vertical: -3),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
          leading: ImageUtil.getImageFromPath(
              imagePath: src.addressSource.iconPath, height: 24, width: 24),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          onTap: () => onItemSelected?.call(src),
        );
      },
    );
  }
}
