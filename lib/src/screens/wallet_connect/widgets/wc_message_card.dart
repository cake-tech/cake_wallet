import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart';
import 'package:flutter/material.dart';

class WCMessageCard extends StatefulWidget {
  const WCMessageCard({
    super.key,
    required this.decoded,
    this.infoRows = const [],
    this.title,
  });

  final WCDecodedRequest decoded;
  final List<WCDecodedRow> infoRows;
  final String? title;

  @override
  State<WCMessageCard> createState() => _WCMessageCardState();
}

class _WCMessageCardState extends State<WCMessageCard> {
  bool _showRaw = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final resolvedTitle = widget.title ?? widget.decoded.actionTitle;

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
          if (widget.decoded.actionSubtitle != null &&
              widget.decoded.actionSubtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.decoded.actionSubtitle!,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
          for (final warning in widget.decoded.warnings) ...[
            const SizedBox(height: 12),
            _WarningRow(message: warning),
          ],
          for (final row in widget.decoded.rows) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: colors.outlineVariant),
            const SizedBox(height: 12),
            _DecodedRowView(row: row),
          ],
          if (widget.infoRows.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: colors.outlineVariant),
            const SizedBox(height: 12),
            for (final row in widget.infoRows) ...[
              _DecodedRowView(row: row),
              const SizedBox(height: 8),
            ],
          ],
          if (widget.decoded.rawFallback != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _showRaw = !_showRaw),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                _showRaw ? S.of(context).wc_hide_raw : S.of(context).wc_view_raw,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            if (_showRaw)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SelectableText(
                  widget.decoded.rawFallback!,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: colors.onSurfaceVariant,
                        fontFamily: 'monospace',
                        height: 1.3,
                      ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DecodedRowView extends StatelessWidget {
  const _DecodedRowView({required this.row});

  final WCDecodedRow row;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            row.label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SelectableText(
                row.value,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFamily: row.kind == WCDecodedRowKind.address ? 'monospace' : null,
                    ),
              ),
              if (row.fiatValue != null)
                Text(
                  row.fiatValue!,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WarningRow extends StatelessWidget {
  const _WarningRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: colors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: colors.onErrorContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
