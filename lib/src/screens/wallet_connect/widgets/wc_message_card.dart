import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';

class WCMessageRow {
  const WCMessageRow({required this.label, required this.value});

  final String label;
  final String value;
}

class WCMessageCard extends StatelessWidget {
  const WCMessageCard({
    super.key,
    required this.message,
    this.title,
    this.extraRows = const [],
  });

  final String? title;
  final String message;
  final List<WCMessageRow> extraRows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final resolvedTitle = title ?? S.of(context).wc_message_to_sign;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resolvedTitle,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              message,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ],
          for (final row in extraRows) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: colors.outlineVariant),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    row.value,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
