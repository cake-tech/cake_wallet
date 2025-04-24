import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class WCVerifyContextWidget extends StatelessWidget {
  const WCVerifyContextWidget({
    super.key,
    required this.verifyContext,
    required this.currentTheme,
  });

  final VerifyContext? verifyContext;
  final ThemeBase currentTheme;

  @override
  Widget build(BuildContext context) {
    if (verifyContext == null) {
      return const SizedBox.shrink();
    }

    if (verifyContext!.validation.scam) {
      return VerifyBanner(
        color: Theme.of(context).colorScheme.error,
        origin: verifyContext!.origin,
        title: S.current.security_risk,
        text: S.current.security_risk_description,
      );
    }
    if (verifyContext!.validation.invalid) {
      return VerifyBanner(
        color: Theme.of(context).colorScheme.error,
        origin: verifyContext!.origin,
        title: S.current.domain_mismatch,
        text: S.current.domain_mismatch_description,
      );
    }
    if (verifyContext!.validation.valid) {
      return VerifyHeader(
        iconColor: currentTheme.type == ThemeType.dark
            ? Theme.of(context).extension<DashboardPageTheme>()!.textColor
            : Theme.of(context).extension<CakeTextTheme>()!.buttonTextColor,
        title: verifyContext!.origin,
      );
    }
    return VerifyBanner(
      color: Colors.orange,
      origin: verifyContext!.origin,
      title: S.current.cannot_verify,
      text: S.current.cannot_verify_description,
    );
  }
}

class VerifyHeader extends StatelessWidget {
  const VerifyHeader({
    super.key,
    required this.iconColor,
    required this.title,
  });
  final Color iconColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shield_outlined,
          color: iconColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: iconColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class VerifyBanner extends StatelessWidget {
  const VerifyBanner({
    super.key,
    required this.origin,
    required this.title,
    required this.text,
    required this.color,
  });
  final String origin, title, text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          origin,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox.square(dimension: 8.0),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: const BorderRadius.all(Radius.circular(12.0)),
          ),
          child: Column(
            children: [
              VerifyHeader(
                iconColor: color,
                title: title,
              ),
              const SizedBox(height: 4.0),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
