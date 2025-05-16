import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/wallet_type_utils.dart';

class CreatePinWelcomePage extends BasePage {
  CreatePinWelcomePage(this.isWalletPasswordDirectInput);

  final bool isWalletPasswordDirectInput;

  static const aspectRatioImage = 1.25;
  final welcomeImageLight = Image.asset('assets/images/welcome_light.png');
  final welcomeImageDark = Image.asset('assets/images/welcome.png');

  String appTitle(BuildContext context) {
    if (isMoneroOnly) {
      return S.of(context).monero_com;
    }

    return S.of(context).cake_wallet;
  }

  String appDescription(BuildContext context) {
    if (isMoneroOnly) {
      return S.of(context).monero_com_wallet_text;
    }

    return S.of(context).new_first_wallet_text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        resizeToAvoidBottomInset: false,
        body: body(context));
  }

  @override
  Widget body(BuildContext context) {
    final welcomeImage = currentTheme.type == ThemeType.dark ? welcomeImageDark : welcomeImageLight;

    final newWalletImage = Image.asset('assets/images/new_wallet.png',
        height: 12,
        width: 12,
        color: Theme.of(context).colorScheme.surface);

    return PopScope(
      canPop: false,
      child: ScrollableWithBottomSection(
        content: Container(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    SizedBox(height: 70),
                    AspectRatio(
                      aspectRatio: aspectRatioImage,
                      child: FittedBox(child: welcomeImage, fit: BoxFit.contain),
                    ),
                    SizedBox(height: 50),
                    Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text(
                        S.of(context).welcome,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color:  Theme.of(context).colorScheme.onSurface
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text(
                        appTitle(context),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text(
                        appDescription(context),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        bottomSection: Column(
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                children: [
                  TextSpan(text: 'By continuing, you agree to our '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => Navigator.pushNamed(context, Routes.readDisclaimer),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: PrimaryImageButton(
                key: ValueKey('create_pin_welcome_page_create_a_pin_button_key'),
                onPressed: () => Navigator.pushNamed(context, Routes.welcomeWallet),
                image: newWalletImage,
                text: isWalletPasswordDirectInput ? S.current.set_up_a_wallet : S.current.set_a_pin,
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
