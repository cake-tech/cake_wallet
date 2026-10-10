import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:flutter/material.dart";
import "package:reown_walletkit/reown_walletkit.dart";

class WCMessageCard extends StatefulWidget {
  const WCMessageCard({
    required this.decoded,
    super.key,
    this.infoRows = const [],
  });

  final WCDecodedRequest decoded;
  final List<WCDecodedRow> infoRows;

  @override
  State<WCMessageCard> createState() => _WCMessageCardState();
}

class _WCMessageCardState extends State<WCMessageCard> {
  bool _showRaw = false;
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
            widget.decoded.actionTitle,
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
          if (widget.decoded.detailRows.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _showDetails = !_showDetails),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                _showDetails ? S.of(context).wc_hide_details : S.of(context).wc_show_details,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            if (_showDetails)
              for (final row in widget.decoded.detailRows) ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: colors.outlineVariant),
                const SizedBox(height: 12),
                _DecodedRowView(row: row),
              ],
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
                        fontFamily: "monospace",
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

  static final _evmAddress = RegExp(r"^0x[0-9a-fA-F]{40}$");

  final WCDecodedRow row;
  String get _value {
    if (row.kind != WCDecodedRowKind.address || !_evmAddress.hasMatch(row.value)) {
      return row.value;
    }
    try {
      return EthereumAddress.fromHex(row.value).hexEip55;
    } catch (e) {
      printV("WCMessageCard: could not checksum ${row.label}: $e");
      return row.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isAmount = row.kind == WCDecodedRowKind.amount;
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
                _value,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: isAmount ? colors.onSurface : colors.onSurfaceVariant,
                      fontWeight: isAmount ? FontWeight.w600 : null,
                      fontFamily: row.kind == WCDecodedRowKind.address ? "monospace" : null,
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
