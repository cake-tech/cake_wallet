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
    final maxHeight = MediaQuery.of(context).size.height * 0.65;

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
            if (_results.isNotEmpty || _isSearching)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isSearching
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, thickness: .5),
                          itemBuilder: (_, i) {
                            final addr = _results[i];
                            return ListTile(
                              dense: true,
                              title: Text(addr.name.isEmpty ? addr.addresses.first : addr.name),
                              subtitle: addr.name.isEmpty
                                  ? null
                                  : Text(addr.addresses.first,
                                      style: Theme.of(context).textTheme.bodySmall),
                              onTap: () {
                                // pass selection back
                                Navigator.of(context).pop(addr);
                              },
                            );
                          },
                        ),
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
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        itemCount: supportedHandles.length,
        separatorBuilder: (context, index) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final src = supportedHandles[index];
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
      ),
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
