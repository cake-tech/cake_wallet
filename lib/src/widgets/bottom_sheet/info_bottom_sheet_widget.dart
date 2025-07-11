import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'base_bottom_sheet_widget.dart';

class LoadingBottomSheet extends BaseBottomSheet {
  LoadingBottomSheet({required String titleText, String? titleIconPath})
      : super(titleText: titleText, titleIconPath: titleIconPath);

  @override
  Widget contentWidget(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget footerWidget(BuildContext context) => const SizedBox(height: 94);
}

class InfoBottomSheet extends BaseBottomSheet {
  final MaterialThemeBase currentTheme;
  final String? contentImage;
  final Color? contentImageColor;
  final String? content;
  final bool isTwoAction;
  final bool showDontAskMeCheckbox;
  final bool showDisclaimerText;
  final Function(bool)? onCheckboxChanged;
  final String? actionButtonText;
  final VoidCallback? actionButton;
  final Key? actionButtonKey;
  final String? leftButtonText;
  final String? rightButtonText;
  final VoidCallback? actionLeftButton;
  final VoidCallback? actionRightButton;
  final Key? rightActionButtonKey;
  final Key? leftActionButtonKey;
  final double height;
  final double? contentImageSize;

  InfoBottomSheet({
    required String titleText,
    String? titleIconPath,
    required this.currentTheme,
    this.contentImage,
    this.contentImageColor,
    this.contentImageSize,
    this.content,
    this.isTwoAction = false,
    this.showDontAskMeCheckbox = false,
    this.showDisclaimerText = false,
    this.height = 200,
    this.onCheckboxChanged,
    this.actionButtonText,
    this.actionButton,
    this.actionButtonKey,
    this.leftButtonText,
    this.rightButtonText,
    this.actionLeftButton,
    this.actionRightButton,
    this.rightActionButtonKey,
    this.leftActionButtonKey,
    double maxHeight = 900,
  }) : super(titleText: titleText, titleIconPath: titleIconPath, maxHeight: maxHeight);

  @override
  Widget contentWidget(BuildContext context) {
    return SizedBox(
      height: height,
      child: Column(
        children: [
          if (contentImage != null)
            Expanded(
              flex: 4,
              child: SizedBox(
                width: contentImageSize,
                child: getImage(contentImage!, imageColor: contentImageColor),
              ),
            )
          else
            Container(),
          if (content != null)
            Expanded(
              flex: 2,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),
                  Expanded(
                    flex: 6,
                    child: AutoSizeText(
                      content!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            decoration: TextDecoration.none,
                          ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          if (showDisclaimerText)
            Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 10),
                child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                children: [
                  TextSpan(
                    text: 'By continuing you agree to this ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: 'disclaimer',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w700,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => Navigator.pushNamed(context, Routes.readThirdPartyDisclaimer),
                  ),
                ],
              ),
            ),
            ),
          if (showDontAskMeCheckbox)
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Row(
                children: [
                  SimpleCheckbox(onChanged: onCheckboxChanged),
                  const SizedBox(width: 8),
                  Text(
                    'Don’t ask me next time',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          decoration: TextDecoration.none,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget footerWidget(BuildContext context) {
    if (isTwoAction) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 34),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                child: PrimaryButton(
                  key: leftActionButtonKey,
                  onPressed: actionLeftButton,
                  text: leftButtonText ?? '',
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                child: PrimaryButton(
                  key: rightActionButtonKey,
                  onPressed: actionRightButton,
                  text: rightButtonText ?? '',
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
        child: LoadingPrimaryButton(
          key: actionButtonKey,
          onPressed: actionButton ?? () {},
          text: actionButtonText ?? '',
          color: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
          isLoading: false,
          isDisabled: false,
        ),
      );
    }
  }

  Widget getImage(String imagePath, {Color? imageColor}) {
    final bool isSvg = imagePath.endsWith('.svg');
    if (isSvg) {
      return SvgPicture.asset(
        imagePath,
        colorFilter: imageColor != null ? ColorFilter.mode(imageColor, BlendMode.srcIn) : null,
      );
    } else {
      return Image.asset(imagePath);
    }
  }
}

class SimpleCheckbox extends StatefulWidget {
  SimpleCheckbox({this.onChanged});

  final Function(bool)? onChanged;

  @override
  State<SimpleCheckbox> createState() => _SimpleCheckboxState();
}

class _SimpleCheckboxState extends State<SimpleCheckbox> {
  bool initialValue = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24.0,
      width: 24.0,
      child: Checkbox(
        value: initialValue,
        onChanged: (value) => setState(() {
          initialValue = value!;
          widget.onChanged?.call(value);
        }),
        checkColor: Theme.of(context).colorScheme.onSurfaceVariant,
        activeColor: Colors.transparent,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: WidgetStateBorderSide.resolveWith((states) =>
            BorderSide(color: Theme.of(context).colorScheme.onSurfaceVariant, width: 1.0)),
      ),
    );
  }
}
