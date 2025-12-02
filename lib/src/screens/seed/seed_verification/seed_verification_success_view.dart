import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:flutter/material.dart';

class SeedVerificationSuccessView extends StatelessWidget {
  const SeedVerificationSuccessView({required this.currentTheme, super.key});

  final MaterialThemeBase currentTheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
              child: CakeImageWidget(
                height: 200,
                imageUrl: currentTheme.isDark
                    ? 'assets/images/seed_verified_dark.png'
                    : 'assets/images/seed_verified_light.png',
              ),
          ),
          SizedBox(height: 40),
          Text(
            S.current.seed_verified,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 48),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${S.current.seed_verified_subtext} ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                ),
                TextSpan(
                  text: S.current.seed_display_path,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          Spacer(),
          PrimaryButton(
            key: ValueKey('wallet_seed_page_open_wallet_button_key'),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            text: S.current.open_wallet,
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
