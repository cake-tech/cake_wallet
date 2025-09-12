import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';

abstract class InfoPage extends BasePage {
  InfoPage({
    this.imageLightPath = 'assets/images/pre_seed_light.png',
    this.imageDarkPath = 'assets/images/pre_seed_dark.png',
  });

  final String imageLightPath;
  final String imageDarkPath;

  bool get onWillPop => true;
  String get pageTitle;
  String get pageDescription;
  String get buttonText;
  Key? get buttonKey;
  void Function(BuildContext) get onPressed;

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
          (BuildContext context, Widget scaffold) => GradientBackground(scaffold: scaffold, currentTheme: currentTheme);

  @override
  Widget? leading(BuildContext context) => null;

  @override
  String get title => pageTitle;

  @override
  Widget body(BuildContext context) {
    final image = currentTheme.isDark ? imageDarkPath : imageLightPath;

    return PopScope(
      canPop: onWillPop,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: AspectRatio(
                    aspectRatio: 0.9,
                    child: CakeImageWidget(imageUrl: image),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    pageDescription,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ),
              ),
              PrimaryButton(
                key: buttonKey,
                onPressed: () => onPressed(context),
                text: buttonText,
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
