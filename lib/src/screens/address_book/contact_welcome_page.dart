import 'dart:async';

import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/parse_address_from_domain.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/address_book/sheet_page.dart';
import 'package:cake_wallet/src/widgets/rounded_icon_button.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/standard_text_form_field_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactWelcomePage extends SheetPage {
  ContactWelcomePage({required this.contactViewModel});

  final ContactViewModel contactViewModel;

  @override
  Widget body(BuildContext context) => _WelcomeBody(
        currentTheme: currentTheme,
        contactViewModel: contactViewModel,
      );
}

class _WelcomeBody extends StatefulWidget {
  const _WelcomeBody({required this.currentTheme, required this.contactViewModel});

  final MaterialThemeBase currentTheme;
  final ContactViewModel contactViewModel;

  @override
  State<_WelcomeBody> createState() => _WelcomeBodyState(contactViewModel);
}

class _PlainTextSelection {
  const _PlainTextSelection(this.text);

  final String text;
}

class _WelcomeBodyState extends State<_WelcomeBody> {
  _WelcomeBodyState(this.contactViewModel);

  final ContactViewModel contactViewModel;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _debouncer = const Duration(milliseconds: 700);
  final resolver = getIt<AddressResolverService>();

  Timer? _debounce;

  List<ParsedAddress> _results = [];
  bool _isSearching = false;
  ParsedAddress? _selectedHandle;
  _PlainTextSelection? _plainSelected;
  String _typedText = '';

  CryptoCurrency? _detectedCurrency;
  String? _detectedAddress;

  String get _hintText => contactViewModel.record == null
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

  Set<CryptoCurrency> _detectCurrencies(String txt) => AddressValidator.detectCurrencies(txt);

  void _handleChanged(String q) {
    _typedText = q.trim();

    setState(() {
      _results = [];
      _selectedHandle = null;
      _plainSelected = null;
      _detectedCurrency = null;
      _detectedAddress = null;
      _isSearching = _typedText.isNotEmpty;
    });

    _debounce?.cancel();

    if (_typedText.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
      return;
    }

    _debounce = Timer(_debouncer, () async {
      if (!mounted) return;

      try {
        final found = await resolver.resolve(
          query: _typedText,
          wallet: contactViewModel.wallet,
        );

        if (!mounted) return;

        if (found.isNotEmpty) {
          setState(() {
            _results = found;
            _selectedHandle = found.length == 1 ? found.first : null;
            _plainSelected = null;
            _detectedCurrency = null;
            _detectedAddress = null;
          });
        } else {
          final detected = _detectCurrencies(_typedText);
          setState(() {
            if (detected.length == 1) {
              _detectedCurrency = detected.first;
              _detectedAddress = _typedText;
            } else {
              _detectedCurrency = null;
              _detectedAddress = null;
              _plainSelected = detected.isEmpty ? _PlainTextSelection(_typedText) : null;
            }
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
    final hasDropdown =
        _results.isNotEmpty || _isSearching || _detectedCurrency != null || _plainSelected != null;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        reverse: true,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/images/add_contact_coins_img.png'),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(_hintText,
                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge)),
            SizedBox(
              height: 160,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildInput(hasDropdown),
                    if (hasDropdown) _buildDropdown() else _handlesHint(),
                  ],
                ),
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
                isDisabled: _isSearching ||
                    (_selectedHandle == null &&
                        _detectedCurrency == null &&
                        _plainSelected == null),
                onPressed: _onNextPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(bool hasDropdown) {
    final _noBorder = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(15)),
      borderSide: BorderSide.none,
    );
    return SizedBox(
      height: 50,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (hasDropdown)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: StandardTextFormFieldWidget(
              controller: _controller,
              focusNode: _focusNode,
              labelText: 'Enter an address or handle',
              fillColor: Theme.of(context).colorScheme.surfaceContainer,
              outlineInputBorder: _noBorder,
              enabledInputBorder: _noBorder,
              focusedInputBorder: _noBorder,
              onChanged: _handleChanged,
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
              validator: (_) => null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    final bgColor = Theme.of(context).colorScheme.surfaceContainerLowest;

    Widget _buildContent() {
      if (_isSearching) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      if (_results.isNotEmpty) {
        if (_results.length == 1) return _ParsedItem(item: _results.first);

        return _ParsedList(
          items: _results,
          selected: _selectedHandle,
          onSelected: (sel) {
            setState(() {
              _selectedHandle = sel;
              _plainSelected = null;
              _detectedCurrency = null;
              _detectedAddress = null;
            });
            _focusNode.unfocus();
          },
        );
      }

      if (_detectedCurrency != null) return _AddressRow(currency: _detectedCurrency!);

      if (_plainSelected != null) {
        return ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
            shape:
                const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            title: Text('No address detected proceed with plain text',
                style: Theme.of(context).textTheme.bodyLarge),
            onTap: () => _focusNode.unfocus());
      }

      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 80),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: _buildContent(),
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
        arguments: [_selectedHandle!, contactViewModel.record],
      );
    } else if (_detectedCurrency != null && _detectedAddress != null) {
      final parsed = ParsedAddress(
        parsedAddressByCurrencyMap: {},
        manualAddressByCurrencyMap: {_detectedCurrency!: _detectedAddress!.trim()},
        addressSource: AddressSource.contact,
        handle: '',
        profileName: '',
        profileImageUrl: 'assets/images/profile.png',
        description: '',
      );
      Navigator.pushNamed(
        context,
        Routes.editNewContactPage,
        arguments: [parsed, contactViewModel.record],
      );
    } else if (_plainSelected != null) {
      final parsed = ParsedAddress(
        parsedAddressByCurrencyMap: {},
        manualAddressByCurrencyMap: {},
        addressSource: AddressSource.notParsed,
        handle: '',
        profileName: '',
        profileImageUrl: '',
        description: _plainSelected!.text,
      );
      Navigator.pushNamed(
        context,
        Routes.editNewContactPage,
        arguments: [parsed, contactViewModel.record],
      );
    }

    _selectedHandle = null;
    _plainSelected = null;
    _detectedCurrency = null;
  }
}

class _ParsedItem extends StatelessWidget {
  const _ParsedItem({required this.item});

  final ParsedAddress item;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        leading: ImageUtil.getImageFromPath(
            imagePath: item.addressSource.iconPath, height: 24, width: 24),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(item.addressSource.label, style: Theme.of(context).textTheme.bodyLarge),
            Row(
              children: [
                if (item.profileImageUrl.isNotEmpty)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: ClipOval(
                      child: ImageUtil.getImageFromPath(
                        imagePath: item.profileImageUrl,
                        height: 24,
                        width: 24,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 24, height: 24),
                const SizedBox(width: 6),
                Text(item.handle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      );
}

class _ParsedList extends StatelessWidget {
  const _ParsedList({
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<ParsedAddress> items;
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
  const _AddressRow({required this.currency});

  final CryptoCurrency currency;

  @override
  Widget build(BuildContext context) => ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      leading:
          ImageUtil.getImageFromPath(imagePath: currency.iconPath ?? '', height: 24, width: 24),
      title:
          Text(currency.fullName ?? currency.title, style: Theme.of(context).textTheme.bodyLarge));
}
