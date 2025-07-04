import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/core/theme_store.dart';
import 'package:flutter/material.dart';

abstract class SheetPage extends StatelessWidget {
  SheetPage({super.key});

  MaterialThemeBase get currentTheme => getIt<ThemeStore>().currentTheme;

  Color pageBackgroundColor(BuildContext context) => Theme.of(context).colorScheme.surface;

  Color iconColor(BuildContext context) => Theme.of(context).colorScheme.onSurface;

  bool get resizeToAvoidBottomInset => false;

  Widget _backButton(BuildContext context) =>
      Icon(Icons.arrow_back_ios, size: 14, color: iconColor(context));

  void _onClose(BuildContext context) => Navigator.of(context).maybePop();

  String? get title => null;

  Widget? leading(BuildContext context) {
    if (ModalRoute.of(context)?.isFirst ?? true) return null;

    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        icon: _backButton(context),
        onPressed: () => _onClose(context),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(
          width: 24,
          height: 24,
        ),
        splashRadius: 14,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget? middle(BuildContext context) => title == null
      ? null
      : Text(
    title!,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
  );

  Widget? trailing(BuildContext context) => null;

  Widget body(BuildContext context);

  @override
  Widget build(BuildContext context) {
    Widget content = Material(
      color: pageBackgroundColor(context),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (middle(context) != null) middle(context)!,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      leading(context) ?? const SizedBox(width: 48),
                      trailing(context) ?? const SizedBox(width: 48),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(child: body(context)),
          ],
        ),
      ),
    );

    if (resizeToAvoidBottomInset) {
      content = AnimatedPadding(
        padding: MediaQuery.of(context).viewInsets,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: content,
      );
    }


    return content;

  }
}
