import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/menu_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'base_bottom_sheet_widget.dart';

class LoadingBottomSheet extends BaseBottomSheet {
  LoadingBottomSheet() : super(titleText: '', titleIconPath: null);

  @override
  Widget contentWidget(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget footerWidget(BuildContext context) => const SizedBox.shrink();
}

class InfoBottomSheet extends BaseBottomSheet {
  final ThemeBase currentTheme;
  final String? contentImage;
  final Color? contentImageColor;
  final String? content;
  final bool isTwoAction;
  final bool showDontAskMeCheckbox;
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

  InfoBottomSheet({
    required String titleText,
    String? titleIconPath,
    required this.currentTheme,
    this.contentImage,
    this.contentImageColor,
    this.content,
    this.isTwoAction = false,
    this.showDontAskMeCheckbox = false,
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
  }) : super(titleText: titleText, titleIconPath: titleIconPath);

  @override
  Widget contentWidget(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Column(
        children: [
          if (contentImage != null)
            Expanded(
              flex: 4,
              child: getImage(contentImage!, imageColor: contentImageColor),
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
                    child: Text(
                      content!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          if (showDontAskMeCheckbox)
            Padding(
              padding: const EdgeInsets.only(left: 34.0),
              child: Row(
                children: [
                  SimpleCheckbox(onChanged: onCheckboxChanged),
                  const SizedBox(width: 8),
                  Text(
                    'Don’t ask me next time',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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
                  color: currentTheme.type == ThemeType.dark
                      ? Theme.of(context).extension<CakeMenuTheme>()!.backgroundColor
                      : Theme.of(context).cardColor,
                  textColor: currentTheme.type == ThemeType.dark
                      ? Theme.of(context).extension<DashboardPageTheme>()!.textColor
                      : Theme.of(context).extension<CakeTextTheme>()!.buttonTextColor,
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
                  color: Theme.of(context).primaryColor,
                  textColor: currentTheme.type == ThemeType.dark
                      ? Theme.of(context).extension<DashboardPageTheme>()!.textColor
                      : Theme.of(context).extension<CakeTextTheme>()!.buttonTextColor,
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
          color: Theme.of(context).primaryColor,
          textColor: Colors.white,
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
        checkColor: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
        activeColor: Colors.transparent,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: WidgetStateBorderSide.resolveWith((states) => BorderSide(
            color: Theme.of(context).extension<CakeTextTheme>()!.titleColor, width: 1.0)),
      ),
    );
  }
}
