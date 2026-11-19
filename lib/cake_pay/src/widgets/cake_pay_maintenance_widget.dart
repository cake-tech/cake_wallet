import "package:cake_wallet/generated/i18n.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

class CakePayMaintenanceWidget extends StatelessWidget {
  const CakePayMaintenanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                SizedBox.square(
                  dimension: 75,
                  child: Center(
                    child: SvgPicture.asset(
                      "assets/images/cake_pay_logo.svg",
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  "assets/images/warning.svg",
                  excludeFromSemantics: true,
                  colorFilter: ColorFilter.mode(colorScheme.onSurfaceVariant, BlendMode.srcIn),
                ),
              ],
            ),
            Column(
              spacing: 12,
              children: [
                Text(
                  S.of(context).cake_pay_under_maintenance,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
                Text(
                  S.of(context).please_check_back_soon,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
