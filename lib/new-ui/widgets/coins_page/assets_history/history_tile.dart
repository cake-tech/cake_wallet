import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile_base.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/token_image_widget.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import "package:cake_wallet/entities/conversion_display.dart";
import "package:cake_wallet/entities/conversion_status.dart";
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:flutter/material.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    required this.amountFiat,
    required this.roundedTop,
    required this.roundedBottom,
    required this.direction,
    required this.pending,
    required this.bottomSeparator,
    required this.hasTokens,
    this.chainIconPath,
    this.asset,
    this.conversionDisplay,
  });

  final String title;
  final String date;
  final String amount;
  final String amountFiat;
  final bool roundedTop;
  final bool roundedBottom;
  final bool bottomSeparator;
  final bool hasTokens;
  final String? chainIconPath;
  final TransactionDirection direction;
  final bool pending;
  final CryptoCurrency? asset;

  /// A Stable Balance conversion this payment is part of - see [ConversionDisplay]. Null for the
  /// overwhelming majority of payments, which never touch Stable Balance. Every status (including
  /// `completed`) gets conversion-specific title text - see "Variant B" of the approved mockup:
  /// a plain "Sent"/"Received" row never actually communicates that a conversion happened.
  final ConversionDisplay? conversionDisplay;

  static const Map<ConversionStatus, Color> _statusColors = {
    ConversionStatus.pending: Color(0xFFB26A00),
    ConversionStatus.failed: Color(0xFFC93A3A),
    ConversionStatus.refundNeeded: Color(0xFFC93A3A),
    ConversionStatus.refunded: Color(0xFF8A8A93),
  };

  String _title(BuildContext context) {
    final display = conversionDisplay!;
    return switch (display.status) {
      ConversionStatus.pending => S.of(context).conversion_converting_to(display.toLabel),
      ConversionStatus.failed => S.of(context).conversion_failed,
      ConversionStatus.refundNeeded => S.of(context).conversion_failed,
      ConversionStatus.refunded => S.of(context).conversion_refunded,
      ConversionStatus.completed => S.of(context).conversion_converted_from(display.fromLabel),
    };
  }

  /// The row's subtitle line, in the same slot a plain payment's date normally occupies -
  /// "Pending"/"Refund needed" while a conversion is unsettled, else the real date like any
  /// other row.
  String _subtitle(BuildContext context) {
    final status = conversionDisplay!.status;
    if (status == ConversionStatus.pending) return S.of(context).trade_state_pending;
    // Only refundNeeded actually has something to refund - a plain `failed` never moved funds.
    if (status == ConversionStatus.refundNeeded) {
      return S.of(context).conversion_refund_needed_review;
    }
    return date;
  }

  IconData _statusIcon() {
    switch (conversionDisplay!.status) {
      case ConversionStatus.pending:
        return Icons.schedule;
      case ConversionStatus.failed:
      case ConversionStatus.refundNeeded:
        return Icons.warning_amber_rounded;
      case ConversionStatus.refunded:
      case ConversionStatus.completed:
        return Icons.check;
    }
  }

  String _getDirectionIcon() {
    if (pending) {
      return _effectiveDirection == TransactionDirection.incoming
          ? 'assets/new-ui/history-receiving.svg'
          : 'assets/new-ui/history-sending.svg';
    } else {
      return _effectiveDirection == TransactionDirection.incoming
          ? 'assets/new-ui/history-received.svg'
          : 'assets/new-ui/history-sent.svg';
    }
  }

  String _getDirectionIconToken() {
    if (pending) {
      return _effectiveDirection == TransactionDirection.incoming
          ? 'assets/new-ui/history-receiving.svg'
          : 'assets/new-ui/history-sending.svg';
    } else {
      return _effectiveDirection == TransactionDirection.incoming
          ? 'assets/new-ui/token-received.svg'
          : 'assets/new-ui/token-sent.svg';
    }
  }

  /// A settled conversion (completed/refunded) always reads as incoming, regardless of this
  /// specific record's own direction - the record [ConversionTwinCollapser] keeps for a
  /// self-transfer pair may be the outgoing leg, and the user experiences either leg as
  /// "I now have the destination asset", never as sending something away.
  TransactionDirection get _effectiveDirection =>
      conversionDisplay != null && !_showsStatusIcon ? TransactionDirection.incoming : direction;

  /// Only pending/failed/refund-needed get the status-icon-circle treatment (clock/warning) - a
  /// settled conversion (completed/refunded) shows the destination asset's own logo instead, per
  /// the earlier request that received assets show their real icon rather than a generic
  /// checkmark.
  bool get _showsStatusIcon =>
      conversionDisplay != null &&
      (conversionDisplay!.status == ConversionStatus.pending ||
          ConversionDisplayUtils.needsAttention(conversionDisplay!.status));

  Widget _getLeadingIcon(BuildContext context) {
    if (_showsStatusIcon) {
      final color =
          _statusColors[conversionDisplay!.status] ?? Theme.of(context).colorScheme.onSurface;
      return Container(
        decoration: BoxDecoration(color: color.withAlpha(35), shape: BoxShape.circle),
        child: Icon(_statusIcon(), color: color, size: 18),
      );
    }

    if (asset == CryptoCurrency.btcln) {
      return Stack(
        children: [
          CakeImageWidget(
            imageUrl: "assets/new-ui/lightning-icon.svg",
            width: 34,
            height: 34,
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onInverseSurface, shape: BoxShape.circle),
              child: CakeImageWidget(
                imageUrl: _getDirectionIconToken(),
                height: 14,
                width: 14,
                colorFilter: ColorFilter.mode(
                    _effectiveDirection == TransactionDirection.outgoing
                        ? Theme.of(context).colorScheme.inverseSurface.withAlpha(175)
                        : Colors.green,
                    BlendMode.srcIn),
              ),
            ),
          )
        ],
      );
    }

    if (hasTokens) {
      return Stack(
        children: [
          Opacity(
            opacity: pending ? 0.5 : 1,
            child: TokenImageWidget(
              imageUrl: asset?.iconPath ?? "",
              size: 34,
            ),
          ),
          Align(
              alignment: Alignment.bottomRight,
              // The Lightning badge already reads clearly in its own colorful orange/white
              // artwork (the same asset used for the pending/sent icon elsewhere on this row) -
              // forcing it through the generic black-tinted chain-badge treatment below made it
              // unreadable. Every other chain still uses that generic treatment.
              child: chainIconPath == "assets/new-ui/chain_badges/lightning.svg"
                  ? const CakeImageWidget(
                      imageUrl: "assets/new-ui/lightning-icon.svg",
                      width: 16,
                      height: 16,
                    )
                  : Container(
                      decoration: ShapeDecoration(
                          shape: RoundedSuperellipseBorder(
                              borderRadius: BorderRadius.circular(5),
                              side: BorderSide(color: Colors.black)),
                          color: Colors.white),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: CakeImageWidget(
                          imageUrl: chainIconPath,
                          width: 12,
                          height: 12,
                          colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                        ),
                      ),
                    ))
        ],
      );
    }

    return CakeImageWidget(
        imageUrl: _getDirectionIcon(),
        colorFilter: ColorFilter.mode(
            _effectiveDirection == TransactionDirection.outgoing
                ? Theme.of(context).colorScheme.inverseSurface.withAlpha(175)
                : Colors.green,
            BlendMode.srcIn));
  }

  @override
  Widget build(BuildContext context) {
    final isConversion = conversionDisplay != null;
    return HistoryTileBase(
      title: isConversion ? null : title,
      titleWidget: isConversion
          ? Text(
              _title(context),
              style: TextStyle(
                color: _statusColors[conversionDisplay!.status],
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      date: isConversion ? _subtitle(context) : date,
      dateColor: isConversion ? _statusColors[conversionDisplay!.status] : null,
      amount: amount,
      amountFiat: amountFiat,
      // Decorative: `title` already reads out sent/received/pending.
      leadingIcon: ExcludeSemantics(child: _getLeadingIcon(context)),
      roundedTop: roundedTop,
      roundedBottom: roundedBottom,
      bottomSeparator: bottomSeparator,
      asset: asset,
    );
  }
}
