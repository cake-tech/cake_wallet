import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/themes/core/custom_theme_colors.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class WCVerifyContextWidget extends StatelessWidget {
  const WCVerifyContextWidget({
    super.key,
    required this.verifyContext,
    required this.currentTheme,
  });

  final VerifyContext? verifyContext;
  final MaterialThemeBase currentTheme;

  @override
  Widget build(BuildContext context) {
    if (verifyContext == null) {
      return const SizedBox.shrink();
    }

    if (verifyContext!.validation.scam) {
      return VerifyBanner(
        color: Theme.of(context).colorScheme.errorContainer,
        origin: verifyContext!.origin,
        title: S.current.security_risk,
        text: S.current.security_risk_description,
      );
    }
    if (verifyContext!.validation.invalid) {
      return VerifyBanner(
        color: Theme.of(context).colorScheme.errorContainer,
        origin: verifyContext!.origin,
        title: S.current.domain_mismatch,
        text: S.current.domain_mismatch_description,
      );
    }
    if (verifyContext!.validation.valid) {
      return VerifyHeader(
        iconColor: Theme.of(context).colorScheme.onPrimary,
        title: verifyContext!.origin,
      );
    }
    return VerifyBanner(
      color: CustomThemeColors.syncYellow,
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
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
