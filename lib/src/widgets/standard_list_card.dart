import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';

class TradeDetailsStandardListCard extends StatelessWidget {
  TradeDetailsStandardListCard({
    required this.id,
    this.extraId,
    required this.create,
    required this.pair,
    required this.onTap,
    required this.currentTheme,
  });

  final String id;
  final String? extraId;
  final String create;
  final String pair;
  final ThemeType currentTheme;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: GestureDetector(
        onTap: () => onTap(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(
                  height: 8,
                ),
                if (extraId != null && extraId!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      extraId!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                          ),
                    ),
                  ),
                Text(
                  create,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                SizedBox(
                  height: 35,
                ),
                Text(
                  pair,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
