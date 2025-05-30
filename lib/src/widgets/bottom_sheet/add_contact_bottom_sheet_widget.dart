import 'dart:async';

import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:flutter/material.dart';

class AddContactBottomSheet extends InfoBottomSheet {
  AddContactBottomSheet({
    required String titleText,
    String? titleIconPath,
    required this.currentTheme,
    required FooterType footerType,
    this.contentImage,
    this.contentImageColor,
    this.content,
    required this.onHandlerSearch,
    String? singleActionButtonText,
    VoidCallback? onSingleActionButtonPressed,
    Key? singleActionButtonKey,
    String? doubleActionLeftButtonText,
    String? doubleActionRightButtonText,
    VoidCallback? onLeftActionButtonPressed,
    VoidCallback? onRightActionButtonPressed,
    Key? leftActionButtonKey,
    Key? rightActionButtonKey,
  })  : _onSingleActionButtonPressed = onSingleActionButtonPressed,
        _singleActionButtonText = singleActionButtonText,
        _singleActionButtonKey = singleActionButtonKey,
        super(
          titleText: titleText,
          titleIconPath: titleIconPath,
          currentTheme: currentTheme,
          footerType: footerType,
          contentImage: contentImage,
          contentImageColor: contentImageColor,
          content: content,
          singleActionButtonText: singleActionButtonText,
          onSingleActionButtonPressed: onSingleActionButtonPressed,
          singleActionButtonKey: singleActionButtonKey,
          doubleActionLeftButtonText: doubleActionLeftButtonText,
          doubleActionRightButtonText: doubleActionRightButtonText,
          onLeftActionButtonPressed: onLeftActionButtonPressed,
          onRightActionButtonPressed: onRightActionButtonPressed,
          leftActionButtonKey: leftActionButtonKey,
          rightActionButtonKey: rightActionButtonKey,
        );

  final MaterialThemeBase currentTheme;
  final String? contentImage;
  final Color? contentImageColor;
  final String? content;
  final String? _singleActionButtonText;
  final VoidCallback? _onSingleActionButtonPressed;
  final Key? _singleActionButtonKey;
  final Future<List<ParsedAddress>> Function(String query) onHandlerSearch;

  @override
  Widget? buildHeader(BuildContext context) => null;

  @override
  Widget contentWidget(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return SizedBox(
      height: maxHeight,
      child: Navigator(
        onPopPage: (route, result) => route.didPop(result),
        pages: [
          MaterialPage(
            child: _MainPage(
              currentTheme: currentTheme,
              contentImage: contentImage,
              contentImageColor: contentImageColor,
              contentText: content,
              singleActionButtonText: _singleActionButtonText,
              onSingleActionButtonPressed: _onSingleActionButtonPressed,
              singleActionButtonKey: _singleActionButtonKey,
              onSearch: (query) async => await onHandlerSearch(query),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainPage extends StatefulWidget {
  const _MainPage({
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
  State<_MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<_MainPage> {
  final _controller = TextEditingController();
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
                                Navigator.of(context).push(
                                  _slideLeft(
                                    _NewDetectedContactPage(
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
                    onTap: () => Navigator.of(context).push(
                      _slideLeft(_SupportedHandlesPage(fillColor: fillColor)),
                    ),
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
          title: Text(src.parseFrom.label, style: Theme.of(context).textTheme.bodyLarge),
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
              ImageUtil.getImageFromPath(imagePath: src.parseFrom.iconPath, height: 24, width: 24),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          onTap: () => onItemSelected?.call(src),
        );
      },
    );
  }
}

class _SupportedHandlesPage extends StatelessWidget {
  const _SupportedHandlesPage({required this.fillColor});

  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supportedHandles = AddressSource.supported();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: MergeSemantics(
          child: SizedBox(
            height: 37,
            width: 37,
            child: ButtonTheme(
              minWidth: double.minPositive,
              child: Semantics(
                label: S.of(context).seed_alert_back,
                child: TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      overlayColor: WidgetStateColor.resolveWith((states) => Colors.transparent)),
                  onPressed: () => Navigator.of(context).pop(),
                  child: backButton(context),
                ),
              ),
            ),
          ),
        ),
        title: Text('Supported handles', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: HandlesListWidget(items: supportedHandles, fillColor: fillColor),
    );
  }
}

class _NewDetectedContactPage extends StatelessWidget {
  const _NewDetectedContactPage({
    required this.fillColor,
    required this.selectedParsedAddress,
    this.singleActionButtonText,
    this.onSingleActionButtonPressed,
    this.singleActionButtonKey,
  });

  final Color fillColor;
  final ParsedAddress selectedParsedAddress;
  final String? singleActionButtonText;
  final VoidCallback? onSingleActionButtonPressed;
  final Key? singleActionButtonKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          centerTitle: true,
          leading: MergeSemantics(
            child: SizedBox(
              height: 37,
              width: 37,
              child: ButtonTheme(
                minWidth: double.minPositive,
                child: Semantics(
                  label: S.of(context).seed_alert_back,
                  child: TextButton(
                    style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                        overlayColor: WidgetStateColor.resolveWith((states) => Colors.transparent)),
                    onPressed: () => Navigator.of(context).pop(),
                    child: backButton(context),
                  ),
                ),
              ),
            ),
          ),
          title: Text('New Contact', style: Theme.of(context).textTheme.titleLarge),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text(
                    'Contact info auto-detected from ${selectedParsedAddress.parseFrom.label}',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: fillColor,
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 1),
                            child: Column(
                              children: [
                                ImageUtil.getImageFromPath(
                                  imagePath: selectedParsedAddress.profileImageUrl,
                                  height: 24,
                                  width: 24,
                                ),
                                const SizedBox(height: 1),
                                Text('Icon',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 8,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    )),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 1),
                            decoration: BoxDecoration(
                              color: fillColor,
                              borderRadius: const BorderRadius.all(Radius.circular(12)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Address group name',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 8,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Text(
                                  selectedParsedAddress.profileName,
                                  style:
                                  theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
                child: LoadingPrimaryButton(
                  key: singleActionButtonKey,
                  text: singleActionButtonText ?? '',
                  onPressed: onSingleActionButtonPressed ?? () {},
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                  isLoading: false,
                  isDisabled: false,
                ),
              )
            ],
          ),
        ));
  }
}

class HandlesListWidget extends StatelessWidget {
  const HandlesListWidget({
    super.key,
    required this.items,
    required this.fillColor,
  });

  final List<AddressSource> items;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final src = items[index];
        return ListTile(
          title: Text(src.label, style: Theme.of(context).textTheme.bodyMedium),
          trailing: Text(src.alias, style: Theme.of(context).textTheme.bodyMedium),
          tileColor: fillColor,
          dense: true,
          visualDensity: VisualDensity(horizontal: 0, vertical: -3),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
          leading: ImageUtil.getImageFromPath(imagePath: src.iconPath, height: 24, width: 24),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          onTap: () {
            // Handle tap on the supported handle
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

Widget backButton(BuildContext context) => Icon(
      Icons.arrow_back_ios,
      color: Theme.of(context).colorScheme.onSurface,
      size: 16,
    );

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
