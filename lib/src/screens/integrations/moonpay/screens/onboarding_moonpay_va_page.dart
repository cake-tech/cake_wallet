import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MoonPayVAOnboardingPage extends BasePage {
  MoonPayVAOnboardingPage();

  @override
  Widget leading(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: ButtonTheme(
          minWidth: double.minPositive,
          child: Semantics(
            label: S.of(context).seed_alert_back,
            child: ModernButton(
              size: 37,
              icon: Icon(CupertinoIcons.clear_thick),
              iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
              onPressed: () => onClose(context),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return MoonPayVAOnboardingBody();
  }
}

class MoonPayVAOnboardingBody extends StatefulWidget {
  const MoonPayVAOnboardingBody({super.key});

  @override
  State<MoonPayVAOnboardingBody> createState() => _MoonPayVAOnboardingBodyState();
}

class _MoonPayVAOnboardingBodyState extends State<MoonPayVAOnboardingBody> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleTextStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        );

    final textTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        );

    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              MoonPayVAIntroPage(
                titleTextStyle: titleTextStyle,
                textTextStyle: textTextStyle,
              ),
              MoonPayVAHowItWorksPage(
                titleTextStyle: titleTextStyle,
                textTextStyle: textTextStyle,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              2,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(80),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: PrimaryButton(
            key: ValueKey('moonpay_va_onboarding_continue_button_key'),
            onPressed: () => Navigator.pushNamed(context, Routes.moonPayVASetupPage),
            text: S.of(context).continue_text,
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }
}

class MoonPayVAIntroPage extends StatelessWidget {
  const MoonPayVAIntroPage({required this.titleTextStyle, required this.textTextStyle, super.key});

  final TextStyle? titleTextStyle;
  final TextStyle? textTextStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        CakeImageWidget(imageUrl: 'assets/images/iron_icon.svg', height: 100, width: 100),
        const SizedBox(height: 40),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Iron (by Moonpay)', style: titleTextStyle),
                  const SizedBox(height: 12),
                  Text(
                      'Create a virtual bank account to receive USD or EUR directly to your wallet. No fees on incoming transfers.',
                      style: textTextStyle),
                  const SizedBox(height: 18),
                  Container(
                    height: 1,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(40),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Account details will include:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                  ),
                  const SizedBox(height: 10),
                  _BulletText(
                      text: 'Personal account number (in your name)', textStyle: textTextStyle),
                  const SizedBox(height: 8),
                  _BulletText(text: 'Receive domestic transfers', textStyle: textTextStyle),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MoonPayVAHowItWorksPage extends StatelessWidget {
  const MoonPayVAHowItWorksPage(
      {required this.titleTextStyle, required this.textTextStyle, super.key});

  final TextStyle? titleTextStyle;
  final TextStyle? textTextStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 140),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.attach_money_outlined,
                  color: Theme.of(context).colorScheme.onSurface, size: 60),
              const SizedBox(width: 10),
              Icon(Icons.arrow_forward_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant, size: 30),
              const SizedBox(width: 10),
              Icon(Icons.account_balance_outlined,
                  color: Theme.of(context).colorScheme.onSurface, size: 60),
              const SizedBox(width: 10),
              Icon(Icons.arrow_forward_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant, size: 30),
              const SizedBox(width: 10),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CakeImageWidget(imageUrl: 'assets/images/usdc_icon.svg', height: 60, width: 60),
                  Positioned(
                    right: -10,
                    bottom: -10,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      margin: const EdgeInsets.only(bottom: 1),
                      child: CakeImageWidget(
                          imageUrl: 'assets/new-ui/navbar/wallets.svg', height: 28, width: 28),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              children: [
                Text(
                  'How does it work?',
                  style: titleTextStyle,
                ),
                const SizedBox(height: 24),
                Text(
                  'USD, EUR or GBP deposited into your new virtual bank account will automatically be converted into stablecoins in your own wallet.',
                  textAlign: TextAlign.center,
                  style: textTextStyle,
                ),
                const SizedBox(height: 24),
                Text(
                  'This way, you can receive crypto payments easily without the sender needing to use crypto, or even knowing that you will receive it.',
                  textAlign: TextAlign.center,
                  style: textTextStyle,
                ),
              ],
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText({this.text, this.textStyle});

  final String? text;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text ?? '',
            style: textStyle,
          ),
        ),
      ],
    );
  }
}
