import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/themes/core/custom_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

enum WCDappCardAction { connect, sign, connected }

class WCDappCard extends StatelessWidget {
  const WCDappCard({
    super.key,
    required this.name,
    required this.iconUrl,
    required this.subtitle,
    required this.action,
    this.verifyContext,
  });

  final String name;
  final String? iconUrl;
  final String subtitle;
  final WCDappCardAction action;
  final VerifyContext? verifyContext;

  String _actionLine(BuildContext context) {
    switch (action) {
      case WCDappCardAction.connect:
        return S.of(context).wc_would_like_to_connect_to(name);
      case WCDappCardAction.sign:
        return S.of(context).wc_would_like_to_sign(name);
      case WCDappCardAction.connected:
        return S.of(context).wc_connected_to(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CakeImageWidget(
              borderRadius: 16,
              imageUrl: iconUrl,
              fit: BoxFit.cover,
              errorWidget: CircleAvatar(
                backgroundImage: AssetImage('assets/images/walletconnect_logo.png'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _actionLine(context),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
          if (verifyContext != null) ...[
            const SizedBox(height: 10),
            _VerifyBadge(verifyContext: verifyContext!),
          ],
        ],
      ),
    );
  }
}

class _VerifyBadge extends StatelessWidget {
  const _VerifyBadge({required this.verifyContext});

  final VerifyContext verifyContext;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final IconData icon;
    final Color color;
    final String label;

    if (verifyContext.validation.scam) {
      icon = Icons.error_outline;
      color = colors.error;
      label = S.of(context).security_risk;
    } else if (verifyContext.validation.invalid) {
      icon = Icons.error_outline;
      color = colors.error;
      label = S.of(context).domain_mismatch;
    } else if (verifyContext.validation.valid) {
      icon = Icons.check_circle;
      color = CustomThemeColors.syncGreen;
      label = S.of(context).wc_verified;
    } else {
      icon = Icons.shield_outlined;
      color = CustomThemeColors.syncYellow;
      label = S.of(context).wc_could_not_verify;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
