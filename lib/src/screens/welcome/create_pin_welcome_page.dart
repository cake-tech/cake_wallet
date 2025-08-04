import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/wallet_type_utils.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/animated_typing_text.dart';

class CreatePinWelcomePage extends BasePage {
  CreatePinWelcomePage(this.isWalletPasswordDirectInput);

  final bool isWalletPasswordDirectInput;

  static const imageAspectRatio = 1.25;
  static const imageMaxWidth = 600.0;
  final welcomeImageLight = 'assets/images/welcome_light_theme.svg';
  final welcomeImageDark = 'assets/images/welcome_dark_theme.svg';
  final cakeLogoLight = 'assets/images/cake_logo_light.svg';
  final cakeLogoDark = 'assets/images/cake_logo_dark.svg';

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

    return S.of(context).payment_made_easy;
  }

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => GradientBackground(scaffold: scaffold);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: false,
      body: Builder(
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
                  currentTheme.isDark
                      ? CustomThemeColors.backgroundGradientColorDark
                      : CustomThemeColors.backgroundGradientColorLight,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: body(context),
          );
        },
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    String welcomeImage;
    String cakeLogoThemed;

    if (currentTheme.isDark) {
      welcomeImage = welcomeImageDark;
      cakeLogoThemed = cakeLogoDark;
    } else {
      welcomeImage = welcomeImageLight;
      cakeLogoThemed = cakeLogoLight;
    }

    return PopScope(
      canPop: false,
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.zero,
        content: Container(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: imageMaxWidth),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: <Widget>[
                AspectRatio(
                  aspectRatio: imageAspectRatio,
                  child: FittedBox(
                    child: CakeImageWidget(
                      imageUrl: welcomeImage,
                      fit: BoxFit.contain,
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: (imageMaxWidth / imageAspectRatio) * 0.57,
                  child: Column(
                    children: <Widget>[
                      Text(
                        S.current.welcome,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 60,
                              letterSpacing: 2.5,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            S.current.to.toLowerCase(),
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(width: 8),
                          if (!isMoneroOnly) ...[
                            SizedBox(width: 8),
                            CakeImageWidget(
                              height: 40,
                              imageUrl: cakeLogoThemed,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: 8),
                          ],
                          Text(
                            appTitle(context),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      SizedBox(height: 48),
                      if (isMoneroOnly)
                        Text(
                          appDescription(context),
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      if (!isMoneroOnly)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedTypingText(
                              words: [S.current.payments, S.current.privacy, S.current.security],
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                              cursorColor: Theme.of(context).colorScheme.primary,
                              cursorHeight: 28,
                              cursorWidth: 4,
                            ),
                            SizedBox(width: 4),
                            Text(
                              S.current.made_easy,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                    ],
                  ),
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
                  TextSpan(
                    text: 'By continuing, you agree to our ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  TextSpan(
                    text: 'Terms of Service',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w700,
                        ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => Navigator.pushNamed(context, Routes.readDisclaimer),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: PrimaryButton(
                key: ValueKey('create_pin_welcome_page_create_a_pin_button_key'),
                onPressed: () => Navigator.pushNamed(context, Routes.welcomeWallet),
                text: isWalletPasswordDirectInput ? S.current.set_up_a_wallet : S.current.set_a_pin,
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
