import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:flutter/material.dart';

class AlertButtonStyle {
  final Color backgroundColor;
  final Color textColor;
  final FontWeight fontWeight;

  const AlertButtonStyle(
      {required this.backgroundColor, required this.textColor, this.fontWeight = FontWeight.w400});

  factory AlertButtonStyle.primary(BuildContext context) => AlertButtonStyle(
        backgroundColor: Theme.of(context).colorScheme.primary,
        textColor: Theme.of(context).colorScheme.onPrimary,
      );

  factory AlertButtonStyle.secondary(BuildContext context) => AlertButtonStyle(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        textColor: Theme.of(context).colorScheme.primary,
      );

  factory AlertButtonStyle.error(BuildContext context) => AlertButtonStyle(
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      textColor: Theme.of(context).colorScheme.error,
      fontWeight: FontWeight.w500);
}

class BaseAlertDialog extends StatelessWidget {
  String? get headerText => '';

  String? get titleText => '';

  double? get titleTextSize => 18;

  String get contentText => '';

  Widget? get contentTextWidget => null;

  String get leftActionButtonText => '';

  String get rightActionButtonText => '';

  bool get isDividerExists => false;

  bool get isBottomDividerExists => true;

  VoidCallback get actionLeft => () {};

  VoidCallback get actionRight => () {};

  bool get barrierDismissible => true;

  String? get headerImageUrl => null;

  Key? leftActionButtonKey;

  Key? rightActionButtonKey;

  Key? dialogKey;

  AlertButtonStyle? get leftAlertButtonStyle => null;

  AlertButtonStyle? get rightAlertButtonStyle => null;

  bool get showLeftButton => true;

  Widget title(BuildContext context) {
    return Text(
      titleText!,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: titleTextSize,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            decoration: TextDecoration.none,
          ),
    );
  }

  Widget headerTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Text(
        headerText!,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 25,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              decoration: TextDecoration.none,
            ),
      ),
    );
  }

  Widget content(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          contentTextWidget ??
              Text(
                contentText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      decoration: TextDecoration.none,
                    ),
              ),
        ],
      ),
    );
  }

  Widget actionButtons(BuildContext context) {
    final rightButtonStyle = rightAlertButtonStyle ?? AlertButtonStyle.primary(context);
    final leftButtonStyle = leftAlertButtonStyle ?? AlertButtonStyle.secondary(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      spacing: 8,
      children: <Widget>[
        if (showLeftButton)
          Expanded(
            child: GestureDetector(
                key: leftActionButtonKey,
                onTap: actionLeft,
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999999),
                      color: leftButtonStyle.backgroundColor),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: AutoSizeText(
                        maxLines: 1,
                        leftActionButtonText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            color: leftButtonStyle.textColor,
                            fontWeight: leftButtonStyle.fontWeight)),
                  ),
                )),
          ),
        Expanded(
          child: GestureDetector(
              key: rightActionButtonKey,
              onTap: actionRight,
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999999),
                    color: rightButtonStyle.backgroundColor),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: AutoSizeText(
                      maxLines: 1,
                      rightActionButtonText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          color: rightButtonStyle.textColor,
                          fontWeight: rightButtonStyle.fontWeight)),
                ),
              )),
        ),
      ],
    );
  }

  Widget headerImage(BuildContext context, String imageUrl) {
    return Positioned(
      top: -50,
      left: 0,
      right: 0,
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: ClipOval(
          child: CakeImageWidget(imageUrl: imageUrl, width: 100, height: 100, fit: BoxFit.cover),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: key,
      onTap: () => barrierDismissible ? Navigator.of(context).pop() : null,
      child: Container(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Container(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withAlpha(25)),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () => null,
                  child: Material(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            if (headerImageUrl != null) headerImage(context, headerImageUrl!),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                if (headerImageUrl != null) const SizedBox(height: 50),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    if (headerText?.isNotEmpty ?? false) headerTitle(context),
                                    titleText != null ? title(context) : SizedBox(height: 16),
                                    isDividerExists
                                        ? Padding(
                                            padding: EdgeInsets.only(top: 16, bottom: 8),
                                            child: const HorizontalSectionDivider(),
                                          )
                                        : Offstage(),
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 25),
                                      child: content(context),
                                    )
                                  ],
                                ),
                                // if (isBottomDividerExists) const HorizontalSectionDivider(),
                                actionButtons(context)
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
