import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';

class WCHeroCard extends StatelessWidget {
  const WCHeroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CakeImageWidget(
              imageUrl: 'assets/new-ui/walletconnect_icon.svg',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            S.of(context).walletConnect,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: -0.08,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            S.of(context).wc_pairing_list_header_subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              letterSpacing: -0.06,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
