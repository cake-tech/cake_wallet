import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';

class WCScamBanner extends StatelessWidget {
  const WCScamBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.errorContainer,
        border: Border.all(color: colors.onError, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 36,
            color: colors.error,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.of(context).wc_scam_warning_title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: colors.error,
                        letterSpacing: -0.06,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  S.of(context).wc_scam_warning_message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: colors.error,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
