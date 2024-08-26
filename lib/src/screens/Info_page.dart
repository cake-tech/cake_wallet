import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';

abstract class InfoPage extends BasePage {
  InfoPage({
    this.imageLightPath = 'assets/images/pre_seed_light.png',
    this.imageDarkPath = 'assets/images/pre_seed_dark.png',
  });

  final String imageLightPath;
  final String imageDarkPath;

  Image get imageLight => Image.asset(imageLightPath);
  Image get imageDark => Image.asset(imageDarkPath);

  bool get onWillPop => true;
  String get pageTitle;
  String get pageDescription;
  String get buttonText;
  void Function(BuildContext) get onPressed;

  @override
  Widget? leading(BuildContext context) => null;

  @override
  String get title => pageTitle;

  @override
  Widget body(BuildContext context) {
    final image = currentTheme.type == ThemeType.dark ? imageDark : imageLight;

    return WillPopScope(
      onWillPop: () async => onWillPop,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.3),
                  child: AspectRatio(aspectRatio: 1, child: image),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    pageDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.7,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context)
                          .extension<CakeTextTheme>()!
                          .secondaryTextColor,
                    ),
                  ),
                ),
              ),
              PrimaryButton(
                onPressed: () => onPressed(context),
                text: buttonText,
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
