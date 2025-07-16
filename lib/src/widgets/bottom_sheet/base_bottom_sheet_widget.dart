import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/standard_slide_button_widget.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:flutter/material.dart';

enum FooterType { none, slideActionButton, singleActionButton, doubleActionButton }

abstract class BaseBottomSheet extends StatelessWidget {
  const BaseBottomSheet({
    super.key,
    required this.titleText,
    this.titleIconPath,
    required this.footerType,
    this.currentTheme,
    this.slideActionButtonText,
    this.onSlideActionComplete,
    this.singleActionButtonText,
    this.accessibleNavigationModeSlideActionButtonText,
    this.onSingleActionButtonPressed,
    this.singleActionButtonKey,
    this.doubleActionLeftButtonText,
    this.doubleActionRightButtonText,
    this.onLeftActionButtonPressed,
    this.onRightActionButtonPressed,
    this.leftActionButtonKey,
    this.rightActionButtonKey,
    required this.maxHeight,
  }) : assert(footerType == FooterType.none || currentTheme != null,
            'currentTheme is required unless footerType is none');

  final String titleText;
  final String? titleIconPath;
  final MaterialThemeBase? currentTheme;
  final FooterType footerType;
  final String? slideActionButtonText;
  final VoidCallback? onSlideActionComplete;
  final String? singleActionButtonText;
  final String? accessibleNavigationModeSlideActionButtonText;
  final VoidCallback? onSingleActionButtonPressed;
  final Key? singleActionButtonKey;
  final String? doubleActionLeftButtonText;
  final String? doubleActionRightButtonText;
  final VoidCallback? onLeftActionButtonPressed;
  final VoidCallback? onRightActionButtonPressed;
  final Key? leftActionButtonKey;
  final Key? rightActionButtonKey;
  final double maxHeight;

  Widget contentWidget(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0)),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildHeader(context),
              contentWidget(context),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 64,
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (titleIconPath != null) ...[
                Image.asset(titleIconPath!, height: 24, width: 24),
                const SizedBox(width: 6),
              ],
              Text(
                titleText,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 13),
        ],
      );

  Widget _buildFooter(BuildContext context) {
    switch (footerType) {
      case FooterType.none:
        return const SizedBox.shrink();

      case FooterType.slideActionButton:
        return Padding(
          padding: const EdgeInsets.fromLTRB(40, 12, 40, 34),
          child: StandardSlideButton(
            buttonText: slideActionButtonText ?? '',
            onSlideComplete: onSlideActionComplete ?? () {},
            currentTheme: currentTheme!,
            accessibleNavigationModeButtonText: accessibleNavigationModeSlideActionButtonText ?? '',
          ),
        );

      case FooterType.singleActionButton:
        return Padding(
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
        );

      case FooterType.doubleActionButton:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 34),
          child: Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  key: leftActionButtonKey,
                  text: doubleActionLeftButtonText ?? '',
                  onPressed: onLeftActionButtonPressed,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    textColor: Theme.of(context).colorScheme.onSecondaryContainer
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  key: rightActionButtonKey,
                  text: doubleActionRightButtonText ?? '',
                  onPressed: onRightActionButtonPressed,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        );
    }
  }
}
