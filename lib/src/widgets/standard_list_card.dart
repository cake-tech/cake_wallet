import "package:cake_wallet/new-ui/widgets/coins_page/token_image_widget.dart";
import "package:cake_wallet/themes/core/material_base_theme.dart";
import "package:flutter/material.dart";

class TradeDetailsStandardListCard extends StatelessWidget {
  const TradeDetailsStandardListCard({
    required this.id,
    required this.create,
    required this.pair,
    required this.onTap,
    required this.currentTheme,
    this.extraId,
    this.leadingIconPath,
  });

  final String id;
  final String? extraId;
  final String create;
  final String pair;
  final ThemeType currentTheme;
  final Function onTap;
  final String? leadingIconPath;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: GestureDetector(
          onTap: () => onTap(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leadingIconPath != null) ...[
                    TokenImageWidget(imageUrl: leadingIconPath!, size: 36),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
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
                        const SizedBox(
                          height: 8,
                        ),
                        if (extraId != null && extraId!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
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
                        const SizedBox(
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
                ],
              ),
            ),
          ),
        ),
      );
}
