import 'package:auto_size_text/auto_size_text.dart';

import 'package:cake_wallet/utils/image_utill.dart';

import 'package:cake_wallet/routes.dart';
import 'package:flutter/gestures.dart';

import 'package:flutter/material.dart';

import 'base_bottom_sheet_widget.dart';

class LoadingBottomSheet extends BaseBottomSheet {
  LoadingBottomSheet({required String titleText, String? titleIconPath})
      : super(
            titleText: titleText,
            titleIconPath: titleIconPath,
            footerType: FooterType.none,
            maxHeight: 900);

  @override
  Widget contentWidget(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class InfoBottomSheet extends BaseBottomSheet {
  InfoBottomSheet({
    required String titleText,
    String? titleIconPath,
    required this.footerType,
    this.contentImage,
    this.contentImageColor,
    this.contentImageSize,
    this.contentSize,
    this.height = 200,
    this.content,
    this.bottomActionPanel,
    this.bottomTextWidget,
    this.singleActionButtonText,
    this.onSingleActionButtonPressed,
    this.singleActionButtonKey,
    this.doubleActionLeftButtonText,
    this.doubleActionRightButtonText,
    this.onLeftActionButtonPressed,
    this.onRightActionButtonPressed,
    this.leftActionButtonKey,
    this.rightActionButtonKey,
    this.showDisclaimerText = false,
    Key? key,
  }) : super(
            titleText: titleText,
            titleIconPath: titleIconPath,
            maxHeight: 900,
            footerType: footerType,
            singleActionButtonText: singleActionButtonText,
            onSingleActionButtonPressed: onSingleActionButtonPressed,
            singleActionButtonKey: singleActionButtonKey,
            doubleActionLeftButtonText: doubleActionLeftButtonText,
            doubleActionRightButtonText: doubleActionRightButtonText,
            onLeftActionButtonPressed: onLeftActionButtonPressed,
            onRightActionButtonPressed: onRightActionButtonPressed,
            leftActionButtonKey: leftActionButtonKey,
            rightActionButtonKey: rightActionButtonKey,
            key: key);

  final FooterType footerType;
  final String? contentImage;
  final Color? contentImageColor;
  final String? content;
  final double? contentSize;
  final Widget? bottomActionPanel;
  final Widget? bottomTextWidget;
  final String? singleActionButtonText;
  final VoidCallback? onSingleActionButtonPressed;
  final Key? singleActionButtonKey;
  final String? doubleActionLeftButtonText;
  final String? doubleActionRightButtonText;
  final VoidCallback? onLeftActionButtonPressed;
  final VoidCallback? onRightActionButtonPressed;
  final Key? rightActionButtonKey;
  final Key? leftActionButtonKey;
  final double height;
  final double? contentImageSize;
  final bool showDisclaimerText;

  @override
  Widget contentWidget(BuildContext context) {
    return SizedBox(
      height: height,
      child: Column(
        children: [
          if (contentImage != null)
            contentImageSize == null ? Expanded(
              flex: 4,
              child: ImageUtil.getImageFromPath(
                imagePath: contentImage!,
                svgImageColor: contentImageColor,
                fit: BoxFit.contain,
                borderRadius: 10,
              ),
            ) : Container(
              height: contentImageSize,
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: ImageUtil.getImageFromPath(
                imagePath: contentImage!,
                svgImageColor: contentImageColor,
                fit: BoxFit.contain,
                borderRadius: 10,
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
          bottomActionPanel ?? const SizedBox(),
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
                        ..onTap =
                            () => Navigator.pushNamed(context, Routes.readThirdPartyDisclaimer),
                    ),
                  ],
                ),
              ),
            ),
          if(bottomTextWidget != null) bottomTextWidget!,

        ],
      ),
    );
  }
}
