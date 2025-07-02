import 'dart:async';

import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/address_book/sheet_page.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/rounded_icon_button.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/standard_text_form_field_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactWelcomePage extends SheetPage {
  ContactWelcomePage({
    required this.onSearch,
    this.existingContact,
    Key? key,
  });

  final Future<List<ParsedAddress>> Function(String query) onSearch;
  final ContactRecord? existingContact;

  @override
  Widget body(BuildContext context) => _WelcomeBody(
    currentTheme: currentTheme,
    onSearch: onSearch,
    existingContact: existingContact,
  );
}

class _WelcomeBody extends StatefulWidget {
  const _WelcomeBody({
    required this.currentTheme,
    required this.onSearch,
    required this.existingContact,
    Key? key,
  }) : super(key: key);

  final MaterialThemeBase currentTheme;
  final Future<List<ParsedAddress>> Function(String query) onSearch;
  final ContactRecord? existingContact;

  @override
  State<_WelcomeBody> createState() => _WelcomeBodyState();
}

class _WelcomeBodyState extends State<_WelcomeBody> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _debouncer = const Duration(milliseconds: 700);
  Timer? _debounce;

  List<ParsedAddress> _results = [];
  bool _isSearching = false;
  ParsedAddress? _selectedHandle;
  String _typedText = '';

  CryptoCurrency? _detectedCurrency;
  String? _detectedAddress;

  String get _hintText => widget.existingContact == null
      ? 'Contacts allows you to create a profile with multiple addresses, as well as detect them automatically from social media profiles. Start by entering a social handle or an address manually'
      : 'Add a new address or handle';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => _handleChanged(_controller.text));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  CryptoCurrency? _detectCurrency(String text) {
    for (final cur in CryptoCurrency.all) {
      final pattern =
          AddressValidator.getAddressFromStringPattern(cur) ?? AddressValidator.getPattern(cur);
      if (pattern.isEmpty) continue;
      if (RegExp(pattern, caseSensitive: false).hasMatch(text)) return cur;
    }
    return null;
  }

  void _handleChanged(String q) {
    _typedText = q.trim();
    _debounce?.cancel();
    _debounce = Timer(_debouncer, () async {
      if (!mounted) return;
      if (_typedText.isEmpty) {
        setState(() {
          _results = [];
          _detectedCurrency = null;
          _detectedAddress = null;
        });
        return;
      }

      setState(() => _isSearching = true);

      try {
        final found = await widget.onSearch(_typedText);
        if (!mounted) return;

        if (found.isNotEmpty) {
          setState(() {
            _results = found;
            _detectedCurrency = null;
            _detectedAddress = null;
          });
        } else {
          final cur = _detectCurrency(_typedText);
          setState(() {
            _results = [];
            _detectedCurrency = cur;
            _detectedAddress = cur != null ? _typedText : null;
          });
        }
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final fillColor = widget.currentTheme.isDark
        ? CustomThemeColors.backgroundGradientColorDark
        : CustomThemeColors.backgroundGradientColorLight;

    final hasDropdown = _results.isNotEmpty || _isSearching || _detectedCurrency != null;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        reverse: true,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          children: [
            Image.asset(
              'assets/images/add_contact_coins_img.png',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_hintText,
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildInput(fillColor),
                  if (hasDropdown) _buildDropdown(fillColor) else _handlesHint(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: LoadingPrimaryButton(
                text: S.of(context).seed_language_next,
                width: 150,
                height: 40,
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
                isLoading: false,
                isDisabled: _isSearching || (_selectedHandle == null && _detectedCurrency == null),
                onPressed: _onNextPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(Color fillColor) {
    final radius = BorderRadius.vertical(
      top: const Radius.circular(12),
      bottom: (_results.isNotEmpty || _isSearching || _detectedCurrency != null)
          ? Radius.zero
          : const Radius.circular(12),
    );

    return StandardTextFormFieldWidget(
      controller: _controller,
      focusNode: _focusNode,
      labelText: 'Enter an address or handle',
      fillColor: Theme.of(context).colorScheme.surfaceContainer,
      onChanged: _handleChanged,
      outline: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      suffixIconConstraints: const BoxConstraints(minWidth: 32, maxWidth: 40),
      suffixIcon: RoundedIconButton(
        icon: Icons.paste_outlined,
        iconSize: 20,
        width: 38,
        height: 36,
        onPressed: () async {
          final data = await Clipboard.getData(Clipboard.kTextPlain);
          final txt = data?.text?.trim() ?? '';
          if (txt.isEmpty) return;
          _controller.text = txt;
          _handleChanged(txt);
        },
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
      ),
      addressValidator: (_) {},
    );
  }

  Widget _buildDropdown(Color fillColor) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: _isSearching
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      )
          : _results.isNotEmpty
          ? _ParsedList(
        items: _results,
        fillColor: fillColor,
        selected: _selectedHandle,
        onSelected: (sel) {
          setState(() {
            _selectedHandle = (_selectedHandle == sel) ? null : sel;
            _detectedCurrency = null;
            _detectedAddress = null;
          });
          _focusNode.unfocus();
        },
      )
          : _detectedCurrency != null
          ? _AddressRow(
        currency: _detectedCurrency!,
        address: _detectedAddress!,
        selected: true,
        fillColor: fillColor,
        onTap: () {
          setState(() {
            _detectedCurrency = null;
            _detectedAddress = null;
          });
        },
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _handlesHint() => InkWell(
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
            Text('View supported handles', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    ),
  );

  void _onNextPressed() {
    _focusNode.unfocus();

    if (_selectedHandle != null) {
      Navigator.pushNamed(
        context,
        Routes.editNewContactPage,
        arguments: [_selectedHandle!, widget.existingContact],
      );
    } else if (_detectedCurrency != null && _detectedAddress != null) {
      final parsed = ParsedAddress(
        parsedAddressByCurrencyMap: {},
        manualAddressByCurrencyMap: {
          _detectedCurrency!: _detectedAddress!.trim(),
        },
        addressSource: AddressSource.contact,
        handle: '',
        profileName: '',
        profileImageUrl: 'assets/images/profile.png',
        description: '',
      );

      Navigator.pushNamed(
        context,
        Routes.editNewContactPage,
        arguments: [parsed, widget.existingContact],
      );
    }

    _selectedHandle = null;
    _detectedCurrency = null;
  }
}

class _ParsedList extends StatelessWidget {
  const _ParsedList({
    required this.items,
    required this.fillColor,
    required this.selected,
    required this.onSelected,
  });

  final List<ParsedAddress> items;
  final Color fillColor;
  final ParsedAddress? selected;
  final ValueChanged<ParsedAddress> onSelected;

  @override
  Widget build(BuildContext context) => ListView.separated(
    shrinkWrap: true,
    itemCount: items.length,
    separatorBuilder: (_, __) => const SizedBox(height: 6),
    itemBuilder: (_, i) {
      final p = items[i];
      return ListTile(
        tileColor: fillColor,
        dense: true,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        leading: ImageUtil.getImageFromPath(
          imagePath: p.addressSource.iconPath,
          height: 24,
          width: 24,
        ),
        title: Text(p.addressSource.label, style: Theme.of(context).textTheme.bodyLarge),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120, minWidth: 80),
              child: Text(p.handle,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
            const SizedBox(width: 6),
            Icon(selected == p ? Icons.check_circle : Icons.circle_outlined,
                size: 20, color: Theme.of(context).colorScheme.primary),
          ],
        ),
        onTap: () => onSelected(p),
      );
    },
  );
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.currency,
    required this.address,
    required this.selected,
    required this.fillColor,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  final CryptoCurrency currency;
  final String address;
  final bool selected;
  final Color fillColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    tileColor: fillColor,
    dense: true,
    visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    leading: ImageUtil.getImageFromPath(
      imagePath: currency.iconPath ?? '',
      height: 24,
      width: 24,
    ),
    title: Text(currency.title, style: Theme.of(context).textTheme.bodyLarge),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(address,
              overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyLarge),
        ),
        const SizedBox(width: 6),
        Icon(selected ? Icons.check_circle : Icons.circle_outlined,
            size: 20, color: Theme.of(context).colorScheme.primary),
      ],
    ),
    onTap: onTap,
  );
}