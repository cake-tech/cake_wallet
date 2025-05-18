import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class SeedVerificationSuccessView extends StatelessWidget {
  const SeedVerificationSuccessView({required this.imageColor, super.key});

  final Color imageColor;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset('assets/images/seed_verified.png', color: imageColor);

    return Center(
      child: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
            child: AspectRatio(
              aspectRatio: 1.8,
              child: image,
            ),
          ),
          SizedBox(height: 16),
          Text(
            S.current.seed_verified,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                TextSpan(
                  text: S.current.seed_display_path,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
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
