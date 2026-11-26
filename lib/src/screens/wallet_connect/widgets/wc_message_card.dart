import 'package:cake_wallet/generated/i18n.dart';
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/wc_warning_row.dart";
import "package:cw_core/utils/print_verbose.dart";
import 'package:flutter/material.dart';
import "package:reown_walletkit/reown_walletkit.dart";

class WCMessageCard extends StatefulWidget {
  const WCMessageCard({
    super.key,
    required this.decoded,
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

    return DecoratedSliver(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      sliver: SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
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
                ],
              ),
            ),
            SliverList.builder(
              itemCount: widget.decoded.warnings.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: WCWarningRow(message: widget.decoded.warnings[index]),
              ),
            ),
            SliverList.builder(
              itemCount: widget.decoded.rows.length,
              itemBuilder: (context, index) => _DividedRow(row: widget.decoded.rows[index]),
            ),
            if (widget.decoded.detailRows.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _showDetails = !_showDetails),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(
                        _showDetails
                            ? S.of(context).wc_hide_details
                            : S.of(context).wc_show_details,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_showDetails)
                SliverList.builder(
                  itemCount: widget.decoded.detailRows.length,
                  itemBuilder: (context, index) =>
                      _DividedRow(row: widget.decoded.detailRows[index]),
                ),
            ],
            if (widget.infoRows.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 12),
                  child: Divider(height: 1, color: colors.outlineVariant),
                ),
              ),
              SliverList.builder(
                itemCount: widget.infoRows.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DecodedRowView(row: widget.infoRows[index]),
                ),
              ),
            ],
            if (widget.decoded.rawFallback != null)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                fontFamily: "IBM Plex Mono",
                                height: 1.3,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DividedRow extends StatelessWidget {
  const _DividedRow({required this.row});

  final WCDecodedRow row;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 12),
          _DecodedRowView(row: row),
        ],
      );
}

class _DecodedRowView extends StatelessWidget {
  const _DecodedRowView({required this.row});

  static final _evmAddress = RegExp(r"^0x[0-9a-fA-F]{40}$");

  final WCDecodedRow row;

  bool get _isLongText => row.kind == WCDecodedRowKind.text && row.value.length > 60;

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
    final label = Text(
      row.label,
      style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
          ),
    );

    if (_isLongText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          label,
          SelectableText(
            row.value,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: label),
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
                      fontFamily: row.kind == WCDecodedRowKind.address ? "IBM Plex Mono" : null,
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
