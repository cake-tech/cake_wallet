import 'package:auto_size_text/auto_size_text.dart';


import 'package:cake_wallet/utils/image_utill.dart';

import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';

import 'package:flutter/material.dart';

import 'base_bottom_sheet_widget.dart';

class LoadingBottomSheet extends BaseBottomSheet {
  LoadingBottomSheet(
      {required String titleText, required FooterType footerType, String? titleIconPath})
      : super(titleText: titleText, titleIconPath: titleIconPath, footerType: footerType);

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
    required this.currentTheme,
    required this.footerType,
    this.contentImage,
    this.contentImageColor,
    this.content,
    this.bottomActionPanel,
    this.singleActionButtonText,
    this.onSingleActionButtonPressed,
    this.singleActionButtonKey,
    this.doubleActionLeftButtonText,
    this.doubleActionRightButtonText,
    this.onLeftActionButtonPressed,
    this.onRightActionButtonPressed,
    this.leftActionButtonKey,
    this.rightActionButtonKey,
    Key? key,
  }) : super(
            titleText: titleText,
            titleIconPath: titleIconPath,
            currentTheme: currentTheme,
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

  final MaterialThemeBase currentTheme;
  final FooterType footerType;
  final String? contentImage;
  final Color? contentImageColor;
  final String? content;
  final Widget? bottomActionPanel;
  final String? singleActionButtonText;
  final VoidCallback? onSingleActionButtonPressed;
  final Key? singleActionButtonKey;
  final String? doubleActionLeftButtonText;
  final String? doubleActionRightButtonText;
  final VoidCallback? onLeftActionButtonPressed;
  final VoidCallback? onRightActionButtonPressed;
  final Key? rightActionButtonKey;
  final Key? leftActionButtonKey;

  @override
  Widget contentWidget(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Column(
        children: [
          if (contentImage != null)
            Expanded(
              flex: 4,
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
        ],
      ),
    );
  }
}
