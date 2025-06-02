import 'dart:async';

import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/contact/new_contact_page.dart';
import 'package:cake_wallet/src/screens/contact/supported_handles_page.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:flutter/material.dart';

class NewContactPage extends StatefulWidget {
  const NewContactPage({
    required this.currentTheme,
    required this.onSearch,
    this.contentImage,
    this.contentImageColor,
    this.contentText,
    this.singleActionButtonText,
    this.onSingleActionButtonPressed,
    this.singleActionButtonKey,
  });

  final MaterialThemeBase currentTheme;
  final Future<List<ParsedAddress>> Function(String query) onSearch;
  final String? contentImage;
  final Color? contentImageColor;
  final String? contentText;
  final String? singleActionButtonText;
  final VoidCallback? onSingleActionButtonPressed;
  final Key? singleActionButtonKey;

  @override
  State<NewContactPage> createState() => _NewContactPageState();
}

class _NewContactPageState extends State<NewContactPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _debouncer = Duration(milliseconds: 500);
  Timer? _debounceTimer;
  List<ParsedAddress> _results = [];
  bool _isSearching = false;

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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final fillColor = widget.currentTheme.isDark
        ? CustomThemeColors.backgroundGradientColorDark
        : CustomThemeColors.backgroundGradientColorLight;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        reverse: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.contentImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ImageUtil.getImageFromPath(
                  imagePath: widget.contentImage!,
                  svgImageColor: widget.contentImageColor,
                  fit: BoxFit.contain,
                  height: 120,
                ),
              ),
            if (widget.contentText != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  widget.contentText!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge!,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  BaseTextFormField(
                    controller: _controller,
                    focusNode: _focusNode,
                    fillColor: fillColor,
                    hintText: 'Enter an address or handle',
                    onChanged: _handleChanged,
                    textStyle: Theme.of(context).textTheme.bodyMedium!,
                  ),
                  if (_results.isNotEmpty || _isSearching)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 90),
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
                              onItemSelected: (selected) {
                                _focusNode.unfocus();
                                Navigator.of(context).push(
                                  _slideLeft(
                                    EditNewContactGroupPage(
                                      fillColor: fillColor,
                                      selectedParsedAddress: selected,
                                      singleActionButtonText: S.of(context).seed_language_next,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  InkWell(
                    onTap: () {
                      _focusNode.unfocus();
                      Navigator.of(context).push(_slideLeft(SupportedHandlesPage()));
                      },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        children: [
                          Text('View supported handles',
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios,
                              size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
              child: LoadingPrimaryButton(
                key: widget.singleActionButtonKey,
                text: widget.singleActionButtonText ?? '',
                onPressed: widget.onSingleActionButtonPressed ?? () {},
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
                isLoading: false,
                isDisabled: false,
              ),
            )
          ],
        ),
      ),
    );
  }
}
class ParsedAddressListWidget extends StatelessWidget {
  const ParsedAddressListWidget(
      {super.key, required this.items, required this.fillColor, this.onItemSelected});

  final List<ParsedAddress> items;
  final Color fillColor;
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
              ImageUtil.getImageFromPath(imagePath: src.profileImageUrl, height: 24, width: 24),
              const SizedBox(width: 6),
              Text(src.profileName, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
          tileColor: fillColor,
          dense: true,
          visualDensity: VisualDensity(horizontal: 0, vertical: -3),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
          leading:
          ImageUtil.getImageFromPath(imagePath: src.addressSource.iconPath, height: 24, width: 24),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          onTap: () => onItemSelected?.call(src),
        );
      },
    );
  }
}


Route<Object?> _slideLeft(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: child,
    ),
  );
}
