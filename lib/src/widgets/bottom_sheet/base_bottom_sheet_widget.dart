import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/standard_slide_button_widget.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';

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
  }) : assert(
  footerType == FooterType.none || currentTheme != null,
  'currentTheme is required unless footerType is none'
  );


  final String titleText;
  final String? titleIconPath;
  final ThemeBase? currentTheme;
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

  Widget contentWidget(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 900),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0)),
        child: Container(
          color: Theme.of(context).dialogBackgroundColor,
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
              color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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
            color: Theme.of(context).primaryColor,
            textColor: Colors.white,
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
                  color: currentTheme!.type == ThemeType.dark
                      ? Theme.of(context).cardColor
                      : Theme.of(context).dialogBackgroundColor,
                  textColor: Theme.of(context).extension<CakeTextTheme>()!.buttonTextColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  key: rightActionButtonKey,
                  text: doubleActionRightButtonText ?? '',
                  onPressed: onRightActionButtonPressed,
                  color: Theme.of(context).primaryColor,
                  textColor: Theme.of(context).extension<CakeTextTheme>()!.buttonTextColor,
                ),
              ),
            ],
          ),
        );
    }
  }
}
